import 'dart:async';
import 'dart:io';

import 'package:b2205946_duonghuuluan_luanvan/app/theme/colors.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/helmet_designer/domain/ai_sticker_request.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/helmet_designer/domain/sticker_template.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/helmet_designer/presentation/view/helmet_preview_canvas.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/helmet_designer/presentation/viewmodel/helmet_designer_viewmodel.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/helmet_designer/presentation/widget/ai_sticker_section.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/helmet_designer/presentation/widget/ai_sticker_voice_screen.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/helmet_designer/presentation/widget/design_view_selector.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/helmet_designer/presentation/widget/designer_hero_card.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/helmet_designer/presentation/widget/hint_card.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/helmet_designer/presentation/widget/layer_tile.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/helmet_designer/presentation/widget/layer_toolbar.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/helmet_designer/presentation/widget/sticker_catalog_card.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/product/domain/product_image.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';

class HelmetDesignerPage extends StatefulWidget {
  final int? designId;
  final int? initialHelmetProductId;
  final int? initialProductDetailId;
  final int? initialQuantity;
  final String? initialHelmetName;
  final String? initialHelmetBaseImageUrl;
  final String? initialHelmetModel3dUrl;
  final List<ProductImage> initialHelmetDesignViews;

  const HelmetDesignerPage({
    super.key,
    this.designId,
    this.initialHelmetProductId,
    this.initialProductDetailId,
    this.initialQuantity,
    this.initialHelmetName,
    this.initialHelmetBaseImageUrl,
    this.initialHelmetModel3dUrl,
    this.initialHelmetDesignViews = const [],
  });

  @override
  State<HelmetDesignerPage> createState() => _HelmetDesignerPageState();
}

class _HelmetDesignerPageState extends State<HelmetDesignerPage> {
  static const List<String> _aiStyles = [
    "Đường phố",
    "Thể thao",
    "Dễ thương",
    "Tối giản",
    "Ngọn lửa",
  ];

  static const List<Color> _pickerColors = [
    Color(0xFFE53935),
    Color(0xFFFB8C00),
    Color(0xFFFDD835),
    Color(0xFF43A047),
    Color(0xFF1E88E5),
    Color(0xFF3949AB),
    Color(0xFF8E24AA),
    Color(0xFF212121),
    Color(0xFFFFFFFF),
  ];

  final TextEditingController _aiPromptController = TextEditingController();
  final AudioRecorder _audioRecorder = AudioRecorder();
  String _selectedAiStyle = _aiStyles.first;
  Color? _selectedAiColor;
  bool _removeAiBackground = true;
  bool _isPreparingVoice = false;
  bool _isRecordingVoice = false;
  bool _isProcessingVoice = false;
  bool _hasDetectedSpeech = false;
  DateTime? _voiceRecordingStartedAt;
  StreamSubscription<Amplitude>? _voiceAmplitudeSubscription;
  Timer? _voiceSilenceTimer;
  Timer? _voiceMaxDurationTimer;
  final ValueNotifier<AiStickerVoiceScreenState?> _voiceScreenState =
      ValueNotifier(null);
  BuildContext? _voiceScreenDialogContext;
  bool _isVoiceScreenVisible = false;
  bool _isDisposingPage = false;

  static const double _voiceActivityThresholdDbfs = -40;
  static const Duration _voiceSilenceDuration = Duration(milliseconds: 1600);
  static const Duration _voiceMaxRecordingDuration = Duration(seconds: 20);
  static const Duration _voiceMinRecordingDuration = Duration(
    milliseconds: 700,
  );

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final vm = context.read<HelmetDesignerViewModel>();
      vm.setOrderTarget(
        productDetailId: widget.initialProductDetailId,
        quantity: widget.initialQuantity ?? 1,
        notify: false,
      );
      if (vm.stickerCatalog.isEmpty) {
        await vm.loadStickerCatalog();
      }
      if (!mounted) return;

      if (widget.designId != null) {
        await vm.loadDesign(widget.designId!);
        return;
      }

