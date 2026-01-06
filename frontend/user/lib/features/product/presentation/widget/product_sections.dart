import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:b2205946_duonghuuluan_luanvan/features/category/domain/category.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/product/domain/product.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/product/domain/product_variant.dart';

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
    // Gom product theo categoryId
    final Map<String, List<Product>> byCategory = HashMap();
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
          onSeeMore: () {
            // nếu muốn đi trang /products lọc theo category
            // context.go('/products?categoryId=${c.id}');
          },
          onProductTap: (p) => context.go('/products/${p.id}'),
          onAddToCart: (Product p, ProductVariant v) {
            // TODO: cart
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Đã chọn: ${p.name} - size ${v.size}')),
            );
          },
        );
      }).toList(),
    );
  }
}
