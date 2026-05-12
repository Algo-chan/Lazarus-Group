import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:local_service_app/core/constants/api_constants.dart';
import 'package:local_service_app/core/services/secure_storage_service.dart';
import 'package:local_service_app/shared/widgets/loading_widget.dart';
import 'package:local_service_app/shared/widgets/error_display.dart';
import 'package:local_service_app/features/auth/presentation/providers/auth_provider.dart';

class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  int _currentTab = 0;
  List<dynamic> _myBookings = [];
  List<dynamic> _services = [];
  String _searchQuery = '';
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
        http.get(Uri.parse(ApiConstants.services), headers: headers),
      ]);

      _myBookings = jsonDecode(results[0].body);
      final servicesResponse = jsonDecode(results[1].body);
      _services = servicesResponse['services'] ?? [];
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
        title: const Text('LocalConnect'),
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
          ? const LoadingWidget(message: 'Loading...')
          : _error != null
              ? ErrorDisplay(message: _error!, onRetry: _loadData)
              : _buildBody(),
      bottomNavigationBar: _buildBottomNav(),
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
                (auth.user?.name ?? 'C')[0].toUpperCase(),
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
              ),
            ),
            accountName: Text(auth.user?.name ?? 'Customer'),
            accountEmail: Text(auth.user?.email ?? ''),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF007BFF), Color(0xFF00C6FB)]),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            selected: _currentTab == 0,
            onTap: () => setState(() => _currentTab = 0),
          ),
          ListTile(
            leading: const Icon(Icons.search),
            title: const Text('Browse Services'),
            selected: _currentTab == 1,
            onTap: () => setState(() => _currentTab = 1),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: Text('My Bookings (${_myBookings.length})'),
            selected: _currentTab == 2,
            onTap: () => setState(() => _currentTab = 2),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
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

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _currentTab,
      onTap: (index) => setState(() => _currentTab = index),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF007BFF),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Bookings'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }

  Widget _buildBody() {
    switch (_currentTab) {
      case 0:
        return _buildHome();
      case 1:
        return _buildSearch();
      case 2:
        return _buildBookings();
      case 3:
        return _buildProfile();
      default:
        return _buildHome();
    }
  }

  Widget _buildHome() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Find Local Experts',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: InputDecoration(
              hintText: 'Search for any service...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (val) => setState(() => _searchQuery = val),
          ),
          const SizedBox(height: 24),
          Text('Popular Services', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...(_services.where((s) {
            if (_searchQuery.isEmpty) return true;
            final query = _searchQuery.toLowerCase();
            return (s['title'] ?? '').toString().toLowerCase().contains(query) ||
                (s['category'] ?? '').toString().toLowerCase().contains(query);
          }).take(6).map((service) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    child: const Icon(Icons.miscellaneous_services),
                  ),
                  title: Text(service['title'] ?? ''),
                  subtitle: Text('${service['provider']} - ${service['price'] ?? ''}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showBookingDialog(service),
                ),
              ))),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search services...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (val) => setState(() => _searchQuery = val),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _services.length,
            itemBuilder: (context, index) {
              final service = _services[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: Icon(
                    _getCategoryIcon(service['category'] ?? ''),
                    color: Theme.of(context).primaryColor,
                  ),
                  title: Text(service['title'] ?? ''),
                  subtitle: Text(service['provider'] ?? ''),
                  trailing: Text(service['price'] ?? ''),
                  onTap: () => _showBookingDialog(service),
                ),
              );
            },
          ),
        ),
      ],
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
            SizedBox(height: 8),
            Text('Browse services and book a provider', style: TextStyle(color: Colors.grey)),
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
          'in_progress' => Colors.purple,
          'completed' => Colors.green,
          'cancelled' => Colors.red,
          _ => Colors.grey,
        };

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: statusColor.withValues(alpha: 0.2),
              child: Icon(Icons.calendar_today, color: statusColor, size: 20),
            ),
            title: Text('Booking #${booking['_id']?.toString().substring(0, 6) ?? ''}'),
            subtitle: Text('Status: $status'),
            trailing: status == 'pending'
                ? IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    onPressed: () => _cancelBooking(booking['_id']),
                  )
                : Icon(Icons.chevron_right),
          ),
        );
      },
    );
  }

  Widget _buildProfile() {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 32),
          CircleAvatar(
            radius: 50,
            backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            child: Text(
              (user?.name ?? 'U')[0].toUpperCase(),
              style: TextStyle(fontSize: 40, color: Theme.of(context).primaryColor),
            ),
          ),
          const SizedBox(height: 16),
          Text(user?.name ?? 'Customer', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(user?.email ?? '', style: const TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 8),
          Text('Role: Customer', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          const SizedBox(height: 32),
          Card(
            child: Column(
              children: [
                ListTile(leading: const Icon(Icons.settings), title: const Text('Settings'), trailing: const Icon(Icons.chevron_right), onTap: () {}),
                const Divider(height: 1),
                ListTile(leading: const Icon(Icons.help), title: const Text('Help & Support'), trailing: const Icon(Icons.chevron_right), onTap: () {}),
                const Divider(height: 1),
                ListTile(leading: const Icon(Icons.info), title: const Text('About'), trailing: const Icon(Icons.chevron_right), onTap: () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('plumbing')) return Icons.plumbing;
    if (cat.contains('electric')) return Icons.electrical_services;
    if (cat.contains('clean')) return Icons.cleaning_services;
    if (cat.contains('garden')) return Icons.yard;
    if (cat.contains('paint')) return Icons.format_paint;
    return Icons.miscellaneous_services;
  }

  void _showBookingDialog(dynamic service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(service['title'] ?? 'Book Service'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Provider: ${service['provider'] ?? ''}'),
            Text('Price: ${service['price'] ?? ''}'),
            if (service['location'] != null) Text('Location: ${service['location']}'),
            const SizedBox(height: 16),
            const Text('Would you like to request this service?'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _bookService(service);
            },
            child: const Text('Request Now'),
          ),
        ],
      ),
    );
  }

  Future<void> _bookService(dynamic service) async {
    try {
      final token = await _storage.getToken();
      await http.post(
        Uri.parse(ApiConstants.bookings),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({
          'service_id': service['_id'] ?? service['id'],
          'provider_id': service['provider_id'],
          'description': 'Service request from customer',
        }),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking requested!'), backgroundColor: Colors.green),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _cancelBooking(String bookingId) async {
    try {
      final token = await _storage.getToken();
      await http.put(
        Uri.parse('${ApiConstants.bookings}/$bookingId/status'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({'status': 'cancelled'}),
      );
      _loadData();
    } catch (_) {}
  }
}
