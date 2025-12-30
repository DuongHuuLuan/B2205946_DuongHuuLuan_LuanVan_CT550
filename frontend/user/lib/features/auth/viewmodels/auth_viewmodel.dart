import 'package:flutter/material.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/auth/domain/user.dart';
import 'package:b2205946_duonghuuluan_luanvan/core/storage/secure_storage.dart';

class AuthViewmodel extends ChangeNotifier {
  User? _user;
  final SecureStorage _storage = SecureStorage();

  User? get user => _user;
  // kiểm tra xem người dùng đã đăn nhập chưa
  bool get isAuthenticated => _user != null;

  // cập nhật thông tin user sau khi login thành công
  void setAuth(User user) {
    _user = user;
    notifyListeners();
  }

  //logout - xóa token và trạng thái user
  Future<void> logout() async {
    await _storage.deleteAccessToken();
    _user = null;
    notifyListeners();
  }
}
