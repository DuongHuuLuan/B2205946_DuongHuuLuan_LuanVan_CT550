import 'package:b2205946_duonghuuluan_luanvan/features/product/domain/product_detail.dart';

class ProductDetailMapper extends ProductDetail {
  ProductDetailMapper({
    required super.id,
    required super.colorId,
    required super.colorHex,
    required super.colorName,
    required super.sizeId,
    required super.size,
    required super.price,
    required super.isActive,
  });

  factory ProductDetailMapper.fromJson(Map<String, dynamic> json) {
    final color = (json["color"] ?? {}) as Map<String, dynamic>;
    final size = (json["size"] ?? {}) as Map<String, dynamic>;
    int toInt(dynamic value) =>
        value is int ? value : int.tryParse(value?.toString() ?? "") ?? 0;

    bool toBool(dynamic value) {
      if (value is bool) return value;
      if (value is int) return value == 1;
      if (value is String) {
        final v = value.trim().toLowerCase();
        return v == "1" || v == "true";
      }
      return false;
    }

    return ProductDetailMapper(
      id: toInt(json["id"]),
      colorId: toInt(color["id"]),
      colorName: color["name"] ?? "",
      colorHex: color["hexcode"] ?? "",
      sizeId: toInt(size["id"]),
      size: size["size"] ?? "",
      price: double.tryParse(json["price"].toString()) ?? 0,
      isActive: toBool(json["is_active"]),
    );
  }
}
