import 'package:flutter/material.dart';
import '../core/enums/user_role.dart';
import '../core/services/secure_storage_service.dart';
import '../api_service.dart';

class AuthProvider extends ChangeNotifier {
  final SecureStorageService _storage = SecureStorageService();
  
  Map<String, dynamic>? _currentUser;
  bool _isAuthenticated = false;
  bool _isGuest = false;
  bool _isLoading = true;
  String? _token;

  Map<String, dynamic>? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isGuest => _isGuest;
  bool get isLoading => _isLoading;
  String? get token => _token;
  
  UserRole? get role {
    if (_currentUser == null || _currentUser!['role'] == null) return null;
    return UserRole.fromString(_currentUser!['role']);
  }

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();
    
    _token = await _storage.getToken();
    _isGuest = await _storage.isGuestMode();
    _currentUser = await _storage.getUserData();
    
    if (_token != null && _currentUser != null) {
      _isAuthenticated = true;
      _isGuest = false;
    } else if (_isGuest) {
      _isAuthenticated = false;
    } else {
      _isAuthenticated = false;
      _isGuest = false;
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> login(String email, String password, {bool rememberMe = false}) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final response = await ApiService.login(email, password);
      _token = response['token'];
      _currentUser = response['user'];
      _isAuthenticated = true;
      _isGuest = false;
      
      if (rememberMe) {
        await ApiService.saveUserSession(email);
      } else {
        await _storage.saveRememberedEmail('');
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signup({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phone,
  }) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final response = await ApiService.signup(
        name: name,
        email: email,
        password: password,
        role: role,
        phone: phone,
      );
      _token = response['token'];
      _currentUser = response['user'];
      _isAuthenticated = true;
      _isGuest = false;
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> continueAsGuest() async {
    await ApiService.setGuestMode();
    _isGuest = true;
    _isAuthenticated = false;
    _currentUser = null;
    _token = null;
    notifyListeners();
  }

  Future<void> logout() async {
    await ApiService.logout();
    _isAuthenticated = false;
    _isGuest = false;
    _currentUser = null;
    _token = null;
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    try {
      final data = await ApiService.getProfile();
      _currentUser = data['user'];
      await _storage.saveUserData(_currentUser!);
      notifyListeners();
    } catch (_) {}
  }

  void handleUnauthorized() {
    logout();
  }
}
