import 'package:b2205946_duonghuuluan_luanvan/features/helmet_designer/domain/ai_sticker_request.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/helmet_designer/domain/helmet_design.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/helmet_designer/domain/sticker_template.dart';

abstract class HelmetDesignerRepository {
  Future<List<StickerTemplate>> getStickerCatalog();

  Future<String> transcribeAiStickerVoice(String audioPath);

  Future<StickerTemplate> generateAiSticker(AiStickerRequest request);

  Future<String> removeBackground(String imageUrl);

  Future<HelmetDesign> saveDesign(HelmetDesign design);

  Future<HelmetDesign> getDesignDetail(int designId);

  Future<String> createShareLink(int designId);

  Future<void> orderDesign(
    int designId, {
    required int productDetailId,
    int quantity = 1,
  });

  Future<List<HelmetDesign>> getMyDesigns();
}
