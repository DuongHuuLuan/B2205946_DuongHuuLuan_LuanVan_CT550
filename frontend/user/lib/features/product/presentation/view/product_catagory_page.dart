import 'package:b2205946_duonghuuluan_luanvan/features/cart/presentation/viewmodel/cart_viewmodel.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/cart/presentation/view/widget/cart_drawer.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/category/presentation/viewmodel/category_viewmodel.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/category/presentation/widget/category_grid.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/product/presentation/viewmodel/product_viewmodel.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/product/presentation/widget/product_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ProductCatagoryPage extends StatefulWidget {
  final int? categoryId;
  const ProductCatagoryPage({super.key, this.categoryId});

  @override
  State<ProductCatagoryPage> createState() => _ProductCatagoryPageState();
}

class _ProductCatagoryPageState extends State<ProductCatagoryPage> {
  final ScrollController _scrollController = ScrollController();
  static const double _loadMoreThreshold = 300;
  static const int _perPage = 8;

  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.categoryId;
    _scrollController.addListener(_onScroll);

    Future.microtask(() async {
      await context.read<CategoryViewModel>().load();
      await context.read<ProductViewmodel>().loadInitialPaged(
        categoryId: _selectedCategoryId,
        perPage: _perPage,
      );
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - _loadMoreThreshold) {
      context.read<ProductViewmodel>().loadMoreProducts();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _selectCategory(int? categoryId) async {
    setState(() {
      _selectedCategoryId = categoryId;
    });
    await context.read<ProductViewmodel>().loadInitialPaged(
      categoryId: categoryId,
      perPage: _perPage,
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoryVm = context.watch<CategoryViewModel>();
    final productVm = context.watch<ProductViewmodel>();

    // 1. Lấy thông tin Theme
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        elevation: 0,
        title: Text(
          "Danh Mục Sản Phẩm",
          style: textTheme.titleLarge?.copyWith(
            color: colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go("/");
            }
          },
          icon: Icon(Icons.arrow_back, color: colorScheme.onPrimary),
        ),
      ),
      body: RefreshIndicator(
        color: colorScheme.primary,
        onRefresh: () async {
          await productVm.loadInitialPaged(
            categoryId: _selectedCategoryId,
            perPage: _perPage,
          );
        },
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(8, 16, 8, 24),
          children: [
            CategoryGrid(
              categories: categoryVm.categories,
              selectedCategoryId: _selectedCategoryId,
              onSelectAll: () => _selectCategory(null),
              onSelectCategory: (c) => _selectCategory(c.id),
            ),
            const SizedBox(height: 20),

            // TITLE PRODUCTS SECTION
            Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedCategoryId == null
                        ? "Tất cả sản phẩm"
                        : "Sản phẩm theo danh mục",
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                if (productVm.isLoading)
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.secondary,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Product Grid Area
            if (productVm.errorMessage != null && productVm.products.isEmpty)
              _buildEmptyState(
                message: productVm.errorMessage!,
                color: colorScheme.error,
              )
            else if (!productVm.isLoading && productVm.products.isEmpty)
              _buildEmptyState(
                message: "Không có sản phẩm nào trong danh mục này",
                color: colorScheme.onSurfaceVariant,
              )
            else
              // card sản phẩm
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: productVm.products.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 14,
                  mainAxisExtent: 500,
                ),
                itemBuilder: (context, index) {
                  final product = productVm.products[index];
                  return ProductCard(
                    product: product,
                    onTap: () => context.go("/products/${product.id}"),
                    onAddToCart: (product, productDetail, quantity) async {
                      await context.read<CartViewmodel>().addToCart(
                        productDetailId: productDetail.id,
                        quantity: quantity,
                      );
                      await CartDrawer.show(
                        context,
                        productDetailId: productDetail.id,
                      );
                    },
                  );
                },
              ),
            if (productVm.isLoadingMore)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 8),
                      Text("Đang tải"),
                    ],
                  ),
                ),
              )
            else if (!productVm.hasMore && productVm.products.isNotEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: Text("Đã tải hết sản phẩm")),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({required String message, required Color color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: color),
        ),
      ),
    );
  }
}
