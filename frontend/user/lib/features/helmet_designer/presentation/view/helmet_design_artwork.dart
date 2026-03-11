import 'dart:math' as math;

import 'package:b2205946_duonghuuluan_luanvan/features/helmet_designer/domain/sticker_crop.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/helmet_designer/domain/sticker_layer.dart';
import 'package:flutter/material.dart';

class HelmetDesignArtwork extends StatelessWidget {
  final String helmetBaseImageUrl;
  final List<StickerLayer> layers;
  final EdgeInsets padding;

  const HelmetDesignArtwork({
    super.key,
    required this.helmetBaseImageUrl,
    required this.layers,
    this.padding = const EdgeInsets.all(0),
  });

  @override
  Widget build(BuildContext context) {
    final sortedLayers = [...layers]..sort((a, b) => a.zIndex.compareTo(b.zIndex));

    return ClipRect(
      child: Padding(
        padding: padding,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            final baseSize = math.min(width, height);

            return Stack(
              children: [
                Positioned.fill(
                  child: _HelmetBaseVisual(imageUrl: helmetBaseImageUrl),
                ),
                for (final layer in sortedLayers)
                  _StickerArtworkLayer(
                    layer: layer,
                    canvasWidth: width,
                    canvasHeight: height,
                    baseSize: baseSize,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StickerArtworkLayer extends StatelessWidget {
  final StickerLayer layer;
  final double canvasWidth;
  final double canvasHeight;
  final double baseSize;

  const _StickerArtworkLayer({
    required this.layer,
    required this.canvasWidth,
    required this.canvasHeight,
    required this.baseSize,
  });

  @override
  Widget build(BuildContext context) {
    final size = (baseSize * 0.24 * layer.scale).clamp(
      26.0,
      baseSize * 0.58,
    );
    final left = (layer.x * canvasWidth - size / 2).clamp(
      -size * 0.22,
      canvasWidth - size * 0.78,
    );
    final top = (layer.y * canvasHeight - size / 2).clamp(
      -size * 0.22,
      canvasHeight - size * 0.78,
    );

    return Positioned(
      left: left.toDouble(),
      top: top.toDouble(),
      child: Transform.rotate(
        angle: layer.rotation,
        child: SizedBox(
          width: size.toDouble(),
          height: size.toDouble(),
          child: _StickerGraphic(
            crop: layer.crop,
            imageUrl: layer.imageUrl,
            tintColorValue: layer.tintColorValue,
          ),
        ),
      ),
    );
  }
}

class _StickerGraphic extends StatelessWidget {
  final StickerCrop crop;
  final String imageUrl;
  final int? tintColorValue;

  const _StickerGraphic({
    required this.crop,
    required this.imageUrl,
    this.tintColorValue,
  });

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (imageUrl.startsWith("assets/")) {
      child = Image.asset(imageUrl, fit: BoxFit.contain);
    } else {
      child = Image.network(
        imageUrl,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
      );
    }

    if (tintColorValue != null) {
      child = ColorFiltered(
        colorFilter: ColorFilter.mode(
          Color(tintColorValue!),
          BlendMode.modulate,
        ),
        child: child,
      );
    }

    final widthFactor = (crop.right - crop.left).clamp(0.12, 1.0).toDouble();
    final heightFactor = (crop.bottom - crop.top).clamp(0.12, 1.0).toDouble();
    final alignX = (((crop.left + crop.right) / 2) * 2 - 1).clamp(-1.0, 1.0);
    final alignY = (((crop.top + crop.bottom) / 2) * 2 - 1).clamp(-1.0, 1.0);

    return Padding(
      padding: const EdgeInsets.all(4),
      child: ClipRect(
        child: Align(
          alignment: Alignment(alignX.toDouble(), alignY.toDouble()),
          widthFactor: widthFactor,
          heightFactor: heightFactor,
          child: child,
        ),
      ),
    );
  }
}

class _HelmetBaseVisual extends StatelessWidget {
  final String imageUrl;

  const _HelmetBaseVisual({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    if (imageUrl.trim().isEmpty) {
      return CustomPaint(painter: const _HelmetBasePainter());
    }

    Widget child;
    if (imageUrl.startsWith("assets/")) {
      child = Image.asset(
        imageUrl,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => CustomPaint(
          painter: const _HelmetBasePainter(),
        ),
      );
    } else {
      child = Image.network(
        imageUrl,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => CustomPaint(
          painter: const _HelmetBasePainter(),
        ),
      );
    }

    return Opacity(opacity: 0.98, child: child);
  }
}

class _HelmetBasePainter extends CustomPainter {
  const _HelmetBasePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF1B3550), Color(0xFF0C1628)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Offset.zero & size);

    final visorPaint = Paint()
      ..color = const Color(0xFFB4C9E8).withOpacity(0.28);
    final strokePaint = Paint()
      ..color = Colors.white.withOpacity(0.20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final shell = Path()
      ..moveTo(size.width * 0.18, size.height * 0.63)
      ..quadraticBezierTo(
        size.width * 0.15,
        size.height * 0.23,
        size.width * 0.50,
        size.height * 0.16,
      )
      ..quadraticBezierTo(
        size.width * 0.82,
        size.height * 0.24,
        size.width * 0.84,
        size.height * 0.54,
      )
      ..quadraticBezierTo(
        size.width * 0.85,
        size.height * 0.74,
        size.width * 0.62,
        size.height * 0.80,
      )
      ..lineTo(size.width * 0.34, size.height * 0.80)
      ..quadraticBezierTo(
        size.width * 0.22,
        size.height * 0.77,
        size.width * 0.18,
        size.height * 0.63,
      )
      ..close();

    final visor = Path()
      ..moveTo(size.width * 0.48, size.height * 0.32)
      ..quadraticBezierTo(
        size.width * 0.68,
        size.height * 0.36,
        size.width * 0.70,
        size.height * 0.53,
      )
      ..quadraticBezierTo(
        size.width * 0.59,
        size.height * 0.58,
        size.width * 0.45,
        size.height * 0.52,
      )
      ..quadraticBezierTo(
        size.width * 0.41,
        size.height * 0.40,
        size.width * 0.48,
        size.height * 0.32,
      )
      ..close();

    canvas.drawPath(shell, bodyPaint);
    canvas.drawPath(shell, strokePaint);
    canvas.drawPath(visor, visorPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
