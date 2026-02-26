import 'package:b2205946_duonghuuluan_luanvan/features/evaluate/domain/evaluate.dart';

abstract class EvaluateRepository {
  Future<EvaluatePage> getMyEvaluates({int page = 1, int perPage = 8});
  Future<ProductEvaluatePage> getProductEvaluates({
    required int productId,
    int page = 1,
    int perPage = 3,
  });
  Future<EvaluateItem> getEvaluateDetail(int evaluateId);
  Future<EvaluateItem?> getEvaluateByOrder(int orderId);
  Future<EvaluateItem> createEvaluate({
    required int orderId,
    required int rate,
    String? content,
    List<String> imagePaths = const [],
  });
}
