import 'package:b2205946_duonghuuluan_luanvan/features/helmet_designer/domain/ai_sticker_request.dart';

class AiStickerRequestMapper {
  static Map<String, dynamic> toJson(AiStickerRequest request) {
    return {
      "prompt": request.prompt,
      "style": request.style,
      "dominant_color": request.dominantColor,
      "remove_background": request.removeBackground,
    };
  }
}
