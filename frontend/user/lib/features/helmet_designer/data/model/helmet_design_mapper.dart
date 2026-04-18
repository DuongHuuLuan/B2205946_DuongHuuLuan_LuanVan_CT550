import 'package:b2205946_duonghuuluan_luanvan/features/helmet_designer/data/model/sticker_layer_mapper.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/helmet_designer/domain/helmet_design.dart';

class HelmetDesignMapper {
  static HelmetDesign fromJson(Map<String, dynamic> json) {
    final rawStickers =
        (json["stickers"] as List?) ??
        (json["sticker_layers"] as List?) ??
        const [];

    return HelmetDesign(
      id: (json["id"] as num?)?.toInt() ?? 0,
      helmetProductId: (json["product_id"] as num?)?.toInt() ?? 0,
      productDetailId: (json["product_detail_id"] as num?)?.toInt(),
      helmetName: json["name"]?.toString() ?? "",
      helmetBaseImageUrl: json["base_image_url"]?.toString() ?? "",
      stickers: rawStickers
          .whereType<Map>()
          .map(_mapDynamic)
          .map(StickerLayerMapper.fromJson)
          .toList(),
      isShared:
          json["is_shared"] as bool? ?? json["isShared"] as bool? ?? false,
      createdAt: _parseDate(json["created_at"] ?? json["createdAt"]),
      updatedAt: _parseDate(json["updated_at"] ?? json["updatedAt"]),
    );
  }

  static Map<String, dynamic> toJson(HelmetDesign design) {
    return {
      "id": design.id,
      "product_id": design.helmetProductId,
      "product_detail_id": design.productDetailId,
      "name": design.helmetName,
      "base_image_url": design.helmetBaseImageUrl,
      "stickers": design.stickers.map(StickerLayerMapper.toJson).toList(),
      "is_shared": design.isShared,
      "created_at": design.createdAt?.toIso8601String(),
      "updated_at": design.updatedAt?.toIso8601String(),
    };
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  static Map<String, dynamic> _mapDynamic(Map item) {
    return item.map((key, value) => MapEntry(key.toString(), value));
  }
}
