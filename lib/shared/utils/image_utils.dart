import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_sizes.dart';

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

    // Auto brightness correction
    image = img.adjustColor(image, brightness: 0.05);

    final outDir = Directory(srcPath).parent.path;
    final outPath = p.join(outDir, '${_Uuid.short()}_norm.jpg');
    File(outPath).writeAsBytesSync(img.encodeJpg(image, quality: 90));
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
    final outPath = p.join(outDir, '${_Uuid.short()}_thumb.jpg');
    File(outPath).writeAsBytesSync(img.encodeJpg(image, quality: 80));
    return File(outPath);
  }

  // ── Tile slicing ─────────────────────────────────────────────────────────

  /// Slice [srcFile] into a [cols]×[rows] grid of image tiles.
  /// Returns a row-major list of [Uint8List] JPEG bytes.
  static Future<List<Uint8List>> sliceIntoTiles(
      File srcFile, int cols, int rows) async {
    return Isolate.run(() => _sliceTilesSync(srcFile.path, cols, rows));
  }

  static List<Uint8List> _sliceTilesSync(
      String srcPath, int cols, int rows) {
    final bytes = File(srcPath).readAsBytesSync();
    var image = img.decodeImage(bytes);
    if (image == null) throw Exception('Cannot decode image: $srcPath');

    // Ensure square crop
    final minDim = image.width < image.height ? image.width : image.height;
    image = img.copyCrop(
      image,
      x: (image.width - minDim) ~/ 2,
      y: (image.height - minDim) ~/ 2,
      width: minDim,
      height: minDim,
    );

    final tileW = image.width ~/ cols;
    final tileH = image.height ~/ rows;
    final tiles = <Uint8List>[];

    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        final tile = img.copyCrop(
          image,
          x: col * tileW,
          y: row * tileH,
          width: tileW,
          height: tileH,
        );
        tiles.add(Uint8List.fromList(img.encodeJpg(tile, quality: 85)));
      }
    }

    return tiles;
  }

  // ── Spot-the-difference transformation ──────────────────────────────────

  /// Produce a modified version of [srcFile] with [count] differences applied.
  /// Returns the modified image bytes and a list of difference region rects
  /// as [_DiffRegion] (encoded as int lists: [x, y, w, h]).
  static Future<SpotDiffResult> generateSpotDifferences(
      File srcFile, int count) async {
    return Isolate.run(() => _genDiffSync(srcFile.path, count));
  }

  static SpotDiffResult _genDiffSync(String srcPath, int count) {
    final bytes = File(srcPath).readAsBytesSync();
    var original = img.decodeImage(bytes);
    if (original == null) throw Exception('Cannot decode image: $srcPath');

    // Square crop
    final minDim = original.width < original.height ? original.width : original.height;
    original = img.copyCrop(
      original,
      x: (original.width - minDim) ~/ 2,
      y: (original.height - minDim) ~/ 2,
      width: minDim,
      height: minDim,
    );

    final modified = img.Image.from(original);
    final regions = <List<int>>[];
    final rng = img.ExternalRandom(42);

    final patchSize = original.width ~/ 6; // ~1/6 of image width per patch

    for (var i = 0; i < count; i++) {
      // Pick a region that doesn't overlap previous ones
      int x, y;
      var attempts = 0;
      do {
        x = (rng.nextDouble() * (original.width - patchSize)).toInt();
        y = (rng.nextDouble() * (original.height - patchSize)).toInt();
        attempts++;
      } while (_overlaps(regions, x, y, patchSize) && attempts < 30);

      regions.add([x, y, patchSize, patchSize]);

      // Apply a colour-inversion transform to this patch
      for (var py = y; py < y + patchSize; py++) {
        for (var px = x; px < x + patchSize; px++) {
          final pixel = modified.getPixel(px, py);
          modified.setPixelRgba(
            px,
            py,
            255 - pixel.r.toInt(),
            255 - pixel.g.toInt(),
            255 - pixel.b.toInt(),
            pixel.a.toInt(),
          );
        }
      }
    }

    return SpotDiffResult(
      originalBytes:
          Uint8List.fromList(img.encodeJpg(original, quality: 90)),
      modifiedBytes:
          Uint8List.fromList(img.encodeJpg(modified, quality: 90)),
      differenceRegions: regions,
    );
  }

  static bool _overlaps(List<List<int>> regions, int x, int y, int size) {
    for (final r in regions) {
      if (x < r[0] + r[2] &&
          x + size > r[0] &&
          y < r[1] + r[3] &&
          y + size > r[1]) {
        return true;
      }
    }
    return false;
  }

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

/// Result of [ImageUtils.generateSpotDifferences].
class SpotDiffResult {
  const SpotDiffResult({
    required this.originalBytes,
    required this.modifiedBytes,
    required this.differenceRegions,
  });

  final Uint8List originalBytes;
  final Uint8List modifiedBytes;

  /// Row-major list of [x, y, width, height] int lists (one per difference).
  final List<List<int>> differenceRegions;
}

/// Tiny non-crypto UUID helper for sync isolate code (no async allowed).
abstract final class _Uuid {
  static int _counter = 0;
  static String short() =>
      '${DateTime.now().millisecondsSinceEpoch}_${_counter++}';
}
