import 'package:b2205946_duonghuuluan_luanvan/core/network/dio_client.dart';
import 'package:b2205946_duonghuuluan_luanvan/core/constants/api_endpoints.dart';
import 'package:b2205946_duonghuuluan_luanvan/core/network/error_handler.dart';
import 'package:dio/dio.dart';

class ProductApi {
  Future<Response> getAllProduct({int? categoryId}) async {
    try {
      return await DioClient.instance.get(
        ApiEndpoints.products,
        queryParameters: {if (categoryId != null) "category_id": categoryId},
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

