import 'dart:math';
import 'package:b2205946_duonghuuluan_luanvan/app/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:b2205946_duonghuuluan_luanvan/app/utils/currency_ext.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/cart/presentation/viewmodel/cart_viewmodel.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/cart/presentation/view/widget/cart_drawer.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/product/domain/product.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/product/domain/product_detail.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/product/presentation/viewmodel/product_viewmodel.dart';

class ProductDetailPage extends StatefulWidget {
  final int productId;
  final void Function(Product product, ProductDetail productDetail, int qty)?
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Trạng thái Loading
    if (vm.isLoading && vm.product == null) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: Center(
          child: CircularProgressIndicator(color: colorScheme.primary),
        ),
      );
    }

    // Trạng thái Lỗi
    if (vm.errorMessage != null && vm.product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Chi tiết sản phẩm")),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                const SizedBox(height: 16),
                Text(vm.errorMessage!, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => context
                      .read<ProductViewmodel>()
                      .productDetail(widget.productId),
                  icon: const Icon(Icons.refresh),
                  label: const Text("Thử lại"),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final Product p = vm.product!;
    final productDetail = vm.selectedProductDetail;
    final productImages = vm.displayProductImages;
    final availableQuantity = vm.availableQuantity;

    final mainUrl = productImages.isNotEmpty
        ? productImages[vm.imgIndex.clamp(0, max(0, productImages.length - 1))]
              .url
        : null;

    final priceText = (productDetail?.price ?? 0).toVnd();
    final inStock = availableQuantity != null && availableQuantity > 0;

    return Scaffold(
      backgroundColor: colorScheme.onPrimary,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              elevation: 0,
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              title: Text(
                p.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () =>
                    context.canPop() ? context.pop() : context.go('/'),
              ),
            ),

            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    color: Colors.white,
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: mainUrl != null
                          ? Image.network(
                              mainUrl,
                              fit: BoxFit
                                  .contain, // Contain giúp thấy toàn bộ mũ
                              errorBuilder: (_, __, ___) =>
                                  _imagePlaceholder(colorScheme),
                            )
                          : _imagePlaceholder(colorScheme),
                    ),
                  ),

                  // Danh sách màu sắc (Thumbnails)
                  if (vm.colors.length > 1)
                    _buildSectionTitle("Chọn màu sắc", textTheme, colorScheme),

                  if (vm.colors.length > 1)
                    Container(
                      height: 70,
                      margin: const EdgeInsets.only(top: 8),
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        scrollDirection: Axis.horizontal,
                        itemCount: vm.colors.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, i) {
                          final c = vm.colors[i];
                          final active = c.colorId == vm.selectedColorId;
                          final thumbUrl = _thumbForColor(
                            product: p,
                            colorId: c.colorId,
                          );

                          return InkWell(
                            onTap: () => vm.selectColor(c.colorId),
                            borderRadius: BorderRadius.circular(12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: active
                                      ? colorScheme.secondary
                                      : colorScheme.outlineVariant,
                                  width: active ? 2.5 : 1,
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: thumbUrl == null
                                  ? Icon(
                                      Icons.image,
                                      color: colorScheme.outline,
                                    )
                                  : Image.network(thumbUrl, fit: BoxFit.cover),
                            ),
                          );
                        },
                      ),
                    ),

                  // Tên và Giá
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          priceText,
                          style: textTheme.headlineSmall?.copyWith(
                            color: colorScheme.error,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Chọn Size
                  if (vm.sizes.isNotEmpty)
                    _buildSectionTitle("Kích thước", textTheme, colorScheme),

                  if (vm.sizes.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: vm.sizes.map((s) {
                          final selected = s.sizeId == vm.selectedSizeId;
                          return ChoiceChip(
                            label: Text(s.size),
                            selected: selected,
                            onSelected: (_) => vm.selectSize(s.sizeId),
                            selectedColor: colorScheme.primaryContainer,
                            labelStyle: TextStyle(
                              color: selected
                                  ? colorScheme.secondary
                                  : colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                  // // Số lượng
                  // _buildSectionTitle("Số lượng", textTheme, colorScheme),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                    ), // Lề trái phải để không sát mép màn hình
                    child: Row(
                      children: [
                        Container(
                          height:
                              45, // Giảm chiều cao xuống (trước đó mặc định khá lớn)
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Nút Giảm
                              SizedBox(
                                width: 36,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => vm.updateQuantity(-1),
                                  icon: const Icon(Icons.remove, size: 16),
                                  color: Colors.black54,
                                ),
                              ),

                              VerticalDivider(
                                width: 1,
                                color: Colors.grey.shade300,
                                indent: 8,
                                endIndent: 8,
                              ),

                              // Số lượng
                              Container(
                                alignment: Alignment.center,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Text(
                                  vm.quantity.toString(),
                                  style: textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),

                              VerticalDivider(
                                width: 1,
                                color: Colors.grey.shade300,
                                indent: 8,
                                endIndent: 8,
                              ),

                              // Nút Tăng
                              SizedBox(
                                width: 36,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => vm.updateQuantity(1),
                                  icon: const Icon(Icons.add, size: 16),
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
      // Bottom Action Bar - Nút mua hàng cố định phía dưới
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.onPrimary,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
          ],
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.secondary,
            foregroundColor: colorScheme.onPrimary,
            minimumSize: const Size(double.infinity, 54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: (!inStock || productDetail == null)
              ? null
              : () async {
                  if (widget.onAddToCart != null) {
                    widget.onAddToCart!(p, productDetail, vm.quantity);
                  } else {
                    await context.read<CartViewmodel>().addToCart(
                      productDetailId: productDetail.id,
                      quantity: vm.quantity,
                    );
                    await CartDrawer.show(
                      context,
                      productDetailId: productDetail.id,
                    );
                  }
                },
          child: Text(
            inStock ? "THÊM VÀO GIỎ HÀNG" : "TẠM HẾT HÀNG",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(
    String title,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: textTheme.titleSmall?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _imagePlaceholder(ColorScheme colorScheme) => Container(
    color: colorScheme.surfaceVariant,
    alignment: Alignment.center,
    child: Icon(
      Icons.image_not_supported_outlined,
      size: 48,
      color: colorScheme.outline,
    ),
  );

  static String? _thumbForColor({
    required Product product,
    required int colorId,
  }) {
    final byColor = product.images.where((e) => e.colorId == colorId).toList();
    if (byColor.isNotEmpty) return byColor.first.url;
    if (product.images.isNotEmpty) return product.images.first.url;
    return null;
  }
}
