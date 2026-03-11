import 'package:b2205946_duonghuuluan_luanvan/features/helmet_designer/domain/sticker_template.dart';

class StickerTemplateMapper {
  static StickerTemplate fromJson(Map<String, dynamic> json) {
    return StickerTemplate(
      id: (json["id"] as num?)?.toInt() ?? 0,
      name: json["name"]?.toString() ?? "",
      imageUrl:
          json["image_url"]?.toString() ?? json["imageUrl"]?.toString() ?? "",
      category: json["category"]?.toString() ?? "",
      isAiGenerated:
          json["is_ai_generated"] as bool? ??
          json["isAiGenerated"] as bool? ??
          false,
      hasTransparentBackground:
          json["has_transparent_background"] as bool? ??
          json["hasTransparentBackground"] as bool? ??
          false,
    );
  }

  static Map<String, dynamic> toJson(StickerTemplate sticker) {
    return {
      "id": sticker.id,
      "name": sticker.name,
      "image_url": sticker.imageUrl,
      "category": sticker.category,
      "is_ai_generated": sticker.isAiGenerated,
      "has_transparent_background": sticker.hasTransparentBackground,
    };
  }
}
