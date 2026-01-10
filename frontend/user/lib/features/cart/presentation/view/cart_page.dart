import 'package:b2205946_duonghuuluan_luanvan/app/theme/colors.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/cart/presentation/view/widget/cart_actions.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/cart/presentation/view/widget/cart_summary.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/cart/presentation/view/widget/cart_table.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/cart/presentation/viewmodel/cart_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final _couponController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<CartViewmodel>().fetchCart());
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CartViewmodel>();
    final cartDetails = vm.cartDetails;

    return Scaffold(
      appBar: AppBar(title: const Text("Giỏ hàng")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // const _Breadcrumb(),
            const SizedBox(height: 12),
            CartTable(
              cartDetails: cartDetails,
              isLoading: vm.isLoading,
              resolveProduct: vm.productForDetail,
              onRemove: (id) => vm.deleteCartDetail(cartDetailId: id),
              onUpdateQuantity: (id, qty) =>
                  vm.updateCartDetail(cartDetailId: id, newQuantity: qty),
            ),
            const SizedBox(height: 16),
            CartActions(
              onContinue: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go("/");
                }
              },
              onRefresh: vm.fetchCart,
              isLoading: vm.isLoading,
            ),
            const SizedBox(height: 20),
            CartSummary(total: vm.totalPrice),
            const SizedBox(height: 16),
            _CheckoutButton(onPressed: () {}),
            const SizedBox(height: 16),
            _CouponBox(controller: _couponController, onApply: () {}),
          ],
        ),
      ),
    );
  }
}

class _Breadcrumb extends StatelessWidget {
  const _Breadcrumb();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: const Text(
        "Trang chủ | Giỏ hàng",
        style: TextStyle(color: AppColors.textSecondary),
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          flex: 4,
          child: Text(
            "SẢN PHẨM",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            "GiÁ",
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            "SỐ LƯỢNG",
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            "TẠM TÍNH",
            textAlign: TextAlign.end,
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _CheckoutButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _CheckoutButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        child: const Text("TIẾN HÀNH THANH TOÁN"),
      ),
    );
  }
}

class _CouponBox extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onApply;

  const _CouponBox({required this.controller, required this.onApply});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: const [
              Icon(Icons.local_offer, color: AppColors.textSecondary, size: 18),
              SizedBox(width: 8),
              Text("Mã ưu đãi", style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: "Nhập mã giảm giá"),
          ),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onApply, child: const Text("Áp dụng")),
        ],
      ),
    );
  }
}
