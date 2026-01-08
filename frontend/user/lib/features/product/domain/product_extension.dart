import 'package:b2205946_duonghuuluan_luanvan/features/product/domain/product.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/product/domain/product_image.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/product/domain/product_variant.dart';

extension ProductX on Product {
  // lấy danh sách màu không trùng
  List<ProductVariant> get uniqueColors {
    final seen = <String>{};
    return variants.where((element) => seen.add(element.colorId)).toList();
  }

  // lấy danh sách size theo màu đã chọn
  List<ProductVariant> getUniqueSizesByColor(String? colorId) {
    if (variants.isEmpty) return [];

    final cId = colorId ?? variants.first.colorId;

    final seen = <String>{};
    return variants
        .where((element) => element.colorId == cId)
        .where((element) => seen.add(element.sizeId))
        .toList();
  }

  // tìm biến thể (variant) khớp nhất
  // ProductVariant? findVariant(String? colorId, String? sizeId) {
  //   if (variants.isEmpty) return null;
  //   try {
  //     return variants.firstWhere(
  //       (element) => element.colorId == colorId && element.sizeId == sizeId,
  //       orElse: () =>
  //           variants.firstWhere((element) => element.colorId == colorId),
  //     );
  //   } catch (_) {
  //     return variants.first;
  //   }
  // }
  ProductVariant? findVariant(String? colorId, String? sizeId) {
    final vs = variants.cast<ProductVariant>(); // ✅ ép type về base
    if (vs.isEmpty) return null;

    final cId = colorId ?? vs.first.colorId;
    final sId = sizeId ?? vs.first.sizeId;

    final exact = vs.where((e) => e.colorId == cId && e.sizeId == sId);
    if (exact.isNotEmpty) return exact.first;

    final byColor = vs.where((e) => e.colorId == cId);
    if (byColor.isNotEmpty) return byColor.first;

    return vs.first;
  }

  // lọc ảnh hiển thị (theo màu hoặc ảnh chung)
  List<ProductImage> filterImages(String? colorId) {
    final byColor = images
        .where((element) => element.colorId == colorId)
        .toList();
    if (byColor.isNotEmpty) return byColor;

    final commons = images.where((element) => element.colorId == null).toList();
    return commons.isNotEmpty ? commons : images;
  }
}
