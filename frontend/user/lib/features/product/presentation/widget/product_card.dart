import 'dart:math';
import 'package:flutter/material.dart';

import 'package:b2205946_duonghuuluan_luanvan/app/theme/colors.dart';
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
  String? _selectedColorId;

  List<ProductVariant> get _variants => widget.product.variants;

  // ====== VARIANTS: sizes theo màu ======

  List<ProductVariant> get _uniqueSizes {
    final seen = <String>{};
    final result = <ProductVariant>[];

    final colorId =
        _selectedColorId ??
        (_variants.isNotEmpty ? _variants.first.colorId : null);

    final filtered = (colorId == null)
        ? _variants
        : _variants.where((v) => v.colorId == colorId).toList();

    for (final v in filtered) {
      if (seen.add(v.sizeId)) result.add(v);
    }
    return result;
  }

  ProductVariant? get _selectedVariant {
    if (_variants.isEmpty) return null;

    final colorId = _selectedColorId ?? _variants.first.colorId;
    final sizeId = _selectedSizeId ?? _variants.first.sizeId;

    final exact = _variants.where(
      (v) => v.colorId == colorId && v.sizeId == sizeId,
    );
    if (exact.isNotEmpty) return exact.first;

    final byColor = _variants.where((v) => v.colorId == colorId);
    if (byColor.isNotEmpty) return byColor.first;

    return _variants.first;
  }

  // ====== IMAGES: filter theo màu + fallback ảnh chung ======

  List get _allImages => widget.product.images;

  List get _commonImages =>
      _allImages.where((img) => img.colorId == null).toList();

  List _imagesByColor(String colorId) =>
      _allImages.where((img) => img.colorId == colorId).toList();

  // ảnh dùng để hiển thị cho màu đang chọn
  List get _displayImages {
    if (_allImages.isEmpty) return [];

    final cId = _selectedColorId;
    if (cId != null) {
      final byColor = _imagesByColor(cId);
      if (byColor.isNotEmpty) return byColor;
    }

    if (_commonImages.isNotEmpty) return _commonImages;

    return _allImages;
  }

  // ====== THUMBNAILS CHỌN MÀU (mỗi màu 1 ảnh đại diện) ======
  // ưu tiên lấy ảnh đầu tiên của màu đó; nếu không có thì bỏ qua
  List<_ColorThumb> get _colorThumbs {
    final seen = <String>{};
    final result = <_ColorThumb>[];

    for (final v in _variants) {
      if (!seen.add(v.colorId)) continue; // unique theo colorId

      final imgs = _imagesByColor(v.colorId);
      if (imgs.isEmpty) continue;

      result.add(
        _ColorThumb(
          colorId: v.colorId,
          label: v.colorName, // nếu bạn muốn hiện tên màu (optional)
          url: imgs.first.url,
        ),
      );
    }

    // fallback: nếu không có ảnh theo màu, không render dòng này
    return result;
  }

  @override
  void initState() {
    super.initState();
    if (_variants.isNotEmpty) {
      _selectedColorId = _variants.first.colorId;
      _selectedSizeId = _variants.first.sizeId;
    }
  }

  void _selectColor(String colorId) {
    setState(() {
      _selectedColorId = colorId;
      _imgIndex = 0; // đổi màu thì reset về ảnh đầu

      // nếu size đang chọn không tồn tại trong màu mới -> auto chọn size đầu tiên của màu đó
      final ok = _variants.any(
        (x) => x.colorId == colorId && x.sizeId == _selectedSizeId,
      );
      if (!ok) {
        final firstOfColor = _variants.firstWhere((x) => x.colorId == colorId);
        _selectedSizeId = firstOfColor.sizeId;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final variant = _selectedVariant;

    final images = _displayImages;

    final mainUrl = images.isNotEmpty
        ? images[_imgIndex.clamp(0, images.length - 1)].url
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

            // ✅ Dòng thumbnails chọn MÀU (mỗi màu 1 thumbnail)
            if (_colorThumbs.length > 1)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                child: SizedBox(
                  height: 48,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _colorThumbs.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final t = _colorThumbs[i];
                      final active = t.colorId == _selectedColorId;

                      return InkWell(
                        onTap: () => _selectColor(t.colorId),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: active
                                  ? AppColors.secondary
                                  : Colors.black12,
                              width: active ? 2 : 1,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image.network(
                            t.url,
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

            // ✅ Thumbnails ảnh (của màu đang chọn + fallback)
            if (images.length > 1)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                child: SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: min(images.length, 4),
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final url = images[i].url;
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

            // Size chips (theo màu)
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

            // Add to cart (đúng variant theo màu + size)
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

  // ===== helpers =====

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

// helper class nội bộ để render list thumbnail theo màu
class _ColorThumb {
  final String colorId;
  final String label;
  final String url;

  _ColorThumb({required this.colorId, required this.label, required this.url});
}
