import 'package:b2205946_duonghuuluan_luanvan/core/network/dio_client.dart';
import 'package:b2205946_duonghuuluan_luanvan/core/constants/api_endpoints.dart';
import 'package:b2205946_duonghuuluan_luanvan/core/network/error_handler.dart';
import 'package:dio/dio.dart';

class ProductApi {
  Future<Response> getAllProduct({
    int? categoryId,
    int? page,
    int? perPage,
  }) async {
    try {
      final params = <String, dynamic>{};
      if (page != null) {
        params["page"] = page;
      }
      if (perPage != null) {
        params["per_page"] = perPage;
      }

      if (categoryId != null) {
        return await DioClient.instance.get(
          ApiEndpoints.productsByCategory(categoryId),
          queryParameters: params.isEmpty ? null : params,
        );
      }

      return await DioClient.instance.get(
        ApiEndpoints.products,
        queryParameters: params.isEmpty ? null : params,
      );
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<Response> productDetail(int id) async {
    try {
      return await DioClient.instance.get(ApiEndpoints.productDetail(id));
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}
