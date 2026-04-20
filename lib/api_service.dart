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

  static Future<List<dynamic>> getServices({String? query, String? category, String? location}) async {
    try {
      String url = '$baseUrl/services';
      Map<String, String> params = {};
      if (query != null && query.isNotEmpty) params['query'] = query;
      if (category != null && category != 'All') params['category'] = category;
      if (location != null && location != 'All Areas') params['location'] = location;
      
      if (params.isNotEmpty) {
        url += '?' + Uri(queryParameters: params).query;
      }

      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Fetch Error: $e');
      if (kIsWeb) return mockServices; // Fallback for web/cors issues
      throw Exception('Connection failed');
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

  static final List<Map<String, dynamic>> mockServices = [
    {
      'id': '1',
      'title': 'Expert Plumbing & Repair',
      'category': 'Plumbing',
      'provider': 'Abebe Plumbing Solutions',
      'rating': 4.8,
      'reviewsCount': 156,
      'price': '\$45/hr',
      'description': 'Emergency leak repair and installations.',
      'image': 'assets/images/photo-1.jpg',
      'location': 'Bole, Addis Ababa',
      'verified': true,
      'contact': {'phone': '+251911234567', 'whatsapp': '+251911234567'}
    },
    {
      'id': '2',
      'title': 'Garden & Landscape Design',
      'category': 'Gardening',
      'provider': 'Kebede Green Landscapes',
      'rating': 4.5,
      'reviewsCount': 89,
      'price': '\$35/hr',
      'description': 'Expert landscaping and lawn maintenance.',
      'image': 'assets/images/oto-2.jpg',
      'location': 'CMC, Addis Ababa',
      'verified': true,
      'contact': {'phone': '+251912345678', 'whatsapp': '+251912345678'}
    }
  ];
}
