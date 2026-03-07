import 'package:b2205946_duonghuuluan_luanvan/core/constants/api_endpoints.dart';
import 'package:b2205946_duonghuuluan_luanvan/core/network/dio_client.dart';
import 'package:b2205946_duonghuuluan_luanvan/core/network/error_handler.dart';
import 'package:dio/dio.dart';

class PushNotificationApi {
  Future<void> registerDevice({
    required String platform,
    required String pushToken,
  }) async {
    try {
      await DioClient.instance.post(
        ApiEndpoints.pushDevices,
        data: {
          "platform": platform,
          "push_token": pushToken,
        },
      );
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<void> deactivateDevice(String pushToken) async {
    try {
      await DioClient.instance.delete(
        ApiEndpoints.pushDevices,
        queryParameters: {
          "push_token": pushToken,
        },
      );
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}
