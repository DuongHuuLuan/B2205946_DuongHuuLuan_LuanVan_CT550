import 'package:b2205946_duonghuuluan_luanvan/app/utils/currency_ext.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/evaluate/presentation/view/evaluate_create_page.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/evaluate/presentation/viewmodel/evaluate_viewmodel.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/order/domain/order_models.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/order/domain/order_repository.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/profile/presentation/viewmodel/profile_viewmodel.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/profile/presentation/widget/status_chip.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class OrderDetailPage extends StatefulWidget {
  final int orderId;

  const OrderDetailPage({super.key, required this.orderId});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  OrderOut? _order;
  bool _isLoading = true;
  bool _isActing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadOrder);
  }

  Future<void> _loadOrder() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final order = await context.read<OrderRepository>().getOrderDetail(
        widget.orderId,
      );
      if (!mounted) return;
      setState(() => _order = order);
      await _syncEvaluateStatus(order.id);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _syncEvaluateStatus(int orderId) async {
    try {
      await context.read<EvaluateViewmodel>().syncEvaluateStatusForOrders([
        orderId,
      ]);
    } catch (_) {}
  }

  Future<void> _confirmReceived() async {
    final order = _order;
    if (order == null ||
        _normalizeStatus(order.status) != "shipping" ||
        _isActing) {
      return;
    }
    final shouldConfirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
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
      ),
    );
    if (shouldConfirm != true) return;

    setState(() => _isActing = true);
    try {
      await context.read<ProfileViewmodel>().confirmOrderReceived(order.id);
      await _loadOrder();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Xác nhận nhận hàng thành công.")),
      );
    } catch (_) {
      if (!mounted) return;
      final msg =
          context.read<ProfileViewmodel>().errorMessage ??
          "Xác nhận nhận hàng thất bại.";
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _isActing = false);
    }
  }

  Future<void> _cancelOrder() async {
    final order = _order;
    if (order == null ||
        _normalizeStatus(order.status) != "pending" ||
        _isActing) {
      return;
    }
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xác nhận hủy đơn hàng"),
        content: Text("Bạn có muốn hủy đơn hàng #DH-${order.id}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              "Không",
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Hủy đơn"),
          ),
        ],
      ),
    );
    if (shouldCancel != true) return;

    setState(() => _isActing = true);
    try {
      await context.read<ProfileViewmodel>().cancelOrder(order.id);
      await _loadOrder();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Hủy đơn hàng thành công.")));
    } catch (_) {
      if (!mounted) return;
      final msg =
          context.read<ProfileViewmodel>().errorMessage ??
          "Hủy đơn hàng thất bại.";
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _isActing = false);
    }
  }

  Future<void> _createEvaluate() async {
    final order = _order;
    if (order == null ||
        _normalizeStatus(order.status) != "completed" ||
        _isActing) {
      return;
    }
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => EvaluateCreatePage(orderId: order.id)),
    );
    if (result == true && mounted) {
      await _syncEvaluateStatus(order.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;
    final evaluateVm = context.watch<EvaluateViewmodel>();
    final isReviewed =
        order != null && evaluateVm.reviewedOrderIds.contains(order.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          order == null ? "Chi tiết đơn hàng" : "Đơn hàng #DH-${order.id}",
        ),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadOrder,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _ErrorView(message: _error!, onRetry: _loadOrder)
          : order == null
          ? _ErrorView(message: "Không tìm thấy đơn hàng.", onRetry: _loadOrder)
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _OrderHeaderCard(order: order),
                    const SizedBox(height: 12),
                    _SectionCard(
                      title: "Thông tin người đặt",
                      child: _InfoList(
                        rows: [
                          _InfoRowData(
                            label: "Người nhận",
                            value: _safeText(order.deliveryInfo?.name),
                          ),
                          _InfoRowData(
                            label: "Số điện thoại",
                            value: _safeText(order.deliveryInfo?.phone),
                          ),
                          _InfoRowData(
                            label: "Địa chỉ",
                            value: _safeText(order.deliveryInfo?.address),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      title: "Thanh toán & vận chuyển",
                      child: _InfoList(
                        rows: [
                          _InfoRowData(
                            label: "Phương thức thanh toán",
                            value: _safeText(order.paymentMethod?.name),
                          ),
                          _InfoRowData(
                            label: "Mã giảm giá",
                            value: (order.discountCode ?? "").trim().isEmpty
                                ? "Không áp dụng"
                                : order.discountCode!.trim(),
                          ),
                          _InfoRowData(
                            label: "Phí ship",
                            value: order.shippingFee.toVnd(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      title: "Sản phẩm",
                      child: order.orderDetails.isEmpty
                          ? const Text("Không có sản phẩm trong đơn hàng.")
                          : Column(
                              children: order.orderDetails
                                  .map(
                                    (item) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12,
                                      ),
                                      child: _OrderProductTile(detail: item),
                                    ),
                                  )
                                  .toList(),
                            ),
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      title: "Tổng tiền",
                      child: _TotalBox(order: order),
                    ),
                    const SizedBox(height: 16),
                    _ActionSection(
                      status: order.status,
                      isBusy: _isActing,
                      isReviewed: isReviewed,
                      onCancel: _cancelOrder,
                      onConfirmReceived: _confirmReceived,
                      onEvaluate: _createEvaluate,
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: () => context.go("/"),
                      child: const Text("Về trang chủ"),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  String _normalizeStatus(String value) => value.trim().toLowerCase();

  String _safeText(String? value) {
    final text = value?.trim() ?? "";
    return text.isEmpty ? "Chưa có" : text;
  }
}

class _OrderHeaderCard extends StatelessWidget {
  final OrderOut order;

  const _OrderHeaderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final date = order.createdAt;
    final dateText = date == null
        ? "--/--/----"
        : "${date.day.toString().padLeft(2, "0")}/${date.month.toString().padLeft(2, "0")}/${date.year} ${date.hour.toString().padLeft(2, "0")}:${date.minute.toString().padLeft(2, "0")}";
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "#DH-${order.id}",
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                StatusChip(status: order.status),
                Text("Ngày đặt: $dateText"),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _InfoRowData {
  final String label;
  final String value;

  const _InfoRowData({required this.label, required this.value});
}

class _InfoList extends StatelessWidget {
  final List<_InfoRowData> rows;

  const _InfoList({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: rows
          .map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 138,
                    child: Text(
                      row.label,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      row.value,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _OrderProductTile extends StatelessWidget {
  final OrderDetailOut detail;

  const _OrderProductTile({required this.detail});

  @override
  Widget build(BuildContext context) {
    final imageUrl = (detail.imageUrl ?? "").trim();
    final lineTotal = detail.quantity * detail.price;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 72,
            height: 72,
            color: Colors.grey.shade100,
            child: imageUrl.isEmpty
                ? const Icon(Icons.image_not_supported_outlined)
                : Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.broken_image_outlined),
                  ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                detail.productName,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                _variantText(detail),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Text(
                "Số lượng: ${detail.quantity}",
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                "Đơn giá: ${detail.price.toVnd()}",
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 2),
              Text(
                "Thành tiền: ${lineTotal.toVnd()}",
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _variantText(OrderDetailOut item) {
    final parts = <String>[];
    final color = (item.colorName ?? "").trim();
    final size = (item.sizeName ?? "").trim();
    if (color.isNotEmpty) parts.add("Màu: $color");
    if (size.isNotEmpty) parts.add("Kích thước: $size");
    return parts.isEmpty ? "Biến thể: --" : parts.join(" | ");
  }
}

class _TotalBox extends StatelessWidget {
  final OrderOut order;

  const _TotalBox({required this.order});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _totalRow("Tiền hàng", order.subtotal.toVnd()),
        const SizedBox(height: 6),
        _totalRow("Phí ship", order.shippingFee.toVnd()),
        const Divider(height: 18),
        _totalRow("Tổng thanh toán", order.total.toVnd(), isTotal: true),
      ],
    );
  }

  Widget _totalRow(String label, String value, {bool isTotal = false}) {
    return Builder(
      builder: (context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: isTotal ? Colors.red : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionSection extends StatelessWidget {
  final String status;
  final bool isBusy;
  final bool isReviewed;
  final VoidCallback onCancel;
  final VoidCallback onConfirmReceived;
  final VoidCallback onEvaluate;

  const _ActionSection({
    required this.status,
    required this.isBusy,
    required this.isReviewed,
    required this.onCancel,
    required this.onConfirmReceived,
    required this.onEvaluate,
  });

  @override
  Widget build(BuildContext context) {
    final normalized = status.trim().toLowerCase();
    final children = <Widget>[];

    if (normalized == "pending") {
      children.add(
        FilledButton.tonal(
          onPressed: isBusy ? null : onCancel,
          child: Text(isBusy ? "Đang xử lý..." : "Hủy đơn hàng"),
        ),
      );
    }

    if (normalized == "shipping") {
      children.add(
        FilledButton(
          onPressed: isBusy ? null : onConfirmReceived,
          child: Text(isBusy ? "Đang xử lý..." : "Đã nhận được hàng"),
        ),
      );
    }

    if (normalized == "completed") {
      children.add(
        OutlinedButton.icon(
          onPressed: isBusy || isReviewed ? null : onEvaluate,
          icon: Icon(
            isReviewed ? Icons.check_circle_outline : Icons.star_outline,
          ),
          label: Text(isReviewed ? "Đã đánh giá" : "Đánh giá"),
        ),
      );
    }

    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "Thao tác",
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        ...children.map(
          (w) => Padding(padding: const EdgeInsets.only(bottom: 8), child: w),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 40),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRetry, child: const Text("Tải lại")),
          ],
        ),
      ),
    );
  }
}
