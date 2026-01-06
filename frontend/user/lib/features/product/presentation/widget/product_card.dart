import 'dart:math';

import 'package:b2205946_duonghuuluan_luanvan/app/theme/colors.dart';
import 'package:flutter/material.dart';

import 'package:b2205946_duonghuuluan_luanvan/features/product/domain/product.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/product/domain/product_variant.dart';

class ProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback? onTap;
  final void Function(Product product, ProductVariant variant)? onAddToCart;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onAddToCart,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  int _imgIndex = 0;
  String? _selectedSizeId;

  List<ProductVariant> get _variants => widget.product.variants;

  // size unique theo sizeId
  List<ProductVariant> get _uniqueSizes {
    final seen = <String>{};
    final result = <ProductVariant>[];
    for (final v in _variants) {
      if (seen.add(v.sizeId)) result.add(v);
    }
    return result;
  }

  ProductVariant? get _selectedVariant {
    if (_variants.isEmpty) return null;

    if (_selectedSizeId != null) {
      final match = _variants
          .where((v) => v.sizeId == _selectedSizeId)
          .toList();
      if (match.isNotEmpty) return match.first;
    }
    return _variants.first;
  }

  @override
  void initState() {
    super.initState();
    if (_variants.isNotEmpty) _selectedSizeId = _variants.first.sizeId;
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final variant = _selectedVariant;

    final mainUrl = p.images.isNotEmpty
        ? p.images[_imgIndex.clamp(0, p.images.length - 1)].url
        : null;

    final inStock = (variant?.stockQuantity ?? 0) > 0;
    final priceText = variant != null ? _formatVnd(variant.price) : "Liên hệ";

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black12, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Ảnh lớn
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
              child: AspectRatio(
                aspectRatio: 1,
                child: mainUrl != null
                    ? Image.network(
                        mainUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _imagePlaceholder(),
                        loadingBuilder: (context, child, progress) =>
                            progress == null ? child : _imageLoading(),
                      )
                    : _imagePlaceholder(),
              ),
            ),

            // thumbnails
            if (p.images.length > 1)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                child: SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: min(p.images.length, 4),
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final url = p.images[i].url;
                      final active = i == _imgIndex;

                      return InkWell(
                        onTap: () => setState(() => _imgIndex = i),
                        child: Container(
                          width: 44,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: active
                                  ? AppColors.secondary
                                  : Colors.black12,
                              width: active ? 2 : 1,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image.network(
                            url,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                Container(color: Colors.grey.shade200),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

            // size chips
            if (_uniqueSizes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _uniqueSizes.map((v) {
                    final selected = v.sizeId == _selectedSizeId;
                    return InkWell(
                      onTap: () => setState(() => _selectedSizeId = v.sizeId),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selected
                                ? AppColors.secondary
                                : Colors.black26,
                            width: selected ? 2 : 1,
                          ),
                        ),
                        child: Text(
                          v.size,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

            // Tên
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: Text(
                p.name.toUpperCase(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
            ),

            // Giá
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
              child: Text(
                "$priceText đ",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.error,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Add to cart
            Padding(
              padding: const EdgeInsets.all(10),
              child: SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed: (!inStock || variant == null)
                      ? null
                      : () => widget.onAddToCart?.call(p, variant),
                  child: Text(
                    inStock ? "THÊM VÀO GIỎ HÀNG" : "HẾT HÀNG",
                    style: inStock
                        ? TextStyle(color: AppColors.textPrimary)
                        : TextStyle(color: AppColors.error),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() => Container(
    color: Colors.grey.shade200,
    alignment: Alignment.center,
    child: const Icon(Icons.image, size: 40, color: Colors.black38),
  );

  Widget _imageLoading() => Container(
    color: Colors.grey.shade200,
    alignment: Alignment.center,
    child: const CircularProgressIndicator(strokeWidth: 2),
  );

  String _formatVnd(double v) {
    final s = v.toStringAsFixed(0);
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final left = s.length - i;
      buf.write(s[i]);
      if (left > 1 && left % 3 == 1) buf.write('.');
    }
    return buf.toString();
  }
}
