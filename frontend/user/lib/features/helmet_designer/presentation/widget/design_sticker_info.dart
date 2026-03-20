import 'package:b2205946_duonghuuluan_luanvan/features/helmet_designer/domain/helmet_designer_repository.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DesignStickerInfo extends StatefulWidget {
  final int? designId;
  final String? designName;
  final String? designPreviewImageUrl;
  final double imageSize;
  final String label;

  const DesignStickerInfo({
    super.key,
    required this.designId,
    this.designName,
    this.designPreviewImageUrl,
    this.imageSize = 32,
    this.label = "Thiết kế",
  });

  @override
  State<DesignStickerInfo> createState() => _DesignStickerInfoState();
}

class _DesignStickerInfoState extends State<DesignStickerInfo> {
  static final Map<int, Future<String?>> _stickerUrlCache = {};
  Future<String?>? _stickerUrlFuture;

  @override
  void initState() {
    super.initState();
    _stickerUrlFuture = _createStickerFuture();
  }

  @override
  void didUpdateWidget(covariant DesignStickerInfo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.designId != widget.designId ||
        oldWidget.designPreviewImageUrl != widget.designPreviewImageUrl) {
      _stickerUrlFuture = _createStickerFuture();
    }
  }

  Future<String?>? _createStickerFuture() {
    final designId = widget.designId;
    if (designId == null || designId <= 0) {
      return null;
    }
    final fallbackUrl = _normalizeUrl(widget.designPreviewImageUrl);
    final repository = context.read<HelmetDesignerRepository>();
    return _stickerUrlCache.putIfAbsent(designId, () async {
      try {
        final design = await repository.getDesignDetail(designId);
        for (final sticker in design.stickers) {
          final url = _normalizeUrl(sticker.imageUrl);
          if (url != null) return url;
        }
      } catch (_) {}
      return fallbackUrl;
    });
  }

  String? _normalizeUrl(String? value) {
    final text = value?.trim() ?? "";
    if (text.isEmpty) return null;
    return text;
  }

  @override
  Widget build(BuildContext context) {
    final designId = widget.designId;
    if (designId == null || designId <= 0) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    final title = (widget.designName?.trim().isNotEmpty ?? false)
        ? widget.designName!.trim()
        : "Thiết kế riêng";

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withOpacity(0.32),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          FutureBuilder<String?>(
            future: _stickerUrlFuture,
            builder: (context, snapshot) => _StickerThumb(
              url: snapshot.data ?? _normalizeUrl(widget.designPreviewImageUrl),
              size: widget.imageSize,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.secondary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      color: colorScheme.onSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StickerThumb extends StatelessWidget {
  final String? url;
  final double size;

  const _StickerThumb({required this.url, required this.size});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final imageUrl = url?.trim() ?? "";
    if (imageUrl.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.auto_awesome,
          size: size * 0.55,
          color: colorScheme.secondary,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: size,
          height: size,
          color: colorScheme.surfaceContainerHighest,
        ),
        errorWidget: (context, url, error) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.broken_image_outlined,
            size: size * 0.55,
            color: colorScheme.error,
          ),
        ),
      ),
    );
  }
}
