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
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      // Load categories + products (náº¿u Ä‘Ã£ load á»Ÿ Home thÃ¬ váº«n OK)
      await context.read<CategoryViewModel>().load();
      await context.read<ProductViewmodel>().getAllProduct();
    });
  }

  @override
  Widget build(BuildContext context) {
    final categoryVm = context.watch<CategoryViewModel>();
    final productVm = context.watch<ProductViewmodel>();

    final List<Category> categories = categoryVm.categories;
    final List<Product> products = productVm.products;

    // Loading/Error tá»‘i thiá»ƒu (khÃ´ng Ä‘á»¥ng fields categoryVm.isLoading/errorMessage Ä‘á»ƒ trÃ¡nh sai compile)
    if (productVm.isLoading && products.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (productVm.errorMessage != null && products.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Sáº£n pháº©m")),
        body: Center(child: Text(productVm.errorMessage!)),
      );
    }

    // Gom product theo categoryId
    final Map<int, List<Product>> byCategory = HashMap();
    for (final p in products) {
      byCategory.putIfAbsent(p.categoryId, () => []).add(p);
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Sáº£n pháº©m theo loáº¡i")),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [ProductSections(categories: categories, products: products)],
      ),
    );
  }
}

