import 'package:b2205946_duonghuuluan_luanvan/app/utils/currency_ext.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/order/domain/order_models.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/profile/presentation/widget/status_chip.dart';
import 'package:flutter/material.dart';

class OrderHistoryList extends StatelessWidget {
  final List<OrderOut> orders;
  final String emptyMessage;
  final bool enableDetail;
  final Future<void> Function(OrderOut order)? onConfirmReceived;
  final Set<int> confirmingOrderIds;
  final Future<void> Function(OrderOut order)? onCancelOrder;
  final Set<int> cancellingOrderIds;

  const OrderHistoryList({
    super.key,
    required this.orders,
    this.emptyMessage = "Bạn chưa có đơn hàng nào.",
    this.enableDetail = true,
    this.onConfirmReceived,
    this.confirmingOrderIds = const {},
    this.onCancelOrder,
    this.cancellingOrderIds = const {},
  });

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Text(emptyMessage, textAlign: TextAlign.center),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        final discountCode = order.discountCode?.trim() ?? "";
        final isConfirming = confirmingOrderIds.contains(order.id);
        final isCancelling = cancellingOrderIds.contains(order.id);

        return Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            onTap: enableDetail ? () => _showOrderDetail(context, order) : null,
            title: Text(
              "#DH-${order.id}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Ngày đặt: ${_formatDate(order.createdAt)}"),
                if (discountCode.isNotEmpty)
                  Text(
                    "Mã giảm giá: $discountCode",
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                if (_canConfirm(order) && onConfirmReceived != null) ...[
                  const SizedBox(height: 8),
                  FilledButton.tonal(
                    onPressed: isConfirming
                        ? null
                        : () => _handleConfirmReceived(context, order),
                    child: Text(
                      isConfirming ? "Đang xử lý..." : "Đã nhận hàng",
                    ),
                  ),
                ],
                if (_canCancel(order) && onCancelOrder != null) ...[
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: isCancelling
                        ? null
                        : () => _handleCancelOrder(context, order),
                    child: Text(
                      isCancelling ? "Đang xử lý..." : "Hủy đơn hàng",
                    ),
                  ),
                ],
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                StatusChip(status: order.status),
                const SizedBox(height: 4),
                Text(
                  order.total.toVnd(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleConfirmReceived(
    BuildContext context,
    OrderOut order,
  ) async {
    final callback = onConfirmReceived;
    if (callback == null) return;

    final shouldConfirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Xác nhận nhận hàng"),
          content: Text("Bạn đã nhận thành công đơn hàng #DH-${order.id}?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Hủy"),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("Xác nhận"),
            ),
          ],
        );
      },
    );

    if (shouldConfirm == true) {
      await callback(order);
    }
  }

  Future<void> _handleCancelOrder(BuildContext context, OrderOut order) async {
    final callback = onCancelOrder;
    if (callback == null) return;

    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Xác nhận hủy đơn hàng"),
          content: Text("Bạn có muốn hủy đơn hàng #DH-${order.id}?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Không"),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("Hủy đơn"),
            ),
          ],
        );
      },
    );

    if (shouldCancel == true) {
      await callback(order);
    }
  }

  Future<void> _showOrderDetail(BuildContext context, OrderOut order) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        final discountCode = order.discountCode?.trim() ?? "";
        return AlertDialog(
          title: Text("Chi tiết đơn hàng #DH-${order.id}"),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Ngày đặt: ${_formatDate(order.createdAt)}"),
                  const SizedBox(height: 8),
                  StatusChip(status: order.status),
                  if (discountCode.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text("Mã giảm giá: $discountCode"),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    "Sản phẩm",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (order.orderDetails.isEmpty)
                    const Text("Không có chi tiết sản phẩm.")
                  else
                    Column(
                      children: order.orderDetails
                          .map(
                            (detail) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _OrderLine(detail: detail),
                            ),
                          )
                          .toList(),
                    ),
                  const Divider(height: 20),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      "Tổng: ${order.total.toVnd()}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Đóng"),
            ),
          ],
        );
      },
    );
  }

  bool _canConfirm(OrderOut order) {
    return _normalizeStatus(order.status) == "shipping";
  }

  bool _canCancel(OrderOut order) {
    return _normalizeStatus(order.status) == "pending";
  }

  String _normalizeStatus(String value) => value.trim().toLowerCase();

  String _formatDate(DateTime? date) {
    if (date == null) return "--/--/----";
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }
}

class _OrderLine extends StatelessWidget {
  final OrderDetailOut detail;

  const _OrderLine({required this.detail});

  @override
  Widget build(BuildContext context) {
    final variant = _variantText(detail);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          detail.productName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        if (variant.isNotEmpty)
          Text(variant, style: Theme.of(context).textTheme.bodySmall),
        Text(
          "${detail.quantity} x ${detail.price.toVnd()}",
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  String _variantText(OrderDetailOut item) {
    final parts = <String>[];
    final color = item.colorName?.trim() ?? "";
    final size = item.sizeName?.trim() ?? "";
    if (color.isNotEmpty) parts.add("Màu: $color");
    if (size.isNotEmpty) parts.add("Kích thước: $size");
    return parts.join(" | ");
  }
}
