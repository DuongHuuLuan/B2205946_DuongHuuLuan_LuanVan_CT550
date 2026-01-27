import 'dart:math';
import 'package:b2205946_duonghuuluan_luanvan/app/theme/colors.dart';
import 'package:b2205946_duonghuuluan_luanvan/app/utils/currency_ext.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

// Giữ nguyên các import domain của bạn
import 'package:b2205946_duonghuuluan_luanvan/features/product/domain/product.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/product/domain/product_extension.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/product/domain/product_image.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/product/domain/product_detail.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/warehouse/domain/warehouse_repository.dart';
import 'package:provider/provider.dart';

class ProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback? onTap;
  final void Function(
    Product product,
    ProductDetail productDetail,
    int quantity,
  )?
  onAddToCart;

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
  int? _selectedColorId;
  int? _selectedSizeId;
  int? _availableQuantity;

  Product get _p => widget.product;

  // ====== Giữ nguyên helpers images ======
  List<ProductImage> _imagesByColor(int colorId) =>
      _p.images.where((img) => img.colorId == colorId).toList();

  List<ProductImage> get _commonImages =>
      _p.images.where((img) => img.colorId == null).toList();

  List<ProductImage> get _displayImages =>
      _p.filterProductImages(_selectedColorId);

  // ====== Giữ nguyên UI data ======
  List<ProductDetail> get _colors => _p.uniqueColors;
  List<ProductDetail> get _sizes => _p.getUniqueSizesByColor(_selectedColorId);
  ProductDetail? get _selectedProductDetail =>
      _p.findProductDetail(_selectedColorId, _selectedSizeId);

  // ====== Giữ nguyên Color thumbnails ======
  List<_ColorThumb> get _colorThumbs {
    if (_colors.isEmpty) return [];
    final result = <_ColorThumb>[];
    for (final c in _colors) {
      final byColor = _imagesByColor(c.colorId);
      final fallback = _commonImages.isNotEmpty ? _commonImages : _p.images;
      final list = byColor.isNotEmpty ? byColor : fallback;
      if (list.isEmpty) continue;
      result.add(
        _ColorThumb(
          colorId: c.colorId,
          label: c.colorName,
          url: list.first.url,
        ),
      );
    }
    return result;
  }

  @override
  void initState() {
    super.initState();
    if (_p.productDetails.isNotEmpty) {
      _selectedColorId = _p.productDetails.first.colorId;
      _selectedSizeId = _p.productDetails.first.sizeId;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadStock());
  }

  void _selectColor(int colorId) {
    setState(() {
      _selectedColorId = colorId;
      _imgIndex = 0;
      final sizes = _p.getUniqueSizesByColor(colorId);
      final stillOk = sizes.any((s) => s.sizeId == _selectedSizeId);
      if (!stillOk) {
        _selectedSizeId = sizes.isNotEmpty ? sizes.first.sizeId : null;
      }
    });
    _loadStock();
  }

  void _selectSize(int sizeId) {
    setState(() => _selectedSizeId = sizeId);
    _loadStock();
  }

  Future<void> _loadStock() async {
    final detail = _selectedProductDetail;
    if (detail == null) {
      if (!mounted) return;
      setState(() => _availableQuantity = null);
      return;
    }
    if (mounted) setState(() => _availableQuantity = null);
    try {
      final qty = await context.read<WarehouseRepository>().getTotalStock(
        productId: _p.id,
        colorId: detail.colorId,
        sizeId: detail.sizeId,
      );
      if (!mounted) return;
      setState(() => _availableQuantity = qty);
    } catch (_) {
      if (!mounted) return;
      setState(() => _availableQuantity = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final productDetail = _selectedProductDetail;
    final images = _displayImages;

    // Khai báo theme để sử dụng bên dưới
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final mainUrl = images.isNotEmpty
        ? images[_imgIndex.clamp(0, images.length - 1)].url
        : null;

    final inStock = _availableQuantity != null && _availableQuantity! > 0;
    final priceText = productDetail != null
        ? productDetail.price.toVnd()
        : "Liên hệ";

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.onPrimary,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: colorScheme.outline,
            width: 1.25,
          ), // Thay Colors.black12
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
              child: AspectRatio(
                aspectRatio: 1,
                child: mainUrl != null
                    ? CachedNetworkImage(
                        imageUrl: mainUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            _imageLoading(colorScheme),
                        errorWidget: (context, url, error) =>
                            _imagePlaceholder(colorScheme),
                      )
                    : _imagePlaceholder(colorScheme),
              ),
            ),

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
                                  ? colorScheme.secondary
                                  : colorScheme.outline,
                              width: active ? 2 : 1,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: CachedNetworkImage(
                            imageUrl: t.url,
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                Container(color: colorScheme.surfaceVariant),
                            errorWidget: (context, url, error) =>
                                Container(color: colorScheme.surfaceVariant),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

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
                                  ? colorScheme.secondary
                                  : colorScheme.outlineVariant,
                              width: active ? 2 : 1,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: CachedNetworkImage(
                            imageUrl: url,
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                Container(color: colorScheme.surfaceVariant),
                            errorWidget: (context, url, error) =>
                                Container(color: colorScheme.surfaceVariant),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

            // Size
            if (_sizes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _sizes.map((v) {
                    final selected = v.sizeId == _selectedSizeId;
                    return InkWell(
                      onTap: () => _selectSize(v.sizeId),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selected
                                ? colorScheme.secondary
                                : colorScheme.outline,
                            width: selected ? 2 : 1,
                          ),
                        ),
                        child: Text(
                          v.size,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: selected
                                ? colorScheme.secondary
                                : colorScheme.onSecondary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: Text(
                _p.name.toUpperCase(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSecondary,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
              child: Text(
                priceText,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: colorScheme.error,
                ),
              ),
            ),

            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.all(10),
              child: SizedBox(
                height: 44,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: inStock
                        ? colorScheme.secondary
                        : colorScheme.surfaceVariant,
                    foregroundColor: inStock
                        ? colorScheme.onPrimary
                        : colorScheme.onSurfaceVariant,
                  ),
                  onPressed: (!inStock || productDetail == null)
                      ? null
                      : () => widget.onAddToCart?.call(_p, productDetail, 1),
                  child: Text(inStock ? "THÊM VÀO GIỎ HÀNG" : "HẾT HÀNG"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder(ColorScheme colorScheme) => Container(
    color: colorScheme.surfaceVariant,
    alignment: Alignment.center,
    child: Icon(Icons.image, size: 40, color: colorScheme.outline),
  );

  Widget _imageLoading(ColorScheme colorScheme) => Container(
    color: colorScheme.surfaceVariant,
    alignment: Alignment.center,
    child: const CircularProgressIndicator(strokeWidth: 2),
  );
}

class _ColorThumb {
  final int colorId;
  final String label;
  final String url;
  _ColorThumb({required this.colorId, required this.label, required this.url});
}
