import 'package:dio/dio.dart';
import 'package:b2205946_duonghuuluan_luanvan/core/constants/app_constants.dart';
import 'package:b2205946_duonghuuluan_luanvan/core/network/auth_interceptor.dart';
import 'package:b2205946_duonghuuluan_luanvan/core/network/error_handler.dart';

class DioClient {
  static Dio? _dio;

  static Dio get instance {
    _dio ??=
        Dio(
            BaseOptions(
              baseUrl: AppConstants.baseUrl,
              connectTimeout: AppConstants.connectTimeout,
              receiveTimeout: AppConstants.receiveTimeout,
              headers: {'Content-Type': 'application/json'},
            ),
          )
          ..interceptors.add(AuthInterceptor())
          ..interceptors.add(
            LogInterceptor(requestBody: true, responseBody: true),
          );

    return _dio!;
  }
}
