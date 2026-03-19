import 'dart:math' as math;

import 'package:b2205946_duonghuuluan_luanvan/app/theme/colors.dart';
import 'package:b2205946_duonghuuluan_luanvan/core/constants/app_constants.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/helmet_designer/domain/helmet_3d_preview_profile.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/helmet_designer/domain/helmet_3d_surface.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/helmet_designer/domain/sticker_crop.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/helmet_designer/domain/sticker_layer.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/helmet_designer/presentation/viewmodel/helmet_designer_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:provider/provider.dart';

class Helmet3dViewPage extends StatefulWidget {
  const Helmet3dViewPage({super.key});

  @override
  State<Helmet3dViewPage> createState() => _Helmet3dViewPageState();
}

class _Helmet3dViewPageState extends State<Helmet3dViewPage> {
  static const List<Helmet3dSurface> _viewSurfaceOrder = [
    Helmet3dSurface.front,
    Helmet3dSurface.right,
    Helmet3dSurface.back,
    Helmet3dSurface.left,
  ];

  bool _seeded = false;
  Helmet3dSurface _activeSurface = Helmet3dSurface.front;
  double _viewSurfaceValue = 0;
  double _zoomFactor = 1;

  String _resolveModelUrl(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return "";

    final baseUrl = AppConstants.baseUrl.replaceAll(RegExp(r"/+$"), "");
    if (trimmed.startsWith("/static/")) {
      return "$baseUrl$trimmed";
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null) return trimmed;
    if (uri.path.startsWith("/static/models/")) {
      return "$baseUrl${uri.path}";
    }

    return trimmed;
  }

  double _sliderValueForSurface(Helmet3dSurface surface) {
    final index = _viewSurfaceOrder.indexOf(surface);
    return index < 0 ? 0 : index.toDouble();
  }

  Helmet3dSurface _surfaceForSliderValue(double value) {
    final safeIndex = value
        .round()
        .clamp(0, _viewSurfaceOrder.length - 1)
        .toInt();
    return _viewSurfaceOrder[safeIndex];
  }

  void _setActiveSurface(Helmet3dSurface surface) {
    setState(() {
      _activeSurface = surface;
      _viewSurfaceValue = _sliderValueForSurface(surface);
    });
  }

  String _buildCameraOrbit(Helmet3dSurfaceProfile profile) {
    final segments = profile.cameraOrbit
        .split(RegExp(r"\s+"))
        .where((item) => item.isNotEmpty)
        .toList();
    if (segments.length < 3) return profile.cameraOrbit;

    final baseDistance = double.tryParse(segments[2].replaceAll("%", ""));
    if (baseDistance == null) return profile.cameraOrbit;

    final adjustedDistance = (baseDistance / _zoomFactor).clamp(90, 140);
    return "${segments[0]} ${segments[1]} ${adjustedDistance.toStringAsFixed(1)}%";
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seeded) return;
    final vm = context.read<HelmetDesignerViewModel>();
    if (vm.selectedLayer == null && vm.stickerLayers.isNotEmpty) {
      vm.selectLayer(vm.stickerLayers.last.id);
    }
    _activeSurface = vm.selectedLayer?.surface ?? Helmet3dSurface.front;
    _viewSurfaceValue = _sliderValueForSurface(_activeSurface);
    _seeded = true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final vm = context.watch<HelmetDesignerViewModel>();
    final design = vm.currentDesign;
    final rawModelUrl = design.helmetModel3dUrl?.trim() ?? "";
    final modelUrl = _resolveModelUrl(rawModelUrl);
    final selectedLayer = vm.selectedLayer;

