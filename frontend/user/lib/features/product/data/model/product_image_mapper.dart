import 'package:b2205946_duonghuuluan_luanvan/features/product/domain/product_image.dart';

class ProductImageMapper extends ProductImage {
  ProductImageMapper({
    required super.id,
    required super.url,
    required super.publicId,
    required super.colorId,
  });

  factory ProductImageMapper.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic value) =>
        value is int ? value : int.tryParse(value?.toString() ?? "") ?? 0;
    int? toNullableInt(dynamic value) => value == null ? null : toInt(value);
    return ProductImageMapper(
      id: toInt(json["id"]),
      url: json["url"] ?? "",
      publicId: json["public_id"] ?? "",
      colorId: toNullableInt(json["color_id"]),
    );
  }
}

