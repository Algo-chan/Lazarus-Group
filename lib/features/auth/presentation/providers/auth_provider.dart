import 'package:flutter/foundation.dart';
import 'package:local_service_app/core/enums/user_role.dart';
import 'package:local_service_app/core/network/api_client.dart';
import 'package:local_service_app/features/auth/domain/entities/user_model.dart';
import 'package:local_service_app/features/auth/data/repositories/auth_repository.dart';

enum AuthStatus { uninitialized, authenticated, unauthenticated, loading }

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;

  AuthStatus _status = AuthStatus.uninitialized;
  UserModel? _user;
  UserRole? _role;
  String? _token;
  String? _error;

  AuthProvider({AuthRepository? authRepository})
      : _authRepository = authRepository ?? AuthRepository();

  AuthStatus get status => _status;
  UserModel? get user => _user;
  UserRole? get role => _role;
  String? get token => _token;
  String? get error => _error;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  bool get isAdmin => _role == UserRole.admin;
  bool get isProvider => _role == UserRole.provider;
  bool get isCustomer => _role == UserRole.customer;

  Future<void> initialize() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      final isLoggedIn = await _authRepository.isLoggedIn();
      if (!isLoggedIn) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return;
      }

      final result = await _authRepository.loadSession();
      _user = result.user;
      _token = result.token;
      _role = result.user.role;
      _status = AuthStatus.authenticated;
    } on ApiException {
      await _authRepository.logout();
      _status = AuthStatus.unauthenticated;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
    }

    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();

    try {
      final result = await _authRepository.login(email, password);
      _user = result.user;
      _token = result.token;
      _role = result.user.role;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'An unexpected error occurred';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signup({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? phone,
  }) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();

    try {
      final result = await _authRepository.signup(
        name: name,
        email: email,
        password: password,
        role: role,
        phone: phone,
      );
      _user = result.user;
      _token = result.token;
      _role = result.user.role;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'An unexpected error occurred';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    _user = null;
    _token = null;
    _role = null;
    _status = AuthStatus.unauthenticated;
    _error = null;
    notifyListeners();
  }

  Future<void> refreshSession() async {
    try {
      final result = await _authRepository.loadSession();
      _user = result.user;
      _token = result.token;
      _role = result.user.role;
      _status = AuthStatus.authenticated;
    } catch (_) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
