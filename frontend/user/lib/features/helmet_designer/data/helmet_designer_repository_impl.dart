import 'package:b2205946_duonghuuluan_luanvan/features/helmet_designer/data/helmet_designer_api.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/helmet_designer/data/mock/mock_helmet_designer_data.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/helmet_designer/data/model/ai_sticker_request_mapper.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/helmet_designer/data/model/helmet_design_mapper.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/helmet_designer/data/model/sticker_template_mapper.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/helmet_designer/domain/ai_sticker_request.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/helmet_designer/domain/helmet_design.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/helmet_designer/domain/helmet_designer_repository.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/helmet_designer/domain/sticker_template.dart';

class HelmetDesignerRepositoryImpl extends HelmetDesignerRepository {
  final HelmetDesignerApi _api;
  final bool useMockData;

  HelmetDesignerRepositoryImpl(this._api, {this.useMockData = false});

  @override
  Future<List<StickerTemplate>> getStickerCatalog() async {
    if (useMockData) {
      return MockHelmetDesignerData.getStickerCatalog();
    }

    try {
      final response = await _api.getStickerCatalog();
      final items = _extractList(response.data);
      return items.map(StickerTemplateMapper.fromJson).toList();
    } catch (_) {
      return MockHelmetDesignerData.getStickerCatalog();
    }
  }

  @override
  Future<StickerTemplate> generateAiSticker(AiStickerRequest request) async {
    if (useMockData) {
      return MockHelmetDesignerData.generateAiSticker(request);
    }

    try {
      final response = await _api.generateAiSticker(
        AiStickerRequestMapper.toJson(request),
      );
      return StickerTemplateMapper.fromJson(_extractMap(response.data));
    } catch (_) {
      return MockHelmetDesignerData.generateAiSticker(request);
    }
  }

  @override
  Future<String> removeBackground(String imageUrl) async {
    if (useMockData) {
      return MockHelmetDesignerData.removeBackground(imageUrl);
    }

    try {
      final response = await _api.removeBackground(imageUrl);
      final data = _extractMap(response.data);
      return data["image_url"]?.toString() ??
          data["url"]?.toString() ??
          imageUrl;
    } catch (_) {
      return MockHelmetDesignerData.removeBackground(imageUrl);
    }
  }

  @override
  Future<HelmetDesign> saveDesign(HelmetDesign design) async {
    if (useMockData) {
      return MockHelmetDesignerData.saveDesign(design);
    }

    try {
      final response = await _api.saveDesign(HelmetDesignMapper.toJson(design));
      return HelmetDesignMapper.fromJson(_extractMap(response.data));
    } catch (_) {
      return MockHelmetDesignerData.saveDesign(design);
    }
  }

  @override
  Future<HelmetDesign> getDesignDetail(int designId) async {
    if (useMockData) {
      return MockHelmetDesignerData.getDesignDetail(designId);
    }

    try {
      final response = await _api.getDesignDetail(designId);
      return HelmetDesignMapper.fromJson(_extractMap(response.data));
    } catch (_) {
      return MockHelmetDesignerData.getDesignDetail(designId);
    }
  }

  @override
  Future<String> createShareLink(int designId) async {
    if (useMockData) {
      return MockHelmetDesignerData.createShareLink(designId);
    }

    try {
      final response = await _api.createShareLink(designId);
      final data = _extractMap(response.data);
      return data["share_url"]?.toString() ??
          data["url"]?.toString() ??
          MockHelmetDesignerData.createShareLink(designId);
    } catch (_) {
      return MockHelmetDesignerData.createShareLink(designId);
    }
  }

  @override
  Future<void> orderDesign(int designId) async {
    if (useMockData) {
      MockHelmetDesignerData.orderDesign(designId);
      return;
    }

    try {
      await _api.orderDesign(designId);
    } catch (_) {
      MockHelmetDesignerData.orderDesign(designId);
    }
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
        .map((item) => item.map((key, value) => MapEntry(key.toString(), value)))
        .toList();
  }
}
