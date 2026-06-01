import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _tokenKey = 'auth_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userKey = 'user_data';
  static const _roleKey = 'user_role';
  static const _guestKey = 'guest_mode';
  static const _rememberedEmailKey = 'remembered_email';

  final FlutterSecureStorage _storage;

  SecureStorageService()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
        );

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  Future<void> saveUserData(Map<String, dynamic> user) async {
    await _storage.write(key: _userKey, value: jsonEncode(user));
    if (user['role'] != null) {
      await _storage.write(key: _roleKey, value: user['role']);
    }
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final data = await _storage.read(key: _userKey);
    if (data == null) return null;
    return jsonDecode(data) as Map<String, dynamic>;
  }

  Future<String?> getRole() async {
    return await _storage.read(key: _roleKey);
  }

  Future<bool> hasToken() async {
    final token = await _storage.read(key: _tokenKey);
    return token != null && token.isNotEmpty;
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  Future<void> saveGuestMode(bool isGuest) async {
    await _storage.write(key: _guestKey, value: isGuest.toString());
  }

  Future<bool> isGuestMode() async {
    final value = await _storage.read(key: _guestKey);
    return value == 'true';
  }

  Future<void> saveRememberedEmail(String email) async {
    await _storage.write(key: _rememberedEmailKey, value: email);
  }

  Future<String?> getRememberedEmail() async {
    return await _storage.read(key: _rememberedEmailKey);
  }
}
