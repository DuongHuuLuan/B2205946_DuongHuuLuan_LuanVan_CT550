import 'package:b2205946_duonghuuluan_luanvan/features/product/data/model/product_image_mapper.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/product/data/model/product_variant_mapper.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/product/domain/product.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/product/domain/product_image.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/product/domain/product_variant.dart';

class ProductMapper extends Product {
  ProductMapper({
    required super.id,
    required super.name,
    required super.description,
    required super.unit,
    required super.categoryId,
    required super.images,
    required super.variants,
    super.createdAt,
    super.updatedAt,
  });

  factory ProductMapper.fromJson(Map<String, dynamic> json) {
    final variantsJson = (json["variants"] as List? ?? [])
        .cast<Map<String, dynamic>>();
    final imagesJson = (json["images"] as List? ?? [])
        .cast<Map<String, dynamic>>();

    return ProductMapper(
      id: json["id"].toString(),
      name: json["name"] ?? "",
      description: json["description"] ?? "",
      unit: json["unit"] ?? "",
      categoryId: json["category_id"]?.toString() ?? "",

      images: imagesJson
          .map<ProductImage>((e) => ProductImageMapper.fromJson(e))
          .toList(),

      variants: variantsJson
          .map<ProductVariant>((e) => ProductVariantMapper.fromJson(e))
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
