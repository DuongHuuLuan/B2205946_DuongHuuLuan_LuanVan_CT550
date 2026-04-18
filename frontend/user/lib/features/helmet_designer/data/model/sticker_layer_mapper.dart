import 'package:b2205946_duonghuuluan_luanvan/features/helmet_designer/data/model/sticker_crop_mapper.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/helmet_designer/domain/sticker_layer.dart';

class StickerLayerMapper {
  static StickerLayer fromJson(Map<String, dynamic> json) {
    return StickerLayer(
      id: (json["id"] as num?)?.toInt() ?? 0,
      stickerId: (json["sticker_id"] as num?)?.toInt() ?? 0,
      imageUrl:
          json["image_url"]?.toString() ?? json["imageUrl"]?.toString() ?? "",
      x: (json["x"] as num?)?.toDouble() ?? 0,
      y: (json["y"] as num?)?.toDouble() ?? 0,
      scale: (json["scale"] as num?)?.toDouble() ?? 1,
      rotation: (json["rotation"] as num?)?.toDouble() ?? 0,
      zIndex: (json["z_index"] as num?)?.toInt() ?? 0,
      viewImageKey: json["view_image_key"]?.toString(),
      tintColorValue: (json["tint_color_value"] as num?)?.toInt(),
      crop: StickerCropMapper.fromJson(json["crop"] as Map<String, dynamic>?),
    );
  }

  static Map<String, dynamic> toJson(StickerLayer layer) {
    return {
      "id": layer.id,
      "sticker_id": layer.stickerId,
      "image_url": layer.imageUrl,
      "x": layer.x,
      "y": layer.y,
      "scale": layer.scale,
      "rotation": layer.rotation,
      "z_index": layer.zIndex,
      "view_image_key": layer.viewImageKey,
      "tint_color_value": layer.tintColorValue,
      "crop": StickerCropMapper.toJson(layer.crop),
    };
  }
}
