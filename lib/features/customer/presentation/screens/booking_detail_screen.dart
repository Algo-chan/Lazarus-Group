import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:local_service_app/core/constants/api_constants.dart';
import 'package:local_service_app/core/services/secure_storage_service.dart';
import 'package:local_service_app/shared/widgets/status_chip.dart';
import 'package:local_service_app/shared/widgets/loading_widget.dart';
import 'package:local_service_app/shared/widgets/error_display.dart';
import 'package:local_service_app/shared/widgets/confirm_dialog.dart';

class BookingDetailScreen extends StatefulWidget {
  final String bookingId;
  const BookingDetailScreen({super.key, required this.bookingId});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  final _storage = SecureStorageService();
  Map<String, dynamic>? _booking;
  bool _isLoading = true;
  String? _error;

  static const _statusSteps = [
    'pending',
    'confirmed',
    'in_progress',
    'completed',
    'reviewed',
  ];

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  Future<void> _loadBooking() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final token = await _storage.getToken();
      final response = await http.get(
        Uri.parse('${ApiConstants.bookings}/${widget.bookingId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        _booking = jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        _error = 'Failed to load booking details';
      }
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _cancelBooking() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Cancel Booking',
      message: 'Are you sure you want to cancel this booking?',
      confirmLabel: 'Cancel Booking',
      confirmColor: const Color(0xFFDC3545),
    );
    if (!confirmed) return;

    try {
      final token = await _storage.getToken();
      await http.put(
        Uri.parse('${ApiConstants.bookings}/${widget.bookingId}/status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'status': 'cancelled'}),
      );
      await _loadBooking();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking cancelled'),
            backgroundColor: Color(0xFF28A745),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  int _currentStepIndex(String? status) {
    final idx = _statusSteps.indexOf(status?.toLowerCase() ?? '');
    return idx >= 0 ? idx : 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Booking Details')),
      body: _isLoading
          ? const LoadingWidget(message: 'Loading booking...')
          : _error != null
              ? ErrorDisplay(message: _error!, onRetry: _loadBooking)
              : RefreshIndicator(
                  onRefresh: _loadBooking,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildServiceCard(theme),
                        const SizedBox(height: 24),
                        _buildStatusTimeline(theme),
                        const SizedBox(height: 24),
                        _buildContactSection(theme),
                        const SizedBox(height: 24),
                        _buildInfoSection(theme),
                        const SizedBox(height: 24),
                        _buildActionButtons(theme),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildServiceCard(ThemeData theme) {
    final service = _booking?['service'] as Map<String, dynamic>? ?? {};
    final provider = _booking?['provider'] as Map<String, dynamic>? ?? {};
    final price = _booking?['price'] ?? service['price'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.miscellaneous_services,
                color: theme.primaryColor,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service['name'] ?? service['title'] ?? 'Service',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    provider['name'] ?? 'Provider',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    price != null ? 'ETB ${price}' : '',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF47E20),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTimeline(ThemeData theme) {
    final status = _booking?['status']?.toString() ?? 'pending';
    final currentIndex = _currentStepIndex(status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...List.generate(_statusSteps.length, (index) {
              final step = _statusSteps[index];
              final isCompleted = index <= currentIndex;
              final isCurrent = index == currentIndex;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted
                              ? const Color(0xFF28A745)
                              : Colors.grey[300],
                        ),
                        child: Icon(
                          isCompleted ? Icons.check : Icons.circle_outlined,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                      if (index < _statusSteps.length - 1)
                        Container(
                          width: 2,
                          height: 32,
                          color: isCompleted
                              ? const Color(0xFF28A745)
                              : Colors.grey[300],
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: index < _statusSteps.length - 1 ? 8.0 : 0,
                      ),
                      child: Text(
                        step.replaceAll('_', ' '),
                        style: TextStyle(
                          fontWeight:
                              isCurrent ? FontWeight.bold : FontWeight.normal,
                          color: isCompleted
                              ? Colors.black87
                              : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  if (isCurrent) StatusChip(status: status),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSection(ThemeData theme) {
    final provider = _booking?['provider'] as Map<String, dynamic>? ?? {};
    final phone = provider['phone']?.toString() ?? '';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contact Provider',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: phone.isNotEmpty ? () {} : null,
                    icon: const Icon(Icons.phone, size: 18),
                    label: const Text('Call'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: phone.isNotEmpty ? () {} : null,
                    icon: const Icon(Icons.chat, size: 18),
                    label: const Text('WhatsApp'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(ThemeData theme) {
    final date = _booking?['scheduled_date'] ?? _booking?['date'] ?? '';
    final notes = _booking?['description'] ?? _booking?['notes'] ?? '';
    final createdAt = _booking?['createdAt'] ?? '';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Details',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _infoRow(Icons.calendar_today, 'Scheduled', date.toString()),
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              _infoRow(Icons.notes, 'Notes', notes.toString()),
            ],
            if (createdAt.isNotEmpty) ...[
              const SizedBox(height: 8),
              _infoRow(Icons.access_time, 'Created', createdAt.toString()),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 8),
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(color: Colors.grey),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    final status = _booking?['status']?.toString() ?? '';
    final hasReview = _booking?['hasReview'] == true;

    return Column(
      children: [
        if (status == 'pending')
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _cancelBooking,
              icon: const Icon(Icons.cancel, color: Color(0xFFDC3545)),
              label: const Text(
                'Cancel Booking',
                style: TextStyle(color: Color(0xFFDC3545)),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFDC3545)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        if (status == 'completed' && !hasReview) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/customer/write-review',
                  arguments: {
                    'service_id': _booking?['service']?['id'] ?? _booking?['service_id'],
                    'service_name': _booking?['service']?['name'] ?? 'Service',
                    'provider_id': _booking?['provider']?['id'] ?? _booking?['provider_id'],
                    'booking_id': widget.bookingId,
                  },
                );
              },
              icon: const Icon(Icons.star),
              label: const Text('Write a Review'),
            ),
          ),
        ],
      ],
    );
  }
}
