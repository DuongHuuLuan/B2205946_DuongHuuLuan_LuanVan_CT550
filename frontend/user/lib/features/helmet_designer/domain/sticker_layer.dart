import 'package:b2205946_duonghuuluan_luanvan/features/helmet_designer/domain/helmet_3d_surface.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/helmet_designer/domain/sticker_crop.dart';

class StickerLayer {
  final int id;
  final int stickerId;
  final String imageUrl;
  final double x;
  final double y;
  final double scale;
  final double rotation;
  final int zIndex;
  final String? viewImageKey;
  final int? tintColorValue;
  final StickerCrop crop;
  final Helmet3dSurface surface;
  final double surfaceX;
  final double surfaceY;
  final double surfaceScale;

  StickerLayer({
    required this.id,
    required this.stickerId,
    required this.imageUrl,
    required this.x,
    required this.y,
    required this.scale,
    required this.rotation,
    required this.zIndex,
    this.viewImageKey,
    required this.crop,
    this.tintColorValue,
    this.surface = Helmet3dSurface.front,
    this.surfaceX = 0.5,
    this.surfaceY = 0.5,
    this.surfaceScale = 1.0,
  });

  StickerLayer copyWith({
    int? id,
    int? stickerId,
    String? imageUrl,
    double? x,
    double? y,
    double? scale,
    double? rotation,
    int? zIndex,
    String? viewImageKey,
    bool clearViewImageKey = false,
    int? tintColorValue,
    bool clearTintColor = false,
    StickerCrop? crop,
    Helmet3dSurface? surface,
    double? surfaceX,
    double? surfaceY,
    double? surfaceScale,
  }) {
    return StickerLayer(
      id: id ?? this.id,
      stickerId: stickerId ?? this.stickerId,
      imageUrl: imageUrl ?? this.imageUrl,
      x: x ?? this.x,
      y: y ?? this.y,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      zIndex: zIndex ?? this.zIndex,
      viewImageKey: clearViewImageKey
          ? null
          : (viewImageKey ?? this.viewImageKey),
      tintColorValue: clearTintColor
          ? null
          : (tintColorValue ?? this.tintColorValue),
      crop: crop ?? this.crop,
      surface: surface ?? this.surface,
      surfaceX: surfaceX ?? this.surfaceX,
      surfaceY: surfaceY ?? this.surfaceY,
      surfaceScale: surfaceScale ?? this.surfaceScale,
    );
  }
}
