import 'package:b2205946_duonghuuluan_luanvan/features/product/domain/product_variant.dart';

class ProductVariantMapper extends ProductVariant {
  ProductVariantMapper({
    required super.id,
    required super.colorId,
    required super.colorHex,
    required super.colorName,
    required super.sizeId,
    required super.size,
    required super.price,
    required super.stockQuantity,
  });

  factory ProductVariantMapper.fromJson(Map<String, dynamic> json) {
    final color = (json["color"] ?? {}) as Map<String, dynamic>;
    final size = (json["size"] ?? {}) as Map<String, dynamic>;
    int toInt(dynamic value) =>
        value is int ? value : int.tryParse(value?.toString() ?? "") ?? 0;
    return ProductVariantMapper(
      id: toInt(json["id"]),
      colorId: toInt(color["id"]),
      colorName: color["name"] ?? "",
      colorHex: color["hexcode"] ?? "",
      sizeId: toInt(size["id"]),
      size: size["size"] ?? "",
      price: double.tryParse(json["price"].toString()) ?? 0,
      stockQuantity: (json["stock_quantity"] ?? 0) as int,
    );
  }
}


