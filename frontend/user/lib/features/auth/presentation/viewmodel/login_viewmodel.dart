import 'package:b2205946_duonghuuluan_luanvan/core/network/error_handler.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/auth/domain/auth_repository.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/auth/presentation/viewmodel/auth_viewmodel.dart';
import 'package:flutter/material.dart';

class LoginViewModel extends ChangeNotifier {
  final AuthRepository _repository;

  LoginViewModel(this._repository);

  bool _isLoadding = false;
  String _errorMessage = '';

  bool get isLoading => _isLoadding;
  String get errorMessage => _errorMessage;

  Future<bool> login(
    String email,
    String password,
    AuthViewmodel authState,
  ) async {
    _isLoadding = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final user = await _repository.login(email, password);
      authState.setAuth(user);
      _isLoadding = false;
      _errorMessage = '';
      notifyListeners();
      return true;
    } catch (error) {
      _isLoadding = false;
      _errorMessage = _mapLoginError(error);
      notifyListeners();
      return false;
    }
  }

  String _mapLoginError(Object error) {
    if (error is ApiException) {
      if (error.statusCode == 401) {
        return 'Sai email hoặc mật khẩu';
      }

      if (error.message.trim().isNotEmpty) {
        return error.message;
      }
    }

    return 'Đăng nhập thất bại. Vui lòng thử lại.';
  }
}
