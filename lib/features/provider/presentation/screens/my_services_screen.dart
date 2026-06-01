import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:local_service_app/core/constants/api_constants.dart';
import 'package:local_service_app/core/services/secure_storage_service.dart';
import 'package:local_service_app/shared/widgets/loading_widget.dart';
import 'package:local_service_app/shared/widgets/error_display.dart';
import 'package:local_service_app/shared/widgets/empty_state.dart';
import 'package:local_service_app/shared/widgets/confirm_dialog.dart';

class MyServicesScreen extends StatefulWidget {
  const MyServicesScreen({super.key});

  @override
  State<MyServicesScreen> createState() => _MyServicesScreenState();
}

class _MyServicesScreenState extends State<MyServicesScreen> {
  final _storage = SecureStorageService();
  List<dynamic> _services = [];
  bool _isLoading = true;
  String? _error;
  Set<String> _togglingIds = {};
  Set<String> _deletingIds = {};

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<String?> _getUserId() async {
    final userData = await _storage.getUserData();
    return userData?['id'] as String? ?? userData?['_id'] as String?;
  }

  Future<Map<String, String>> _authHeaders() async {
    final token = await _storage.getToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Future<void> _loadServices() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final userId = await _getUserId();
      if (userId == null) {
        _error = 'User ID not found';
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/services?provider_id=$userId'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        _services = body is List
            ? body
            : (body['services'] as List? ?? []);
      } else {
        _error = 'Failed to load services (${response.statusCode})';
      }
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _toggleActive(String serviceId, bool currentlyActive) async {
    setState(() => _togglingIds.add(serviceId));
    try {
      final headers = await _authHeaders();
      await http.put(
        Uri.parse('${ApiConstants.baseUrl}/services/$serviceId'),
        headers: headers,
        body: jsonEncode({'is_active': !currentlyActive}),
      );
      await _loadServices();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: $e'),
            backgroundColor: const Color(0xFFDC3545),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _togglingIds.remove(serviceId));
    }
  }

  Future<void> _deleteService(String serviceId) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete Service',
      message: 'Are you sure you want to delete this service? This action cannot be undone.',
      confirmLabel: 'Delete',
      confirmColor: const Color(0xFFDC3545),
    );
    if (!confirmed) return;

    setState(() => _deletingIds.add(serviceId));
    try {
      final headers = await _authHeaders();
      await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/services/$serviceId'),
        headers: headers,
      );
      await _loadServices();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Service deleted'),
            backgroundColor: Color(0xFF28A745),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: $e'),
            backgroundColor: const Color(0xFFDC3545),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _deletingIds.remove(serviceId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Services')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/provider/services/create'),
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Loading services...')
          : _error != null
              ? ErrorDisplay(message: _error!, onRetry: _loadServices)
              : _services.isEmpty
                  ? EmptyStateWidget(
                      icon: Icons.miscellaneous_services,
                      title: 'No Services Yet',
                      message: 'Create your first service to get started.',
                      buttonLabel: 'Create Service',
                      onButtonPressed: () =>
                          context.push('/provider/services/create'),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadServices,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _services.length,
                        itemBuilder: (context, index) {
                          return _buildServiceCard(_services[index]);
                        },
                      ),
                    ),
    );
  }

  Widget _buildServiceCard(dynamic service) {
    final id = service['id'] ?? service['_id'] as String? ?? '';
    final title = service['title'] as String? ?? 'Untitled';
    final category = service['category'] as String? ?? '';
    final price = service['price'];
    final isActive = service['is_active'] == true;
    final rating = (service['rating'] ?? 0).toDouble();
    final bookingsCount = (service['bookings_count'] ?? 0).toInt();
    final photo = service['photo'] as String? ?? service['image'] as String?;
    final isDeleting = _deletingIds.contains(id);
    final isToggling = _togglingIds.contains(id);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ListTile(
            leading: photo != null && photo.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      photo,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _serviceIcon(category),
                    ),
                  )
                : _serviceIcon(category),
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (category.isNotEmpty)
                  Text(category, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (rating > 0) ...[
                      Icon(Icons.star, size: 14, color: Colors.amber[700]),
                      const SizedBox(width: 2),
                      Text(
                        rating.toStringAsFixed(1),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Icon(Icons.calendar_today, size: 14, color: Colors.grey[400]),
                    const SizedBox(width: 2),
                    Text(
                      '$bookingsCount bookings',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
            trailing: price != null
                ? Text(
                    'ETB $price',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF47E20),
                      fontSize: 15,
                    ),
                  )
                : null,
          ),
          Row(
            children: [
              Switch(
                value: isActive,
                onChanged: isToggling
                    ? null
                    : (_) => _toggleActive(id, isActive),
              ),
              Text(
                isActive ? 'Active' : 'Inactive',
                style: TextStyle(
                  fontSize: 12,
                  color: isActive ? const Color(0xFF28A745) : Colors.grey,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: () => context.push(
                  '/provider/services/$id/edit',
                ),
                tooltip: 'Edit',
              ),
              IconButton(
                icon: isDeleting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.delete, size: 20, color: Color(0xFFDC3545)),
                onPressed: isDeleting ? null : () => _deleteService(id),
                tooltip: 'Delete',
              ),
              const SizedBox(width: 4),
            ],
          ),
        ],
      ),
    );
  }

  Widget _serviceIcon(String category) {
    IconData icon;
    switch (category.toLowerCase()) {
      case 'plumbing':
        icon = Icons.plumbing;
        break;
      case 'electrician':
        icon = Icons.electrical_services;
        break;
      case 'cleaning':
        icon = Icons.cleaning_services;
        break;
      case 'gardening':
        icon = Icons.yard;
        break;
      case 'painting':
        icon = Icons.format_paint;
        break;
      case 'carpentry':
        icon = Icons.handyman;
        break;
      case 'ac repair':
        icon = Icons.ac_unit;
        break;
      case 'car mechanic':
        icon = Icons.time_to_leave;
        break;
      default:
        icon = Icons.miscellaneous_services;
    }
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFF007BFF).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: const Color(0xFF007BFF), size: 28),
    );
  }
}
