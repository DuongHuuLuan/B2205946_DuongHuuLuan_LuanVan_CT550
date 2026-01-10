import 'package:b2205946_duonghuuluan_luanvan/app/theme/colors.dart';
import 'package:b2205946_duonghuuluan_luanvan/app/utils/currency_ext.dart';
import 'package:flutter/material.dart';

class CartSummary extends StatelessWidget {
  final double total;

  const CartSummary({super.key, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "TỔNG CỘNG GIỎ HÀNG",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const Divider(height: 20),
          _SummaryRow(label: "Tạm Tính", value: total.toVnd()),
          const Divider(height: 18),
          _SummaryRow(label: "Tổng", value: total.toVnd()),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
