import 'package:b2205946_duonghuuluan_luanvan/features/helmet_designer/data/model/helmet_design_mapper.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/helmet_designer/data/model/sticker_template_mapper.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/helmet_designer/domain/ai_sticker_request.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/helmet_designer/domain/helmet_design.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/helmet_designer/domain/sticker_template.dart';

class MockHelmetDesignerData {
  static const _demoHelmetModel3dUrl =
      "https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Assets/main/Models/DamagedHelmet/glTF-Binary/DamagedHelmet.glb";

  static final List<Map<String, dynamic>> _stickerCatalog = [
    {
      "id": 1,
      "name": "Royal Crest",
      "image_url": "assets/images/logo_royalStore2.png",
      "category": "Logo",
      "is_ai_generated": false,
      "has_transparent_background": true,
    },
    {
      "id": 2,
      "name": "Royal Mark",
      "image_url": "assets/images/logo_royalStore.png",
      "category": "Logo",
      "is_ai_generated": false,
      "has_transparent_background": true,
    },
    {
      "id": 3,
      "name": "Street Burst",
      "image_url": "assets/images/banner1.webp",
      "category": "Street",
      "is_ai_generated": false,
      "has_transparent_background": false,
    },
    {
      "id": 4,
      "name": "Speed Wave",
      "image_url": "assets/images/banner2.webp",
      "category": "Sport",
      "is_ai_generated": false,
      "has_transparent_background": false,
    },
    {
      "id": 5,
      "name": "Urban Flame",
      "image_url": "assets/images/banner3.webp",
      "category": "Graphic",
      "is_ai_generated": false,
      "has_transparent_background": false,
    },
    {
      "id": 6,
      "name": "Sunset Stripe",
      "image_url": "assets/images/banner4.webp",
      "category": "Graphic",
      "is_ai_generated": false,
      "has_transparent_background": false,
    },
  ];

  static final Map<int, Map<String, dynamic>> _designs = {
    1001: {
      "id": 1001,
      "helmet_product_id": 101,
      "helmet_name": "Royal Street Helmet",
      "helmet_base_image_url": "assets/images/logo.webp",
      "helmet_model_3d_url": _demoHelmetModel3dUrl,
      "stickers": [
        {
          "id": 1,
          "sticker_id": 1,
          "image_url": "assets/images/logo_royalStore2.png",
          "x": 0.38,
          "y": 0.32,
          "scale": 0.9,
          "rotation": 0.0,
          "z_index": 0,
          "crop": {"left": 0, "top": 0, "right": 1, "bottom": 1},
          "tint_color_value": null,
          "surface": "front",
          "surface_x": 0.52,
          "surface_y": 0.34,
          "surface_scale": 0.92,
        },
        {
          "id": 2,
          "sticker_id": 4,
          "image_url": "assets/images/banner2.webp",
          "x": 0.57,
          "y": 0.56,
          "scale": 0.65,
          "rotation": -0.18,
          "z_index": 1,
          "crop": {"left": 0.1, "top": 0.1, "right": 0.9, "bottom": 0.9},
          "tint_color_value": 4294924066,
          "surface": "right",
          "surface_x": 0.46,
          "surface_y": 0.44,
          "surface_scale": 0.78,
        },
      ],
      "is_shared": false,
      "created_at": "2026-03-12T00:00:00.000",
      "updated_at": "2026-03-12T00:00:00.000",
    },
  };

  static int _nextStickerId = 100;
  static int _nextDesignId = 2000;

  static List<StickerTemplate> getStickerCatalog() {
    return _stickerCatalog.map(StickerTemplateMapper.fromJson).toList();
  }

  static StickerTemplate generateAiSticker(AiStickerRequest request) {
    final images = _stickerCatalog
        .map((item) => item["image_url"] as String)
        .toList();
    final imageUrl = images[request.prompt.length % images.length];
    final sticker = StickerTemplate(
      id: _nextStickerId++,
      name: request.prompt.trim().isEmpty ? "AI Sticker" : request.prompt.trim(),
      imageUrl: imageUrl,
      category:
          request.style?.trim().isNotEmpty == true ? request.style!.trim() : "AI",
      isAiGenerated: true,
      hasTransparentBackground: request.removeBackground,
    );
    _stickerCatalog.insert(0, StickerTemplateMapper.toJson(sticker));
    return sticker;
  }

  static String transcribeAiStickerVoice(String audioPath) {
    final name = audioPath.split(RegExp(r"[\\\\/]")).last.toLowerCase();
    if (name.contains("fire")) {
      return "rong lua phong cach the thao";
    }
    return "sticker rong lua phong cach the thao";
  }

  static String removeBackground(String imageUrl) {
    return imageUrl;
  }

  static HelmetDesign saveDesign(HelmetDesign design) {
    final now = DateTime.now();
    final saved = HelmetDesign(
      id: design.id > 0 ? design.id : _nextDesignId++,
      helmetProductId: design.helmetProductId,
      helmetName: design.helmetName,
      helmetBaseImageUrl: design.helmetBaseImageUrl,
      helmetModel3dUrl: design.helmetModel3dUrl,
      helmetModel3dIosUrl: design.helmetModel3dIosUrl,
      stickers: design.stickers,
      isShared: design.isShared,
      createdAt: design.createdAt ?? now,
      updatedAt: now,
    );
    _designs[saved.id] = HelmetDesignMapper.toJson(saved);
    return saved;
  }

  static HelmetDesign getDesignDetail(int designId) {
    final raw = _designs[designId] ?? _designs.values.first;
    return HelmetDesignMapper.fromJson(raw);
  }

  static String createShareLink(int designId) {
    return "https://royalstore.local/designs/$designId";
  }

  static void orderDesign(
    int designId, {
    required int productDetailId,
    int quantity = 1,
  }) {
    if (!_designs.containsKey(designId)) {
      throw StateError("Design $designId not found");
    }
    if (productDetailId <= 0) {
      throw StateError("Product detail is required");
    }
    if (quantity <= 0) {
      throw StateError("Quantity must be greater than 0");
    }
  }
}
