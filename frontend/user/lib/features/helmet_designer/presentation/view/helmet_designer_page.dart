import 'package:b2205946_duonghuuluan_luanvan/app/theme/colors.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/helmet_designer/domain/ai_sticker_request.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/helmet_designer/domain/sticker_crop.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/helmet_designer/domain/sticker_layer.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/helmet_designer/domain/sticker_template.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/helmet_designer/presentation/view/helmet_preview_canvas.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/helmet_designer/presentation/viewmodel/helmet_designer_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class HelmetDesignerPage extends StatefulWidget {
  final int? designId;
  final int? initialHelmetProductId;
  final String? initialHelmetName;
  final String? initialHelmetBaseImageUrl;

  const HelmetDesignerPage({
    super.key,
    this.designId,
    this.initialHelmetProductId,
    this.initialHelmetName,
    this.initialHelmetBaseImageUrl,
  });

  @override
  State<HelmetDesignerPage> createState() => _HelmetDesignerPageState();
}

class _HelmetDesignerPageState extends State<HelmetDesignerPage> {
  static const List<String> _aiStyles = [
    "Street",
    "Sport",
    "Cute",
    "Minimal",
    "Flame",
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
  String _selectedAiStyle = _aiStyles.first;
  Color? _selectedAiColor;
  bool _removeAiBackground = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final vm = context.read<HelmetDesignerViewModel>();
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
          helmetName: widget.initialHelmetName ?? "Helmet",
          helmetBaseImageUrl: widget.initialHelmetBaseImageUrl ?? "",
        );
        return;
      }

      if (vm.currentDesign.helmetProductId == 0) {
        vm.startNewDesign(
          helmetProductId: 101,
          helmetName: "Royal Street Helmet",
          helmetBaseImageUrl: "assets/images/logo.webp",
        );
      }
    });
  }

  @override
  void dispose() {
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
          "Helmet Designer",
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
                        SnackBar(content: Text("Da luu thiet ke #${saved.id}")),
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
          _HeroCard(
            title: vm.currentDesign.helmetName.isEmpty
                ? "Khoi tao mau non"
                : vm.currentDesign.helmetName,
            subtitle:
                "Canvas da noi voi state quan ly sticker. Buoc tiep theo se them thao tac keo tha truc tiep va cong cu chinh sua day du.",
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
                            SnackBar(content: Text("Link chia se: $url")),
                          );
                        },
                  icon: const Icon(Icons.ios_share_outlined),
                  label: Text(vm.shareUrl == null ? "Chia se" : "Da tao link"),
                ),
                FilledButton.icon(
                  onPressed: () => context.go("/helmet-try-on"),
                  icon: const Icon(Icons.view_in_ar_outlined),
                  label: const Text("Thu non"),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Preview canvas",
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          HelmetPreviewCanvas(
            layers: vm.stickerLayers,
            selectedLayerId: vm.selectedLayerId,
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
          Text(
            "Keo sticker de di chuyen. Dung pinch de phong to hoac thu nho, va xoay hai ngon tay de doi huong truc tiep tren canvas.",
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.light.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          if (selectedLayer != null)
            _LayerToolbar(
              layer: selectedLayer,
              palette: _pickerColors,
            )
          else
            const _HintCard(
              text:
                  "Chon mot sticker trong danh sach layer hoac them sticker tu catalog de bat dau chinh sua.",
            ),
          const SizedBox(height: 20),
          _AiStickerSection(
            promptController: _aiPromptController,
            selectedStyle: _selectedAiStyle,
            selectedColor: _selectedAiColor,
            removeBackground: _removeAiBackground,
            styles: _aiStyles,
            palette: _pickerColors,
            isGenerating: vm.isGeneratingSticker,
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
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  "Sticker catalog",
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
                return _StickerCatalogCard(template: item);
              },
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  "Layer stack",
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                "${vm.stickerLayers.length} sticker",
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.light.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (!vm.hasLayers)
            const _HintCard(
              text:
                  "Chua co sticker nao trong thiet ke. Tap vao mot sticker ben tren de dua vao non.",
            )
          else
            ...vm.stickerLayers.reversed.map(_LayerTile.new),
          if (vm.errorMessage != null) ...[
            const SizedBox(height: 16),
            _HintCard(text: vm.errorMessage!, isError: true),
          ],
        ],
      ),
    );
  }

  Future<void> _generateAiSticker(BuildContext context) async {
    final prompt = _aiPromptController.text.trim();
    if (prompt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nhap prompt de tao sticker AI.")),
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
    );
    if (!mounted || sticker == null) return;

    _aiPromptController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Da tao sticker AI: ${sticker.name}")),
    );
  }

  String _colorToHex(Color color) {
    final value = color.value.toRadixString(16).padLeft(8, '0');
    return "#${value.substring(2).toUpperCase()}";
  }
}

