class EvaluateImage {
  final int id;
  final String imageUrl;
  final int? sortOrder;

  const EvaluateImage({
    required this.id,
    required this.imageUrl,
    this.sortOrder,
  });
}

class EvaluateItem {
  final int id;
  final int orderId;
  final int userId;
  final int rate;
  final String? content;
  final String? adminReply;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? adminRepliedAt;
  final List<EvaluateImage> images;

  const EvaluateItem({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.rate,
    this.content,
    this.adminReply,
    this.createdAt,
    this.updatedAt,
    this.adminRepliedAt,
    this.images = const [],
  });
}

class EvaluatePage {
  final List<EvaluateItem> items;
  final int page;
  final int perPage;
  final int total;
  final int totalPages;

  const EvaluatePage({
    required this.items,
    required this.page,
    required this.perPage,
    required this.total,
    required this.totalPages,
  });

  bool get hasNextPage => page < totalPages;
}
