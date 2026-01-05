import 'package:b2205946_duonghuuluan_luanvan/features/auth/domain/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/auth/presentation/viewmodel/auth_viewmodel.dart';

class LoginViewModel extends ChangeNotifier {
  final AuthRepository _repository;
  LoginViewModel(this._repository);

  bool _isLoadding = false;
  String _errorMessage = "";
  bool get isLoading => _isLoadding;
  String get errorMessage => _errorMessage;

  Future<bool> login(
    String email,
    String password,
    AuthViewmodel authState,
  ) async {
    _isLoadding = true;
    notifyListeners();

    try {
      final user = await _repository.login(email, password);

      authState.setAuth(user);
      _isLoadding = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoadding = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
