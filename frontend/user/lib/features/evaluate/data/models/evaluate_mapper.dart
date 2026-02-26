import 'package:b2205946_duonghuuluan_luanvan/core/constants/app_constants.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/evaluate/domain/evaluate.dart';

class EvaluateMapper {
  static EvaluateImage imageFromJson(Map<String, dynamic> json) {
    final rawUrl = (json["image_url"] ?? "") as String;
    return EvaluateImage(
      id: (json["id"] ?? 0) as int,
      imageUrl: _resolveUrl(rawUrl),
      sortOrder: json["sort_order"] as int?,
    );
  }

  static EvaluateItem fromJson(Map<String, dynamic> json) {
    final rawImages = (json["images"] as List?) ?? const [];
    final rawMatchedVariants = (json["matched_variants"] as List?) ?? const [];
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
      reviewerName: json["reviewer_name"] as String?,
      reviewerNameMasked: json["reviewer_name_masked"] as String?,
      matchedVariants: rawMatchedVariants.map((e) => e.toString()).toList(),
      hasImages: (json["has_images"] ?? false) == true,
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

    return ProductEvaluatePage(
      summary: ProductEvaluateSummary(
        productId: (summary["product_id"] ?? 0) as int,
        averageRate: ((summary["average_rate"] ?? 0) as num).toDouble(),
        totalReviews: (summary["total_reviews"] ?? 0) as int,
        totalWithImages: (summary["total_with_images"] ?? 0) as int,
        summaryText: summary["summary_text"] as String?,
        rateCounts: rawRateCounts
            .whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .map(
              (e) => EvaluateRateCount(
                star: (e["star"] ?? 0) as int,
                count: (e["count"] ?? 0) as int,
              ),
            )
            .toList(),
      ),
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

  static String _resolveUrl(String raw) {
    if (raw.isEmpty) return raw;
    if (raw.startsWith("http://") || raw.startsWith("https://")) return raw;
    final base = AppConstants.baseUrl.replaceAll(RegExp(r"/+$"), "");
    return "$base${raw.startsWith("/") ? "" : "/"}$raw";
  }
}
