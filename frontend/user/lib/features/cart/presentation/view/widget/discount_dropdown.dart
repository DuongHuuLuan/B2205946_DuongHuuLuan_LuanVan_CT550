import 'package:b2205946_duonghuuluan_luanvan/features/discount/domain/discount.dart';
import 'package:flutter/material.dart';

class DiscountDropdown extends StatelessWidget {
  final List<Discount> discounts;
  final bool isLoading;
  final int? selectedId;
  final ValueChanged<int?> onChanged;
  const DiscountDropdown({
    super.key,
    required this.discounts,
    required this.isLoading,
    required this.onChanged,
    required this.selectedId,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final divider = Theme.of(context).dividerColor;
    final titleStyle = Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600);
    final iconColor = Theme.of(context).textTheme.bodySmall?.color;
    final items = <DropdownMenuItem<int?>>[
      const DropdownMenuItem(value: null, child: Text("Không áp dụng")),
      ...discounts.map(
        (d) => DropdownMenuItem(
          value: d.id,
          child: Text("${d.name} - ${d.percent}%"),
        ),
      ),
    ];

    final hasSelected =
        selectedId != null && discounts.any((d) => d.id == selectedId);
    final effectiveSelectedId = hasSelected ? selectedId : null;

    Discount? selected;
    if (hasSelected) {
      for (final discount in discounts) {
        if (discount.id == selectedId) {
          selected = discount;
          break;
        }
      }
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.local_offer, color: iconColor, size: 18),
              const SizedBox(width: 8),
              Text("Mã giảm giá", style: titleStyle),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int?>(
            value: effectiveSelectedId,
            items: items,
            onChanged: isLoading ? null : onChanged,
            decoration: const InputDecoration(hintText: "Chọn mã giảm giá"),
          ),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text("Đang tải mã giảm giá..."),
            )
          else if (selected != null && selected.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(selected.description),
            ),
        ],
      ),
    );
  }
}
