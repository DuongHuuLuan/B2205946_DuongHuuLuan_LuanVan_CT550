import 'package:b2205946_duonghuuluan_luanvan/features/product/domain/product_image.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/product/domain/product_detail.dart';

class Product {
  final int id;
  final String name;
  final String description;
  final String unit;
  final int categoryId;
  final List<ProductImage> images;
  final List<ProductDetail> productDetails;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.unit,
    required this.categoryId,
    required this.images,
    required this.productDetails,
    this.createdAt,
    this.updatedAt,
  });
}
