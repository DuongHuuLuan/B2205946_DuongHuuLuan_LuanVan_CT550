import 'package:b2205946_duonghuuluan_luanvan/app/theme/colors.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/cart/domain/cart.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/cart/presentation/view/widget/cart_row.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/product/domain/product.dart';
import 'package:flutter/material.dart';

class CartTable extends StatelessWidget {
  final List<CartDetail> cartDetails;
  final bool isLoading;
  final void Function(int id) onRemove;
  final void Function(int id, int quantity) onUpdateQuantity;
  final Product? Function(int productDetailId) resolveProduct;
  const CartTable({
    super.key,
    required this.cartDetails,
    required this.isLoading,
    required this.onRemove,
    required this.onUpdateQuantity,
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
          // Tiêu đề bảng (Nếu bạn muốn giữ lại HeaderRow)
          const Text(
            "Chi tiết đơn hàng",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),

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
            // Dùng separated để có đường kẻ giữa các Item
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cartDetails.length,
              separatorBuilder: (context, index) => const Divider(height: 24),
              itemBuilder: (context, index) {
                final item = cartDetails[index];
                return CartRow(
                  cartDetail: item,
                  product: resolveProduct(item.productDetailId),
                  onRemove: () => onRemove(item.id),
                  onUpdateQuantity: (qty) => onUpdateQuantity(item.id, qty),
                );
              },
            ),
        ],
      ),
    );
  }
}
