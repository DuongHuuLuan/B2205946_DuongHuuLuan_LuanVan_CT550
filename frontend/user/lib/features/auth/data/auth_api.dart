import 'package:b2205946_duonghuuluan_luanvan/core/network/dio_client.dart';
import 'package:b2205946_duonghuuluan_luanvan/core/network/error_handler.dart';
import 'package:dio/dio.dart';

class AuthApi {
  Future<Response> login(String email, String password) {
    try {
      return DioClient.instance.post(
        "/auth/login",
        data: {"username": email, "password": password},
        options: Options(
          contentType: Headers
              .formUrlEncodedContentType, // QUAN TRỌNG: Chuyển sang Form Data
        ),
      );
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<Response> register(Map<String, dynamic> data) {
    return DioClient.instance.post("/auth/register", data: data);
  }

  Future<Response> getMe() async {
    try {
      return await DioClient.instance.get("/auth/me");
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}
