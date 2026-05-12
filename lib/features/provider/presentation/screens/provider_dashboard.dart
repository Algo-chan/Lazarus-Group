import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:local_service_app/core/constants/api_constants.dart';
import 'package:local_service_app/core/services/secure_storage_service.dart';
import 'package:local_service_app/shared/widgets/loading_widget.dart';
import 'package:local_service_app/shared/widgets/error_display.dart';
import 'package:local_service_app/features/auth/presentation/providers/auth_provider.dart';

class ProviderDashboard extends StatefulWidget {
  const ProviderDashboard({super.key});

  @override
  State<ProviderDashboard> createState() => _ProviderDashboardState();
}

class _ProviderDashboardState extends State<ProviderDashboard> {
  int _currentTab = 0;
  List<dynamic> _myServices = [];
  List<dynamic> _myBookings = [];
  bool _isLoading = true;
  String? _error;

  final _storage = SecureStorageService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await _storage.getToken();
      final headers = {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'};

      final results = await Future.wait([
        http.get(Uri.parse(ApiConstants.myBookings), headers: headers),
      ]);

      _myBookings = jsonDecode(results[0].body);
      _myServices = [];
    } catch (e) {
      _error = e.toString();
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Provider Panel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => auth.logout(),
          ),
        ],
      ),
      drawer: _buildDrawer(context, auth),
      body: _isLoading
          ? const LoadingWidget(message: 'Loading your dashboard...')
          : _error != null
              ? ErrorDisplay(message: _error!, onRetry: _loadData)
              : _buildBody(),
    );
  }

  Widget _buildDrawer(BuildContext context, AuthProvider auth) {
    return Drawer(
      child: ListView(
        children: [
          UserAccountsDrawerHeader(
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                (auth.user?.name ?? 'P')[0].toUpperCase(),
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
              ),
            ),
            accountName: Text(auth.user?.name ?? 'Provider'),
            accountEmail: Text(auth.user?.email ?? ''),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Colors.blue, Colors.blueAccent]),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Overview'),
            selected: _currentTab == 0,
            onTap: () => setState(() => _currentTab = 0),
          ),
          ListTile(
            leading: const Icon(Icons.miscellaneous_services),
            title: const Text('My Services'),
            selected: _currentTab == 1,
            onTap: () => setState(() => _currentTab = 1),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: Text('Bookings (${_myBookings.length})'),
            selected: _currentTab == 2,
            onTap: () => setState(() => _currentTab = 2),
          ),
          ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('Availability'),
            selected: _currentTab == 3,
            onTap: () => setState(() => _currentTab = 3),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () => auth.logout(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentTab) {
      case 0:
        return _buildOverview();
      case 1:
        return _buildMyServices();
      case 2:
        return _buildBookings();
      case 3:
        return _buildAvailability();
      default:
        return _buildOverview();
    }
  }

  Widget _buildOverview() {
    final pendingBookings = _myBookings.where((b) => b['status'] == 'pending').length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Welcome Back!', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _StatCard('My Services', '${_myServices.length}', Icons.miscellaneous_services, Colors.blue)),
              const SizedBox(width: 12),
              Expanded(child: _StatCard('Total Bookings', '${_myBookings.length}', Icons.calendar_today, Colors.orange)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _StatCard('Pending', '$pendingBookings', Icons.pending, Colors.red)),
              const SizedBox(width: 12),
              Expanded(child: _StatCard('Completed', '${_myBookings.where((b) => b['status'] == 'completed').length}', Icons.check_circle, Colors.green)),
            ],
          ),
          if (pendingBookings > 0) ...[
            const SizedBox(height: 24),
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.notifications_active, color: Colors.orange),
                    const SizedBox(width: 12),
                    Expanded(child: Text('$pendingBookings pending booking(s) require your attention!', style: const TextStyle(fontWeight: FontWeight.w500))),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMyServices() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.miscellaneous_services, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Service Management', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () => _showAddServiceDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Add New Service'),
          ),
        ],
      ),
    );
  }

  Widget _buildBookings() {
    if (_myBookings.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No bookings yet', style: TextStyle(fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _myBookings.length,
      itemBuilder: (context, index) {
        final booking = _myBookings[index];
        final status = booking['status'] ?? 'pending';
        final statusColor = switch (status) {
          'pending' => Colors.orange,
          'confirmed' => Colors.blue,
          'completed' => Colors.green,
          'cancelled' => Colors.red,
          _ => Colors.grey,
        };

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: statusColor.withValues(alpha: 0.2),
              child: Icon(Icons.calendar_today, color: statusColor),
            ),
            title: Text(booking['customer_name'] ?? 'Customer'),
            subtitle: Text('Status: $status'),
            trailing: PopupMenuButton<String>(
              onSelected: (value) => _updateBookingStatus(booking['_id'], value),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'confirmed', child: Text('Confirm')),
                const PopupMenuItem(value: 'completed', child: Text('Mark Complete')),
                const PopupMenuItem(value: 'cancelled', child: Text('Cancel')),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvailability() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.access_time, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('Availability settings coming soon', style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  void _showAddServiceDialog() {
    showDialog(
      context: context,
      builder: (context) => const AlertDialog(
        title: Text('Add Service'),
        content: Text('Service creation form will be implemented here.'),
      ),
    );
  }

  Future<void> _updateBookingStatus(String bookingId, String status) async {
    try {
      final token = await _storage.getToken();
      await http.put(
        Uri.parse('${ApiConstants.bookings}/$bookingId/status'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({'status': status}),
      );
      _loadData();
    } catch (_) {}
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard(this.title, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
