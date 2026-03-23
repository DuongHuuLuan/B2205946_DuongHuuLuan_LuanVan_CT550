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
  final bool isVoiceRecording;
  final bool isVoiceBusy;
  final String? voiceStatusText;
  final List<double> voiceWaveLevels;
  final ValueChanged<String> onStyleChanged;
  final ValueChanged<Color?> onColorChanged;
  final ValueChanged<bool> onBackgroundChanged;
  final VoidCallback onGenerate;
  final VoidCallback onToggleVoice;

  const AiStickerSection({
    super.key,
    required this.promptController,
    required this.selectedStyle,
    required this.selectedColor,
    required this.removeBackground,
    required this.styles,
    required this.palette,
    required this.isGenerating,
    required this.isVoiceRecording,
    required this.isVoiceBusy,
    required this.voiceStatusText,
    required this.voiceWaveLevels,
    required this.onStyleChanged,
    required this.onColorChanged,
    required this.onBackgroundChanged,
    required this.onGenerate,
    required this.onToggleVoice,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final hasVoiceStatus = (voiceStatusText ?? '').trim().isNotEmpty;
    final voiceButtonLabel = isVoiceRecording
        ? 'Dừng ghi âm'
        : isVoiceBusy
        ? 'Đang xử lý...'
        : 'Nhấn để nói';

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
            'Nhập mô tả ngắn, chọn phong cách và màu chủ đạo. Bạn có thể gõ prompt hoặc nhấn nút mic để nói.',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.light.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Khi bạn im lặng, ứng dụng sẽ tự dừng ghi âm, xử lý giọng nói và tạo sticker.',
            style: textTheme.bodySmall?.copyWith(
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
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: isGenerating || isVoiceRecording || isVoiceBusy
                    ? null
                    : onGenerate,
                icon: isGenerating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome),
                label: const Text('Tạo sticker ngay'),
              ),
              OutlinedButton.icon(
                onPressed: isGenerating || isVoiceBusy ? null : onToggleVoice,
                icon: Icon(
                  isVoiceRecording
                      ? Icons.stop_circle_outlined
                      : Icons.mic_none_outlined,
                ),
                label: Text(voiceButtonLabel),
              ),
            ],
          ),
          if (hasVoiceStatus) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (isVoiceRecording || isVoiceBusy) ...[
                  _VoiceWaveBars(
                    levels: voiceWaveLevels,
                    color: isVoiceRecording
                        ? AppColors.primary
                        : AppColors.light.textSecondary,
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    voiceStatusText!,
                    style: textTheme.bodySmall?.copyWith(
                      color: isVoiceRecording
                          ? AppColors.primary
                          : AppColors.light.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _VoiceWaveBars extends StatelessWidget {
  static const List<double> _fallbackLevels = [
    0.18,
    0.24,
    0.32,
    0.42,
    0.32,
    0.24,
    0.18,
  ];

  final List<double> levels;
  final Color color;

  const _VoiceWaveBars({required this.levels, required this.color});

  @override
  Widget build(BuildContext context) {
    final bars = levels.length >= 5 ? levels : _fallbackLevels;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(bars.length, (index) {
        final level = bars[index].clamp(0.18, 1.0).toDouble();
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          margin: EdgeInsets.only(right: index == bars.length - 1 ? 0 : 3),
          width: 4,
          height: 8 + (18 * level),
          decoration: BoxDecoration(
            color: color.withOpacity(0.25 + (0.75 * level)),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}
