import 'package:b2205946_duonghuuluan_luanvan/app/theme/colors.dart';
import 'package:b2205946_duonghuuluan_luanvan/app/utils/currency_ext.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/cart/domain/cart.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/product/domain/product.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/product/domain/product_extension.dart';
import 'package:flutter/material.dart';

class CartRow extends StatelessWidget {
  final CartDetail cartDetail;
  final Product? product;
  final VoidCallback onRemove;
  final void Function(int quantity) onUpdateQuantity;
  const CartRow({
    super.key,
    required this.cartDetail,
    required this.onRemove,
    required this.onUpdateQuantity,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    final detailProduct = cartDetail.productDetail;
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
            flex: 7,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _RemoveButton(onPressed: onRemove),

                const SizedBox(width: 5),
                _ProductImage(url: imageUrl),

                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product?.name ??
                            "Sản phẩm #${cartDetail.productDetailId}",
                        maxLines: 2,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),

                      const SizedBox(height: 6),
                      Text(
                        "Màu sắc: ${detailProduct.colorName}",
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      Text(
                        "Kích cỡ: ${detailProduct.size}",
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "${cartDetail.quantity} x ${detailProduct.price.toVnd()}",
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            flex: 3,
            child: _QuantityControl(
              onChanged: onUpdateQuantity,
              quantity: cartDetail.quantity,
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
          border: Border.all(color: AppColors.onSecondary),
        ),
        child: const Icon(Icons.close, size: 16, color: AppColors.textPrimary),
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  final String? url;
  const _ProductImage({this.url});

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
        errorBuilder: (context, error, stackTrace) => _ImagePlaceholder(),
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

class _QuantityControl extends StatelessWidget {
  final int quantity;
  final void Function(int quantity) onChanged;
  const _QuantityControl({required this.onChanged, required this.quantity});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _QuantityButton(
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
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        _QuantityButton(
          icon: Icons.add,
          onPressed: () => onChanged(quantity + 1),
        ),
      ],
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  const _QuantityButton({required this.icon, required this.onPressed});

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
