import 'package:b2205946_duonghuuluan_luanvan/features/auth/domain/auth_repository.dart';
import 'package:dio/dio.dart';
import 'auth_api.dart';
import 'model/user_mapper.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/auth/domain/user.dart';
import 'package:b2205946_duonghuuluan_luanvan/core/storage/secure_storage.dart';
import 'package:b2205946_duonghuuluan_luanvan/core/network/error_handler.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthApi _authApi;
  final SecureStorage _storage = SecureStorage();

  AuthRepositoryImpl(this._authApi);

  @override
  Future<User> login(String email, String password) async {
    try {
      final response = await _authApi.login(email, password);

      // lấy dữ liệu từ reponse
      final String token = response.data["access_token"];
      final userJson = response.data["user"];

      //lưu token vào Secure Storage
      await _storage.saveAccessToken(token);

      // chuyển từ JSON sangg UserModel (Data) rồi trả về User (Domain)
      return UserMapper.fromJson(userJson);
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<void> register(Map<String, dynamic> data) async {
    try {
      await _authApi.register(data);
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<bool> checkAuthStatus() async {
    final token = await _storage.getAccessToken();
    return token != null;
  }

  @override
  Future<User> getMe() async {
    try {
      final response = await _authApi.getMe();
      // chuyển đổi User nhận được thành User domain model
      return UserMapper.fromJson(response.data);
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _storage.deleteAccessToken();

      print("AuthRepository: Đã xóa token, người dùng đã đăng xuất.");
    } catch (e) {
      throw Exception("Lỗi khi đăng xuất , $e");
    }
  }
}
