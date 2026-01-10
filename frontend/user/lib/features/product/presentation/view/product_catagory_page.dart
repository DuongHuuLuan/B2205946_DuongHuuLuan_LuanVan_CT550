import 'package:b2205946_duonghuuluan_luanvan/app/theme/colors.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/cart/presentation/viewmodel/cart_viewmodel.dart';
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onSecondary,
        title: Text(
          "Danh Mục Sản Phẩm",
          style: TextStyle(color: AppColors.onPrimary),
        ),
        leading: IconButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go("/");
            }
          },
          icon: Icon(Icons.arrow_back, color: AppColors.onPrimary),
        ),
      ),
      body: RefreshIndicator(
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
            const SizedBox(height: 16),
            // TITLE PRODUCTS
            Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedCategoryId == null
                        ? "Tất cả sản phẩm"
                        : "Sản phẩm theo danh mục",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (productVm.isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Product Grid
            if (productVm.errorMessage != null && productVm.products.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(productVm.errorMessage ?? "Lỗi không xác định"),
                ),
              )
            else if (!productVm.isLoading && productVm.products.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: Text("Không có sản phẩm")),
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
                  // childAspectRatio: 0.62,
                  mainAxisExtent: 450,
                ),
                itemBuilder: (context, index) {
                  final product = productVm.products[index];
                  return ProductCard(
                    product: product,
                    onTap: () {
                      context.go("/products/${product.id}");
                    },
                    onAddToCart: (product, productDetail, quantity) {
                      context.read<CartViewmodel>().addToCart(
                        productDetailId: productDetail.id,
                        quantity: quantity,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Da them "${product.name}" vao gio hang',
                          ),
                        ),
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
}
