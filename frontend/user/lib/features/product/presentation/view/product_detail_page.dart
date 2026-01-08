import 'dart:math';

import 'package:b2205946_duonghuuluan_luanvan/app/utils/currency_ext.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:b2205946_duonghuuluan_luanvan/app/theme/colors.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/product/domain/product.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/product/domain/product_variant.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/product/presentation/viewmodel/product_viewmodel.dart';

class ProductDetailPage extends StatefulWidget {
  final String productId;

  final void Function(Product product, ProductVariant variant, int qty)?
  onAddToCart;

  const ProductDetailPage({
    super.key,
    required this.productId,
    this.onAddToCart,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<ProductViewmodel>().productDetail(widget.productId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProductViewmodel>();

    // Loading lần đầu
    if (vm.isLoading && vm.product == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    // Error
    if (vm.errorMessage != null && vm.product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Chi tiết sản phẩm")),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(vm.errorMessage!),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => context
                      .read<ProductViewmodel>()
                      .productDetail(widget.productId),
                  child: const Text("Thử lại"),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final Product p = vm.product!;
    final variant = vm.selectedVariant;
    final images = vm.displayImages;

    final mainUrl = images.isNotEmpty
        ? images[vm.imgIndex.clamp(0, max(0, images.length - 1))].url
        : null;

    final priceText = (variant?.price ?? 0).toVnd();
    final inStock = (variant?.stockQuantity ?? 0) > 0;

    return Scaffold(
      // backgroundColor: const Color(0xFF070C14),
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              elevation: 0,
              backgroundColor: AppColors.primary,
              title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (context.canPop()) {
                    return Navigator.pop(context);
                  } else {
                    context.go('/');
                  }
                },
              ),
            ),

            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ===== Ảnh lớn =====
                    AspectRatio(
                      aspectRatio: 1,
                      child: mainUrl != null
                          ? Image.network(
                              mainUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _imagePlaceholder(),
                            )
                          : _imagePlaceholder(),
                    ),

                    // ===== Thumbnails chọn MÀU (dựa theo ảnh theo color_id) =====
                    if (vm.colors.length > 1)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: SizedBox(
                          height: 52,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: vm.colors.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 10),
                            itemBuilder: (context, i) {
                              final c = vm.colors[i];
                              final active = c.colorId == vm.selectedColorId;

                              final thumbUrl = _thumbForColor(
                                product: p,
                                colorId: c.colorId,
                              );

                              return InkWell(
                                onTap: () => vm.selectColor(c.colorId),
                                child: Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: active
                                          ? AppColors.secondary
                                          : Colors.black12,
                                      width: active ? 2 : 1,
                                    ),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: thumbUrl == null
                                      ? Container(
                                          color: Colors.grey.shade200,
                                          child: const Icon(
                                            Icons.image,
                                            color: Colors.black38,
                                          ),
                                        )
                                      : Image.network(
                                          thumbUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              Container(
                                                color: Colors.grey.shade200,
                                              ),
                                        ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                    // ===== Thumbnails ảnh (theo màu đang chọn + fallback ảnh chung) =====
                    if (images.length > 1)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: SizedBox(
                          height: 46,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: min(images.length, 6),
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, i) {
                              final url = images[i].url;
                              final active = i == vm.imgIndex;

                              return InkWell(
                                onTap: () => vm.setImgIndex(i),
                                child: Container(
                                  width: 46,
                                  height: 46,
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

                    // ===== Tên + Giá =====
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Text(
                        p.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSecondary,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Text(
                        priceText,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.error,
                        ),
                      ),
                    ),

                    // ===== Size =====
                    if (vm.sizes.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: vm.sizes.map((s) {
                            final selected = s.sizeId == vm.selectedSizeId;
                            return InkWell(
                              onTap: () => vm.selectSize(s.sizeId),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: selected
                                        ? AppColors.secondary
                                        : Colors.black26,
                                    width: selected ? 2 : 1,
                                  ),
                                ),
                                child: Text(
                                  s.size,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.onSecondary,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                    // ===== Quantity =====
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Row(
                        children: [
                          const Text(
                            "Số lượng:",
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSecondary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            onPressed: () => vm.updateQuantity(-1),
                            icon: const Icon(
                              Icons.remove_circle_outline,
                              color: AppColors.onSecondary,
                            ),
                          ),
                          Text(
                            vm.quantity.toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: AppColors.onSecondary,
                            ),
                          ),
                          IconButton(
                            onPressed: () => vm.updateQuantity(1),
                            icon: const Icon(
                              Icons.add_circle_outline,
                              color: AppColors.onSecondary,
                            ),
                          ),
                          const Spacer(),
                          // if (variant != null)
                          //   Text(
                          //     "Kho: ${variant.stockQuantity}",
                          //     style: const TextStyle(color: Colors.black54),
                          //   ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ===== Add to cart =====
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: (!inStock || variant == null)
                              ? null
                              : () {
                                  widget.onAddToCart?.call(
                                    p,
                                    variant,
                                    vm.quantity,
                                  );
                                },
                          child: Text(
                            inStock ? "THÊM VÀO GIỎ HÀNG" : "HẾT HÀNG",
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _imagePlaceholder() => Container(
    color: Colors.grey.shade200,
    alignment: Alignment.center,
    child: const Icon(Icons.image, size: 42, color: Colors.black38),
  );

  /// lấy ảnh đại diện cho màu:
  /// - ưu tiên ảnh có color_id = màu đó
  /// - fallback ảnh chung (color_id null)
  /// - fallback ảnh đầu tiên
  static String? _thumbForColor({
    required Product product,
    required String colorId,
  }) {
    final byColor = product.images.where((e) => e.colorId == colorId).toList();
    if (byColor.isNotEmpty) return byColor.first.url;

    final commons = product.images.where((e) => e.colorId == null).toList();
    if (commons.isNotEmpty) return commons.first.url;

    if (product.images.isNotEmpty) return product.images.first.url;
    return null;
  }
}
