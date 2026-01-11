import 'package:b2205946_duonghuuluan_luanvan/features/auth/domain/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/auth/domain/user.dart';
// import 'package:b2205946_duonghuuluan_luanvan/core/storage/secure_storage.dart';

class AuthViewmodel extends ChangeNotifier {
  User? _user;
  bool _isInitialized = false; // biển kiếm soát trạng thái nạp dữ liệu
  // final SecureStorage _storage = SecureStorage();
  final AuthRepository _repository;

  AuthViewmodel(this._repository) {
    _initAuth();
  }

  User? get user => _user;
  // kiểm tra xem người dùng đã đăn nhập chưa
  bool get isAuthenticated => _user != null;
  bool get isInitialized => _isInitialized;

  // hàm khởi tạo kiểm tra trạng thía đăng nhập từ ổ cứng
  Future<void> _initAuth() async {
    try {
      debugPrint("AuthViewModel: bắt đầu khởi động");
      final hasToken = await _repository.checkAuthStatus();
      debugPrint("AuthViewModel: hasToken=$hasToken");

      if (hasToken) {
        try {
          _user = await _repository.getMe();
          debugPrint(
            "AuthViewModel: phiên đăng nhập đã được khôi phục cho ${_user?.username}",
          );
        } catch (e) {
          await logout();
          debugPrint("AuthViewModel: phiên đăng nhập đã hết hạn");
        }
      }
    } catch (e) {
      debugPrint("AuthViewModel: lỗi khởi tạo $e");
    } finally {
      _isInitialized = true;
      notifyListeners();
      debugPrint("AuthViewModel: khởi tạo hoàn thành");
    }
  }

  // cập nhật thông tin user sau khi login thành công
  void setAuth(User user) {
    _user = user;
    _isInitialized = true;
    notifyListeners();
  }

  //logout - xóa token và trạng thái user
  Future<void> logout() async {
    await _repository.logout();
    _user = null;
    notifyListeners();
  }
}
