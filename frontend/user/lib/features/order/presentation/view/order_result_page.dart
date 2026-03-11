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
  final String callbackStatus;
  final String callbackValid;

  const OrderResultPage({
    super.key,
    required this.orderId,
    required this.paymentUrl,
    this.callbackStatus = "",
    this.callbackValid = "",
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
    } else if (mounted) {
      setState(() => _error = "Không thể mở liên kết thanh toán");
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

  bool get _hasSuccessCallback {
    return widget.callbackStatus == "success" && widget.callbackValid != "0";
  }

  bool get _hasFailedCallback {
    if (widget.callbackValid == "0") return true;
    return widget.callbackStatus == "failed";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final status = _order?.status;
    final orderIsSuccess = status != null && _isSuccess(status);
    final orderIsFailed = status != null && _isFailed(status);
    final isSuccess = orderIsSuccess;
    final isFailed = orderIsFailed || (!orderIsSuccess && _hasFailedCallback);
    final isWaiting = !isSuccess && !isFailed;

    final titleText = isSuccess
        ? "Thanh toán thành công"
        : isFailed
        ? "Thanh toán thất bại"
        : (_hasSuccessCallback
              ? "Đang đồng bộ kết quả thanh toán..."
              : "Đang chờ xác nhận thanh toán");

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Thanh toán"),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => context.go("/"),
          icon: const Icon(Icons.close),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 72,
                    height: 72,
                    child: isWaiting
                        ? Center(
                            child: SizedBox(
                              width: 42,
                              height: 42,
                              child: CircularProgressIndicator(
                                strokeWidth: 4,
                                color: colorScheme.secondary,
                              ),
                            ),
                          )
                        : Icon(
                            isSuccess ? Icons.check_circle : Icons.cancel,
                            size: 72,
                            color: isSuccess ? Colors.green : Colors.red,
                          ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    titleText,
                    style: textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Mã đơn hàng: #DH-${widget.orderId}",
                    style: textTheme.bodySmall,
                  ),
                  const SizedBox(height: 24),
                  if (_error != null)
                    Text(
                      _error!,
                      style: TextStyle(color: colorScheme.error),
                      textAlign: TextAlign.center,
                    ),
                  if (_error != null) const SizedBox(height: 12),
                  if (isWaiting)
                    ElevatedButton.icon(
                      onPressed: _isChecking ? null : _checkStatus,
                      icon: _isChecking
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh),
                      label: Text(
                        _isChecking ? "Đang kiểm tra..." : "Kiểm tra lại",
                      ),
                    ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => context.go("/orders/${widget.orderId}"),
                    child: Text(
                      "Xem đơn hàng",
                      style: TextStyle(color: colorScheme.secondary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
