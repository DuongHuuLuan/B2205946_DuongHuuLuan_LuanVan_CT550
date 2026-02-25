import 'package:b2205946_duonghuuluan_luanvan/core/constants/api_endpoints.dart';
import 'package:b2205946_duonghuuluan_luanvan/core/network/dio_client.dart';
import 'package:b2205946_duonghuuluan_luanvan/core/network/error_handler.dart';
import 'dart:io';
import 'package:dio/dio.dart';

class EvaluateApi {
  Future<Response> getMyEvaluates({int page = 1, int perPage = 8}) async {
    try {
      return await DioClient.instance.get(
        ApiEndpoints.evaluatesUser,
        queryParameters: {"page": page, "per_page": perPage},
      );
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<Response> getEvaluateDetail(int evaluateId) async {
    try {
      return await DioClient.instance.get(
        ApiEndpoints.evaluateDetail(evaluateId),
      );
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<Response> getEvaluateByOrder(int orderId) {
    return DioClient.instance.get(ApiEndpoints.evaluateByOrder(orderId));
  }

  Future<Response> createEvaluate({
    required int orderId,
    required int rate,
    String? content,
    List<String> imagePaths = const [],
  }) async {
    try {
      final files = <MultipartFile>[];
      for (final path in imagePaths) {
        final filename = path.split(Platform.pathSeparator).last;
        files.add(await MultipartFile.fromFile(path, filename: filename));
      }

      final payload = <String, dynamic>{"rate": rate};

      if ((content ?? "").trim().isNotEmpty) {
        payload["content"] = content!.trim();
      }

      if (files.isNotEmpty) {
        payload["images"] = files;
      }

      final formData = FormData.fromMap(payload);

      return await DioClient.instance.post(
        ApiEndpoints.createEvaluate(orderId),
        data: formData,
      );
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}
