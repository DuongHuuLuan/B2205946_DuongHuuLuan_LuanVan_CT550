import 'package:dio/dio.dart';
import 'package:b2205946_duonghuuluan_luanvan/core/storage/secure_storage.dart';

class AuthInterceptor extends Interceptor {
  final _storage = SecureStorage();

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // 1. Kiểm tra nếu là API login hoặc register thì không gắn token
    if (options.path.contains('/auth/login') ||
        options.path.contains('/auth/register')) {
      return handler.next(options); // Tiếp tục request mà không làm gì thêm
    }

    final token = await _storage.getAccessToken();

    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
      print("Interceptor : Đã gắn token vào Header");
    }

    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Nếu nhận lỗi 401 (Unauthorized), bạn có thể xử lý logout tại đây
    if (err.response?.statusCode == 401) {
      print(
        "Interceptor: Token hết hạn hoặc không hợp lệ, yêu cầu đăng nhập lại.",
      );
    }
    return handler.next(err);
  }
}
