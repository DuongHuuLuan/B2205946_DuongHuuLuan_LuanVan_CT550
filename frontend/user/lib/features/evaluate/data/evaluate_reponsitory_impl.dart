import 'package:b2205946_duonghuuluan_luanvan/core/network/error_handler.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/evaluate/data/evaluate_api.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/evaluate/data/models/evaluate_mapper.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/evaluate/domain/evaluate.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/evaluate/domain/evaluate_reponsitory.dart';
import 'package:dio/dio.dart';

class EvaluateRepositoryImpl implements EvaluateRepository {
  final EvaluateApi _api;
  EvaluateRepositoryImpl(this._api);

  Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return raw.cast<String, dynamic>();
    return const {};
  }

  @override
  Future<EvaluatePage> getMyEvaluates({int page = 1, int perPage = 8}) async {
    try {
      final response = await _api.getMyEvaluates(page: page, perPage: perPage);
      return EvaluateMapper.pageFromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<EvaluateItem> getEvaluateDetail(int evaluateId) async {
    try {
      final response = await _api.getEvaluateDetail(evaluateId);
      return EvaluateMapper.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<EvaluateItem?> getEvaluateByOrder(int orderId) async {
    try {
      final response = await _api.getEvaluateByOrder(orderId);
      return EvaluateMapper.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<EvaluateItem> createEvaluate({
    required int orderId,
    required int rate,
    String? content,
    List<String> imagePaths = const [],
  }) async {
    try {
      final response = await _api.createEvaluate(
        orderId: orderId,
        rate: rate,
        content: content,
        imagePaths: imagePaths,
      );
      return EvaluateMapper.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}
