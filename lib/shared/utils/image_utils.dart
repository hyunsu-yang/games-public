import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_sizes.dart';

/// Structural effects for spot-the-difference patches.
enum _DiffEffect { mirror, shift, cloneFill, scaleUp }

/// Candidate region scored by edge density for difference placement.
typedef _RegionCandidate = ({int cx, int cy, int radius, double score});

/// Image utilities: resize, crop, thumbnail, and tile slicing.
///
/// All heavy operations run in a Dart [Isolate] to avoid blocking the UI.
abstract final class ImageUtils {
  static const _uuid = Uuid();

  // ── Resize & normalise ───────────────────────────────────────────────────

  /// Resize [srcFile] so neither dimension exceeds [AppSizes.maxImageDimension].
  /// Returns a new file in the app documents directory.
  static Future<File> normalizeImage(File srcFile) async {
    return Isolate.run(() => _normalizeSync(srcFile.path));
  }

  static File _normalizeSync(String srcPath) {
    final bytes = File(srcPath).readAsBytesSync();
    var image = img.decodeImage(bytes);
    if (image == null) throw Exception('Cannot decode image: $srcPath');

    final max = AppSizes.maxImageDimension;
    if (image.width > max || image.height > max) {
      image = img.copyResize(
        image,
        width: image.width > image.height ? max : -1,
        height: image.height >= image.width ? max : -1,
        interpolation: img.Interpolation.linear,
      );
    }

    final outDir = Directory(srcPath).parent.path;
    final outPath = p.join(outDir, '${_Uuid.short()}_norm.png');
    File(outPath).writeAsBytesSync(img.encodePng(image));
    return File(outPath);
  }

  // ── Thumbnail ────────────────────────────────────────────────────────────

  static Future<File> createThumbnail(File srcFile,
      {int size = 256}) async {
    return Isolate.run(() => _thumbnailSync(srcFile.path, size));
  }

  static File _thumbnailSync(String srcPath, int size) {
    final bytes = File(srcPath).readAsBytesSync();
    var image = img.decodeImage(bytes);
    if (image == null) throw Exception('Cannot decode image: $srcPath');

    // Crop to square first
    final minDim = image.width < image.height ? image.width : image.height;
    image = img.copyCrop(
      image,
      x: (image.width - minDim) ~/ 2,
      y: (image.height - minDim) ~/ 2,
      width: minDim,
      height: minDim,
    );
    image = img.copyResize(image, width: size, height: size);

    final outDir = Directory(srcPath).parent.path;
    final outPath = p.join(outDir, '${_Uuid.short()}_thumb.png');
    File(outPath).writeAsBytesSync(img.encodePng(image));
    return File(outPath);
  }

  // ── Tile slicing ─────────────────────────────────────────────────────────

  /// Slice [srcFile] into a grid of image tiles.
  ///
  /// [gridSmall] and [gridLarge] are the two grid dimensions.
  /// The smaller value is assigned to the image's shorter side,
  /// the larger value to the longer side. This ensures the puzzle
  /// matches the photo orientation (portrait or landscape).
  ///
  /// For square grids (slide/rotate), pass the same value for both.
  static Future<SlicedTilesResult> sliceIntoTiles(
      File srcFile, int gridSmall, int gridLarge) async {
    return Isolate.run(
        () => _sliceTilesSync(srcFile.path, gridSmall, gridLarge));
  }

