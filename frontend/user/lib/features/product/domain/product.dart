import 'package:b2205946_duonghuuluan_luanvan/features/product/domain/product_image.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/product/domain/product_variant.dart';

class Product {
  final int id;
  final String name;
  final String description;
  final String unit;
  final int categoryId;
  final List<ProductImage> images;
  final List<ProductVariant> variants;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.unit,
    required this.categoryId,
    required this.images,
    required this.variants,
    this.createdAt,
    this.updatedAt,
  });
}
