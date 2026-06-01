import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:local_service_app/core/constants/api_constants.dart';
import 'package:local_service_app/core/services/secure_storage_service.dart';
import 'package:local_service_app/shared/widgets/loading_widget.dart';
import 'package:local_service_app/shared/widgets/error_display.dart';
import 'package:local_service_app/shared/widgets/status_chip.dart';

class ProviderBookingDetailScreen extends StatefulWidget {
  final String bookingId;

  const ProviderBookingDetailScreen({super.key, required this.bookingId});

  @override
  State<ProviderBookingDetailScreen> createState() =>
      _ProviderBookingDetailScreenState();
}

class _ProviderBookingDetailScreenState
    extends State<ProviderBookingDetailScreen> {
  final _storage = SecureStorageService();
  Map<String, dynamic>? _booking;
  bool _isLoading = true;
  String? _error;
  Set<String> _loadingActions = {};

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
        Uri.parse('${ApiConstants.baseUrl}/bookings/${widget.bookingId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        _booking = jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        _error = 'Failed to load booking (${response.statusCode})';
      }
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _updateStatus(String status) async {
    setState(() => _loadingActions.add(status));
    try {
      final token = await _storage.getToken();
      await http.put(
        Uri.parse('${ApiConstants.baseUrl}/bookings/${widget.bookingId}/status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'status': status}),
      );
      await _loadBooking();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking $status'),
            backgroundColor: const Color(0xFF28A745),
          ),
        );
      }
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
      if (mounted) setState(() => _loadingActions.remove(status));
    }
  }

  Future<void> _callCustomer(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
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
                        _buildCustomerCard(theme),
                        const SizedBox(height: 16),
                        _buildServiceCard(theme),
                        const SizedBox(height: 16),
                        _buildInfoCard(theme),
                        const SizedBox(height: 16),
                        _buildActions(theme),
                        const SizedBox(height: 16),
                        _buildStatusSection(theme),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildCustomerCard(ThemeData theme) {
    final customer =
        _booking?['customer'] as Map<String, dynamic>? ?? {};
    final name = customer['name'] as String? ?? 'Customer';
    final phone = customer['phone'] as String? ?? '';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFF007BFF).withOpacity(0.1),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'C',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF007BFF),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (phone.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () => _callCustomer(phone),
                      child: Row(
                        children: [
                          const Icon(Icons.phone, size: 16, color: Color(0xFF007BFF)),
                          const SizedBox(width: 4),
                          Text(
                            phone,
                            style: const TextStyle(
                              color: Color(0xFF007BFF),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(ThemeData theme) {
    final service =
        _booking?['service'] as Map<String, dynamic>? ?? {};
    final serviceName = service['name'] as String? ??
        service['title'] as String? ??
        _booking?['serviceName'] as String? ??
        _booking?['service_title'] as String? ??
        'Service';
    final price = _booking?['price'] ?? service['price'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF47E20).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.miscellaneous_services,
                color: Color(0xFFF47E20),
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    serviceName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (price != null)
                    Text(
                      'ETB $price',
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

  Widget _buildInfoCard(ThemeData theme) {
    final date = _booking?['scheduled_date'] as String? ??
        _booking?['date'] as String? ??
        '';
    final notes = _booking?['description'] as String? ??
        _booking?['notes'] as String? ??
        '';
    final createdAt = _booking?['createdAt'] as String? ?? '';

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
            _infoRow(Icons.calendar_today, 'Scheduled', date),
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              _infoRow(Icons.notes, 'Notes', notes),
            ],
            if (createdAt.isNotEmpty) ...[
              const SizedBox(height: 8),
              _infoRow(Icons.access_time, 'Created', createdAt),
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
          child: Text(label, style: const TextStyle(color: Colors.grey)),
        ),
        Expanded(child: Text(value.isNotEmpty ? value : 'N/A')),
      ],
    );
  }

  Widget _buildActions(ThemeData theme) {
    final status = (_booking?['status'] as String? ?? '').toLowerCase();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Update Status',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (status == 'pending')
              Row(
                children: [
                  Expanded(
                    child: _actionButton(
                      label: 'Confirm',
                      icon: Icons.check_circle,
                      color: const Color(0xFF28A745),
                      status: 'confirmed',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _actionButton(
                      label: 'Decline',
                      icon: Icons.cancel,
                      color: const Color(0xFFDC3545),
                      status: 'cancelled',
                    ),
                  ),
                ],
              ),
            if (status == 'confirmed')
              SizedBox(
                width: double.infinity,
                child: _actionButton(
                  label: 'Mark In Progress',
                  icon: Icons.engineering,
                  color: const Color(0xFF007BFF),
                  status: 'in_progress',
                ),
              ),
            if (status == 'in_progress')
              SizedBox(
                width: double.infinity,
                child: _actionButton(
                  label: 'Mark Completed',
                  icon: Icons.verified,
                  color: const Color(0xFF28A745),
                  status: 'completed',
                ),
              ),
            if (status == 'completed' || status == 'cancelled')
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    StatusChip(status: status, filled: true),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required String status,
  }) {
    final loading = _loadingActions.contains(status);
    return FilledButton.icon(
      onPressed: loading ? null : () => _updateStatus(status),
      style: FilledButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      icon: loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Icon(icon, size: 18),
      label: Text(label),
    );
  }

  Widget _buildStatusSection(ThemeData theme) {
    final status = (_booking?['status'] as String? ?? '').toLowerCase();
    final isCompleted = status == 'completed';
    final isCancelled = status == 'cancelled';
    final hasChat = _booking?['chatId'] as String? ??
        _booking?['chat_id'] as String?;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.chat, size: 20, color: Color(0xFF007BFF)),
                const SizedBox(width: 8),
                Text(
                  'Communication',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (hasChat != null)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.push(
                    '/provider/chat/$hasChat',
                  ),
                  icon: const Icon(Icons.chat, size: 18),
                  label: const Text('Message Customer'),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Chat not yet available for this booking'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat, size: 18),
                  label: const Text('Message Customer'),
                ),
              ),
            if (!isCompleted && !isCancelled) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    final customer =
                        _booking?['customer'] as Map<String, dynamic>? ?? {};
                    final phone = customer['phone'] as String? ?? '';
                    if (phone.isNotEmpty) {
                      _callCustomer(phone);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No phone number available')),
                      );
                    }
                  },
                  icon: const Icon(Icons.phone, size: 18),
                  label: const Text('Call Customer'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
