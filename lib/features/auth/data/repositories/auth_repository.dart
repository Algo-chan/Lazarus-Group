import 'package:local_service_app/core/enums/user_role.dart';
import 'package:local_service_app/core/network/api_client.dart';
import 'package:local_service_app/core/constants/api_constants.dart';
import 'package:local_service_app/core/services/secure_storage_service.dart';
import 'package:local_service_app/features/auth/domain/entities/user_model.dart';

class AuthRepository {
  final ApiClient _apiClient;
  final SecureStorageService _storage;

  AuthRepository({
    ApiClient? apiClient,
    SecureStorageService? storage,
  })  : _apiClient = apiClient ?? ApiClient(),
        _storage = storage ?? SecureStorageService();

  Future<AuthResult> login(String email, String password) async {
    final data = await _apiClient.post(
      ApiConstants.login,
      body: {'email': email, 'password': password},
      withAuth: false,
    );

    final token = data['token'] as String;
    final refreshToken = data['refresh_token'] as String?;
    final userJson = data['user'] as Map<String, dynamic>;

    await _storage.saveToken(token);
    if (refreshToken != null) {
      await _storage.saveRefreshToken(refreshToken);
    }
    await _storage.saveUserData(userJson);

    final user = UserModel.fromJson(userJson);
    return AuthResult(user: user, token: token);
  }

  Future<AuthResult> signup({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? phone,
  }) async {
    final data = await _apiClient.post(
      ApiConstants.signup,
      body: {
        'name': name,
        'email': email,
        'password': password,
        'role': role.value,
        if (phone != null) 'phone': phone,
      },
      withAuth: false,
    );

    final token = data['token'] as String;
    final refreshToken = data['refresh_token'] as String?;
    final userJson = data['user'] as Map<String, dynamic>;

    await _storage.saveToken(token);
    if (refreshToken != null) {
      await _storage.saveRefreshToken(refreshToken);
    }
    await _storage.saveUserData(userJson);

    final user = UserModel.fromJson(userJson);
    return AuthResult(user: user, token: token);
  }

  Future<AuthResult> loadSession() async {
    final hasToken = await _storage.hasToken();
    if (!hasToken) {
      throw ApiException('No saved session');
    }

    final data = await _apiClient.get(ApiConstants.me);
    final userJson = data['user'] as Map<String, dynamic>;
    await _storage.saveUserData(userJson);

    final token = await _storage.getToken();
    final user = UserModel.fromJson(userJson);
    return AuthResult(user: user, token: token ?? '');
  }

  Future<void> logout() async {
    await _storage.clearAll();
  }

  Future<bool> isLoggedIn() async {
    return await _storage.hasToken();
  }

  Future<UserRole?> getSavedRole() async {
    final role = await _storage.getRole();
    if (role == null) return null;
    return UserRole.fromString(role);
  }
}

class AuthResult {
  final UserModel user;
  final String token;

  AuthResult({required this.user, required this.token});
}
