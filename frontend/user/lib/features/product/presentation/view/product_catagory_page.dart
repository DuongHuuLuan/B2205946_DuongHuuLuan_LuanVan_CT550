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
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.categoryId;

    Future.microtask(() async {
      await context.read<CategoryViewModel>().load();
      await context.read<ProductViewmodel>().getAllProduct(
        categoryId: _selectedCategoryId,
      );
    });
  }

  Future<void> _selectCategory(int? categoryId) async {
    setState(() {
      _selectedCategoryId = categoryId;
    });
    await context.read<ProductViewmodel>().getAllProduct(
      categoryId: categoryId,
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
      backgroundColor: colorScheme.surface, // Dùng màu nền hệ thống
      appBar: AppBar(
        backgroundColor: colorScheme.primary, // Màu chính cho AppBar
        elevation: 0,
        title: Text(
          "Danh Mục Sản Phẩm",
          style: textTheme.titleLarge?.copyWith(
            color: colorScheme.onPrimary, // Chữ trên nền màu chính
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
          await productVm.getAllProduct(categoryId: _selectedCategoryId);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
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
                      color: colorScheme
                          .onSurface, // Chữ màu tối trên nền sáng (và ngược lại)
                    ),
                  ),
                ),
                if (productVm.isLoading)
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color:
                          colorScheme.primary, // Loading xoay theo màu chủ đạo
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
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: productVm.products.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  mainAxisExtent: 450,
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
