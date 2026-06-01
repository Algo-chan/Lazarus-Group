import 'package:flutter/material.dart';
import 'package:local_service_app/core/constants/api_constants.dart';
import 'package:local_service_app/core/network/api_client.dart';
import 'package:local_service_app/shared/widgets/status_chip.dart';
import 'package:local_service_app/shared/widgets/confirm_dialog.dart';
import 'package:local_service_app/shared/widgets/loading_widget.dart';
import 'package:local_service_app/shared/widgets/error_display.dart';
import 'package:local_service_app/shared/widgets/empty_state.dart';

class IncomingBookingsScreen extends StatefulWidget {
  const IncomingBookingsScreen({super.key});

  @override
  State<IncomingBookingsScreen> createState() => _IncomingBookingsScreenState();
}

class _IncomingBookingsScreenState extends State<IncomingBookingsScreen>
    with SingleTickerProviderStateMixin {
  final _api = ApiClient();
  late TabController _tabController;

  bool _loading = true;
  String? _error;
  Map<String, List<dynamic>> _groupedBookings = {};
  Set<String> _loadingBookings = {};

  static const List<String> _tabs = ['New', 'Confirmed', 'In Progress', 'Completed', 'Cancelled'];

  static const Map<String, String> _statusMap = {
    'New': 'pending',
    'Confirmed': 'confirmed',
    'In Progress': 'in_progress',
    'Completed': 'completed',
    'Cancelled': 'cancelled',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _api.get(ApiConstants.providerBookings);
      final bookings = data is List ? List<dynamic>.from(data) : List<dynamic>.from(data['bookings'] ?? []);

      final grouped = <String, List<dynamic>>{};
      for (final tab in _tabs) {
        final status = _statusMap[tab]!;
        grouped[tab] = bookings.where((b) {
          final s = (b['status'] as String? ?? '').toLowerCase();
          return s == status;
        }).toList();
      }
      _groupedBookings = grouped;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Failed to load bookings';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _updateStatus(String bookingId, String newStatus) async {
    final statusLabel = newStatus.replaceAll('_', ' ');
    if (newStatus == 'cancelled') {
      final confirmed = await showConfirmDialog(
        context,
        title: 'Decline Booking',
        message: 'Are you sure you want to decline this booking?',
        confirmLabel: 'Decline',
        confirmColor: const Color(0xFFDC3545),
      );
      if (!confirmed) return;
    }

    setState(() => _loadingBookings.add(bookingId));

    try {
      await _api.put(
        '${ApiConstants.bookings}/$bookingId/status',
        body: {'status': newStatus},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking ${statusLabel.toLowerCase()} successfully'),
            backgroundColor: const Color(0xFF28A745),
          ),
        );
      }
      await _loadBookings();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: const Color(0xFFDC3545)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status'), backgroundColor: const Color(0xFFDC3545)),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingBookings.remove(bookingId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Incoming Bookings'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: const Color(0xFF007BFF),
          unselectedLabelColor: Colors.grey,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: _loading
          ? const LoadingWidget(message: 'Loading bookings...')
          : _error != null
              ? ErrorDisplay(message: _error!, onRetry: _loadBookings)
              : TabBarView(
                  controller: _tabController,
                  children: _tabs.map((tab) => _buildTabContent(tab)).toList(),
                ),
    );
  }

  Widget _buildTabContent(String tab) {
    final bookings = _groupedBookings[tab] ?? [];

    if (bookings.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.calendar_today,
        title: 'No $tab Bookings',
        message: 'There are no $tab bookings at the moment.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBookings,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          return _buildBookingCard(bookings[index], tab);
        },
      ),
    );
  }

  Widget _buildBookingCard(dynamic booking, String tab) {
    final id = booking['id'] ?? booking['_id'] ?? '';
    final customerName = booking['customer_name'] as String? ?? booking['customerName'] as String? ?? 'Customer';
    final serviceName = booking['service_title'] as String? ?? booking['serviceName'] as String? ?? 'Service';
    final date = booking['date'] as String? ?? booking['created_at'] as String? ?? '';
    final notes = booking['notes'] as String? ?? booking['customer_notes'] as String? ?? '';
    final status = booking['status'] as String? ?? 'pending';
    final isLoading = _loadingBookings.contains(id);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF007BFF).withOpacity(0.1),
                  child: Text(
                    customerName.isNotEmpty ? customerName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Color(0xFF007BFF),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(customerName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(serviceName, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                StatusChip(status: status, filled: true),
              ],
            ),
            if (date.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 6),
                  Text(
                    date.length >= 10 ? date.substring(0, 10) : date,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  notes,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            const SizedBox(height: 12),
            _buildActionButtons(tab, id, isLoading),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(String tab, String bookingId, bool isLoading) {
    if (isLoading) {
      return const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)));
    }

    switch (tab) {
      case 'New':
        return Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 38,
                child: FilledButton.icon(
                  onPressed: () => _updateStatus(bookingId, 'confirmed'),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Confirm'),
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF28A745)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 38,
                child: OutlinedButton.icon(
                  onPressed: () => _updateStatus(bookingId, 'cancelled'),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Decline'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFDC3545),
                    side: const BorderSide(color: Color(0xFFDC3545)),
                  ),
                ),
              ),
            ),
          ],
        );
      case 'Confirmed':
        return SizedBox(
          width: double.infinity,
          height: 38,
          child: FilledButton.icon(
            onPressed: () => _updateStatus(bookingId, 'in_progress'),
            icon: const Icon(Icons.play_arrow, size: 18),
            label: const Text('Mark In Progress'),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF007BFF)),
          ),
        );
      case 'In Progress':
        return SizedBox(
          width: double.infinity,
          height: 38,
          child: FilledButton.icon(
            onPressed: () => _updateStatus(bookingId, 'completed'),
            icon: const Icon(Icons.check_circle, size: 18),
            label: const Text('Mark Completed'),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF28A745)),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
