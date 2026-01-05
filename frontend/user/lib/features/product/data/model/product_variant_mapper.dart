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
    //required super.purchasePrice,
  });

  factory ProductVariantMapper.fromJson(Map<String, dynamic> json) {
    final color = (json["color"] ?? {}) as Map<String, dynamic>;
    final size = (json["size"] ?? {}) as Map<String, dynamic>;
    return ProductVariantMapper(
      id: json["id"].toString(),
      colorId: color["id"].toString(),
      colorName: color["name"] ?? "",
      colorHex: color["hexcode"] ?? "",
      sizeId: size["id"]?.toString() ?? "",
      size: size["size"] ?? "",
      price: double.tryParse(json["price"].toString()) ?? 0,
      stockQuantity: (json["stock_quantity"] ?? 0) as int,
    );
  }
}
