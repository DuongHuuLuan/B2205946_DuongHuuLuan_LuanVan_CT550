import 'package:b2205946_duonghuuluan_luanvan/features/product/domain/product_image.dart';

class ProductImageMapper extends ProductImage {
  ProductImageMapper({
    required super.id,
    required super.url,
    required super.publicId,
  });

  factory ProductImageMapper.fromJson(Map<String, dynamic> json) {
    return ProductImageMapper(
      id: json["id"].toString(),
      url: json["url"] ?? "",
      publicId: json["public_id"] ?? "",
    );
  }
}
