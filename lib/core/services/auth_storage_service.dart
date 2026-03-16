import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthStorageService {
  static const _keyEmail = 'auth_email';
  static const _keyRememberMe = 'auth_remember_me';
  static const _keyPassword = 'auth_password';

  final FlutterSecureStorage _secureStorage;

  AuthStorageService({FlutterSecureStorage? secureStorage}) : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  // -------------------------
  // SAVE
  // -------------------------
  Future<void> saveCredentials({required String email, required String password}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyEmail, email);
    await prefs.setBool(_keyRememberMe, true);
    await _secureStorage.write(key: _keyPassword, value: password);
  }

  // -------------------------
  // GETTERS
  // -------------------------
  Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyEmail);
  }

  Future<bool> rememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyRememberMe) ?? false;
  }

  Future<String?> getPassword() {
    return _secureStorage.read(key: _keyPassword);
  }

  // -------------------------
  // CLEAR
  // -------------------------
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyRememberMe);
    await _secureStorage.delete(key: _keyPassword);
  }
}
