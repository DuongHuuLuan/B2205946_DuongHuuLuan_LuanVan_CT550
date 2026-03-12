import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:b2205946_duonghuuluan_luanvan/app/theme/colors.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/helmet_designer/domain/sticker_layer.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/helmet_designer/presentation/view/helmet_design_artwork.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/helmet_designer/presentation/viewmodel/helmet_designer_viewmodel.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart' show ShareParams, SharePlus;

class HelmetTryOnPage extends StatefulWidget {
  const HelmetTryOnPage({super.key});

  @override
  State<HelmetTryOnPage> createState() => _HelmetTryOnPageState();
}

class _HelmetTryOnPageState extends State<HelmetTryOnPage>
    with WidgetsBindingObserver {
  static const Map<DeviceOrientation, int> _orientationCompensation = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  final GlobalKey _previewBoundaryKey = GlobalKey();

  CameraController? _cameraController;
  FaceDetector? _faceDetector;
  Face? _trackedFace;
  Size? _analysisImageSize;
  bool _isInitializingCamera = true;
  bool _isProcessingFrame = false;
  bool _isCapturingPreview = false;
  String? _cameraError;
  int _frameCounter = 0;
  Duration _recordingDuration = Duration.zero;
  Timer? _recordingTimer;
  _TryOnCapturedMedia? _lastCapturedMedia;
  Uint8List? _lastCapturedImageBytes;

  bool get _isPreviewMirrored =>
      _cameraController?.description.lensDirection == CameraLensDirection.front;
  bool get _isRecordingVideo =>
      _cameraController?.value.isRecordingVideo == true;
  bool get _isRecordingPaused =>
      _cameraController?.value.isRecordingPaused == true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(_initializeTryOn);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _recordingTimer?.cancel();
    unawaited(_disposeTryOnResources());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    if (state == AppLifecycleState.inactive) {
      if (_isRecordingVideo) {
        return;
      }
      unawaited(_disposeCamera());
      return;
    }

    if (state == AppLifecycleState.resumed && _cameraController == null) {
      unawaited(_initializeTryOn());
    }
  }

  Future<void> _initializeTryOn() async {
    if (kIsWeb) {
      if (!mounted) return;
      setState(() {
        _isInitializingCamera = false;
        _cameraError =
            "Che do thu non bang camera hien chi ho tro Android va iOS.";
      });
      return;
    }

    setState(() {
      _isInitializingCamera = true;
      _cameraError = null;
      _trackedFace = null;
      _analysisImageSize = null;
    });

    await _disposeCamera();
    await _faceDetector?.close();
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.fast,
        enableContours: false,
        enableLandmarks: false,
        enableClassification: false,
        enableTracking: true,
      ),
    );

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw CameraException(
          "NoCamera",
          "Khong tim thay camera tren thiet bi nay.",
        );
      }

      final description = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        description,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: defaultTargetPlatform == TargetPlatform.iOS
            ? ImageFormatGroup.bgra8888
            : ImageFormatGroup.nv21,
      );

      await controller.initialize();
      await controller.prepareForVideoRecording();
      await controller.lockCaptureOrientation(DeviceOrientation.portraitUp);
      await controller.startImageStream(_processCameraImage);

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _cameraController = controller;
        _cameraError = null;
      });
    } on CameraException catch (e) {
      if (!mounted) return;
      setState(() {
        _cameraError = _cameraMessageFromException(e);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cameraError = "Khong the khoi dong camera: $e";
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isInitializingCamera = false;
      });
    }
  }

  Future<void> _disposeTryOnResources() async {
    await _disposeCamera();
    await _faceDetector?.close();
    _faceDetector = null;
  }

  Future<void> _disposeCamera() async {
    final controller = _cameraController;
    _cameraController = null;
    _recordingTimer?.cancel();

    if (controller == null) {
      return;
    }

    try {
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
    } catch (_) {
      // Ignore stream shutdown errors while disposing.
    }

    try {
      await controller.dispose();
    } catch (_) {
      // Ignore controller disposal errors while tearing down.
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    final detector = _faceDetector;
    final controller = _cameraController;

    if (!mounted ||
        detector == null ||
        controller == null ||
        _isProcessingFrame) {
      return;
    }

    _frameCounter = (_frameCounter + 1) % 3;
    if (_frameCounter != 0) {
      return;
    }

    final inputImage = _buildInputImage(image, controller);
    if (inputImage == null) {
      return;
    }

    _isProcessingFrame = true;
    try {
      final faces = await detector.processImage(inputImage);
      if (!mounted) return;

      final face = _selectPrimaryFace(faces);
      final rawSize = Size(image.width.toDouble(), image.height.toDouble());
      final rotation = _inputImageRotation(
        controller.description,
        controller.value.deviceOrientation,
      );

      setState(() {
        _trackedFace = face;
        _analysisImageSize = _orientedImageSize(rawSize, rotation);
      });
    } catch (_) {
      // Keep camera preview running even if one frame fails to process.
    } finally {
      _isProcessingFrame = false;
    }
  }

  InputImage? _buildInputImage(CameraImage image, CameraController controller) {
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    final rotation = _inputImageRotation(
      controller.description,
      controller.value.deviceOrientation,
    );

    if (format == null || rotation == null) {
      return null;
    }

    final bytes = WriteBuffer();
    for (final plane in image.planes) {
      bytes.putUint8List(plane.bytes);
    }

    return InputImage.fromBytes(
      bytes: bytes.done().buffer.asUint8List(),
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  InputImageRotation? _inputImageRotation(
    CameraDescription description,
    DeviceOrientation orientation,
  ) {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return InputImageRotationValue.fromRawValue(
        description.sensorOrientation,
      );
    }

    final rotationCompensation = _orientationCompensation[orientation];
    if (rotationCompensation == null) {
      return null;
    }

    final sensorOrientation = description.sensorOrientation;
    final adjustedRotation =
        description.lensDirection == CameraLensDirection.front
        ? (sensorOrientation + rotationCompensation) % 360
        : (sensorOrientation - rotationCompensation + 360) % 360;

    return InputImageRotationValue.fromRawValue(adjustedRotation);
  }

  Size _orientedImageSize(Size rawSize, InputImageRotation? rotation) {
    switch (rotation) {
      case InputImageRotation.rotation90deg:
      case InputImageRotation.rotation270deg:
        return Size(rawSize.height, rawSize.width);
      case InputImageRotation.rotation0deg:
      case InputImageRotation.rotation180deg:
      case null:
        return rawSize;
    }
  }

  Face? _selectPrimaryFace(List<Face> faces) {
    if (faces.isEmpty) {
      return null;
    }

    faces.sort((a, b) {
      final aArea = a.boundingBox.width * a.boundingBox.height;
      final bArea = b.boundingBox.width * b.boundingBox.height;
      return bArea.compareTo(aArea);
    });
    return faces.first;
  }

  Rect? _faceRectOnPreview(Size previewSize) {
    final face = _trackedFace;
    final imageSize = _analysisImageSize;
    if (face == null ||
        imageSize == null ||
        imageSize.width <= 0 ||
        imageSize.height <= 0) {
      return null;
    }

    final boundingBox = face.boundingBox;
    double left = boundingBox.left / imageSize.width * previewSize.width;
    double top = boundingBox.top / imageSize.height * previewSize.height;
    double right = boundingBox.right / imageSize.width * previewSize.width;
    double bottom = boundingBox.bottom / imageSize.height * previewSize.height;

    if (_isPreviewMirrored) {
      final mirroredLeft = previewSize.width - right;
      final mirroredRight = previewSize.width - left;
      left = mirroredLeft;
      right = mirroredRight;
    }

    return Rect.fromLTRB(
      left.clamp(0.0, previewSize.width).toDouble(),
      top.clamp(0.0, previewSize.height).toDouble(),
      right.clamp(0.0, previewSize.width).toDouble(),
      bottom.clamp(0.0, previewSize.height).toDouble(),
    );
  }

  Future<void> _capturePreview() async {
    if (_isCapturingPreview) {
      return;
    }
    if (_isRecordingVideo) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Dung quay video truoc khi chup anh preview."),
        ),
      );
      return;
    }

    setState(() {
      _isCapturingPreview = true;
    });

    try {
      Uint8List? bytes;
      final boundaryContext = _previewBoundaryKey.currentContext;
      final boundary =
          boundaryContext?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary != null) {
        final image = await boundary.toImage(pixelRatio: 2.2);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        bytes = byteData?.buffer.asUint8List();
      }

      if (bytes == null) {
        final controller = _cameraController;
        if (controller == null || !controller.value.isInitialized) {
          throw StateError("Camera chua san sang de chup preview.");
        }

        final wasStreaming = controller.value.isStreamingImages;
        if (wasStreaming) {
          await controller.stopImageStream();
        }

        try {
          final file = await controller.takePicture();
          bytes = await file.readAsBytes();
        } finally {
          if (wasStreaming) {
            await controller.startImageStream(_processCameraImage);
          }
        }
      }

      if (!mounted) {
        return;
      }

      final savedFile = await _saveImageBytes(bytes);
      final media = _TryOnCapturedMedia(
        file: savedFile,
        type: _TryOnCaptureType.image,
        createdAt: DateTime.now(),
        includesOverlay: true,
      );

      if (!mounted) return;
      setState(() {
        _lastCapturedMedia = media;
        _lastCapturedImageBytes = bytes;
      });

      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text("Preview da chup"),
            contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            content: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.memory(bytes!),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.of(dialogContext).pop();
                  await _shareCapturedMedia(media);
                },
                child: const Text("Chia se"),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text("Dong"),
              ),
            ],
          );
        },
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Da luu anh preview vao bo nho ung dung: ${media.fileName}",
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Khong the chup preview: $e")));
    } finally {
      if (!mounted) return;
      setState(() {
        _isCapturingPreview = false;
      });
    }
  }

  Future<void> _toggleVideoRecording() async {
    if (_isRecordingVideo) {
      await _stopVideoRecording();
      return;
    }
    await _startVideoRecording();
  }

  Future<void> _startVideoRecording() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    if (_isCapturingPreview || controller.value.isRecordingVideo) {
      return;
    }

    var wasStreaming = controller.value.isStreamingImages;
    try {
      if (wasStreaming) {
        await controller.stopImageStream();
      }
      await controller.prepareForVideoRecording();
      await controller.startVideoRecording(onAvailable: _processCameraImage);
      if (!mounted) return;
      setState(() {
        _recordingDuration = Duration.zero;
      });
      _startRecordingTicker();
    } catch (e) {
      if (wasStreaming && !controller.value.isRecordingVideo) {
        try {
          await controller.startImageStream(_processCameraImage);
        } catch (_) {}
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Khong the bat dau quay video: $e")),
      );
    }
  }

  Future<void> _stopVideoRecording() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    if (!controller.value.isRecordingVideo) {
      return;
    }

    _stopRecordingTicker();

    try {
      final rawVideo = await controller.stopVideoRecording();
      final savedVideo = await _saveVideoFile(rawVideo);

      if (!controller.value.isStreamingImages) {
        await controller.startImageStream(_processCameraImage);
      }

      final media = _TryOnCapturedMedia(
        file: savedVideo,
        type: _TryOnCaptureType.video,
        createdAt: DateTime.now(),
        includesOverlay: false,
      );

      if (!mounted) return;
      setState(() {
        _lastCapturedMedia = media;
        _lastCapturedImageBytes = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Da luu video vao bo nho ung dung: ${media.fileName}"),
        ),
      );
    } catch (e) {
      if (!controller.value.isStreamingImages) {
        try {
          await controller.startImageStream(_processCameraImage);
        } catch (_) {}
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Khong the dung quay video: $e")));
    }
  }

  Future<void> _togglePauseRecording() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isRecordingVideo) {
      return;
    }

    try {
      if (controller.value.isRecordingPaused) {
        await controller.resumeVideoRecording();
        _startRecordingTicker();
      } else {
        await controller.pauseVideoRecording();
        _stopRecordingTicker();
      }
      if (!mounted) return;
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Khong the cap nhat trang thai quay video: $e")),
      );
    }
  }

  void _startRecordingTicker() {
    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _recordingDuration += const Duration(seconds: 1);
      });
    });
  }

  void _stopRecordingTicker() {
    _recordingTimer?.cancel();
    _recordingTimer = null;
  }

  Future<XFile> _saveImageBytes(Uint8List bytes) async {
    final targetPath = await _buildMediaPath(extension: "png");
    final xFile = XFile.fromData(
      bytes,
      mimeType: "image/png",
      name: _fileNameFromPath(targetPath),
    );
    await xFile.saveTo(targetPath);
    return XFile(targetPath, mimeType: "image/png");
  }

  Future<XFile> _saveVideoFile(XFile videoFile) async {
    final sourceExtension = _extensionFromPath(videoFile.path);
    final targetPath = await _buildMediaPath(
      extension: sourceExtension.isEmpty ? "mp4" : sourceExtension,
    );
    await videoFile.saveTo(targetPath);
    return XFile(targetPath, mimeType: "video/mp4");
  }

  Future<String> _buildMediaPath({required String extension}) async {
    final directory = await getApplicationDocumentsDirectory();
    final safeExtension = extension.replaceAll(".", "");
    return "${directory.path}/helmet_try_on_${_timestampToken()}.${safeExtension}";
  }

  String _timestampToken() {
    final now = DateTime.now();
    final year = now.year.toString().padLeft(4, "0");
    final month = now.month.toString().padLeft(2, "0");
    final day = now.day.toString().padLeft(2, "0");
    final hour = now.hour.toString().padLeft(2, "0");
    final minute = now.minute.toString().padLeft(2, "0");
    final second = now.second.toString().padLeft(2, "0");
    return "${year}${month}${day}_${hour}${minute}${second}";
  }

  String _fileNameFromPath(String path) {
    if (path.trim().isEmpty) {
      return "";
    }
    final segments = path.split(RegExp(r"[\\/]"));
    return segments.isEmpty ? path : segments.last;
  }

  String _extensionFromPath(String path) {
    final fileName = _fileNameFromPath(path);
    final dotIndex = fileName.lastIndexOf(".");
    if (dotIndex < 0 || dotIndex == fileName.length - 1) {
      return "";
    }
    return fileName.substring(dotIndex + 1);
  }

  Future<void> _shareCapturedMedia(_TryOnCapturedMedia media) async {
    try {
      final box = context.findRenderObject() as RenderBox?;
      await SharePlus.instance.share(
        ShareParams(
          title: media.type == _TryOnCaptureType.image
              ? "Helmet Try-On Photo"
              : "Helmet Try-On Video",
          text: media.includesOverlay
              ? "Anh preview thu non tu ung dung Royal Store."
              : "Video camera tu man hinh thu non. Ban v1 chua bake overlay non vao file video.",
          files: [media.file],
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Khong the chia se media: $e")));
    }
  }

  String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, "0");
    final seconds = (totalSeconds % 60).toString().padLeft(2, "0");
    return "$minutes:$seconds";
  }

  String _cameraMessageFromException(CameraException exception) {
    switch (exception.code) {
      case "CameraAccessDenied":
        return "Ban da tu choi quyen camera. Hay cap quyen trong cai dat.";
      case "CameraAccessDeniedWithoutPrompt":
        return "Camera dang bi khoa va khong the hien hop thoai xin quyen.";
      case "CameraAccessRestricted":
        return "Camera dang bi gioi han tren thiet bi nay.";
      case "AudioAccessDenied":
        return "Khong co quyen microphone de quay video.";
      default:
        return exception.description ??
            "Khong the khoi dong camera (${exception.code}).";
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final vm = context.watch<HelmetDesignerViewModel>();
    final design = vm.currentDesign;
    final hasDesign = design.helmetProductId > 0;
    final face = _trackedFace;
    final controller = _cameraController;
    final lastMedia = _lastCapturedMedia;
    final trackingLabel = face == null
        ? "Chua thay khuon mat"
        : "Dang theo doi";
    final roll = face?.headEulerAngleZ?.toStringAsFixed(1) ?? "--";
    final yaw = face?.headEulerAngleY?.toStringAsFixed(1) ?? "--";

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        title: Text(
          "Helmet Try-On",
          style: textTheme.titleLarge?.copyWith(
            color: colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go("/helmet-designer");
            }
          },
          icon: Icon(Icons.arrow_back, color: colorScheme.onPrimary),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [Color(0xFFEEF4FB), Color(0xFFDDE9F8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "2D face tracking preview",
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _cameraError ?? _statusDescription(face != null),
                        style: textTheme.bodyMedium?.copyWith(height: 1.45),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: hasDesign
                      ? () => context.go("/helmet-designer")
                      : null,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text("Chinh sua"),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (!hasDesign)
            const _EmptyTryOnState()
          else ...[
            Text(
              "Preview thu non",
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            _TryOnPreviewCard(
              controller: controller,
              boundaryKey: _previewBoundaryKey,
              faceRectBuilder: _faceRectOnPreview,
              trackedFace: face,
              isInitializingCamera: _isInitializingCamera,
              cameraError: _cameraError,
              isMirroredPreview: _isPreviewMirrored,
              isRecordingVideo: _isRecordingVideo,
              isRecordingPaused: _isRecordingPaused,
              recordingDuration: _recordingDuration,
              helmetBaseImageUrl: design.helmetBaseImageUrl,
              stickerLayers: vm.stickerLayers,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed:
                      _isInitializingCamera ||
                          _isCapturingPreview ||
                          _isRecordingVideo
                      ? null
                      : _capturePreview,
                  icon: _isCapturingPreview
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.camera_alt_outlined),
                  label: Text(
                    _isCapturingPreview ? "Dang chup..." : "Chup anh",
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: _isInitializingCamera || _isCapturingPreview
                      ? null
                      : _toggleVideoRecording,
                  icon: Icon(
                    _isRecordingVideo
                        ? Icons.stop_circle_outlined
                        : Icons.videocam_outlined,
                  ),
                  label: Text(
                    _isRecordingVideo
                        ? "Dung ${_formatDuration(_recordingDuration)}"
                        : "Quay video",
                  ),
                ),
                if (_isRecordingVideo)
                  OutlinedButton.icon(
                    onPressed: _togglePauseRecording,
                    icon: Icon(
                      _isRecordingPaused ? Icons.play_arrow : Icons.pause,
                    ),
                    label: Text(_isRecordingPaused ? "Tiep tuc" : "Tam dung"),
                  ),
                OutlinedButton.icon(
                  onPressed: _isInitializingCamera || _isRecordingVideo
                      ? null
                      : _initializeTryOn,
                  icon: const Icon(Icons.refresh),
                  label: const Text("Lam moi camera"),
                ),
                if (lastMedia != null)
                  OutlinedButton.icon(
                    onPressed: () => _shareCapturedMedia(lastMedia),
                    icon: const Icon(Icons.share_outlined),
                    label: const Text("Chia se media"),
                  ),
              ],
            ),
            if (lastMedia != null) ...[
              const SizedBox(height: 16),
              _LatestMediaCard(
                media: lastMedia,
                imagePreviewBytes: _lastCapturedImageBytes,
                onShare: () => _shareCapturedMedia(lastMedia),
              ),
            ],
            const SizedBox(height: 16),
            _InfoCard(
              title: "Trang thai tracking",
              lines: [
                "Camera: ${controller?.description.lensDirection.name ?? "chua khoi dong"}",
                "Tracking: $trackingLabel",
                "Roll Z: $roll deg",
                "Yaw Y: $yaw deg",
                if (_isRecordingVideo)
                  "Dang quay: ${_formatDuration(_recordingDuration)}${_isRecordingPaused ? " (tam dung)" : ""}",
              ],
            ),
            const SizedBox(height: 16),
            _InfoCard(
              title: "Thiet ke hien tai",
              lines: [
                "Design ID: ${design.id > 0 ? design.id : "chua luu"}",
                "Mau non: ${design.helmetName}",
                "So sticker: ${vm.stickerLayers.length}",
                "Trang thai chia se: ${design.isShared ? "da chia se" : "chua chia se"}",
              ],
            ),
            const SizedBox(height: 16),
            const _InfoCard(
              title: "Gioi han ban v1",
              lines: [
                "Overlay hien dang la 2D tracking tren bounding box khuon mat.",
                "Anh chup preview co kem overlay non va sticker.",
                "Video dang luu tu camera goc, chua bake overlay non vao file.",
                "Chua co ARKit/ARCore 3D.",
                "Do khop se phu thuoc vao anh non goc va goc quay khuon mat.",
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _statusDescription(bool isTracking) {
    if (_isInitializingCamera) {
      return "Dang khoi dong camera va model nhan dien khuon mat.";
    }
    if (_isRecordingVideo) {
      return "Dang quay video camera. Overlay non van hien trong live preview, nhung file video ban v1 chua nhung overlay.";
    }
    if (isTracking) {
      return "Da nhan dien khuon mat. Non ao dang duoc dat len dau theo bounding box hien tai.";
    }
    return "Huong mat vao camera truoc, giu du anh sang de bat dau thu non.";
  }
}

class _TryOnPreviewCard extends StatelessWidget {
  final CameraController? controller;
  final GlobalKey boundaryKey;
  final Rect? Function(Size previewSize) faceRectBuilder;
  final Face? trackedFace;
  final bool isInitializingCamera;
  final String? cameraError;
  final bool isMirroredPreview;
  final bool isRecordingVideo;
  final bool isRecordingPaused;
  final Duration recordingDuration;
  final String helmetBaseImageUrl;
  final List<StickerLayer> stickerLayers;

  const _TryOnPreviewCard({
    required this.controller,
    required this.boundaryKey,
    required this.faceRectBuilder,
    required this.trackedFace,
    required this.isInitializingCamera,
    required this.cameraError,
    required this.isMirroredPreview,
    required this.isRecordingVideo,
    required this.isRecordingPaused,
    required this.recordingDuration,
    required this.helmetBaseImageUrl,
    required this.stickerLayers,
  });

  @override
  Widget build(BuildContext context) {
    final activeController = controller;
    final previewAspectRatio = activeController?.value.isInitialized == true
        ? activeController!.value.aspectRatio
        : 3 / 4;

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: RepaintBoundary(
        key: boundaryKey,
        child: AspectRatio(
          aspectRatio: previewAspectRatio,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final previewSize = Size(
                constraints.maxWidth,
                constraints.maxHeight,
              );
              final faceRect = faceRectBuilder(previewSize);

              return DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF09111F), Color(0xFF1A2940)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (activeController != null &&
                        activeController.value.isInitialized)
                      Transform(
                        alignment: Alignment.center,
                        transform: isMirroredPreview
                            ? Matrix4.diagonal3Values(-1, 1, 1)
                            : Matrix4.identity(),
                        child: CameraPreview(activeController),
                      )
                    else
                      _CameraPlaceholder(
                        isInitializing: isInitializingCamera,
                        errorMessage: cameraError,
                      ),
                    if (faceRect != null)
                      _HelmetFaceOverlay(
                        faceRect: faceRect,
                        rollAngleDeg: trackedFace?.headEulerAngleZ ?? 0,
                        helmetBaseImageUrl: helmetBaseImageUrl,
                        stickerLayers: stickerLayers,
                      ),
                    if (faceRect != null)
                      Positioned.fromRect(
                        rect: faceRect,
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.72),
                                width: 1.6,
                              ),
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      left: 14,
                      top: 14,
                      child: _RecordingBadge(
                        isRecordingVideo: isRecordingVideo,
                        isRecordingPaused: isRecordingPaused,
                        recordingDuration: recordingDuration,
                      ),
                    ),
                    Positioned(
                      left: 14,
                      right: 14,
                      bottom: 14,
                      child: _PreviewStatusBar(
                        isTracking: faceRect != null,
                        hasCamera:
                            activeController?.value.isInitialized == true,
                        errorMessage: cameraError,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _RecordingBadge extends StatelessWidget {
  final bool isRecordingVideo;
  final bool isRecordingPaused;
  final Duration recordingDuration;

  const _RecordingBadge({
    required this.isRecordingVideo,
    required this.isRecordingPaused,
    required this.recordingDuration,
  });

  @override
  Widget build(BuildContext context) {
    if (!isRecordingVideo) {
      return const SizedBox.shrink();
    }

    final totalSeconds = recordingDuration.inSeconds;
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, "0");
    final seconds = (totalSeconds % 60).toString().padLeft(2, "0");

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.88),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isRecordingPaused
                ? Icons.pause_circle_filled
                : Icons.fiber_manual_record,
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(width: 8),
          Text(
            isRecordingPaused
                ? "PAUSE $minutes:$seconds"
                : "REC $minutes:$seconds",
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HelmetFaceOverlay extends StatelessWidget {
  final Rect faceRect;
  final double rollAngleDeg;
  final String helmetBaseImageUrl;
  final List<StickerLayer> stickerLayers;

  const _HelmetFaceOverlay({
    required this.faceRect,
    required this.rollAngleDeg,
    required this.helmetBaseImageUrl,
    required this.stickerLayers,
  });

  @override
  Widget build(BuildContext context) {
    final helmetWidth = faceRect.width * 1.9;
    final helmetHeight = helmetWidth * 0.96;
    final left = faceRect.center.dx - helmetWidth / 2;
    final top = faceRect.top - helmetHeight * 0.60;
    final angle = rollAngleDeg * math.pi / 180;

    return Positioned(
      left: left,
      top: top,
      child: IgnorePointer(
        child: Transform.rotate(
          angle: angle,
          alignment: Alignment.center,
          child: Opacity(
            opacity: 0.98,
            child: SizedBox(
              width: helmetWidth,
              height: helmetHeight,
              child: HelmetDesignArtwork(
                helmetBaseImageUrl: helmetBaseImageUrl,
                layers: stickerLayers,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PreviewStatusBar extends StatelessWidget {
  final bool isTracking;
  final bool hasCamera;
  final String? errorMessage;

  const _PreviewStatusBar({
    required this.isTracking,
    required this.hasCamera,
    required this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.52),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(
            isTracking ? Icons.face_retouching_natural : Icons.face_outlined,
            size: 18,
            color: Colors.white,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              errorMessage ??
                  (hasCamera
                      ? (isTracking
                            ? "Da nhan dien khuon mat va ap non ao."
                            : "Dang tim khuon mat trong khung hinh.")
                      : "Camera chua san sang."),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraPlaceholder extends StatelessWidget {
  final bool isInitializing;
  final String? errorMessage;

  const _CameraPlaceholder({
    required this.isInitializing,
    required this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isInitializing)
              const SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(strokeWidth: 3),
              )
            else
              const Icon(
                Icons.camera_alt_outlined,
                color: Colors.white,
                size: 38,
              ),
            const SizedBox(height: 14),
            Text(
              errorMessage ??
                  (isInitializing
                      ? "Dang khoi dong camera..."
                      : "Camera chua san sang."),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LatestMediaCard extends StatelessWidget {
  final _TryOnCapturedMedia media;
  final Uint8List? imagePreviewBytes;
  final VoidCallback onShare;

  const _LatestMediaCard({
    required this.media,
    required this.imagePreviewBytes,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final path = media.file.path;
    final shortPath = path.length > 48
        ? "...${path.substring(path.length - 48)}"
        : path;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.light.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Media vua luu",
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (media.type == _TryOnCaptureType.image &&
              imagePreviewBytes != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.memory(
                imagePreviewBytes!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          if (media.type == _TryOnCaptureType.image &&
              imagePreviewBytes != null)
            const SizedBox(height: 12),
          Text("Ten file: ${media.fileName}"),
          const SizedBox(height: 6),
          Text(
            "Loai: ${media.type == _TryOnCaptureType.image ? "anh" : "video"}",
          ),
          const SizedBox(height: 6),
          Text("Overlay trong file: ${media.includesOverlay ? "co" : "khong"}"),
          const SizedBox(height: 6),
          Text("Luu luc: ${media.createdAt.toLocal()}"),
          const SizedBox(height: 6),
          Text(
            "Duong dan: $shortPath",
            style: textTheme.bodySmall?.copyWith(height: 1.35),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              FilledButton.icon(
                onPressed: onShare,
                icon: const Icon(Icons.share_outlined),
                label: const Text("Chia se"),
              ),
              const SizedBox(width: 10),
              if (media.type == _TryOnCaptureType.video)
                Expanded(
                  child: Text(
                    "Video hien dang la file camera goc.",
                    style: textTheme.bodySmall?.copyWith(height: 1.35),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyTryOnState extends StatelessWidget {
  const _EmptyTryOnState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.light.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Chua co thiet ke de thu",
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Hay vao man hinh Helmet Designer, chon mau non va them sticker truoc khi sang che do thu non.",
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => context.go("/helmet-designer"),
            icon: const Icon(Icons.brush_outlined),
            label: const Text("Mo Helmet Designer"),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<String> lines;

  const _InfoCard({required this.title, required this.lines});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.light.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(line),
            ),
        ],
      ),
    );
  }
}

enum _TryOnCaptureType { image, video }

class _TryOnCapturedMedia {
  final XFile file;
  final _TryOnCaptureType type;
  final DateTime createdAt;
  final bool includesOverlay;

  const _TryOnCapturedMedia({
    required this.file,
    required this.type,
    required this.createdAt,
    required this.includesOverlay,
  });

  String get fileName {
    final path = file.path;
    if (path.trim().isEmpty) {
      return "";
    }
    final segments = path.split(RegExp(r"[\\/]"));
    return segments.isEmpty ? path : segments.last;
  }
}
