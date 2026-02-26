import 'dart:math';
import 'package:b2205946_duonghuuluan_luanvan/app/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:b2205946_duonghuuluan_luanvan/app/utils/currency_ext.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/cart/presentation/viewmodel/cart_viewmodel.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/cart/presentation/view/widget/cart_drawer.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/evaluate/domain/evaluate.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/evaluate/domain/evaluate_reponsitory.dart';
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
  ProductEvaluatePage? _reviewPreview;
  bool _isReviewLoading = false;
  String? _reviewError;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<ProductViewmodel>().productDetail(widget.productId);
      _loadReviewPreview();
    });
  }

  Future<ProductEvaluatePage> _fetchProductReviews({
    int page = 1,
    int perPage = 3,
  }) {
    final repo = context.read<EvaluateRepository>();
    return repo.getProductEvaluates(
      productId: widget.productId,
      page: page,
      perPage: perPage,
    );
  }

  Future<void> _loadReviewPreview() async {
    if (!mounted) return;
    final repo = context.read<EvaluateRepository>();
    setState(() {
      _isReviewLoading = true;
      _reviewError = null;
    });

    try {
      final result = await repo.getProductEvaluates(
        productId: widget.productId,
        perPage: 3,
      );
      if (!mounted) return;
      setState(() {
        _reviewPreview = result;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _reviewError = e.toString();
      });
    }
    if (!mounted) return;
    setState(() {
      _isReviewLoading = false;
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
                          ? CachedNetworkImage(
                              imageUrl: mainUrl,
                              fit: BoxFit
                                  .contain, // Contain giúp thấy toàn bộ mũ
                              placeholder: (context, url) =>
                                  _imagePlaceholder(colorScheme),
                              errorWidget: (context, url, error) =>
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
                                  : CachedNetworkImage(
                                      imageUrl: thumbUrl,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Icon(
                                        Icons.image,
                                        color: colorScheme.outline,
                                      ),
                                      errorWidget: (context, url, error) =>
                                          Icon(
                                            Icons.image,
                                            color: colorScheme.outline,
                                          ),
                                    ),
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

                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                    ), // Lề trái phải để không sát mép màn hình
                    child: Row(
                      children: [
                        Container(
                          height: 45,
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

                  _buildReviewSection(
                    context: context,
                    product: p,
                    textTheme: textTheme,
                    colorScheme: colorScheme,
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

  Widget _buildReviewSection({
    required BuildContext context,
    required Product product,
    required TextTheme textTheme,
    required ColorScheme colorScheme,
  }) {
    final data = _reviewPreview;

    if (_isReviewLoading && data == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(10, 20, 10, 0),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: const Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Expanded(child: Text("Đang tải đánh giá sản phẩm...")),
            ],
          ),
        ),
      );
    }

    if (_reviewError != null && data == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(10, 20, 10, 0),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.error.withOpacity(0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Không tải được đánh giá",
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.error,
                ),
              ),
              const SizedBox(height: 8),
              Text(_reviewError!, maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _loadReviewPreview,
                icon: const Icon(Icons.refresh),
                label: const Text("Thử lại"),
              ),
            ],
          ),
        ),
      );
    }

    final totalReviews = data?.summary.totalReviews ?? 0;
    if (data == null || totalReviews == 0) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(10, 20, 10, 0),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              Icon(Icons.reviews_outlined, color: colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Chưa có đánh giá cho sản phẩm này",
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final previewItems = data.items.take(2).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 20, 10, 0),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => _showAllReviewsSheet(product),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text(
                      data.summary.averageRate.toStringAsFixed(1),
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.star_rounded,
                      color: Colors.amber,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Đánh giá sản phẩm (${data.summary.totalReviews})",
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right, color: colorScheme.outline),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildReviewSummaryCard(
              data: data,
              textTheme: textTheme,
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 14),
            ...List.generate(previewItems.length, (index) {
              final item = previewItems[index];
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == previewItems.length - 1 ? 0 : 12,
                ),
                child: _buildReviewCard(
                  item: item,
                  textTheme: textTheme,
                  colorScheme: colorScheme,
                ),
              );
            }),
            const SizedBox(height: 10),
            InkWell(
              onTap: () => _showAllReviewsSheet(product),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Xem tất cả đánh giá",
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right, color: colorScheme.primary),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewSummaryCard({
    required ProductEvaluatePage data,
    required TextTheme textTheme,
    required ColorScheme colorScheme,
  }) {
    final rateMap = {
      for (final rate in data.summary.rateCounts) rate.star: rate.count,
    };
    // final galleryImages = data.items
    //     .expand((e) => e.images)
    //     .map((e) => e.imageUrl)
    //     .where((url) => url.isNotEmpty)
    //     .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.55),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Tóm tắt đánh giá sản phẩm",
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          if ((data.summary.summaryText ?? "").trim().isNotEmpty)
            Text(
              data.summary.summaryText!,
              style: textTheme.bodyMedium?.copyWith(height: 1.35),
            ),
          if ((data.summary.summaryText ?? "").trim().isEmpty)
            Text(
              "Sản phẩm có ${data.summary.totalReviews} đánh giá, ${data.summary.totalWithImages} đánh giá có hình ảnh.",
              style: textTheme.bodyMedium?.copyWith(height: 1.35),
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(5, (i) {
              final star = 5 - i;
              final count = rateMap[star] ?? 0;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Text(
                  "$star★ ($count)",
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            }),
          ),
          // if (galleryImages.isNotEmpty) ...[
          //   const SizedBox(height: 12),
          //   _buildReviewGallery(galleryImages, colorScheme),
          // ],
        ],
      ),
    );
  }

  // Widget _buildReviewGallery(List<String> urls, ColorScheme colorScheme) {
  //   final display = urls.take(3).toList();
  //   final remain = urls.length - display.length;

  //   return Row(
  //     children: List.generate(display.length, (index) {
  //       final isLast = index == display.length - 1;
  //       final showOverlay = remain > 0 && isLast;
  //       return Expanded(
  //         child: Padding(
  //           padding: EdgeInsets.only(right: isLast ? 0 : 8),
  //           child: AspectRatio(
  //             aspectRatio: 1.1,
  //             child: ClipRRect(
  //               borderRadius: BorderRadius.circular(12),
  //               child: Stack(
  //                 fit: StackFit.expand,
  //                 children: [
  //                   CachedNetworkImage(
  //                     imageUrl: display[index],
  //                     fit: BoxFit.cover,
  //                     placeholder: (context, url) =>
  //                         _imagePlaceholder(colorScheme),
  //                     errorWidget: (context, url, error) =>
  //                         _imagePlaceholder(colorScheme),
  //                   ),
  //                   if (showOverlay)
  //                     Container(
  //                       color: Colors.black.withOpacity(0.35),
  //                       alignment: Alignment.center,
  //                       child: Text(
  //                         "+$remain",
  //                         style: const TextStyle(
  //                           color: Colors.white,
  //                           fontSize: 20,
  //                           fontWeight: FontWeight.bold,
  //                         ),
  //                       ),
  //                     ),
  //                 ],
  //               ),
  //             ),
  //           ),
  //         ),
  //       );
  //     }),
  //   );
  // }

  Widget _buildReviewCard({
    required EvaluateItem item,
    required TextTheme textTheme,
    required ColorScheme colorScheme,
    bool compact = true,
  }) {
    final reviewerName =
        item.reviewerNameMasked ?? item.reviewerName ?? "Khách hàng";
    final variantText = item.matchedVariants.isNotEmpty
        ? item.matchedVariants.join(" | ")
        : null;
    final content = (item.content ?? "").trim();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.onSurfaceVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: colorScheme.surfaceVariant,
                child: Icon(
                  Icons.person_outline,
                  size: 18,
                  color: colorScheme.outline,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  reviewerName,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Text(
                _formatReviewDate(item.createdAt),
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildStarRow(item.rate),
          if (variantText != null) ...[
            const SizedBox(height: 6),
            Text(
              "Phân loại: $variantText",
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.outline,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (content.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              content,
              maxLines: compact ? 3 : null,
              overflow: compact ? TextOverflow.ellipsis : null,
              style: textTheme.bodyMedium?.copyWith(
                height: 1.3,
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (item.images.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: compact ? 86 : 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: item.images.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final img = item.images[index];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: CachedNetworkImage(
                        imageUrl: img.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            _imagePlaceholder(colorScheme),
                        errorWidget: (context, url, error) =>
                            _imagePlaceholder(colorScheme),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStarRow(int rate) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < rate ? Icons.star_rounded : Icons.star_border_rounded,
          size: 18,
          color: index < rate ? Colors.amber : Colors.grey.shade400,
        );
      }),
    );
  }

  Future<void> _showAllReviewsSheet(Product product) async {
    final future = _fetchProductReviews(perPage: 50);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final colorScheme = Theme.of(sheetContext).colorScheme;
        final textTheme = Theme.of(sheetContext).textTheme;
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(sheetContext).size.height * 0.86,
            child: FutureBuilder<ProductEvaluatePage>(
              future: future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: colorScheme.secondary,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 40),
                        const SizedBox(height: 12),
                        Text(
                          "Không tải được danh sách đánh giá",
                          style: textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "${snapshot.error}",
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                }

                final data = snapshot.data;
                if (data == null) {
                  return const SizedBox.shrink();
                }

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 8, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              "Đánh giá ${product.name}",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.onSecondary,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: _buildReviewSummaryCard(
                        data: data,
                        textTheme: textTheme,
                        colorScheme: colorScheme,
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        itemCount: data.items.length + 1,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          if (index == data.items.length) {
                            final remain = data.total - data.items.length;
                            if (remain <= 0) return const SizedBox.shrink();
                            return Container(
                              padding: const EdgeInsets.all(12),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceVariant.withOpacity(
                                  0.5,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                "Đang hiển thị ${data.items.length}/${data.total} đánh giá. Có thể bổ sung phân trang sau.",
                                textAlign: TextAlign.center,
                                style: textTheme.bodySmall,
                              ),
                            );
                          }
                          return _buildReviewCard(
                            item: data.items[index],
                            textTheme: textTheme,
                            colorScheme: colorScheme,
                            compact: false,
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  String _formatReviewDate(DateTime? date) {
    if (date == null) return "";
    final d = date.toLocal();
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return "$dd/$mm/${d.year}";
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