      if ((widget.initialHelmetProductId ?? 0) > 0) {
        vm.startNewDesign(
          helmetProductId: widget.initialHelmetProductId!,
          productDetailId: widget.initialProductDetailId,
          helmetName: widget.initialHelmetName ?? "Mũ bảo hiểm",
          helmetBaseImageUrl: widget.initialHelmetBaseImageUrl ?? "",
          designViews: widget.initialHelmetDesignViews,
          helmetModel3dUrl: widget.initialHelmetModel3dUrl,
          orderQuantity: widget.initialQuantity ?? 1,
        );
        return;
      }

      if (vm.currentDesign.helmetProductId == 0) {
        vm.startNewDesign(
          helmetProductId: 101,
          helmetName: "Mũ bảo hiểm Royal Street",
          helmetBaseImageUrl: "assets/images/logo_royalStore2.png",
          helmetModel3dUrl: widget.initialHelmetModel3dUrl,
          productDetailId: widget.initialProductDetailId,
          orderQuantity: widget.initialQuantity ?? 1,
        );
      }
    });
  }

  @override
  void dispose() {
    _isDisposingPage = true;
    _cancelVoiceTimers();
    unawaited(_voiceAmplitudeSubscription?.cancel() ?? Future<void>.value());
    unawaited(_audioRecorder.dispose());
    _voiceScreenState.dispose();
    _aiPromptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final vm = context.watch<HelmetDesignerViewModel>();
    final selectedLayer = vm.selectedLayer;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        title: Text(
          "Thêm sticker",
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
              context.go("/");
            }
          },
          icon: Icon(Icons.arrow_back, color: colorScheme.onPrimary),
        ),
        actions: [
          IconButton(
            onPressed: vm.isSavingDesign
                ? null
                : () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final saved = await context
                        .read<HelmetDesignerViewModel>()
                        .saveCurrentDesign();
                    if (!mounted) return;
                    if (saved != null) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text("Đã lưu thiết kế thành công."),
                          action: SnackBarAction(
                            label: "Xem thiết kế",
                            onPressed: () {
                              context.go("/profile/my-designs");
                            },
                          ),
                          duration: const Duration(seconds: 4),
                        ),
                      );
                    }
                  },
            icon: vm.isSavingDesign
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.save_outlined, color: colorScheme.onPrimary),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          DesignerHeroCard(
            title: vm.currentDesign.helmetName,
            subtitle: vm.hasOrderTarget
                ? "Đang thiết kế cho mũ bảo hiểm ${vm.currentDesign.helmetName} . Sau khi hoàn tất, bạn có thể lưu, chia sẻ hoặc đặt mua ngay."
                : "Canvas đã kết nối với quản lý sticker. Đặt mua sẽ cần chọn biến thể sản phẩm từ trang chi tiết.",
            trailing: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.tonalIcon(
                  onPressed: vm.isSharingDesign
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final url = await context
                              .read<HelmetDesignerViewModel>()
                              .shareCurrentDesign();
                          if (!mounted || url == null) return;
                          messenger.showSnackBar(
                            SnackBar(content: Text("Link chia sẻ: $url")),
                          );
                        },
                  icon: const Icon(Icons.ios_share_outlined),
                  label: Text(vm.shareUrl == null ? "Chia sẻ" : "Đã tạo link"),
                ),

                FilledButton.tonalIcon(
                  onPressed: vm.isOrderingDesign || !vm.hasOrderTarget
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final ordered = await context
                              .read<HelmetDesignerViewModel>()
                              .orderCurrentDesign();
                          if (!mounted) return;
                          if (ordered) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Đã lưu thiết kế và sản phẩm vào giỏ hàng.",
                                ),
                                action: SnackBarAction(
                                  label: "Xem giỏ hàng",
                                  onPressed: () {
                                    context.go("/cart");
                                  },
                                ),
                              ),
                            );
                          } else if (vm.errorMessage != null &&
                              vm.errorMessage!.isNotEmpty) {
                            messenger.showSnackBar(
                              SnackBar(content: Text(vm.errorMessage!)),
                            );
                          }
                        },
                  icon: vm.isOrderingDesign
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.shopping_bag_outlined),
                  label: Text("Đặt mua"),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Xem trước thiết kế",
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          if (vm.hasMultipleDesignViews) ...[
            DesignViewSelector(
              views: vm.designViews,
              activeViewImageKey: vm.activeViewImageKey,
              onSelected: vm.selectDesignView,
            ),
            const SizedBox(height: 10),
          ],
          HelmetPreviewCanvas(
            layers: vm.visibleStickerLayers,
            selectedLayerId: vm.selectedLayerId,
            helmetBaseImageUrl: vm.currentPreviewImageUrl,
            emptyMessage: vm.hasLayers && vm.hasMultipleDesignViews
                ? "Góc này chưa có sticker. Hãy thêm mới hoặc chuyển sang góc khác."
                : "Chọn sticker để bắt đầu thiết kế.",
            onLayerTap: vm.selectLayer,
            onBackgroundTap: () => vm.selectLayer(null),
            onLayerTransform: (layerId, x, y, scale, rotation) {
              if (vm.selectedLayerId != layerId) {
                vm.selectLayer(layerId);
              }
              vm.updateSelectedLayerTransform(
                x: x,
                y: y,
                scale: scale,
                rotation: rotation,
              );
            },
          ),
          const SizedBox(height: 12),
          if (vm.hasMultipleDesignViews)
            Text(
              "Chọn góc ảnh để gắn sticker đúng mặt. Sticker mới sẽ được thêm vào góc đang xem.",
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.light.textSecondary,
              ),
            )
          else
            Text(
              "Kéo sticker để di chuyển. Dùng hai ngón tay để thu phóng và xoay trực tiếp trên bản xem trước.",
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.light.textSecondary,
              ),
            ),
          const SizedBox(height: 16),
          if (selectedLayer != null)
            LayerToolbar(layer: selectedLayer, palette: _pickerColors)
          else
            const HintCard(
              text:
                  "Chọn một sticker từ danh sách hoặc thêm sticker từ thư viện để bắt đầu chỉnh sửa.",
            ),
          const SizedBox(height: 20),

          AiStickerSection(
            promptController: _aiPromptController,
            selectedStyle: _selectedAiStyle,
            selectedColor: _selectedAiColor,
            removeBackground: _removeAiBackground,
            styles: _aiStyles,
            palette: _pickerColors,
            isGenerating: vm.isGeneratingSticker,
            isVoiceBusy:
                _isPreparingVoice ||
                _isProcessingVoice ||
                vm.isTranscribingSticker ||
                vm.isGeneratingSticker,
            onStyleChanged: (value) {
              setState(() {
                _selectedAiStyle = value;
              });
            },
            onColorChanged: (color) {
              setState(() {
                _selectedAiColor = color;
              });
            },
            onBackgroundChanged: (value) {
              setState(() {
                _removeAiBackground = value;
              });
            },
            onGenerate: () => _generateAiSticker(context),
            onToggleVoice: () => _startVoiceFlow(context),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  "sticker",
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (vm.isLoadingCatalog)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.secondary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 142,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: vm.stickerCatalog.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final item = vm.stickerCatalog[index];
                return StickerCatalogCard(template: item);
              },
            ),
          ),

          const SizedBox(height: 10),
          if (!vm.hasLayers)
            const HintCard(
              text:
                  "Chưa có sticker nào trong thiết kế. Hãy nhấn vào sticker ở trên để thêm vào nón.",
            )
          else
            ...vm.stickerLayers.reversed.map(LayerTile.new),
          if (vm.errorMessage != null) ...[
            const SizedBox(height: 16),
            HintCard(text: vm.errorMessage!, isError: true),
          ],
        ],
      ),
    );
  }

  Future<void> _generateAiSticker(BuildContext context) async {
    final prompt = _aiPromptController.text.trim();
    if (prompt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập mô tả để tạo sticker AI.")),
      );
      return;
    }

    final vm = context.read<HelmetDesignerViewModel>();
    final sticker = await vm.generateAiSticker(
      AiStickerRequest(
        prompt: prompt,
        style: _selectedAiStyle,
        dominantColor: _selectedAiColor == null
            ? null
            : _colorToHex(_selectedAiColor!),
        removeBackground: _removeAiBackground,
      ),
      addToCanvas: false,
    );
    if (!mounted || sticker == null) return;

    _aiPromptController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Sticker AI của bạn",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),

              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: sticker.imageUrl,
                  height: 200,
                  width: 200,
                  fit: BoxFit.contain,
                  fadeInDuration: const Duration(milliseconds: 400),
                  placeholder: (context, url) => const Center(
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    ),
                  ),
                  errorWidget: (context, url, error) => Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.broken_image_outlined,
                        size: 40,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Lỗi tải sticker",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.pop(),
                      child: Text(
                        "Xong",
                        style: TextStyle(color: AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        context.pop();
                        vm.addStickerFromTemplate(sticker);
                      },
                      child: Text(
                        "Thiết kế ngay",
                        style: TextStyle(color: AppColors.primary),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _setPromptText(String text) {
    _aiPromptController
      ..text = text
      ..selection = TextSelection.collapsed(offset: text.length);
  }

  Future<StickerTemplate?> _generateAiStickerSilently(
    BuildContext context,
  ) async {
    final prompt = _aiPromptController.text.trim();
    if (prompt.isEmpty) {
      return null;
    }

    final vm = context.read<HelmetDesignerViewModel>();
    return vm.generateAiSticker(
      AiStickerRequest(
        prompt: prompt,
        style: _selectedAiStyle,
        dominantColor: _selectedAiColor == null
            ? null
            : _colorToHex(_selectedAiColor!),
        removeBackground: _removeAiBackground,
      ),
      addToCanvas: false,
    );
  }

  Future<void> _startVoiceFlow(BuildContext context) async {
    final vm = context.read<HelmetDesignerViewModel>();
    if (vm.isGeneratingSticker ||
        vm.isTranscribingSticker ||
        _isVoiceScreenVisible ||
        _isPreparingVoice ||
        _isProcessingVoice) {
      return;
    }

    _showVoiceScreen(context);
    await _startVoiceRecordingForScreen(context);
  }

  void _showVoiceScreen(BuildContext context) {
    if (_isVoiceScreenVisible) {
      return;
    }

    _isVoiceScreenVisible = true;
    _updateVoiceScreenState(const AiStickerVoiceScreenState.opening());
    unawaited(
      showGeneralDialog<void>(
        context: context,
        barrierDismissible: false,
        barrierLabel: 'Voice sticker',
        barrierColor: Colors.black54,
        transitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (dialogContext, _, __) {
          _voiceScreenDialogContext = dialogContext;
          return ValueListenableBuilder<AiStickerVoiceScreenState?>(
            valueListenable: _voiceScreenState,
            builder: (_, state, __) {
              if (state == null) {
                return const SizedBox.shrink();
              }

              return WillPopScope(
                onWillPop: () async => false,
                child: AiStickerVoiceScreen(
                  state: state,
                  onClose: () => _handleVoiceScreenClose(state),
                  onStopRecording: _isRecordingVoice
                      ? () => _stopVoiceRecordingAndProcessForScreen(context)
                      : null,
                  onUseSticker: state.sticker == null
                      ? null
                      : () => _applyVoiceSticker(context, state.sticker!),
                ),
              );
            },
          );
        },
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: child,
          );
        },
      ).whenComplete(() {
        _voiceScreenDialogContext = null;
        _isVoiceScreenVisible = false;
        if (_isDisposingPage) {
          return;
        }
        _voiceScreenState.value = null;
      }),
    );
  }

  void _updateVoiceScreenState(AiStickerVoiceScreenState state) {
    if (_isDisposingPage) {
      return;
    }
    _voiceScreenState.value = state;
  }

  Future<void> _dismissVoiceScreen() async {
    final dialogContext = _voiceScreenDialogContext;
    if (dialogContext == null) {
      return;
    }

    Navigator.of(dialogContext).pop();
  }

  Future<void> _handleVoiceScreenClose(AiStickerVoiceScreenState state) async {
    if (state.isListening) {
      await _cancelVoiceFlow();
      return;
    }

    await _dismissVoiceScreen();
  }

  Future<void> _cancelVoiceFlow() async {
    _cancelVoiceTimers();
    await _voiceAmplitudeSubscription?.cancel();
    _voiceAmplitudeSubscription = null;
    _voiceRecordingStartedAt = null;

    try {
      if (_isRecordingVoice || _isPreparingVoice) {
        await _audioRecorder.cancel();
      }
    } catch (_) {}

    _resetVoiceState();
    await _dismissVoiceScreen();
  }

  void _applyVoiceSticker(BuildContext context, StickerTemplate sticker) {
    final vm = context.read<HelmetDesignerViewModel>();
    vm.addStickerFromTemplate(sticker);
    _aiPromptController.clear();
    unawaited(_dismissVoiceScreen());
  }

  Future<void> _startVoiceRecordingForScreen(BuildContext context) async {
    setState(() {
      _isPreparingVoice = true;
    });
    _updateVoiceScreenState(const AiStickerVoiceScreenState.opening());

    try {
      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        _resetVoiceState();
        _updateVoiceScreenState(
          const AiStickerVoiceScreenState.error(
            message: 'Bạn cần cấp quyền microphone để ghi âm mô tả sticker.',
          ),
        );
        return;
      }

      final encoder = await _pickVoiceEncoder();
      final tempDir = await getTemporaryDirectory();
      final extension = encoder == AudioEncoder.wav ? 'wav' : 'm4a';
      final filePath =
          '${tempDir.path}${Platform.pathSeparator}ai_sticker_${DateTime.now().millisecondsSinceEpoch}.$extension';

      await _audioRecorder.start(
        RecordConfig(
          encoder: encoder,
          numChannels: 1,
          sampleRate: 16000,
          bitRate: encoder == AudioEncoder.wav ? 128000 : 64000,
          echoCancel: true,
          noiseSuppress: true,
        ),
        path: filePath,
      );

      if (!mounted || !_isVoiceScreenVisible) {
        await _audioRecorder.cancel();
        return;
      }

      _hasDetectedSpeech = false;
      _voiceRecordingStartedAt = DateTime.now();
      _cancelVoiceTimers();
      await _voiceAmplitudeSubscription?.cancel();
      _voiceAmplitudeSubscription = _audioRecorder
          .onAmplitudeChanged(const Duration(milliseconds: 250))
          .listen((amplitude) {
            _handleVoiceAmplitudeForScreen(context, amplitude);
          });
      _voiceMaxDurationTimer = Timer(_voiceMaxRecordingDuration, () {
        unawaited(_stopVoiceRecordingAndProcessForScreen(context));
      });
      if (!mounted) {
        return;
      }
      setState(() {
        _isPreparingVoice = false;
        _isRecordingVoice = true;
      });
      _updateVoiceScreenState(const AiStickerVoiceScreenState.listening());
    } catch (_) {
      await _audioRecorder.cancel();
      if (!mounted) {
        return;
      }
      _resetVoiceState();
      _updateVoiceScreenState(
        const AiStickerVoiceScreenState.error(
          message: 'Không thể bật ghi âm giọng nói lúc này.',
        ),
      );
    }
  }

  void _handleVoiceAmplitudeForScreen(
    BuildContext context,
    Amplitude amplitude,
  ) {
    if (!_isRecordingVoice) {
      return;
    }

    if (amplitude.current > _voiceActivityThresholdDbfs) {
      _hasDetectedSpeech = true;
      _voiceSilenceTimer?.cancel();
      _voiceSilenceTimer = null;
      return;
    }

    if (!_hasDetectedSpeech || _voiceSilenceTimer != null) {
      return;
    }

    _voiceSilenceTimer = Timer(_voiceSilenceDuration, () {
      unawaited(_stopVoiceRecordingAndProcessForScreen(context));
    });
  }

  Future<void> _stopVoiceRecordingAndProcessForScreen(
    BuildContext context,
  ) async {
    if (!_isRecordingVoice) {
      return;
    }

    _cancelVoiceTimers();
    await _voiceAmplitudeSubscription?.cancel();
    _voiceAmplitudeSubscription = null;

    final startedAt = _voiceRecordingStartedAt;
    _voiceRecordingStartedAt = null;
    final audioPath = await _audioRecorder.stop();
    if (!mounted) {
      await _deleteTempAudioFile(audioPath);
      return;
    }

    final recordedMs = startedAt == null
        ? 0
        : DateTime.now().difference(startedAt).inMilliseconds;
    if (audioPath == null || audioPath.isEmpty) {
      _resetVoiceState();
      _updateVoiceScreenState(
        const AiStickerVoiceScreenState.error(
          message: 'Không tạo được file ghi âm. Bạn hãy thử lại.',
        ),
      );
      return;
    }

    if (recordedMs < _voiceMinRecordingDuration.inMilliseconds) {
      await _deleteTempAudioFile(audioPath);
      _resetVoiceState();
      _updateVoiceScreenState(
        const AiStickerVoiceScreenState.error(
          message: 'Đoạn ghi âm quá ngắn. Bạn hãy nói lại mô tả sticker.',
        ),
      );
      return;
    }

    setState(() {
      _isRecordingVoice = false;
      _isProcessingVoice = true;
    });
    _updateVoiceScreenState(const AiStickerVoiceScreenState.transcribing());

    final vm = context.read<HelmetDesignerViewModel>();
    final prompt = await vm.transcribeAiStickerVoice(audioPath);
    await _deleteTempAudioFile(audioPath);
    if (!mounted) {
      return;
    }

    if (prompt == null || prompt.trim().isEmpty) {
      _resetVoiceState();
      _updateVoiceScreenState(
        AiStickerVoiceScreenState.error(
          message: (vm.errorMessage ?? '').trim().isEmpty
              ? 'Không nhận được mô tả hợp lệ từ đoạn ghi âm.'
              : vm.errorMessage!,
        ),
      );
      return;
    }

    final normalizedPrompt = prompt.trim();
    _setPromptText(normalizedPrompt);
    _updateVoiceScreenState(
      AiStickerVoiceScreenState.generating(prompt: normalizedPrompt),
    );

    final sticker = await _generateAiStickerSilently(context);
    if (!mounted) {
      return;
    }

    if (sticker == null) {
      _resetVoiceState();
      _updateVoiceScreenState(
        AiStickerVoiceScreenState.error(
          message: (vm.errorMessage ?? '').trim().isEmpty
              ? 'Không thể tạo sticker từ mô tả vừa ghi âm.'
              : vm.errorMessage!,
        ),
      );
      return;
    }

    _resetVoiceState();
    _updateVoiceScreenState(
      AiStickerVoiceScreenState.result(
        sticker: sticker,
        prompt: normalizedPrompt,
      ),
    );
  }

  Future<void> _deleteTempAudioFile(String? audioPath) async {
    final normalizedPath = (audioPath ?? '').trim();
    if (normalizedPath.isEmpty) {
      return;
    }

    final file = File(normalizedPath);
    if (!await file.exists()) {
      return;
    }

    try {
      await file.delete();
    } catch (_) {}
  }

  Future<AudioEncoder> _pickVoiceEncoder() async {
    final supportsAac = await _audioRecorder.isEncoderSupported(
      AudioEncoder.aacLc,
    );
    return supportsAac ? AudioEncoder.aacLc : AudioEncoder.wav;
  }

  void _resetVoiceState() {
    if (!mounted) {
      return;
    }
    setState(() {
      _isPreparingVoice = false;
      _isRecordingVoice = false;
      _isProcessingVoice = false;
      _hasDetectedSpeech = false;
    });
  }

  void _cancelVoiceTimers() {
    _voiceSilenceTimer?.cancel();
    _voiceSilenceTimer = null;
    _voiceMaxDurationTimer?.cancel();
    _voiceMaxDurationTimer = null;
  }

  String _colorToHex(Color color) {
    final value = color.value.toRadixString(16).padLeft(8, '0');
    return "#${value.substring(2).toUpperCase()}";
  }
}
