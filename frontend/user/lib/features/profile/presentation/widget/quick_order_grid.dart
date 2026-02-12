import 'package:flutter/material.dart';

class QuickOrderItem {
  final IconData icon;
  final String label;
  final int count;
  final Color color;
  final bool isSelected;
  final VoidCallback? onTap;

  QuickOrderItem({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
    this.isSelected = false,
    this.onTap,
  });
}

class QuickOrderGrid extends StatelessWidget {
  final List<QuickOrderItem> items;

  const QuickOrderGrid({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.3,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: item.onTap,
            borderRadius: BorderRadius.circular(16),
            child: Card(
              margin: EdgeInsets.zero,
              elevation: item.isSelected ? 1 : 0.5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: item.isSelected
                      ? item.color.withValues(alpha: 0.6)
                      : Colors.transparent,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: item.color.withValues(alpha: 0.1),
                      child: Icon(item.icon, color: item.color),
                    ),
                    const Spacer(),
                    Text(
                      item.label,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "${item.count} đơn hàng",
                      style: TextStyle(color: item.color, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