class _HeroCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget trailing;

  const _HeroCard({
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF13243B), Color(0xFF30527D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.84),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          trailing,
        ],
      ),
    );
  }
}

class _StickerCatalogCard extends StatelessWidget {
  final StickerTemplate template;

  const _StickerCatalogCard({required this.template});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context
          .read<HelmetDesignerViewModel>()
          .addStickerFromTemplate(template),
      child: Container(
        width: 122,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.light.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Center(
                child: template.imageUrl.startsWith("assets/")
                    ? Image.asset(template.imageUrl, fit: BoxFit.contain)
                    : Image.network(
                        template.imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.image_not_supported),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              template.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              template.category,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.light.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LayerToolbar extends StatelessWidget {
  final StickerLayer layer;
  final List<Color> palette;

  const _LayerToolbar({
    required this.layer,
    required this.palette,
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
            "Layer dang chon #${layer.id}",
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => vm.rotateSelectedLayerBy(-0.15),
                icon: const Icon(Icons.rotate_left),
                label: const Text("Xoay trai"),
              ),
              OutlinedButton.icon(
                onPressed: () => vm.rotateSelectedLayerBy(0.15),
                icon: const Icon(Icons.rotate_right),
                label: const Text("Xoay phai"),
              ),
              OutlinedButton.icon(
                onPressed: () => vm.resizeSelectedLayerBy(0.9),
                icon: const Icon(Icons.remove),
                label: const Text("Thu nho"),
              ),
              OutlinedButton.icon(
                onPressed: () => vm.resizeSelectedLayerBy(1.1),
                icon: const Icon(Icons.add),
                label: const Text("Phong to"),
              ),
              OutlinedButton.icon(
                onPressed: vm.bringSelectedLayerForward,
                icon: const Icon(Icons.flip_to_front),
                label: const Text("Len tren"),
              ),
              OutlinedButton.icon(
                onPressed: vm.removeSelectedLayer,
                icon: const Icon(Icons.delete_outline),
                label: const Text("Xoa"),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            "Mau sticker",
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _ColorChipButton(
                label: "Goc",
                isSelected: layer.tintColorValue == null,
                color: null,
                onTap: () => vm.updateSelectedLayerTint(null),
              ),
              ...palette.map(
                (color) => _ColorChipButton(
                  color: color,
                  isSelected: layer.tintColorValue == color.value,
                  onTap: () => vm.updateSelectedLayerTint(color.value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            "Crop ngang",
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          RangeSlider(
            values: RangeValues(layer.crop.left, layer.crop.right),
            min: 0,
            max: 1,
            divisions: 20,
            labels: RangeLabels(
              layer.crop.left.toStringAsFixed(2),
              layer.crop.right.toStringAsFixed(2),
            ),
            onChanged: (values) {
              final range = _normalizeRange(values);
              vm.updateSelectedLayerCrop(
                layer.crop.copyWith(left: range.start, right: range.end),
              );
            },
          ),
          Text(
            "Crop doc",
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          RangeSlider(
            values: RangeValues(layer.crop.top, layer.crop.bottom),
            min: 0,
            max: 1,
            divisions: 20,
            labels: RangeLabels(
              layer.crop.top.toStringAsFixed(2),
              layer.crop.bottom.toStringAsFixed(2),
            ),
            onChanged: (values) {
              final range = _normalizeRange(values);
              vm.updateSelectedLayerCrop(
                layer.crop.copyWith(top: range.start, bottom: range.end),
              );
            },
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => vm.updateSelectedLayerCrop(StickerCrop()),
              icon: const Icon(Icons.crop_free),
              label: const Text("Reset crop"),
            ),
          ),
        ],
      ),
    );
  }
}

class _AiStickerSection extends StatelessWidget {
  final TextEditingController promptController;
  final String selectedStyle;
  final Color? selectedColor;
  final bool removeBackground;
  final List<String> styles;
  final List<Color> palette;
  final bool isGenerating;
  final ValueChanged<String> onStyleChanged;
  final ValueChanged<Color?> onColorChanged;
  final ValueChanged<bool> onBackgroundChanged;
  final VoidCallback onGenerate;

  const _AiStickerSection({
    required this.promptController,
    required this.selectedStyle,
    required this.selectedColor,
    required this.removeBackground,
    required this.styles,
    required this.palette,
    required this.isGenerating,
    required this.onStyleChanged,
    required this.onColorChanged,
    required this.onBackgroundChanged,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
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
            "Tao sticker bang AI",
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Nhap mo ta ngan, chon style va gam mau. Sticker AI sau khi tao se duoc them vao canvas ngay.",
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.light.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: promptController,
            minLines: 2,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: "Vi du: dragon flame decal, racing fox, cute cloud...",
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: styles.map((style) {
              return ChoiceChip(
                label: Text(style),
                selected: selectedStyle == style,
                onSelected: (_) => onStyleChanged(style),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _ColorChipButton(
                label: "Mac dinh",
                isSelected: selectedColor == null,
                color: null,
                onTap: () => onColorChanged(null),
              ),
              ...palette.map(
                (color) => _ColorChipButton(
                  color: color,
                  isSelected: selectedColor?.value == color.value,
                  onTap: () => onColorChanged(color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: removeBackground,
            onChanged: onBackgroundChanged,
            title: const Text("Tu dong tach nen"),
          ),
          const SizedBox(height: 6),
          FilledButton.icon(
            onPressed: isGenerating ? null : onGenerate,
            icon: isGenerating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
            label: const Text("Tao sticker AI"),
          ),
        ],
      ),
    );
  }
}

class _ColorChipButton extends StatelessWidget {
  final Color? color;
  final bool isSelected;
  final VoidCallback onTap;
  final String? label;

  const _ColorChipButton({
    required this.isSelected,
    required this.onTap,
    this.color,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected ? AppColors.secondary : AppColors.light.border;
    final fillColor = color ?? Colors.white;
    final showCheck = isSelected && color != null;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: label == null ? 0 : 12,
          vertical: label == null ? 0 : 8,
        ),
        width: label == null ? 34 : null,
        height: label == null ? 34 : null,
        decoration: BoxDecoration(
          color: fillColor,
          shape: label == null ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: label == null ? null : BorderRadius.circular(999),
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: label != null
            ? Text(
                label!,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              )
            : showCheck
            ? Icon(
                Icons.check,
                size: 14,
                color: color == const Color(0xFFFFFFFF)
                    ? AppColors.primary
                    : Colors.white,
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}

class _LayerTile extends StatelessWidget {
  final StickerLayer layer;

  const _LayerTile(this.layer);

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HelmetDesignerViewModel>();
    final isSelected = vm.selectedLayerId == layer.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: () =>
            context.read<HelmetDesignerViewModel>().selectLayer(layer.id),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFF0F4FA),
          child: Text(
            "${layer.zIndex + 1}",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        title: Text("Sticker #${layer.stickerId}"),
        subtitle: Text(
          "x ${layer.x.toStringAsFixed(2)}  y ${layer.y.toStringAsFixed(2)}  scale ${layer.scale.toStringAsFixed(2)}",
        ),
        trailing: isSelected
            ? const Icon(Icons.check_circle, color: AppColors.secondary)
            : const Icon(Icons.layers_outlined),
      ),
    );
  }
}

class _HintCard extends StatelessWidget {
  final String text;
  final bool isError;

  const _HintCard({required this.text, this.isError = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isError ? const Color(0xFFFFF0F0) : const Color(0xFFF5F8FC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isError ? const Color(0xFFFFC2C2) : AppColors.light.border,
        ),
      ),
      child: Text(text),
    );
  }
}

RangeValues _normalizeRange(RangeValues values, {double minSpan = 0.15}) {
  var start = values.start;
  var end = values.end;
  if (end - start >= minSpan) {
    return values;
  }

  end = (start + minSpan).clamp(0.0, 1.0);
  start = (end - minSpan).clamp(0.0, 1.0);
  return RangeValues(start.toDouble(), end.toDouble());
}
