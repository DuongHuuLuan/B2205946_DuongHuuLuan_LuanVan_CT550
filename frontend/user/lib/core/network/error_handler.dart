import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});
}

class ErrorHandler {
  static ApiException handle(DioException error) {
    if (error.response != null) {
      return ApiException(
        error.response?.data["message"] ?? "Lỗi server",
        statusCode: error.response?.statusCode,
      );
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return ApiException("Kết nối quá thời gian");

      case DioExceptionType.receiveTimeout:
        return ApiException("Server không phản hồi");

      default:
        return ApiException("Lỗi không xác định");
    }
  }
}
