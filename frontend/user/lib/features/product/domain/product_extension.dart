import 'package:b2205946_duonghuuluan_luanvan/features/product/domain/product.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/product/domain/product_image.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/product/domain/product_variant.dart';

extension ProductX on Product {
  // láº¥y danh sÃ¡ch mÃ u khÃ´ng trÃ¹ng
  List<ProductVariant> get uniqueColors {
    final seen = <int>{};
    return variants.where((element) => seen.add(element.colorId)).toList();
  }

  // láº¥y danh sÃ¡ch size theo mÃ u Ä‘Ã£ chá»n
  List<ProductVariant> getUniqueSizesByColor(int? colorId) {
    if (variants.isEmpty) return [];

    final cId = colorId ?? variants.first.colorId;

    final seen = <int>{};
    return variants
        .where((element) => element.colorId == cId)
        .where((element) => seen.add(element.sizeId))
        .toList();
  }

  // tÃ¬m biáº¿n thá»ƒ (variant) khá»›p nháº¥t
  // ProductVariant? findVariant(int? colorId, int? sizeId) {
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
  ProductVariant? findVariant(int? colorId, int? sizeId) {
    final vs = variants.cast<ProductVariant>(); // âœ… Ã©p type vá» base
    if (vs.isEmpty) return null;

    final cId = colorId ?? vs.first.colorId;
    final sId = sizeId ?? vs.first.sizeId;

    final exact = vs.where((e) => e.colorId == cId && e.sizeId == sId);
    if (exact.isNotEmpty) return exact.first;

    final byColor = vs.where((e) => e.colorId == cId);
    if (byColor.isNotEmpty) return byColor.first;

    return vs.first;
  }

  // lá»c áº£nh hiá»ƒn thá»‹ (theo mÃ u hoáº·c áº£nh chung)
  List<ProductImage> filterImages(int? colorId) {
    final byColor = images
        .where((element) => element.colorId == colorId)
        .toList();
    if (byColor.isNotEmpty) return byColor;

    final commons = images.where((element) => element.colorId == null).toList();
    return commons.isNotEmpty ? commons : images;
  }
}

