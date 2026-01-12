import 'package:b2205946_duonghuuluan_luanvan/core/constants/api_endpoints.dart';
import 'package:b2205946_duonghuuluan_luanvan/core/network/dio_client.dart';
import 'package:b2205946_duonghuuluan_luanvan/core/network/error_handler.dart';
import 'package:dio/dio.dart';

class DiscountApi {
  Future<Response> getDiscountsForCart({required List<int> categoryIds}) async {
    try {
      return await DioClient.instance.get(
        ApiEndpoints.discountCart,
        queryParameters: {"category_ids": categoryIds},
      );
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}
