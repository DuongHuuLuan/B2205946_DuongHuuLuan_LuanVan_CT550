import 'dart:async';

import 'package:b2205946_duonghuuluan_luanvan/features/order/domain/order_models.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/order/domain/order_repository.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderResultPage extends StatefulWidget {
  final int orderId;
  final String paymentUrl;

  const OrderResultPage({
    super.key,
    required this.orderId,
    required this.paymentUrl,
  });

  @override
  State<OrderResultPage> createState() => _OrderResultPageState();
}

class _OrderResultPageState extends State<OrderResultPage>
    with WidgetsBindingObserver {
  bool _isLaunching = false;
  bool _isChecking = false;
  String? _error;
  OrderOut? _order;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.paymentUrl.isNotEmpty) {
      Future.microtask(_launchPayment);
    }
    Future.microtask(_checkStatus);
    _startPolling();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkStatus();
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (mounted) {
        _checkStatus();
      }
    });
  }

  Future<void> _launchPayment() async {
    if (widget.paymentUrl.trim().isEmpty) return;
    if (_isLaunching) return;
    _isLaunching = true;
    final uri = Uri.parse(widget.paymentUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      setState(() => _error = "Không mở được link thanh toán");
    }
    _isLaunching = false;
  }

  Future<void> _checkStatus() async {
    if (_isChecking) return;
    setState(() {
      _isChecking = true;
      _error = null;
    });

    try {
      final repo = context.read<OrderRepository>();
      final order = await repo.getOrderDetail(widget.orderId);
      if (!mounted) return;
      setState(() => _order = order);
      if (_isSuccess(order.status) || _isFailed(order.status)) {
        _pollTimer?.cancel();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  bool _isSuccess(String status) {
    return status == "shipping" || status == "completed";
  }

  bool _isFailed(String status) => status == "cancelled";

  @override
  Widget build(BuildContext context) {
    final status = _order?.status;
    final isSuccess = status != null && _isSuccess(status);
    final isFailed = status != null && _isFailed(status);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Thanh toán"),
        leading: IconButton(
          onPressed: () => context.go("/"),
          icon: Icon(Icons.close),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 24),
            Icon(
              isSuccess
                  ? Icons.check_circle
                  : isFailed
                  ? Icons.cancel
                  : Icons.pending,
              size: 72,
              color: isSuccess
                  ? Colors.green
                  : isFailed
                  ? Colors.red
                  : Colors.orange,
            ),
            const SizedBox(height: 16),
            Text(
              isSuccess
                  ? "Thanh toán thành công"
                  : isFailed
                  ? "Thanh toán thất bại"
                  : "Đang chờ xác nhận thanh toán",
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Mã đơn hàng : #ĐH-${widget.orderId}",
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            const Spacer(),
            if (!isSuccess && !isFailed)
              ElevatedButton.icon(
                onPressed: _isChecking ? null : _checkStatus,
                label: Text(_isChecking ? "Đang kiểm tra..." : "Kiểm tra lại"),
              ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => context.go("/profile"),
              child: const Text("Xem đơn hàng"),
            ),
          ],
        ),
      ),
    );
  }
}
