import 'package:b2205946_duonghuuluan_luanvan/features/evaluate/domain/evaluate.dart';

class EvaluateMapper {
  static EvaluateImage imageFromJson(Map<String, dynamic> json) {
    return EvaluateImage(
      id: (json["id"] ?? 0) as int,
      imageUrl: (json["image_url"] ?? "") as String,
      sortOrder: json["sort_order"] as int?,
    );
  }

  static EvaluateItem fromJson(Map<String, dynamic> json) {
    final rawImages = (json["images"] as List?) ?? const [];
    return EvaluateItem(
      id: (json["id"] ?? 0) as int,
      orderId: (json["order_id"] ?? 0) as int,
      userId: (json["user_id"] ?? 0) as int,
      rate: (json["rate"] ?? 0) as int,
      content: json["content"] as String?,
      adminReply: json["admin_reply"] as String?,
      createdAt: _parseDate(json["created_at"]),
      updatedAt: _parseDate(json["updated_at"]),
      adminRepliedAt: _parseDate(json["admin_replied_at"]),
      images: rawImages
          .whereType<Map>()
          .map((e) => imageFromJson(e.cast<String, dynamic>()))
          .toList(),
    );
  }

  static EvaluatePage pageFromJson(Map<String, dynamic> json) {
    final rawItems = (json["items"] as List?) ?? const [];
    final rawMeta = json["meta"];
    final meta = rawMeta is Map
        ? rawMeta.cast<String, dynamic>()
        : const <String, dynamic>{};

    return EvaluatePage(
      items: rawItems
          .whereType<Map>()
          .map((e) => fromJson(e.cast<String, dynamic>()))
          .toList(),
      page: (meta["page"] ?? 1) as int,
      perPage: (meta["per_page"] ?? 10) as int,
      total: (meta["total"] ?? 0) as int,
      totalPages: (meta["total_pages"] ?? 0) as int,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is! String) return null;
    return DateTime.tryParse(value);
  }
}
