import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:3000/api';

  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await prefs.setString('user', jsonEncode(data['user']));
        await prefs.setBool('isGuest', false);
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to login');
      }
    } catch (e) {
      throw Exception('Login Error: ${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>> signup(String name, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);
      if (response.statusCode == 201) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await prefs.setString('user', jsonEncode(data['user']));
        await prefs.setBool('isGuest', false);
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to signup');
      }
    } catch (e) {
      throw Exception('Signup Error: ${e.toString()}');
    }
  }

  static Future<void> setGuestMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
    await prefs.setBool('isGuest', true);
  }

  static Future<List<dynamic>> getServices({String? query, String? category}) async {
    debugPrint('ApiService: Fetching services (query: $query, category: $category)');
    try {
      String url = '$baseUrl/services';
      Map<String, String> params = {};
      if (query != null && query.isNotEmpty) params['query'] = query;
      if (category != null && category != 'All') params['category'] = category;
      
      if (params.isNotEmpty) {
        url += '?' + Uri(queryParameters: params).query;
      }

      debugPrint('ApiService: Requesting URL: $url');
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('ApiService: Successfully fetched ${data.length} services');
        return data;
      } else {
        debugPrint('ApiService: Server error ${response.statusCode}');
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('ApiService: Fetch Error: $e. Using mock data as fallback.');
      return mockServices; // Always return mock data on failure to ensure something is displayed
    }
  }

  static Future<List<String>> getCategories() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/categories')).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        return List<String>.from(jsonDecode(response.body));
      }
      return ['All', 'Plumbing', 'Electrician', 'Cleaning', 'Gardening', 'Painting'];
    } catch (e) {
      return ['All', 'Plumbing', 'Electrician', 'Cleaning', 'Gardening', 'Painting'];
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
    await prefs.remove('isGuest');
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('token') || (prefs.getBool('isGuest') ?? false);
  }

  static Future<bool> isGuest() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isGuest') ?? false;
  }

  static Future<void> saveUserSession(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('remembered_email', email);
  }

  static final List<Map<String, dynamic>> mockServices = [
    {
      'id': '1',
      'title': 'Quick Fix Plumbing & Sanitary',
      'category': 'Plumbing',
      'provider': 'Abebe Plumbing Solutions',
      'rating': 4.8,
      'reviewsCount': 156,
      'price': '\$45/hr',
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
      'price': '\$35/hr',
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
      'price': '\$50/hr',
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
      'price': '\$25/hr',
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
      'price': '\$40/hr',
      'description': 'Interior and exterior painting, wallpaper installation, and decorative wall finishes.',
      'image': 'assets/images/photo-1.jpg',
      'location': 'Sarbet, Addis Ababa',
      'verified': false,
      'contact': {'phone': '+251915678901', 'whatsapp': '+251915678901'}
    }
  ];
}
