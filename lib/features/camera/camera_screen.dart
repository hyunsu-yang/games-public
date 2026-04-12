import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/database/database_helper.dart';
import '../../core/models/photo.dart';
import '../../shared/utils/image_utils.dart';
import '../../shared/widgets/loading_overlay.dart';
import '../puzzle/puzzle_selection_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _cameraIndex = 0;
  bool _isInitialising = false;
  bool _isProcessing = false;
  File? _capturedFile;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    if (_isInitialising) return;
    setState(() => _isInitialising = true);
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) return;
      await _controller?.dispose();
      _controller = CameraController(
        _cameras[_cameraIndex],
        ResolutionPreset.high,
        enableAudio: false,
      );
      await _controller!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      // Camera unavailable — user must use gallery
    } finally {
      if (mounted) setState(() => _isInitialising = false);
    }
  }

  Future<void> _toggleCamera() async {
    if (_cameras.length < 2) return;
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    await _initCamera();
  }

  Future<void> _onShutter() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    try {
      final xFile = await _controller!.takePicture();
      setState(() => _capturedFile = File(xFile.path));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.errorGeneral)),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final xFile =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (xFile == null) return;
    setState(() => _capturedFile = File(xFile.path));
  }

  Future<void> _usePhoto() async {
    if (_capturedFile == null) return;
    setState(() => _isProcessing = true);
    try {
      // Normalize + thumbnail in isolates
      final normalized =
          await ImageUtils.normalizeImage(_capturedFile!);
      final thumbnail =
          await ImageUtils.createThumbnail(normalized);

      final photo = Photo(
        id: const Uuid().v4(),
        filePath: normalized.path,
        thumbnailPath: thumbnail.path,
        createdAt: DateTime.now(),
      );
      await DatabaseHelper.instance.insertPhoto(photo);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => PuzzleSelectionScreen(photo: photo)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.errorImageLoad)),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: WithLoadingOverlay(
        isLoading: _isProcessing,
        message: '사진 처리 중...',
        child: _capturedFile != null
            ? _PreviewScreen(
                file: _capturedFile!,
                onRetake: () =>
                    setState(() => _capturedFile = null),
                onUse: _usePhoto,
              )
            : _CameraViewport(
                controller: _controller,
                isInitialising: _isInitialising,
                onShutter: _onShutter,
                onGallery: _pickFromGallery,
                onToggle: _cameras.length > 1 ? _toggleCamera : null,
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _CameraViewport extends StatelessWidget {
  const _CameraViewport({
    required this.controller,
    required this.isInitialising,
    required this.onShutter,
    required this.onGallery,
    this.onToggle,
  });

  final CameraController? controller;
  final bool isInitialising;
  final VoidCallback onShutter;
  final VoidCallback onGallery;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (controller != null && controller!.value.isInitialized)
          CameraPreview(controller!)
        else if (isInitialising)
          const Center(
            child: CircularProgressIndicator(color: Colors.white),
          )
        else
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.no_photography_rounded,
                    color: Colors.white, size: 64),
                const SizedBox(height: AppSizes.md),
                Text(
                  AppStrings.cameraPermissionMsg,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

        // Controls overlay
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Gallery button
                  _CircleButton(
                    icon: Icons.photo_library_rounded,
                    size: 52,
                    onTap: onGallery,
                    tooltip: AppStrings.galleryButton,
                  ),

                  // Shutter
                  GestureDetector(
                    onTap: onShutter,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(
                            color: AppColors.primary, width: 4),
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        size: 36,
                        color: AppColors.primary,
                      ),
                    ),
                  ),

                  // Flip camera
                  _CircleButton(
                    icon: Icons.flip_camera_ios_rounded,
                    size: 52,
                    onTap: onToggle,
                    tooltip: '카메라 전환',
                  ),
                ],
              ),
            ),
          ),
        ),

        // Back button
        Positioned(
          top: 0,
          left: 0,
          child: SafeArea(
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded,
                  color: Colors.white, size: 28),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.size,
    this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final double size;
  final VoidCallback? onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withAlpha(120),
        ),
        child: Icon(icon, color: Colors.white, size: size * 0.5),
      ),
    );
    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _PreviewScreen extends StatelessWidget {
  const _PreviewScreen({
    required this.file,
    required this.onRetake,
    required this.onUse,
  });

  final File file;
  final VoidCallback onRetake;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Image.file(file, fit: BoxFit.contain),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.lg),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onRetake,
                    icon: const Icon(Icons.replay_rounded),
                    label: Text(AppStrings.retake),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
                      minimumSize:
                          const Size.fromHeight(AppSizes.minTouchTarget),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusLg),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onUse,
                    icon: const Icon(Icons.check_rounded),
                    label: Text(AppStrings.usePhoto),
                    style: ElevatedButton.styleFrom(
                      minimumSize:
                          const Size.fromHeight(AppSizes.minTouchTarget),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
