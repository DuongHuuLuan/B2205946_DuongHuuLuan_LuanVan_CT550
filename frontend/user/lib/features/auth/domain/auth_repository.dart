import 'package:b2205946_duonghuuluan_luanvan/features/auth/domain/user.dart';

abstract class AuthRepository {
  Future<User> login(String email, String password);

  Future<void> register(Map<String, dynamic> data);
  Future<User> getMe();
  Future<void> logout();
  // check xem có token trong may chưa (dùng cho auto-login)
  Future<bool> checkAuthStatus();
}
