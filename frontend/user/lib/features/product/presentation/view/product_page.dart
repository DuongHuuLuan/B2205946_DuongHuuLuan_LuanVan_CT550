import 'dart:collection';

import 'package:b2205946_duonghuuluan_luanvan/features/product/presentation/widget/product_sections.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/category/domain/category.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/category/presentation/viewmodel/category_viewmodel.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/product/domain/product.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/product/presentation/viewmodel/product_viewmodel.dart';

class ProductPage extends StatefulWidget {
  const ProductPage({super.key});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  final ScrollController _scrollController = ScrollController();
  static const double _loadMoreThreshold = 300;
  static const int _perPage = 8;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    Future.microtask(() async {
      await context.read<CategoryViewModel>().load();
      await context.read<ProductViewmodel>().loadInitialPaged(
        perPage: _perPage,
      );
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    // kiểm tra vị trí hiện tại  đã vượt quá ngưỡng chưa(tổng độ dài - ngưỡng 300px)
    if (position.pixels >= position.maxScrollExtent - _loadMoreThreshold) {
      context.read<ProductViewmodel>().loadMoreProducts();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoryVm = context.watch<CategoryViewModel>();
    final productVm = context.watch<ProductViewmodel>();

    final List<Category> categories = categoryVm.categories;
    final List<Product> products = productVm.products;

    if (productVm.isLoading && products.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (productVm.errorMessage != null && products.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Sản phẩm")),
        body: Center(child: Text(productVm.errorMessage!)),
      );
    }

    // Gom product theo categoryId
    final Map<int, List<Product>> byCategory = HashMap();
    for (final p in products) {
      byCategory.putIfAbsent(p.categoryId, () => []).add(p);
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Sản phẩm theo loại")),
      body: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          ProductSections(categories: categories, products: products),
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
          else if (!productVm.hasMore && products.isNotEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: Text("Đã tải hết sản phẩm")),
            ),
        ],
      ),
    );
  }
}
