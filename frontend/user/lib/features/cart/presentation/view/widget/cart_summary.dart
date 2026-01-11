import 'package:b2205946_duonghuuluan_luanvan/app/utils/currency_ext.dart';
import 'package:flutter/material.dart';

class CartSummary extends StatelessWidget {
  final double total;

  const CartSummary({super.key, required this.total});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface, // Dùng màu nền bề mặt
        border: Border.all(
          color: colorScheme.outlineVariant,
        ), // Viền nhẹ đồng bộ
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "TỔNG CỘNG GIỎ HÀNG",
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          Divider(height: 20, color: colorScheme.outlineVariant),
          _SummaryRow(
            label: "Tạm Tính",
            value: total.toVnd(),
            colorScheme: colorScheme,
          ),
          Divider(height: 18, color: colorScheme.outlineVariant),
          _SummaryRow(
            label: "Tổng",
            value: total.toVnd(),
            isTotal: true,
            colorScheme: colorScheme,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;
  final ColorScheme colorScheme;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isTotal = false,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: isTotal
                  ? colorScheme.onSurface
                  : colorScheme.onSurfaceVariant,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isTotal ? 16 : 14,
            color: isTotal ? colorScheme.onSurface : colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
