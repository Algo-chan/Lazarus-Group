import 'package:flutter/foundation.dart';
import 'package:local_service_app/core/constants/api_constants.dart';
import 'package:local_service_app/core/network/api_client.dart';
import 'package:local_service_app/core/services/secure_storage_service.dart';

class ApiService {
  static final ApiClient _client = ApiClient();
  static final SecureStorageService _storage = SecureStorageService();

  // AUTH
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final data = await _client.post(
      ApiConstants.login,
      body: {'email': email, 'password': password},
      withAuth: false,
    );
    await _persistSession(data);
    return data;
  }

  static Future<Map<String, dynamic>> signup({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phone,
  }) async {
    final data = await _client.post(
      ApiConstants.signup,
      body: {
        'name': name,
        'email': email,
        'password': password,
        'role': role,
        if (phone != null) 'phone': phone,
      },
      withAuth: false,
    );
    await _persistSession(data);
    return data;
  }

  static Future<Map<String, dynamic>> getProfile() async {
    return await _client.get(ApiConstants.me);
  }

  static Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    return await _client.put(ApiConstants.updateProfile, body: data);
  }

  static Future<void> _persistSession(Map<String, dynamic> data) async {
    final token = data['token'] as String?;
    final refreshToken = data['refresh_token'] as String?;
    final user = data['user'] as Map<String, dynamic>?;
    if (token != null) {
      await _storage.saveToken(token);
    }
    if (refreshToken != null) {
      await _storage.saveRefreshToken(refreshToken);
    }
    if (user != null) {
      await _storage.saveUserData(user);
    }
    await _storage.saveGuestMode(false);
  }

  static Future<void> setGuestMode() async {
    await _storage.clearAll();
    await _storage.saveGuestMode(true);
  }

  static Future<void> logout() async {
    await _storage.clearAll();
  }

  // SERVICES
  static Future<List<dynamic>> getServices({String? query, String? category, String? location, String? provider_id, int page = 1}) async {
    try {
      final params = <String, String>{
        'page': page.toString(),
        'limit': '20',
      };
      if (query != null && query.isNotEmpty) params['query'] = query;
      if (category != null && category != 'All') params['category'] = category;
      if (location != null && location.isNotEmpty) params['location'] = location;
      if (provider_id != null && provider_id.isNotEmpty) params['provider_id'] = provider_id;
      
      final data = await _client.get(ApiConstants.services, queryParams: params);
      return data['services'] as List<dynamic>? ?? [];
    } catch (e) {
      debugPrint('ApiService: getServices fallback due to $e');
      if (page == 1) return mockServices;
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getServiceById(String id) async {
    try {
      final data = await _client.get('${ApiConstants.services}/$id');
      return data as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('ApiService: getServiceById fallback due to $e');
      return mockServices.firstWhere((s) => s['id'] == id || s['_id'] == id, orElse: () => mockServices.first);
    }
  }

  static Future<List<String>> getCategories() async {
    try {
      final data = await _client.get(ApiConstants.categories);
      if (data is List) {
        return ['All', ...data.map((item) => item.toString())];
      }
    } catch (_) {}
    return ['All', 'Plumbing', 'Electrician', 'Cleaning', 'Gardening', 'Painting', 'Carpentry', 'AC Repair', 'Car Mechanic'];
  }

  static Future<Map<String, dynamic>> createService(Map<String, dynamic> data) async {
    return await _client.post(ApiConstants.services, body: data);
  }

  static Future<Map<String, dynamic>> updateService(String id, Map<String, dynamic> data) async {
    return await _client.put('${ApiConstants.services}/$id', body: data);
  }

  static Future<void> deleteService(String id) async {
    await _client.delete('${ApiConstants.services}/$id');
  }

  // BOOKINGS
  static Future<Map<String, dynamic>> createBooking({
    required String serviceId,
    required String date,
    required String timeSlot,
    String? notes,
  }) async {
    return await _client.post(
      ApiConstants.bookings,
      body: {
        'serviceId': serviceId,
        'date': date,
        'timeSlot': timeSlot,
        'notes': notes ?? '',
      },
    );
  }

  static Future<List<dynamic>> getMyBookings() async {
    return await _client.get(ApiConstants.myBookings);
  }

  static Future<List<dynamic>> getProviderBookings() async {
    return await _client.get(ApiConstants.providerBookings);
  }

  static Future<List<dynamic>> getAdminBookings() async {
    return await _client.get(ApiConstants.adminBookings);
  }

  static Future<Map<String, dynamic>> updateBookingStatus(String bookingId, String action) async {
    return await _client.patch('${ApiConstants.bookings}/$bookingId/status', body: {'action': action});
  }

  static Future<void> cancelBooking(String bookingId) async {
    await _client.delete('${ApiConstants.bookings}/$bookingId');
  }

  // REVIEWS
  static Future<List<dynamic>> getServiceReviews(String serviceId, {int page = 1}) async {
    final data = await _client.get('${ApiConstants.reviews}/$serviceId', queryParams: {'page': page.toString()});
    return data['reviews'] as List<dynamic>? ?? [];
  }

  static Future<Map<String, dynamic>> submitReview({
    required String serviceId,
    required int rating,
    required String comment,
  }) async {
    return await _client.post('${ApiConstants.reviews}/$serviceId', body: {
      'rating': rating,
      'comment': comment,
    });
  }

  // CHATS
  static Future<List<dynamic>> getChats() async {
    return await _client.get(ApiConstants.chats);
  }

  static Future<Map<String, dynamic>> createChat({String? serviceId, String? providerId}) async {
    return await _client.post(ApiConstants.chats, body: {
      if (serviceId != null) 'serviceId': serviceId,
      if (providerId != null) 'providerId': providerId,
    });
  }

  static Future<Map<String, dynamic>> getMessages(String chatId, {int page = 1}) async {
    return await _client.get('${ApiConstants.chats}/$chatId/messages', queryParams: {'page': page.toString()});
  }

  static Future<Map<String, dynamic>> sendMessage(String chatId, String text) async {
    return await _client.post('${ApiConstants.chats}/$chatId/messages', body: {'text': text});
  }

  static Future<void> markMessagesAsRead(String chatId) async {
    await _client.patch('${ApiConstants.chats}/$chatId/read');
  }

  // NOTIFICATIONS
  static Future<List<dynamic>> getNotifications() async {
    return await _client.get(ApiConstants.notifications);
  }

  static Future<int> getUnreadNotificationCount() async {
    final data = await _client.get('${ApiConstants.notifications}/unread-count');
    return data['unreadCount'] as int? ?? 0;
  }

  static Future<void> markAllNotificationsRead() async {
    await _client.patch('${ApiConstants.notifications}/read-all');
  }

  // PROVIDERS
  static Future<Map<String, dynamic>> getProviderProfile(String id) async {
    return await _client.get('${ApiConstants.providers}/$id');
  }

  // ADMIN
  static Future<Map<String, dynamic>> getAdminStats() async {
    return await _client.get(ApiConstants.adminAnalytics);
  }

  static Future<List<dynamic>> getAdminUsers({String? role, String? search, int page = 1}) async {
    final params = <String, String>{
      'page': page.toString(),
      if (role != null) 'role': role,
      if (search != null) 'search': search,
    };
    final data = await _client.get(ApiConstants.adminUsers, queryParams: params);
    return data['users'] as List<dynamic>? ?? [];
  }

  static Future<List<dynamic>> getPendingProviders() async {
    return await _client.get(ApiConstants.adminPendingProviders);
  }

  static Future<void> verifyProvider(String userId, bool verify) async {
    await _client.put('${ApiConstants.baseUrl}/admin/users/$userId/verify', body: {'is_verified': verify});
  }

  static Future<void> banUser(String userId) async {
    await _client.patch('${ApiConstants.baseUrl}/admin/users/$userId/ban');
  }

  static Future<List<dynamic>> getAuditLogs({int page = 1}) async {
    final data = await _client.get(ApiConstants.adminLogs, queryParams: {'page': page.toString()});
    return data['logs'] as List<dynamic>? ?? [];
  }

  // HELPERS
  static Future<bool> isLoggedIn() async {
    return await _storage.hasToken();
  }

  static Future<bool> isGuest() async {
    return await _storage.isGuestMode();
  }

  static Future<void> saveUserSession(String email) async {
    await _storage.saveRememberedEmail(email);
  }

  static Future<String?> getRememberedEmail() async {
    return await _storage.getRememberedEmail();
  }

  static final List<Map<String, dynamic>> mockServices = [
    {
      'id': '1',
      'title': 'Quick Fix Plumbing & Sanitary',
      'category': 'Plumbing',
      'provider': 'Abebe Plumbing Solutions',
      'rating': 4.8,
      'reviewsCount': 156,
      'price': 'ETB 450/hr',
      'description': 'Emergency leak repair, bathroom installations, and pipe maintenance. We provide 24/7 emergency services across Addis Ababa.',
      'image': 'assets/images/photo-1.jpg',
      'location': 'Bole, Addis Ababa',
      'verified': true,
      'contact': {'phone': '+251911234567', 'whatsapp': '+251911234567'}
    },
    {
      'id': '2',
      'title': 'Green Earth Landscaping',
      'category': 'Gardening',
      'provider': 'Kebede Green Landscapes',
      'rating': 4.5,
      'reviewsCount': 89,
      'price': 'ETB 350/hr',
      'description': 'Expert landscaping, lawn maintenance, and garden design. We specialize in indigenous plants and sustainable garden practices.',
      'image': 'assets/images/oto-2.jpg',
      'location': 'CMC, Addis Ababa',
      'verified': true,
      'contact': {'phone': '+251912345678', 'whatsapp': '+251912345678'}
    },
    {
      'id': '3',
      'title': 'Spark Electrical & Maintenance',
      'category': 'Electrician',
      'provider': 'Tadesse Electricals',
      'rating': 4.9,
      'reviewsCount': 210,
      'price': 'ETB 500/hr',
      'description': 'Certified electrical repairs, wiring installations, and solar panel maintenance. Safety is our top priority.',
      'image': 'assets/images/photo-3.jpg',
      'location': 'Piassa, Addis Ababa',
      'verified': true,
      'contact': {'phone': '+251913456789', 'whatsapp': '+251913456789'}
    },
    {
      'id': '4',
      'title': 'Pure Clean Professional Services',
      'category': 'Cleaning',
      'provider': 'Mulu Cleaning Co.',
      'rating': 4.7,
      'reviewsCount': 120,
      'price': 'ETB 250/hr',
      'description': 'Deep home cleaning, office sanitization, and carpet washing. Eco-friendly cleaning materials used.',
      'image': 'assets/images/photo-4.jpg',
      'location': 'Kazanchis, Addis Ababa',
      'verified': true,
      'contact': {'phone': '+251914567890', 'whatsapp': '+251914567890'}
    },
    {
      'id': '5',
      'title': 'Rainbow Professional Painters',
      'category': 'Painting',
      'provider': 'Alem Paints & Decor',
      'rating': 4.6,
      'reviewsCount': 75,
      'price': 'ETB 400/hr',
      'description': 'Interior and exterior painting, wallpaper installation, and decorative wall finishes.',
      'image': 'assets/images/photo-1.jpg',
      'location': 'Sarbet, Addis Ababa',
      'verified': false,
      'contact': {'phone': '+251915678901', 'whatsapp': '+251915678901'}
    }
  ];
}
