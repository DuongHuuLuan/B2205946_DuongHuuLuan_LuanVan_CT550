import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _accessTokenKey = "access_token";
  static const _lastRouteKey = "last_route";
  static const _pushTokenKey = "push_token";

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  Future<void> deleteAccessToken() async {
    await _storage.delete(key: _accessTokenKey);
  }

  Future<void> saveLastRoute(String route) async {
    await _storage.write(key: _lastRouteKey, value: route);
  }

  Future<String?> getLastRoute() async {
    return await _storage.read(key: _lastRouteKey);
  }

  Future<void> deleteLastRoute() async {
    await _storage.delete(key: _lastRouteKey);
  }

  Future<void> savePushToken(String token) async {
    await _storage.write(key: _pushTokenKey, value: token);
  }

  Future<String?> getPushToken() async {
    return await _storage.read(key: _pushTokenKey);
  }

  Future<void> deletePushToken() async {
    await _storage.delete(key: _pushTokenKey);
  }
}
