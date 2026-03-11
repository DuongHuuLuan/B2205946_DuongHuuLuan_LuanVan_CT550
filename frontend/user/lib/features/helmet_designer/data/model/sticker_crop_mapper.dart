import 'package:b2205946_duonghuuluan_luanvan/features/helmet_designer/domain/sticker_crop.dart';

class StickerCropMapper {
  static StickerCrop fromJson(Map<String, dynamic>? json) {
    final source = json ?? const <String, dynamic>{};
    return StickerCrop(
      left: (source["left"] as num?)?.toDouble() ?? 0,
      top: (source["top"] as num?)?.toDouble() ?? 0,
      right: (source["right"] as num?)?.toDouble() ?? 1,
      bottom: (source["bottom"] as num?)?.toDouble() ?? 1,
    );
  }

  static Map<String, dynamic> toJson(StickerCrop crop) {
    return {
      "left": crop.left,
      "top": crop.top,
      "right": crop.right,
      "bottom": crop.bottom,
    };
  }
}
