import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ErrorHandler {
  static ApiException handle(DioException error) {
    if (error.response != null) {
      return ApiException(
        _extractMessage(error.response?.data),
        statusCode: error.response?.statusCode,
      );
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
        return ApiException('Kết nối quá thời gian');
      case DioExceptionType.receiveTimeout:
        return ApiException('Server không phản hồi');
      case DioExceptionType.connectionError:
        return ApiException('Không thể kết nối đến máy chủ');
      case DioExceptionType.cancel:
        return ApiException('Yêu cầu đã bị hủy');
      default:
        return ApiException('Lỗi không xác định');
    }
  }

  static String _extractMessage(dynamic data) {
    if (data is Map) {
      final dynamic rawMessage =
          data['message'] ?? data['detail'] ?? data['error'];

      if (rawMessage is String && rawMessage.trim().isNotEmpty) {
        return rawMessage.trim();
      }

      if (rawMessage is List && rawMessage.isNotEmpty) {
        final firstItem = rawMessage.first;

        if (firstItem is String && firstItem.trim().isNotEmpty) {
          return firstItem.trim();
        }

        if (firstItem is Map &&
            firstItem['msg'] is String &&
            (firstItem['msg'] as String).trim().isNotEmpty) {
          return (firstItem['msg'] as String).trim();
        }
      }
    }

    if (data is String && data.trim().isNotEmpty) {
      return data.trim();
    }

    return 'Lỗi server';
  }
}
