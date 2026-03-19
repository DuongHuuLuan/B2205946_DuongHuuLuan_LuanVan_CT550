import 'package:b2205946_duonghuuluan_luanvan/features/helmet_designer/domain/sticker_layer.dart';

class HelmetDesign {
  final int id;
  final int helmetProductId;
  final String helmetName;
  final String helmetBaseImageUrl;
  final String? helmetModel3dUrl;
  final String? helmetModel3dIosUrl;
  final List<StickerLayer> stickers;
  final bool isShared;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  HelmetDesign({
    required this.id,
    required this.helmetProductId,
    required this.helmetName,
    required this.helmetBaseImageUrl,
    this.helmetModel3dUrl,
    this.helmetModel3dIosUrl,
    required this.stickers,
    required this.isShared,
    this.createdAt,
    this.updatedAt,
  });

  HelmetDesign copyWith({
    int? id,
    int? helmetProductId,
    String? helmetName,
    String? helmetBaseImageUrl,
    String? helmetModel3dUrl,
    String? helmetModel3dIosUrl,
    List<StickerLayer>? stickers,
    bool? isShared,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HelmetDesign(
      id: id ?? this.id,
      helmetProductId: helmetProductId ?? this.helmetProductId,
      helmetName: helmetName ?? this.helmetName,
      helmetBaseImageUrl: helmetBaseImageUrl ?? this.helmetBaseImageUrl,
      helmetModel3dUrl: helmetModel3dUrl ?? this.helmetModel3dUrl,
      helmetModel3dIosUrl:
          helmetModel3dIosUrl ?? this.helmetModel3dIosUrl,
      stickers: stickers ?? this.stickers,
      isShared: isShared ?? this.isShared,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
