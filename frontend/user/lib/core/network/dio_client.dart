import 'package:dio/dio.dart';
import 'package:b2205946_duonghuuluan_luanvan/core/constants/app_constants.dart';
import 'package:b2205946_duonghuuluan_luanvan/core/network/auth_interceptor.dart';
// import 'package:b2205946_duonghuuluan_luanvan/core/network/error_handler.dart';

class DioClient {
  static Dio? _dio;

  static Dio get instance {
    final baseUrl = AppConstants.baseUrl;
    final headers = <String, dynamic>{'Content-Type': 'application/json'};
    if (baseUrl.contains("ngrok-free.app")) {
      headers["ngrok-skip-browser-warning"] = "69420";
    }

    _dio ??=
        Dio(
            BaseOptions(
              baseUrl: baseUrl,
              connectTimeout: AppConstants.connectTimeout,
              receiveTimeout: AppConstants.receiveTimeout,
              headers: headers,
            ),
          )
          ..interceptors.add(AuthInterceptor())
          ..interceptors.add(
            LogInterceptor(requestBody: true, responseBody: true),
          );

    return _dio!;
  }
}
