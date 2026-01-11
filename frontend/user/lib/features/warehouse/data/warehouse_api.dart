import 'package:dio/dio.dart';
import 'package:b2205946_duonghuuluan_luanvan/core/constants/api_endpoints.dart';
import 'package:b2205946_duonghuuluan_luanvan/core/network/dio_client.dart';
import 'package:b2205946_duonghuuluan_luanvan/core/network/error_handler.dart';

class WarehouseApi {
  Future<Response> getTotalStock({
    required int productId,
    required int colorId,
    required int sizeId,
  }) async {
    try {
      return await DioClient.instance.get(
        ApiEndpoints.warehouseTotalStock,
        queryParameters: {
          "product_id": productId,
          "color_id": colorId,
          "size_id": sizeId,
        },
      );
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}
