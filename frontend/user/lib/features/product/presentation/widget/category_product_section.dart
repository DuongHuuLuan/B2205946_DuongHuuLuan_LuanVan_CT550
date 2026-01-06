import 'package:b2205946_duonghuuluan_luanvan/app/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/product/domain/product.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/product/domain/product_variant.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/product/presentation/widget/arrow_button.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/product/presentation/widget/product_card.dart';

class CategoryProductSection extends StatefulWidget {
  final String title;
  final List<Product> products;

  final VoidCallback onSeeMore;
  final void Function(Product product) onProductTap;
  final void Function(Product product, ProductVariant variant) onAddToCart;

  const CategoryProductSection({
    super.key,
    required this.title,
    required this.products,
    required this.onAddToCart,
    required this.onProductTap,
    required this.onSeeMore,
  });

  @override
  State<CategoryProductSection> createState() => _CategoryProductSectionState();
}

class _CategoryProductSectionState extends State<CategoryProductSection> {
  final ScrollController _controller = ScrollController();

  bool _showLeft = false;
  bool _showRight = false;

  void _updateArrows() {
    if (!_controller.hasClients) return;

    final max = _controller.position.maxScrollExtent;
    final offset = _controller.offset;

    final canScroll = max > 0;
    final showLeftNow = canScroll && offset > 2;
    final showRightNow = canScroll && offset < max - 2;

    if (showLeftNow != _showLeft || showRightNow != _showRight) {
      setState(() {
        _showLeft = showLeftNow;
        _showRight = showRightNow;
      });
    }
  }

  void _scrollBy(double dx) {
    if (!_controller.hasClients) return;

    final minE = _controller.position.minScrollExtent;
    final maxE = _controller.position.maxScrollExtent;

    final target = (_controller.offset + dx).clamp(minE, maxE);
    _controller.animateTo(
      target,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(_updateArrows);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateArrows());
  }

  @override
  void didUpdateWidget(covariant CategoryProductSection oldWidget) {
    super.didUpdateWidget(oldWidget);

    // products load xong sẽ đổi -> update lại arrows
    if (oldWidget.products.length != widget.products.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _updateArrows());
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_updateArrows);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      margin: const EdgeInsets.only(bottom: 15),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.onPrimary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSecondary,
                      fontSize: 18,
                    ),
                  ),
                ),
                // TextButton(
                //   onPressed: widget.onSeeMore,
                //   child: const Text("Xem thêm"),
                // ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            height: 490,
            child: Stack(
              children: [
                ListView.separated(
                  controller: _controller,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: widget.products.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (context, index) {
                    final product = widget.products[index];
                    return SizedBox(
                      width: 220,
                      child: ProductCard(
                        product: product,
                        onTap: () => widget.onProductTap(product),
                        onAddToCart: (p, v) => widget.onAddToCart(p, v),
                      ),
                    );
                  },
                ),

                // Left arrow (fade)
                Positioned(
                  left: 6,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: IgnorePointer(
                      ignoring: !_showLeft,
                      child: AnimatedOpacity(
                        opacity: _showLeft ? 1 : 0,
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOut,
                        child: ArrowButton(
                          icon: Icons.chevron_left,
                          onTap: () => _scrollBy(-260),
                        ),
                      ),
                    ),
                  ),
                ),

                // Right arrow (fade)
                Positioned(
                  right: 6,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: IgnorePointer(
                      ignoring: !_showRight,
                      child: AnimatedOpacity(
                        opacity: _showRight ? 1 : 0,
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOut,
                        child: ArrowButton(
                          icon: Icons.chevron_right,
                          onTap: () => _scrollBy(260),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  onPressed: widget.onSeeMore,
                  child: Text(
                    "Xem thêm",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w300),
                  ),
                ),
                const SizedBox(width: 5),
                IconButton(
                  onPressed: widget.onSeeMore,
                  style: IconButton.styleFrom(
                    padding: EdgeInsets.zero,
                    backgroundColor: AppColors.secondary,
                  ),
                  icon: Icon(Icons.chevron_right, color: AppColors.onPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
