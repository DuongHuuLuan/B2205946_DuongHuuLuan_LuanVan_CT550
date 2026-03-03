import 'package:b2205946_duonghuuluan_luanvan/core/constants/app_constants.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/evaluate/domain/evaluate.dart';

class EvaluateMapper {
  static EvaluateImage imageFromJson(Map<String, dynamic> json) {
    final rawUrl = (json["image_url"] ?? "").toString();
    return EvaluateImage(
      id: _toInt(json["id"]),
      imageUrl: _resolveUrl(rawUrl),
      sortOrder: json["sort_order"] == null ? null : _toInt(json["sort_order"]),
    );
  }

  static EvaluateItem fromJson(Map<String, dynamic> json) {
    final rawImages = (json["images"] as List?) ?? const [];
    final rawMatchedVariants = (json["matched_variants"] as List?) ?? const [];
    return EvaluateItem(
      id: _toInt(json["id"]),
      orderId: _toInt(json["order_id"]),
      userId: _toInt(json["user_id"]),
      rate: _toInt(json["rate"]),
      content: json["content"] as String?,
      adminReply: json["admin_reply"] as String?,
      createdAt: _parseDate(json["created_at"]),
      updatedAt: _parseDate(json["updated_at"]),
      adminRepliedAt: _parseDate(json["admin_replied_at"]),
      images: rawImages
          .whereType<Map>()
          .map((e) => imageFromJson(e.cast<String, dynamic>()))
          .toList(),
      evaluaterName: json["evaluater_name"] as String?,
      evaluaterNameMasked: json["evaluater_name_masked"] as String?,
      matchedVariants: rawMatchedVariants.map((e) => e.toString()).toList(),
      hasImages: _toBool(json["has_images"]),
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
      page: _toInt(meta["page"], defaultValue: 1),
      perPage: _toInt(meta["per_page"], defaultValue: 10),
      total: _toInt(meta["total"]),
      totalPages: _toInt(meta["total_pages"]),
    );
  }

  static ProductEvaluatePage productPageFromJson(Map<String, dynamic> json) {
    final rawItems = (json["items"] as List?) ?? const [];
    final rawMeta = json["meta"];
    final meta = rawMeta is Map
        ? rawMeta.cast<String, dynamic>()
        : const <String, dynamic>{};
    final rawSummary = json["summary"];
    final summary = rawSummary is Map
        ? rawSummary.cast<String, dynamic>()
        : const <String, dynamic>{};
    final rawRateCounts = (summary["rate_counts"] as List?) ?? const [];

    final totalFromMeta = _toInt(meta["total"]);
    final totalEvaluates = _toInt(
      summary["total_evaluates"],
      defaultValue: totalFromMeta,
    );
    return ProductEvaluatePage(
      summary: ProductEvaluateSummary(
        productId: _toInt(summary["product_id"]),
        averageRate: _toDouble(summary["average_rate"]),
        totalEvaluates: totalEvaluates,
        totalWithImages: _toInt(summary["total_with_images"]),
        summaryText: summary["summary_text"] as String?,
        rateCounts: rawRateCounts
            .whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .map(
              (e) => EvaluateRateCount(
                star: _toInt(e["star"]),
                count: _toInt(e["count"]),
              ),
            )
            .toList(),
      ),
      items: rawItems
          .whereType<Map>()
          .map((e) => fromJson(e.cast<String, dynamic>()))
          .toList(),
      page: _toInt(meta["page"], defaultValue: 1),
      perPage: _toInt(meta["per_page"], defaultValue: 10),
      total: _toInt(meta["total"]),
      totalPages: _toInt(meta["total_pages"]),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is String) return DateTime.tryParse(value);
    return DateTime.tryParse(value.toString());
  }

  static String _resolveUrl(String raw) {
    if (raw.isEmpty) return raw;
    if (raw.startsWith("http://") || raw.startsWith("https://")) return raw;
    final base = AppConstants.baseUrl.replaceAll(RegExp(r"/+$"), "");
    return "$base${raw.startsWith("/") ? "" : "/"}$raw";
  }

  static int _toInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  static double _toDouble(dynamic value, {double defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  static bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == "true" || normalized == "1";
    }
    return false;
  }
}