    if (modelUrl.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Xem 3D")),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              "Sản phẩm này chưa có model 3D. Bạn vẫn có thể tiếp tục thiết kế bằng bản xem trước 2D hiện tại.",
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final surfaceProfile = Helmet3dPreviewProfile.defaultProfile.of(
      _activeSurface,
    );
    final visibleLayers =
        vm.stickerLayers
            .where((layer) => layer.surface == _activeSurface)
            .toList()
          ..sort((a, b) => a.zIndex.compareTo(b.zIndex));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Xem 3D",
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.light.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  design.helmetName.isEmpty
                      ? "Model nón 3D"
                      : design.helmetName,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Chế độ 3D dùng model thật của sản phẩm. Sticker được preview theo từng mặt của nón; sản phẩm chưa có model vẫn giữ flow 2D như hiện tại.",
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.light.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                _ViewSliderPanel(
                  activeSurface: _activeSurface,
                  surfaceValue: _viewSurfaceValue,
                  zoomFactor: _zoomFactor,
                  onSurfaceChanged: (value) {
                    final surface = _surfaceForSliderValue(value);
                    setState(() {
                      _viewSurfaceValue = value;
                      _activeSurface = surface;
                    });
                  },
                  onZoomChanged: (value) {
                    setState(() => _zoomFactor = value);
                  },
                ),
                const SizedBox(height: 16),
                AspectRatio(
                  aspectRatio: 0.92,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final overlayRect = Rect.fromLTWH(
                        constraints.maxWidth *
                            surfaceProfile.previewBounds.left,
                        constraints.maxHeight *
                            surfaceProfile.previewBounds.top,
                        constraints.maxWidth *
                            surfaceProfile.previewBounds.width,
                        constraints.maxHeight *
                            surfaceProfile.previewBounds.height,
                      );

                      return ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Container(
                          color: const Color(0xFFF7F7F7),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: ModelViewer(
                                  key: ValueKey(
                                    "viewer:$modelUrl:${_activeSurface.value}:${_zoomFactor.toStringAsFixed(2)}",
                                  ),
                                  src: modelUrl,
                                  alt: design.helmetName,
                                  backgroundColor: Colors.transparent,
                                  cameraControls: false,
                                  disablePan: true,
                                  disableTap: true,
                                  disableZoom: true,
                                  interactionPrompt: InteractionPrompt.none,
                                  shadowIntensity: 1,
                                  shadowSoftness: 0.7,
                                  exposure: 1.1,
                                  cameraOrbit: _buildCameraOrbit(
                                    surfaceProfile,
                                  ),
                                  cameraTarget: "0m 0m 0m",
                                ),
                              ),
                              Positioned.fill(
                                child: _SurfaceStickerOverlay(
                                  layers: visibleLayers,
                                  selectedLayerId: vm.selectedLayerId,
                                  surfaceRect: overlayRect,
                                  baseStickerSizeFactor:
                                      surfaceProfile.baseStickerSizeFactor,
                                  onLayerTap: (layerId) {
                                    vm.selectLayer(layerId);
                                  },
                                ),
                              ),
                              if (visibleLayers.isEmpty)
                                Positioned(
                                  left: 20,
                                  right: 20,
                                  bottom: 20,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.92),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      "Chưa có sticker nào trên ${_activeSurface.label.toLowerCase()}. Chọn sticker ở dưới để chuyển sang mặt này.",
                                      textAlign: TextAlign.center,
                                      style: textTheme.bodySmall?.copyWith(
                                        color: AppColors.light.textSecondary,
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.light.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Sticker trong thiết kế",
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                if (vm.stickerLayers.isEmpty)
                  Text(
                    "Chưa có sticker nào. Hãy quay lại màn Thêm sticker để thêm trước khi xem 3D.",
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.light.textSecondary,
                    ),
                  )
                else
                  Column(
                    children: [
                      for (final layer in vm.stickerLayers) ...[
                        _StickerSelectionCard(
                          layer: layer,
                          /*
                          "Sticker #${layer.id} · ${layer.surface.label}",
                        ),
                          */
                          isSelected: layer.id == vm.selectedLayerId,
                          onSelect: () {
                            vm.selectLayer(layer.id);
                            _setActiveSurface(layer.surface);
                          },
                          onDeselect: () {
                            vm.selectLayer(null);
                          },
                        ),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (selectedLayer != null)
            _SelectedLayer3dPanel(
              layer: selectedLayer,
              activeSurface: _activeSurface,
              onSurfaceChanged: (surface) {
                context
                    .read<HelmetDesignerViewModel>()
                    .updateSelectedLayerSurface(surface);
                _setActiveSurface(surface);
              },
              onAssignToActiveSurface: () {
                context
                    .read<HelmetDesignerViewModel>()
                    .updateSelectedLayerSurface(_activeSurface);
              },
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.light.border),
              ),
              child: Text(
                "Chọn một sticker để đặt mặt dán và tinh chỉnh vị trí hiển thị trên model 3D.",
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.light.textSecondary,
                  height: 1.45,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ViewSliderPanel extends StatelessWidget {
  final Helmet3dSurface activeSurface;
  final double surfaceValue;
  final double zoomFactor;
  final ValueChanged<double> onSurfaceChanged;
  final ValueChanged<double> onZoomChanged;

  const _ViewSliderPanel({
    required this.activeSurface,
    required this.surfaceValue,
    required this.zoomFactor,
    required this.onSurfaceChanged,
    required this.onZoomChanged,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.light.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Mặt đang xem: ${activeSurface.label}",
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            "Kéo thanh để đổi mặt nhìn và độ phóng, thay cho xoay hoặc zoom tự do trên model.",
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.light.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          _LabeledSlider(
            label: "Mặt nhìn",
            value: surfaceValue,
            min: 0,
            max: 3,
            divisions: 3,
            displayValue: activeSurface.label,
            onChanged: onSurfaceChanged,
          ),
          const SizedBox(height: 8),
          _LabeledSlider(
            label: "Độ phóng model",
            value: zoomFactor,
            min: 0.85,
            max: 1.25,
            divisions: 8,
            displayValue: "${(zoomFactor * 100).round()}%",
            onChanged: onZoomChanged,
          ),
        ],
      ),
    );
  }
}

class _SelectedLayer3dPanel extends StatelessWidget {
  final StickerLayer layer;
  final Helmet3dSurface activeSurface;
  final ValueChanged<Helmet3dSurface> onSurfaceChanged;
  final VoidCallback onAssignToActiveSurface;

  const _SelectedLayer3dPanel({
    required this.layer,
    required this.activeSurface,
    required this.onSurfaceChanged,
    required this.onAssignToActiveSurface,
  });

  @override
  Widget build(BuildContext context) {
    final vm = context.read<HelmetDesignerViewModel>();
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.light.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Tinh chỉnh 3D cho sticker #${layer.id}",
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "Đổi mặt dán, rồi chỉnh vị trí và kích thước để preview lên model. Nếu sản phẩm không có model 3D thì toàn bộ phần này sẽ ẩn và hệ thống vẫn dùng bản 2D.",
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.light.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F8F8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.light.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Mặt đang xem: ${activeSurface.label}",
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Sticker này đang gắn ở ${layer.surface.label.toLowerCase()}. Bạn có thể gán nhanh sticker vào đúng mặt đang xem rồi tinh chỉnh tiếp vị trí và kích thước.",
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.light.textSecondary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: layer.surface == activeSurface
                      ? null
                      : onAssignToActiveSurface,
                  icon: const Icon(Icons.push_pin_outlined),
                  label: Text(
                    layer.surface == activeSurface
                        ? "Sticker đã ở mặt này"
                        : "Gán sticker vào mặt đang xem",
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: Helmet3dSurface.values.map((surface) {
              return ChoiceChip(
                label: Text(surface.label),
                selected: layer.surface == surface,
                onSelected: (_) => onSurfaceChanged(surface),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          _LabeledSlider(
            label: "Vị trí ngang trên ${layer.surface.label.toLowerCase()}",
            value: layer.surfaceX,
            onChanged: (value) {
              vm.updateSelectedLayerSurfacePlacement(surfaceX: value);
            },
          ),
          const SizedBox(height: 10),
          _LabeledSlider(
            label: "Vị trí dọc trên ${layer.surface.label.toLowerCase()}",
            value: layer.surfaceY,
            onChanged: (value) {
              vm.updateSelectedLayerSurfacePlacement(surfaceY: value);
            },
          ),
          const SizedBox(height: 10),
          _LabeledSlider(
            label: "Kích thước trên model 3D",
            value: layer.surfaceScale,
            min: 0.35,
            max: 2.4,
            onChanged: (value) {
              vm.updateSelectedLayerSurfacePlacement(surfaceScale: value);
            },
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => vm.rotateSelectedLayerBy(-0.12),
                icon: const Icon(Icons.rotate_left),
                label: const Text("Xoay trái"),
              ),
              OutlinedButton.icon(
                onPressed: () => vm.rotateSelectedLayerBy(0.12),
                icon: const Icon(Icons.rotate_right),
                label: const Text("Xoay phải"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LabeledSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final String? displayValue;
  final ValueChanged<double> onChanged;

  const _LabeledSlider({
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.displayValue,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$label: ${displayValue ?? value.toStringAsFixed(2)}",
          style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        Slider(
          value: value.clamp(min, max).toDouble(),
          min: min,
          max: max,
          divisions: divisions ?? 20,
          label: displayValue ?? value.toStringAsFixed(2),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _StickerSelectionCard extends StatelessWidget {
  final StickerLayer layer;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onDeselect;

  const _StickerSelectionCard({
    required this.layer,
    required this.isSelected,
    required this.onSelect,
    required this.onDeselect,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFF7FAFF) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSelected ? AppColors.secondary : AppColors.light.border,
          width: isSelected ? 1.6 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.light.border),
            ),
            child: _StickerGraphic(
              imageUrl: layer.imageUrl,
              crop: layer.crop,
              tintColorValue: layer.tintColorValue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  layer.surface.label,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isSelected ? "Đang được chọn" : "Chưa chọn sticker này",
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.light.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          isSelected
              ? OutlinedButton(
                  onPressed: onDeselect,
                  child: const Text("Bỏ chọn"),
                )
              : FilledButton(
                  onPressed: onSelect,
                  child: const Text("Chọn"),
                ),
        ],
      ),
    );
  }
}

class _SurfaceStickerOverlay extends StatelessWidget {
  final List<StickerLayer> layers;
  final int? selectedLayerId;
  final Rect surfaceRect;
  final double baseStickerSizeFactor;
  final ValueChanged<int>? onLayerTap;

  const _SurfaceStickerOverlay({
    required this.layers,
    required this.selectedLayerId,
    required this.surfaceRect,
    required this.baseStickerSizeFactor,
    this.onLayerTap,
  });

  @override
  Widget build(BuildContext context) {
    if (layers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        for (final layer in layers)
          _SurfaceStickerPositioned(
            layer: layer,
            selectedLayerId: selectedLayerId,
            surfaceRect: surfaceRect,
            baseStickerSizeFactor: baseStickerSizeFactor,
            onTap: onLayerTap,
          ),
      ],
    );
  }
}

class _SurfaceStickerPositioned extends StatelessWidget {
  final StickerLayer layer;
  final int? selectedLayerId;
  final Rect surfaceRect;
  final double baseStickerSizeFactor;
  final ValueChanged<int>? onTap;

  const _SurfaceStickerPositioned({
    required this.layer,
    required this.selectedLayerId,
    required this.surfaceRect,
    required this.baseStickerSizeFactor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final shortestSide = math.min(surfaceRect.width, surfaceRect.height);
    final size = (shortestSide * baseStickerSizeFactor * layer.surfaceScale)
        .clamp(34.0, shortestSide * 0.88)
        .toDouble();
    final left =
        (surfaceRect.left + layer.surfaceX * surfaceRect.width - size / 2)
            .clamp(
              surfaceRect.left - size * 0.1,
              surfaceRect.right - size * 0.9,
            )
            .toDouble();
    final top =
        (surfaceRect.top + layer.surfaceY * surfaceRect.height - size / 2)
            .clamp(
              surfaceRect.top - size * 0.1,
              surfaceRect.bottom - size * 0.9,
            )
            .toDouble();
    final isSelected = layer.id == selectedLayerId;

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onTap: onTap == null ? null : () => onTap!(layer.id),
        child: Transform.rotate(
          angle: layer.rotation,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: size,
            height: size,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isSelected ? AppColors.secondary : Colors.transparent,
                width: isSelected ? 2.4 : 1,
              ),
              color: Colors.white.withOpacity(isSelected ? 0.24 : 0.08),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isSelected ? 0.18 : 0.08),
                  blurRadius: isSelected ? 18 : 10,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: _StickerGraphic(
              imageUrl: layer.imageUrl,
              crop: layer.crop,
              tintColorValue: layer.tintColorValue,
            ),
          ),
        ),
      ),
    );
  }
}

class _StickerGraphic extends StatelessWidget {
  final String imageUrl;
  final StickerCrop crop;
  final int? tintColorValue;

  const _StickerGraphic({
    required this.imageUrl,
    required this.crop,
    this.tintColorValue,
  });

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (imageUrl.startsWith("assets/")) {
      child = Image.asset(imageUrl, fit: BoxFit.contain);
    } else {
      child = Image.network(
        imageUrl,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
      );
    }

    if (tintColorValue != null) {
      child = ColorFiltered(
        colorFilter: ColorFilter.mode(
          Color(tintColorValue!),
          BlendMode.modulate,
        ),
        child: child,
      );
    }

    final widthFactor = (crop.right - crop.left).clamp(0.12, 1.0).toDouble();
    final heightFactor = (crop.bottom - crop.top).clamp(0.12, 1.0).toDouble();
    final alignX = (((crop.left + crop.right) / 2) * 2 - 1).clamp(-1.0, 1.0);
    final alignY = (((crop.top + crop.bottom) / 2) * 2 - 1).clamp(-1.0, 1.0);

    return ClipRect(
      child: Align(
        alignment: Alignment(alignX.toDouble(), alignY.toDouble()),
        widthFactor: widthFactor,
        heightFactor: heightFactor,
        child: child,
      ),
    );
  }
}
