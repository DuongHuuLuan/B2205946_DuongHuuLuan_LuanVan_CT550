import 'package:b2205946_duonghuuluan_luanvan/features/helmet_designer/data/helmet_designer_api.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/helmet_designer/data/model/ai_sticker_request_mapper.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/helmet_designer/data/model/helmet_design_mapper.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/helmet_designer/data/model/sticker_template_mapper.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/helmet_designer/domain/ai_sticker_request.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/helmet_designer/domain/helmet_design.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/helmet_designer/domain/helmet_designer_repository.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/helmet_designer/domain/sticker_template.dart';

class HelmetDesignerRepositoryImpl extends HelmetDesignerRepository {
  final HelmetDesignerApi _api;

  HelmetDesignerRepositoryImpl(this._api);

  @override
  Future<List<StickerTemplate>> getStickerCatalog() async {
    final response = await _api.getStickerCatalog();
    final items = _extractList(response.data);
    return items.map(StickerTemplateMapper.fromJson).toList();
  }

  @override
  Future<StickerTemplate> generateAiSticker(AiStickerRequest request) async {
    final response = await _api.generateAiSticker(
      AiStickerRequestMapper.toJson(request),
    );
    return StickerTemplateMapper.fromJson(_extractMap(response.data));
  }

  @override
  Future<String> transcribeAiStickerVoice(String audioPath) async {
    final response = await _api.transcribeAiStickerVoice(audioPath);
    final data = _extractMap(response.data);
    final prompt =
        data["prompt"]?.toString().trim() ??
        data["transcript"]?.toString().trim() ??
        "";
    if (prompt.isEmpty) {
      throw StateError("Backend không trả về prompt hợp lệ.");
    }
    return prompt;
  }

  @override
  Future<HelmetDesign> saveDesign(HelmetDesign design) async {
    final response = await _api.saveDesign(HelmetDesignMapper.toJson(design));
    return HelmetDesignMapper.fromJson(_extractMap(response.data));
  }

  @override
  Future<HelmetDesign> getDesignDetail(int designId) async {
    final response = await _api.getDesignDetail(designId);
    return HelmetDesignMapper.fromJson(_extractMap(response.data));
  }

  @override
  Future<String> createShareLink(int designId) async {
    final response = await _api.createShareLink(designId);
    final data = _extractMap(response.data);
    final shareUrl = data["share_url"]?.toString() ?? data["url"]?.toString();
    if (shareUrl == null || shareUrl.isEmpty) {
      throw StateError("Backend không trả về share_url hợp lệ.");
    }
    return shareUrl;
  }

  @override
  Future<void> orderDesign(
    int designId, {
    required int productDetailId,
    int quantity = 1,
  }) async {
    await _api.orderDesign(
      designId,
      productDetailId: productDetailId,
      quantity: quantity,
    );
  }

  List<Map<String, dynamic>> _extractList(dynamic data) {
    if (data is Map<String, dynamic>) {
      if (data["items"] is List) {
        return _toMapList(data["items"] as List);
      }
      if (data["data"] is List) {
        return _toMapList(data["data"] as List);
      }
      if (data["data"] is Map<String, dynamic> &&
          data["data"]["items"] is List) {
        return _toMapList(data["data"]["items"] as List);
      }
    }
    if (data is List) {
      return _toMapList(data);
    }
    return const [];
  }

  Map<String, dynamic> _extractMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      if (data["data"] is Map<String, dynamic>) {
        return data["data"] as Map<String, dynamic>;
      }
      return data;
    }
    return const {};
  }

  List<Map<String, dynamic>> _toMapList(List items) {
    return items
        .whereType<Map>()
        .map(
          (item) => item.map((key, value) => MapEntry(key.toString(), value)),
        )
        .toList();
  }

  @override
  Future<List<HelmetDesign>> getMyDesigns() async {
    final response = await _api.getMyDesigns();
    final items = _extractList(response.data);

    return items.map(HelmetDesignMapper.fromJson).toList();
  }
}
