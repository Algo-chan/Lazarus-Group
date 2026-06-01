import 'package:flutter/material.dart';
import '../api_service.dart';

class ServiceProvider extends ChangeNotifier {
  List<dynamic> _services = [];
  List<String> _categories = [];
  bool _isLoading = false;

  List<dynamic> get services => _services;
  List<String> get categories => _categories;
  bool get isLoading => _isLoading;

  Future<void> fetchServices({String? query, String? category}) async {
    _isLoading = true;
    notifyListeners();
    try {
      _services = await ApiService.getServices(query: query, category: category);
    } catch (e) {
      debugPrint('Error fetching services: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchCategories() async {
    try {
      _categories = await ApiService.getCategories();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching categories: $e');
    }
  }
}
