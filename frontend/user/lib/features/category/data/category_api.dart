import 'package:b2205946_duonghuuluan_luanvan/core/constants/api_endpoints.dart';
import 'package:b2205946_duonghuuluan_luanvan/core/network/dio_client.dart';
import 'package:b2205946_duonghuuluan_luanvan/core/network/error_handler.dart';
import 'package:dio/dio.dart';

class CategoryApi {
  Future<Response> getAll() async {
    try {
      return await DioClient.instance.get(ApiEndpoints.category);
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<Response> getById(String id) async {
    try {
      return await DioClient.instance.get("${ApiEndpoints.category}/$id");
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}
