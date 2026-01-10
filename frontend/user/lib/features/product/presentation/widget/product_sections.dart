import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:b2205946_duonghuuluan_luanvan/features/cart/presentation/viewmodel/cart_viewmodel.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/category/domain/category.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/product/domain/product.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/product/domain/product_detail.dart';

import 'category_product_section.dart';

class ProductSections extends StatelessWidget {
  final List<Category> categories;
  final List<Product> products;

  const ProductSections({
    super.key,
    required this.categories,
    required this.products,
  });

  @override
  Widget build(BuildContext context) {
    final Map<int, List<Product>> byCategory = HashMap();
    for (final p in products) {
      byCategory.putIfAbsent(p.categoryId, () => []).add(p);
    }

    return Column(
      children: categories.map((c) {
        final items = byCategory[c.id] ?? const <Product>[];
        if (items.isEmpty) return const SizedBox.shrink();

        return CategoryProductSection(
          title: c.name.toUpperCase(),
          products: items,
          onSeeMore: () => context.go('/products/categories/${c.id}'),
          onProductTap: (p) => context.go('/products/${p.id}'),
          onAddToCart: (Product p, ProductDetail v, int quantity) {
            context.read<CartViewmodel>().addToCart(
              productDetailId: v.id,
              quantity: quantity,
            );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Da them "${p.name}" vao gio hang')),
            );
          },
        );
      }).toList(),
    );
  }
}
