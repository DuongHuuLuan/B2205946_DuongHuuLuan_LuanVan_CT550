import 'package:b2205946_duonghuuluan_luanvan/features/order/domain/delivery_info.dart';
import 'package:flutter/material.dart';

class AddressSection extends StatelessWidget {
  final List<DeliveryInfo> deliveries;
  final DeliveryInfo? selected;
  final bool useSaved;
  final ValueChanged<DeliveryInfo?> onSelect;
  final VoidCallback onUseNew;
  const AddressSection({
    super.key,
    required this.deliveries,
    required this.onSelect,
    required this.onUseNew,
    required this.selected,
    required this.useSaved,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        if (deliveries.isNotEmpty)
          ...deliveries.map(
            (info) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.location_on_outlined),
                title: Text("${info.name} • ${info.phone}"),
                subtitle: Text(info.address),
                trailing: Radio<DeliveryInfo>(
                  value: info,
                  groupValue: useSaved ? selected : null,
                  onChanged: (_) => onSelect(info),
                  activeColor: colorScheme.secondary,
                ),
                onTap: () => onSelect(info),
              ),
            ),
          ),
        TextButton(
          onPressed: onUseNew,
          child: Text(
            "Nhập địa chỉ mới",
            style: TextStyle(color: colorScheme.onSurface),
          ),
        ),
      ],
    );
  }
}
