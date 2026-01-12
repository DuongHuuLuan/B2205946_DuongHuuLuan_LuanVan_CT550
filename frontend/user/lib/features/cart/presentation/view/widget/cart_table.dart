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
  final bool Function(int cartDetailId) isSelected;
  final void Function(int cartDetailId, bool selected) onSelectChanged;

  const CartTable({
    super.key,
    required this.cartDetails,
    required this.isLoading,
    required this.onRemove,
    required this.onUpdateQuantity,
    required this.resolveProduct,
    required this.isSelected,
    required this.onSelectChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      // padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isLoading && cartDetails.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: CircularProgressIndicator(color: colorScheme.primary),
              ),
            )
          else if (cartDetails.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  "Giỏ hàng trống",
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cartDetails.length,
              separatorBuilder: (context, index) => Divider(
                height: 24,
                color: colorScheme.outlineVariant.withOpacity(0.5),
              ),
              itemBuilder: (context, index) {
                final cartDetail = cartDetails[index];
                return CartRow(
                  cartDetail: cartDetail,
                  product: resolveProduct(cartDetail.productDetailId),
                  onRemove: () => onRemove(cartDetail.id),
                  onUpdateQuantity: (quantity) =>
                      onUpdateQuantity(cartDetail.id, quantity),
                  isSelected: isSelected(cartDetail.id),
                  onSelectedChanged: (value) =>
                      onSelectChanged(cartDetail.id, value ?? false),
                );
              },
            ),
        ],
      ),
    );
  }
}
