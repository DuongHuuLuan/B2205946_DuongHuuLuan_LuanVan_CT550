import 'package:b2205946_duonghuuluan_luanvan/core/constants/api_endpoints.dart';
import 'package:b2205946_duonghuuluan_luanvan/core/network/dio_client.dart';
import 'package:b2205946_duonghuuluan_luanvan/core/network/error_handler.dart';
import 'package:dio/dio.dart';

class CartApi {
  Future<Response> getCart() async {
    try {
      return await DioClient.instance.get(ApiEndpoints.cart);
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<Response> addCartDetail({
    required int productDetailId,
    int quantity = 1,
  }) async {
    try {
      return await DioClient.instance.post(
        ApiEndpoints.cartDetails,
        data: {"product_detail_id": productDetailId, "quantity": quantity},
      );
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<Response> updateCartDetail({
    required int cartDetailId,
    required int newQuantity,
  }) async {
    try {
      return await DioClient.instance.put(
        ApiEndpoints.cartDetail(cartDetailId),
        queryParameters: {"new_quantity": newQuantity},
      );
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<Response> deleteCartDetail({required int cartDetailId}) async {
    try {
      return await DioClient.instance.delete(
        ApiEndpoints.cartDetail(cartDetailId),
      );
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}
