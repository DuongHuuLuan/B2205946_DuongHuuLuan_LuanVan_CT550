import 'package:b2205946_duonghuuluan_luanvan/app/utils/currency_ext.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/cart/domain/cart.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/product/domain/product.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/product/domain/product_extension.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CartRow extends StatelessWidget {
  final CartDetail cartDetail;
  final Product? product;
  final VoidCallback onRemove;
  final void Function(int quantity) onUpdateQuantity;
  final bool isSelected;
  final ValueChanged<bool?> onSelectedChanged;
  const CartRow({
    super.key,
    required this.cartDetail,
    required this.onRemove,
    required this.onUpdateQuantity,
    required this.product,
    required this.isSelected,
    required this.onSelectedChanged,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
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
                Checkbox(
                  value: isSelected,
                  onChanged: onSelectedChanged,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 4),
                _ProductImage(url: imageUrl),

                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product?.name ??
                            "Sản phẩm #${cartDetail.productDetailId}",
                        maxLines: 2,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 6),
                      Text(
                        "Màu sắc: ${detailProduct.colorName}",
                        style: TextStyle(color: color.secondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Kích cỡ: ${detailProduct.size}",
                        style: TextStyle(color: color.secondary),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "${cartDetail.quantity} x ${detailProduct.price.toVnd()}",
                        style: TextStyle(
                          color: color.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 5),

          Expanded(
            flex: 3,
            child: _QuantityControl(
              onChanged: onUpdateQuantity,
              quantity: cartDetail.quantity,
            ),
          ),
          const SizedBox(width: 5),
          _RemoveButton(onPressed: onRemove),
          const SizedBox(width: 3),
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
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onPressed,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: colorScheme.outlineVariant),
          color: colorScheme.surfaceContainerHighest,
        ),
        child: Icon(Icons.close, size: 16, color: colorScheme.error),
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
      child: CachedNetworkImage(
        imageUrl: url!,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        placeholder: (context, url) => _ImagePlaceholder(),
        errorWidget: (context, url, error) => _ImagePlaceholder(),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: colorScheme.outline,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.surfaceContainerHigh),
      ),
      child: Icon(Icons.shopping_bag, color: colorScheme.secondary),
    );
  }
}

class _QuantityControl extends StatelessWidget {
  final int quantity;
  final void Function(int quantity) onChanged;
  const _QuantityControl({required this.onChanged, required this.quantity});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _QuantityButton(
          icon: Icons.remove,
          onPressed: quantity > 1 ? () => onChanged(quantity - 1) : null,
        ),
        Container(
          width: 32,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 5),
          decoration: BoxDecoration(
            border: Border.symmetric(
              horizontal: BorderSide(color: colorScheme.outline),
            ),
          ),
          child: Text(
            "$quantity",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
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
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onPressed,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outline),
        ),
        child: Icon(
          icon,
          size: 16,
          color: onPressed == null
              ? colorScheme.onSurface
              : colorScheme.onSurface,
        ),
      ),
    );
  }
}
