import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OrderSuccessPage extends StatelessWidget {
  final int orderId;

  const OrderSuccessPage({
    super.key,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Đặt hàng thành công"),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 84,
                    color: theme.colorScheme.secondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Đặt hàng thành công",
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    orderId > 0
                        ? "Mã đơn hàng: #ĐH-$orderId"
                        : "Đơn hàng của bạn đã được ghi nhận.",
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 28),
                  ElevatedButton(
                    onPressed: () =>
                        context.go(orderId > 0 ? "/orders/$orderId" : "/profile"),
                    child: const Text("Xem đơn hàng"),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => context.go("/"),
                    child: const Text("Quay về trang chủ"),
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