  static SlicedTilesResult _sliceTilesSync(
      String srcPath, int gridSmall, int gridLarge) {
    final bytes = File(srcPath).readAsBytesSync();
    final image = img.decodeImage(bytes);
    if (image == null) throw Exception('Cannot decode image: $srcPath');

    // Assign grid dimensions based on image orientation
    final bool isLandscape = image.width > image.height;
    final int cols = isLandscape ? gridLarge : gridSmall;
    final int rows = isLandscape ? gridSmall : gridLarge;

    final tileW = image.width ~/ cols;
    final tileH = image.height ~/ rows;
    final tiles = <Uint8List>[];

    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        final tile = img.Image(
          width: tileW,
          height: tileH,
          format: image.format,
          numChannels: image.numChannels,
        );
        for (var y = 0; y < tileH; y++) {
          for (var x = 0; x < tileW; x++) {
            tile.setPixel(
                x, y, image.getPixel(col * tileW + x, row * tileH + y));
          }
        }
        tiles.add(Uint8List.fromList(img.encodePng(tile)));
      }
    }

    return SlicedTilesResult(
      tiles: tiles,
      cols: cols,
      rows: rows,
      imageWidth: image.width,
      imageHeight: image.height,
    );
  }

  // ── Spot-the-difference transformation ──────────────────────────────────

  /// Produce a modified version of [srcFile] with [count] structural differences.
  /// Uses Sobel edge detection to place differences on visually interesting
  /// regions, then applies object-level modifications (mirror, shift,
  /// clone-fill, blur). Returns regions as [cx, cy, radius].
  static Future<SpotDiffResult> generateSpotDifferences(
      File srcFile, int count) async {
    return Isolate.run(() => _genDiffSync(srcFile.path, count));
  }

  static SpotDiffResult _genDiffSync(String srcPath, int count) {
    final bytes = File(srcPath).readAsBytesSync();
    var original = img.decodeImage(bytes);
    if (original == null) throw Exception('Cannot decode image: $srcPath');

    // Square crop
    final minDim =
        original.width < original.height ? original.width : original.height;
    original = img.copyCrop(
      original,
      x: (original.width - minDim) ~/ 2,
      y: (original.height - minDim) ~/ 2,
      width: minDim,
      height: minDim,
    );

    final modified = img.Image.from(original);
    final rng = Random();
    final baseRadius = original.width ~/ 12;

    // Find regions with high edge density (objects / details)
    final selected =
        _findInterestingRegions(original, count, baseRadius, rng);

    final regions = <List<int>>[];
    for (final c in selected) {
      regions.add([c.cx, c.cy, c.radius]);
      final effect =
          _DiffEffect.values[rng.nextInt(_DiffEffect.values.length)];
      _applyStructuralEffect(
          original, modified, c.cx, c.cy, c.radius, effect, rng);
    }

    return SpotDiffResult(
      originalBytes: Uint8List.fromList(img.encodePng(original)),
      modifiedBytes: Uint8List.fromList(img.encodePng(modified)),
      differenceRegions: regions,
      imageWidth: original.width,
      imageHeight: original.height,
    );
  }

  /// Score candidate grid positions by Sobel edge density,
  /// then return top [count] non-overlapping regions.
  static List<_RegionCandidate> _findInterestingRegions(
      img.Image image, int count, int baseRadius, Random rng) {
    final step = baseRadius;
    final margin = baseRadius;
    final candidates = <_RegionCandidate>[];

    for (var cy = margin; cy < image.height - margin; cy += step) {
      for (var cx = margin; cx < image.width - margin; cx += step) {
        final radius =
            baseRadius + rng.nextInt(baseRadius ~/ 3 + 1) - baseRadius ~/ 6;
        final score = _edgeDensity(image, cx, cy, radius);
        candidates.add((cx: cx, cy: cy, radius: radius, score: score));
      }
    }

    // Highest edge density first
    candidates.sort((a, b) => b.score.compareTo(a.score));

    // Greedy non-overlapping selection
    final selected = <_RegionCandidate>[];
    for (final c in candidates) {
      if (selected.length >= count) break;
      bool overlaps = false;
      for (final s in selected) {
        final dx = c.cx - s.cx;
        final dy = c.cy - s.cy;
        final minDist = c.radius + s.radius;
        if (dx * dx + dy * dy < minDist * minDist) {
          overlaps = true;
          break;
        }
      }
      if (!overlaps) selected.add(c);
    }

    return selected;
  }

  /// Average Sobel gradient magnitude in a circular area (sampled every 3px).
  static double _edgeDensity(img.Image image, int cx, int cy, int radius) {
    double total = 0;
    int cnt = 0;
    final rSq = radius * radius;

    for (var y = cy - radius; y <= cy + radius; y += 3) {
      for (var x = cx - radius; x <= cx + radius; x += 3) {
        if (x < 1 || x >= image.width - 1 ||
            y < 1 || y >= image.height - 1) {
          continue;
        }
        final dx = x - cx;
        final dy = y - cy;
        if (dx * dx + dy * dy > rSq) continue;

        final gx = _grayAt(image, x + 1, y) - _grayAt(image, x - 1, y);
        final gy = _grayAt(image, x, y + 1) - _grayAt(image, x, y - 1);
        total += sqrt(gx * gx + gy * gy);
        cnt++;
      }
    }
    return cnt > 0 ? total / cnt : 0;
  }

  static double _grayAt(img.Image image, int x, int y) {
    final p = image.getPixel(x, y);
    return p.r * 0.299 + p.g * 0.587 + p.b * 0.114;
  }

  /// Apply a structural modification inside a feathered circle.
  /// Reads source pixels from [original], writes to [modified].
  static void _applyStructuralEffect(
      img.Image original,
      img.Image modified,
      int cx,
      int cy,
      int radius,
      _DiffEffect effect,
      Random rng) {
    final innerR = radius * 0.6;
    final rSq = radius * radius;
    final iSq = innerR * innerR;
    final featherW = radius - innerR;

    final x0 = (cx - radius).clamp(0, original.width - 1);
    final y0 = (cy - radius).clamp(0, original.height - 1);
    final x1 = (cx + radius).clamp(0, original.width - 1);
    final y1 = (cy + radius).clamp(0, original.height - 1);

    // Pre-compute per-effect parameters
    int shiftX = 0, shiftY = 0;
    int cloneCx = cx, cloneCy = cy;

    if (effect == _DiffEffect.shift) {
      final angle = rng.nextDouble() * 2 * pi;
      final dist = radius * (0.15 + rng.nextDouble() * 0.1);
      shiftX = (cos(angle) * dist).round();
      shiftY = (sin(angle) * dist).round();
    } else if (effect == _DiffEffect.cloneFill) {
      final angle = rng.nextDouble() * 2 * pi;
      cloneCx = (cx + cos(angle) * radius * 2.5)
          .round()
          .clamp(radius, original.width - radius - 1);
      cloneCy = (cy + sin(angle) * radius * 2.5)
          .round()
          .clamp(radius, original.height - radius - 1);
    }

    for (var py = y0; py <= y1; py++) {
      for (var px = x0; px <= x1; px++) {
        final dx = px - cx;
        final dy = py - cy;
        final distSq = dx * dx + dy * dy;
        if (distSq > rSq) continue;

        // Feather: 1.0 in inner core, fading to 0.0 at edge
        final double blend;
        if (distSq <= iSq) {
          blend = 1.0;
        } else {
          blend = (radius - sqrt(distSq.toDouble())) / featherW;
        }

        final orig = original.getPixel(px, py);
        int nr, ng, nb;

        switch (effect) {
          case _DiffEffect.mirror:
            final mx = (2 * cx - px).clamp(0, original.width - 1);
            final src = original.getPixel(mx, py);
            nr = _lerpInt(orig.r.toInt(), src.r.toInt(), blend);
            ng = _lerpInt(orig.g.toInt(), src.g.toInt(), blend);
            nb = _lerpInt(orig.b.toInt(), src.b.toInt(), blend);

          case _DiffEffect.shift:
            final sx = (px - shiftX).clamp(0, original.width - 1);
            final sy = (py - shiftY).clamp(0, original.height - 1);
            final src = original.getPixel(sx, sy);
            nr = _lerpInt(orig.r.toInt(), src.r.toInt(), blend);
            ng = _lerpInt(orig.g.toInt(), src.g.toInt(), blend);
            nb = _lerpInt(orig.b.toInt(), src.b.toInt(), blend);

          case _DiffEffect.cloneFill:
            final sx = (cloneCx + dx).clamp(0, original.width - 1);
            final sy = (cloneCy + dy).clamp(0, original.height - 1);
            final src = original.getPixel(sx, sy);
            nr = _lerpInt(orig.r.toInt(), src.r.toInt(), blend);
            ng = _lerpInt(orig.g.toInt(), src.g.toInt(), blend);
            nb = _lerpInt(orig.b.toInt(), src.b.toInt(), blend);

          case _DiffEffect.scaleUp:
            // ~15% zoom — same object, slightly larger
            final sx = (cx + dx / 1.15).round().clamp(0, original.width - 1);
            final sy = (cy + dy / 1.15).round().clamp(0, original.height - 1);
            final src = original.getPixel(sx, sy);
            nr = _lerpInt(orig.r.toInt(), src.r.toInt(), blend);
            ng = _lerpInt(orig.g.toInt(), src.g.toInt(), blend);
            nb = _lerpInt(orig.b.toInt(), src.b.toInt(), blend);
        }

        modified.setPixelRgba(px, py, nr, ng, nb, orig.a.toInt());
      }
    }
  }

  static int _lerpInt(int a, int b, double t) =>
      (a + (b - a) * t).round().clamp(0, 255);

  // ── File helpers ─────────────────────────────────────────────────────────

  static Future<Directory> get _appImagesDir async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'puzzle_images'));
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  static Future<String> newImagePath([String suffix = 'jpg']) async {
    final dir = await _appImagesDir;
    return p.join(dir.path, '${_uuid.v4()}.$suffix');
  }
}

/// Result of [ImageUtils.sliceIntoTiles].
class SlicedTilesResult {
  const SlicedTilesResult({
    required this.tiles,
    required this.cols,
    required this.rows,
    required this.imageWidth,
    required this.imageHeight,
  });

  final List<Uint8List> tiles;
  final int cols;
  final int rows;
  final int imageWidth;
  final int imageHeight;

  double get aspectRatio => imageWidth / imageHeight;
}

/// Result of [ImageUtils.generateSpotDifferences].
class SpotDiffResult {
  const SpotDiffResult({
    required this.originalBytes,
    required this.modifiedBytes,
    required this.differenceRegions,
    required this.imageWidth,
    required this.imageHeight,
  });

  final Uint8List originalBytes;
  final Uint8List modifiedBytes;

  /// List of [cx, cy, radius] int lists (one per difference).
  final List<List<int>> differenceRegions;

  /// Actual pixel dimensions of the processed image (regions are in this coordinate space).
  final int imageWidth;
  final int imageHeight;
}

/// Tiny non-crypto UUID helper for sync isolate code (no async allowed).
abstract final class _Uuid {
  static int _counter = 0;
  static String short() =>
      '${DateTime.now().millisecondsSinceEpoch}_${_counter++}';
}
