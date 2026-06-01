import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:local_service_app/core/constants/api_constants.dart';
import 'package:local_service_app/core/services/secure_storage_service.dart';
import 'package:local_service_app/shared/widgets/empty_state.dart';
import 'package:local_service_app/shared/widgets/loading_widget.dart';
import 'package:local_service_app/shared/widgets/error_display.dart';
import 'package:local_service_app/shared/widgets/confirm_dialog.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _storage = SecureStorageService();
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _filteredItems = [];
  bool _isLoading = true;
  String? _error;
  String _selectedFilter = 'All';

  final _filters = ['All', 'Flagged Services', 'Flagged Reviews'];

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await _storage.getToken();
      final headers = {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'};
      final response = await http.get(
        Uri.parse(ApiConstants.adminBookings),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> items;
        if (data is List) {
          items = data;
        } else if (data is Map && data.containsKey('bookings')) {
          items = data['bookings'];
        } else {
          items = [];
        }

        final mapped = items.map<Map<String, dynamic>>((e) {
          final item = e is Map<String, dynamic> ? e : <String, dynamic>{};
          final type = item['reportedType'] as String? ??
              (item['status'] == 'cancelled' ? 'reported_service' : 'reported_review');
          return {
            'id': item['id'] ?? item['_id'] ?? '',
            'type': type,
            'title': item['title'] ?? item['serviceName'] ?? item['name'] ?? 'Untitled',
            'description': item['description'] ?? item['content'] ?? '',
            'reporterName': item['reporterName'] ?? item['customerName'] ?? item['userName'] ?? 'Anonymous',
            'reporterEmail': item['reporterEmail'] ?? item['customerEmail'] ?? '',
            'date': item['createdAt'] ?? item['date'] ?? DateTime.now().toIso8601String(),
            'serviceId': item['serviceId'] ?? item['_id'] ?? item['id'] ?? '',
          };
        }).toList();

        if (mounted) {
          setState(() {
            _items = mapped;
            _applyFilter();
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _error = 'Failed to load reports (${response.statusCode})');
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Connection error: $e');
    }
  }

  void _applyFilter() {
    if (_selectedFilter == 'All') {
      _filteredItems = List.from(_items);
    } else if (_selectedFilter == 'Flagged Services') {
      _filteredItems = _items.where((i) => i['type'] == 'reported_service').toList();
    } else {
      _filteredItems = _items.where((i) => i['type'] == 'reported_review').toList();
    }
  }

  Future<void> _dismissItem(int index) async {
    final removed = _filteredItems.removeAt(index);
    _items.removeWhere((i) => i['id'] == removed['id']);
    if (mounted) setState(() {});
  }

  Future<void> _removeContent(Map<String, dynamic> item, int index) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Remove Content',
      message: 'Are you sure you want to permanently remove "${item['title']}"? This action cannot be undone.',
      confirmLabel: 'Remove',
      cancelLabel: 'Cancel',
      confirmColor: const Color(0xFFDC3545),
    );

    if (!confirmed) return;

    final serviceId = item['serviceId'] as String;
    if (serviceId.isEmpty) return;

    try {
      final token = await _storage.getToken();
      final headers = {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'};
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/admin/services/$serviceId'),
        headers: headers,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        _filteredItems.removeAt(index);
        _items.removeWhere((i) => i['id'] == item['id']);
        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Content removed successfully')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to remove content (${response.statusCode})')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'reported_service':
        return const Color(0xFFDC3545);
      case 'reported_review':
        return const Color(0xFFFFC107);
      default:
        return Colors.grey;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'reported_service':
        return Icons.block;
      case 'reported_review':
        return Icons.flag;
      default:
        return Icons.warning;
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'reported_service':
        return 'Flagged Service';
      case 'reported_review':
        return 'Flagged Review';
      default:
        return 'Reported';
    }
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.month}/${dt.day}/${dt.year}';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const LoadingWidget(message: 'Loading reports...');
    }

    if (_error != null) {
      return ErrorDisplay(message: _error!, onRetry: _loadReports);
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: const Color(0xFF1A1A2E),
          child: Row(
            children: _filters.map((f) {
              final selected = _selectedFilter == f;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(f),
                  selected: selected,
                  onSelected: (_) {
                    setState(() {
                      _selectedFilter = f;
                      _applyFilter();
                    });
                  },
                  selectedColor: const Color(0xFF007BFF),
                  checkmarkColor: Colors.white,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : Colors.white70,
                    fontSize: 13,
                  ),
                  backgroundColor: const Color(0xFF16213E),
                  side: BorderSide.none,
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: _filteredItems.isEmpty
              ? const EmptyStateWidget(
                  icon: Icons.flag_outlined,
                  title: 'No flagged items',
                  message: 'All reports have been reviewed.',
                )
              : RefreshIndicator(
                  onRefresh: _loadReports,
                  color: const Color(0xFF007BFF),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = _filteredItems[index];
                      final type = item['type'] as String;
                      return _ReportCard(
                        item: item,
                        typeIcon: _typeIcon(type),
                        typeColor: _typeColor(type),
                        typeLabel: _typeLabel(type),
                        title: item['title'] as String,
                        description: item['description'] as String,
                        reporterName: item['reporterName'] as String,
                        date: _formatDate(item['date'] as String),
                        onDismiss: () {
                          _dismissItem(index);
                        },
                        onRemove: () {
                          _removeContent(item, index);
                        },
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

class _ReportCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final IconData typeIcon;
  final Color typeColor;
  final String typeLabel;
  final String title;
  final String description;
  final String reporterName;
  final String date;
  final VoidCallback onDismiss;
  final VoidCallback onRemove;

  const _ReportCard({
    required this.item,
    required this.typeIcon,
    required this.typeColor,
    required this.typeLabel,
    required this.title,
    required this.description,
    required this.reporterName,
    required this.date,
    required this.onDismiss,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: const Color(0xFF16213E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(typeIcon, color: typeColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        typeLabel,
                        style: TextStyle(
                          color: typeColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  date,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                description,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 13,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.person_outline, size: 14, color: Colors.white.withValues(alpha: 0.4)),
                const SizedBox(width: 4),
                Text(
                  reporterName,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  height: 34,
                  child: OutlinedButton(
                    onPressed: onDismiss,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey,
                      side: BorderSide(color: Colors.grey.withValues(alpha: 0.4)),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Dismiss', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 34,
                  child: ElevatedButton(
                    onPressed: onRemove,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC3545),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Remove Content', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
