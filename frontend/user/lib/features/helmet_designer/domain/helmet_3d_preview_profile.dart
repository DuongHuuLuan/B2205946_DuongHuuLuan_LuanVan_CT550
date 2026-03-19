import 'package:b2205946_duonghuuluan_luanvan/features/helmet_designer/domain/helmet_3d_surface.dart';
import 'package:flutter/widgets.dart';

class Helmet3dSurfaceProfile {
  final Helmet3dSurface surface;
  final String cameraOrbit;
  final Rect previewBounds;
  final double baseStickerSizeFactor;

  const Helmet3dSurfaceProfile({
    required this.surface,
    required this.cameraOrbit,
    required this.previewBounds,
    required this.baseStickerSizeFactor,
  });
}

class Helmet3dPreviewProfile {
  final Map<Helmet3dSurface, Helmet3dSurfaceProfile> surfaces;

  const Helmet3dPreviewProfile({required this.surfaces});

  Helmet3dSurfaceProfile of(Helmet3dSurface surface) {
    return surfaces[surface] ?? surfaces[Helmet3dSurface.front]!;
  }

  static const defaultProfile = Helmet3dPreviewProfile(
    surfaces: {
      Helmet3dSurface.front: Helmet3dSurfaceProfile(
        surface: Helmet3dSurface.front,
        cameraOrbit: "0deg 78deg 112%",
        previewBounds: Rect.fromLTWH(0.28, 0.13, 0.44, 0.48),
        baseStickerSizeFactor: 0.26,
      ),
      Helmet3dSurface.left: Helmet3dSurfaceProfile(
        surface: Helmet3dSurface.left,
        cameraOrbit: "90deg 82deg 114%",
        previewBounds: Rect.fromLTWH(0.20, 0.18, 0.26, 0.42),
        baseStickerSizeFactor: 0.24,
      ),
      Helmet3dSurface.right: Helmet3dSurfaceProfile(
        surface: Helmet3dSurface.right,
        cameraOrbit: "-90deg 82deg 114%",
        previewBounds: Rect.fromLTWH(0.54, 0.18, 0.26, 0.42),
        baseStickerSizeFactor: 0.24,
      ),
      Helmet3dSurface.back: Helmet3dSurfaceProfile(
        surface: Helmet3dSurface.back,
        cameraOrbit: "180deg 78deg 112%",
        previewBounds: Rect.fromLTWH(0.30, 0.16, 0.40, 0.44),
        baseStickerSizeFactor: 0.24,
      ),
    },
  );
}
