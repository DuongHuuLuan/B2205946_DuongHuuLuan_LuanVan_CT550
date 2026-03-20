import 'package:b2205946_duonghuuluan_luanvan/app/theme/colors.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/helmet_designer/presentation/widget/color_chip_button.dart';
import 'package:flutter/material.dart';

class AiStickerSection extends StatelessWidget {
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

  const AiStickerSection({
    super.key,
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
            'Tạo sticker bằng AI',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Nhập mô tả ngắn, chọn phong cách và màu chủ đạo. Sticker AI sẽ được thêm vào thiết kế ngay lập tức.',
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
              hintText:
                  'Ví dụ: rồng lửa decal, cáo đua xe, đám mây dễ thương...',
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
              ColorChipButton(
                label: 'Mặc định',
                isSelected: selectedColor == null,
                color: null,
                onTap: () => onColorChanged(null),
              ),
              ...palette.map(
                (color) => ColorChipButton(
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
            title: const Text('Tự động tách nền'),
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
            label: const Text('Tạo Sticker ngay'),
          ),
        ],
      ),
    );
  }
}
