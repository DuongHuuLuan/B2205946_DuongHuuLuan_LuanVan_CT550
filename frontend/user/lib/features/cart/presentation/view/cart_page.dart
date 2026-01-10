import 'package:b2205946_duonghuuluan_luanvan/app/theme/colors.dart';
import 'package:b2205946_duonghuuluan_luanvan/app/utils/currency_ext.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/cart/domain/cart.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/cart/presentation/viewmodel/cart_viewmodel.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/product/domain/product.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/product/domain/product_extension.dart';
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
            const _Breadcrumb(),
            const SizedBox(height: 12),
            _CartTable(
              cartDetails: cartDetails,
              isLoading: vm.isLoading,
              resolveProduct: vm.productForDetail,
              onRemove: (id) => vm.deleteCartDetail(cartDetailId: id),
              onUpdateQty: (id, qty) =>
                  vm.updateCartDetail(cartDetailId: id, newQuantity: qty),
            ),
            const SizedBox(height: 16),
            _CartActions(
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
            _CartSummary(total: vm.totalPrice),
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

class _CartTable extends StatelessWidget {
  final List<CartDetail> cartDetails;
  final bool isLoading;
  final void Function(int id) onRemove;
  final void Function(int id, int quantity) onUpdateQty;
  final Product? Function(int productDetailId) resolveProduct;

  const _CartTable({
    required this.cartDetails,
    required this.isLoading,
    required this.onRemove,
    required this.onUpdateQty,
    required this.resolveProduct,
  });

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
          const _HeaderRow(),
          const Divider(height: 18),
          if (isLoading && cartDetails.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (cartDetails.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text(
                  "Giỏ hàng trống",
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            ...cartDetails.map(
              (item) => _CartRow(
                detail: item,
                product: resolveProduct(item.productDetailId),
                onRemove: () => onRemove(item.id),
                onUpdateQty: (qty) => onUpdateQty(item.id, qty),
              ),
            ),
        ],
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

class _CartRow extends StatelessWidget {
  final CartDetail detail;
  final Product? product;
  final VoidCallback onRemove;
  final void Function(int quantity) onUpdateQty;

  const _CartRow({
    required this.detail,
    required this.product,
    required this.onRemove,
    required this.onUpdateQty,
  });

  @override
  Widget build(BuildContext context) {
    final detailProduct = detail.productDetail;
    final imageUrl = product
        ?.filterProductImages(detailProduct.colorId)
        .map((e) => e.url)
        .firstWhere((url) => url.isNotEmpty, orElse: () => "");

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _RemoveButton(onPressed: onRemove),
                const SizedBox(width: 10),
                _ProductImage(url: imageUrl),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product?.name ?? "Sản phẩm #${detail.productDetailId}",
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Màu sắc: ${detailProduct.colorName}",
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      Text(
                        "Kích cỡ: ${detailProduct.size}",
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              detailProduct.price.toVnd(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 2,
            child: _QtyControl(
              quantity: detail.quantity,
              onChanged: onUpdateQty,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              detail.lineTotal.toVnd(),
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _RemoveButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _RemoveButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
        ),
        child: const Icon(Icons.close, size: 16, color: AppColors.textPrimary),
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  final String? url;

  const _ProductImage({required this.url});

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return _ImagePlaceholder();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        url!,
        width: 64,
        height: 64,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _ImagePlaceholder();
        },
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: const Icon(Icons.shopping_bag, color: AppColors.textSecondary),
    );
  }
}

class _QtyControl extends StatelessWidget {
  final int quantity;
  final void Function(int quantity) onChanged;

  const _QtyControl({required this.quantity, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _QtyButton(
          icon: Icons.remove,
          onPressed: quantity > 1 ? () => onChanged(quantity - 1) : null,
        ),
        Container(
          width: 36,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            "$quantity",
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        _QtyButton(icon: Icons.add, onPressed: () => onChanged(quantity + 1)),
      ],
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _QtyButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(border: Border.all(color: AppColors.border)),
        child: Icon(icon, size: 16, color: AppColors.textPrimary),
      ),
    );
  }
}

class _CartActions extends StatelessWidget {
  final VoidCallback onContinue;
  final VoidCallback onRefresh;
  final bool isLoading;

  const _CartActions({
    required this.onContinue,
    required this.onRefresh,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onContinue,
            icon: const Icon(Icons.arrow_back),
            label: const Text("TIẾP TỤC XEM SẢN PHẨM"),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: isLoading ? null : onRefresh,
            child: const Text("CẬP NHẬT GIỎ HÀNG"),
          ),
        ),
      ],
    );
  }
}

class _CartSummary extends StatelessWidget {
  final double total;

  const _CartSummary({required this.total});

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
