import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:local_service_app/core/constants/api_constants.dart';
import 'package:local_service_app/core/services/secure_storage_service.dart';
import 'package:local_service_app/shared/widgets/service_card.dart';
import 'package:local_service_app/shared/widgets/empty_state.dart';
import 'package:local_service_app/shared/widgets/loading_widget.dart';
import 'package:local_service_app/shared/widgets/error_display.dart';
import 'package:local_service_app/shared/widgets/confirm_dialog.dart';

class SavedServicesScreen extends StatefulWidget {
  const SavedServicesScreen({super.key});

  @override
  State<SavedServicesScreen> createState() => _SavedServicesScreenState();
}

class _SavedServicesScreenState extends State<SavedServicesScreen> {
  final _storage = SecureStorageService();
  final _secureStorage = const FlutterSecureStorage();
  static const _savedKey = 'saved_services';

  List<String> _savedIds = [];
  List<dynamic> _services = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final raw = await _secureStorage.read(key: _savedKey);
      _savedIds = raw != null
          ? (jsonDecode(raw) as List).cast<String>()
          : [];

      if (_savedIds.isEmpty) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final token = await _storage.getToken();
      final response = await http.get(
        Uri.parse(ApiConstants.services),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final allServices = body['services'] ?? (body is List ? body : []);
        _services = allServices.where((s) {
          final id = s['id'] ?? s['_id'] ?? '';
          return _savedIds.contains(id.toString());
        }).toList();
      } else {
        _error = 'Failed to load services';
      }
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _removeSaved(int index) async {
    final service = _services[index];
    final name = service['name'] ?? service['title'] ?? 'this service';

    final confirmed = await showConfirmDialog(
      context,
      title: 'Remove from Saved',
      message: 'Remove "$name" from your saved services?',
      confirmLabel: 'Remove',
      confirmColor: const Color(0xFFDC3545),
    );
    if (!confirmed) return;

    final id = service['id'] ?? service['_id'] ?? '';
    _savedIds.remove(id.toString());
    await _secureStorage.write(
      key: _savedKey,
      value: jsonEncode(_savedIds),
    );

    setState(() => _services.removeAt(index));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Service removed from saved'),
          backgroundColor: Color(0xFF28A745),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: LoadingWidget(message: 'Loading saved services...'),
      );
    }
    if (_error != null) {
      return Scaffold(
        body: ErrorDisplay(message: _error!, onRetry: _load),
      );
    }
    if (_services.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Saved Services')),
        body: const EmptyStateWidget(
          icon: Icons.bookmark_border,
          title: 'No Saved Services',
          message: 'Browse services and save the ones you like',
          buttonLabel: 'Browse Services',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Saved Services')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.7,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _services.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onLongPress: () => _removeSaved(index),
              child: ServiceCard(
                service: _services[index],
                onTap: () {},
              ),
            );
          },
        ),
      ),
    );
  }
}
