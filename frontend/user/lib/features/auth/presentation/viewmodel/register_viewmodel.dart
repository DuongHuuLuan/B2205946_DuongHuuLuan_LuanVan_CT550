import 'package:flutter/material.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/auth/domain/auth_repository.dart';

class RegisterViewmodel extends ChangeNotifier {
  final AuthRepository _repository;
  RegisterViewmodel(this._repository);

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> register({
    required String email,
    required String username,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = {"email": email, "username": username, "password": password};
      await _repository.register(data);
      _isLoading = false;
      notifyListeners();
      return true; // đăng ký thành công
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false; // đăng ký thất bại
    }
  }
}
