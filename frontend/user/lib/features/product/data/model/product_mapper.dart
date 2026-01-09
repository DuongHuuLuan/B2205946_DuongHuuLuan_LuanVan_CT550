import 'package:b2205946_duonghuuluan_luanvan/features/product/data/model/product_image_mapper.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/product/data/model/product_detail_mapper.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/product/domain/product.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/product/domain/product_image.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/product/domain/product_detail.dart';

class ProductMapper extends Product {
  ProductMapper({
    required super.id,
    required super.name,
    required super.description,
    required super.unit,
    required super.categoryId,
    required super.images,
    required super.productDetails,
    super.createdAt,
    super.updatedAt,
  });

  factory ProductMapper.fromJson(Map<String, dynamic> json) {
    final productDetailJson = (json["product_details"] as List? ?? [])
        .cast<Map<String, dynamic>>();
    final imagesJson = (json["product_images"] as List? ?? [])
        .cast<Map<String, dynamic>>();

    int toInt(dynamic value) =>
        value is int ? value : int.tryParse(value?.toString() ?? "") ?? 0;

    return ProductMapper(
      id: toInt(json["id"]),
      name: json["name"] ?? "",
      description: json["description"] ?? "",
      unit: json["unit"] ?? "",
      categoryId: toInt(json["category_id"]),

      images: imagesJson
          .map<ProductImage>((e) => ProductImageMapper.fromJson(e))
          .toList(),

      productDetails: productDetailJson
          .map<ProductDetail>((e) => ProductDetailMapper.fromJson(e))
          .toList(),

      createdAt: json["created_at"] != null
          ? DateTime.tryParse(json["created_at"])
          : null,
      updatedAt: json["updated_at"] != null
          ? DateTime.tryParse(json["updated_at"])
          : null,
    );
  }
}
