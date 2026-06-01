import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:local_service_app/api_service.dart';
import 'package:local_service_app/providers/auth_provider.dart';

class ProviderDashboard extends StatefulWidget {
  const ProviderDashboard({super.key});

  @override
  State<ProviderDashboard> createState() => _ProviderDashboardState();
}

class _ProviderDashboardState extends State<ProviderDashboard> {
  int _currentTab = 0;
  bool _isLoading = true;
  List<dynamic> _services = [];
  List<dynamic> _bookings = [];
  List<dynamic> _reviews = [];
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthProvider>();
      final providerId = auth.currentUser?['id'] ?? auth.currentUser?['_id'];
      
      final List<Future<dynamic>> futures = [
        ApiService.getProfile(), // for stats
        ApiService.getServices(provider_id: providerId),
        ApiService.getProviderBookings(),
        if (providerId != null) ApiService.getProviderProfile(providerId) else Future.value({}),
      ];
      final results = await Future.wait(futures);

      if (mounted) {
        setState(() {
          _stats = results[0]['stats'];
          _services = results[1] as List<dynamic>? ?? [];
          _bookings = results[2] as List<dynamic>? ?? [];
          if (results.length > 3) {
            _reviews = results[3]['reviews'] ?? [];
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final auth = context.read<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Provider Console'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAll),
          IconButton(icon: const Icon(Icons.logout), onPressed: () => auth.logout()),
        ],
      ),
      drawer: _buildDrawer(colors, auth),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(colors),
      floatingActionButton: _currentTab == 1
          ? FloatingActionButton(
              onPressed: () => context.push('/provider/services/create'),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildDrawer(ColorScheme colors, AuthProvider auth) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(auth.currentUser?['name'] ?? 'Provider'),
            accountEmail: Text(auth.currentUser?['email'] ?? ''),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(auth.currentUser?['name']?[0] ?? 'P', style: TextStyle(color: colors.primary, fontSize: 24, fontWeight: FontWeight.bold)),
            ),
            decoration: BoxDecoration(color: colors.primary),
          ),
          _drawerItem(0, 'Overview', Icons.dashboard),
          _drawerItem(1, 'My Services', Icons.build, badge: _services.length),
          _drawerItem(2, 'Bookings', Icons.calendar_today, badge: _bookings.where((b) => b['status'] == 'pending').length),
          _drawerItem(3, 'Reviews', Icons.star, badge: _reviews.length),
          _drawerItem(4, 'Chats', Icons.chat),
        ],
      ),
    );
  }

  Widget _drawerItem(int index, String title, IconData icon, {int? badge}) {
    final selected = _currentTab == index;
    return ListTile(
      leading: Icon(icon, color: selected ? null : Colors.grey),
      title: Text(title, style: TextStyle(fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
      selected: selected,
      trailing: (badge != null && badge > 0)
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
              child: Text('$badge', style: const TextStyle(color: Colors.white, fontSize: 10)),
            )
          : null,
      onTap: () {
        if (index == 4) {
          context.push('/provider/chats');
          Navigator.pop(context);
        } else {
          setState(() => _currentTab = index);
          Navigator.pop(context);
        }
      },
    );
  }

  Widget _buildBody(ColorScheme colors) {
    switch (_currentTab) {
      case 0: return _buildOverview(colors);
      case 1: return _buildServices(colors);
      case 2: return _buildBookings(colors);
      case 3: return _buildReviews(colors);
      default: return _buildOverview(colors);
    }
  }

  Widget _buildOverview(ColorScheme colors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Good Day, Partner!', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Row(
            children: [
              _statCard('Total Bookings', '${_stats?['total_bookings'] ?? 0}', colors.primary),
              const SizedBox(width: 16),
              _statCard('Avg Rating', '${_stats?['avg_rating'] ?? 0.0}', colors.secondary),
            ],
          ),
          const SizedBox(height: 16),
          _statCard('Active Services', '${_services.length}', Colors.green, fullWidth: true),
          const SizedBox(height: 32),
          Text('Recent Activity', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (_bookings.isEmpty)
            const Text('No recent bookings')
          else
            ..._bookings.take(3).map((b) => ListTile(
              title: Text(b['serviceName'] ?? ''),
              subtitle: Text(b['customerName'] ?? ''),
              trailing: Text(b['status'] ?? ''),
            )),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, Color color, {bool fullWidth = false}) {
    final card = Card(
      elevation: 0,
      color: color.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: color.withOpacity(0.2))),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 12, color: color.withOpacity(0.8))),
          ],
        ),
      ),
    );
    return fullWidth ? SizedBox(width: double.infinity, child: card) : Expanded(child: card);
  }

  Widget _buildServices(ColorScheme colors) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _services.length,
      itemBuilder: (context, index) {
        final s = _services[index];
        return Card(
          child: ListTile(
            title: Text(s['title'] ?? ''),
            subtitle: Text(s['category'] ?? ''),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: () => context.push('/provider/services/${s['id']}/edit')),
                IconButton(icon: const Icon(Icons.delete, size: 20, color: Colors.red), onPressed: () => _confirmDelete(s['id'])),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Service?'),
        content: const Text('This will permanently remove the service listing.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () {
            ApiService.deleteService(id).then((_) => _loadAll());
            Navigator.pop(context);
          }, child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  Widget _buildBookings(ColorScheme colors) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _bookings.length,
      itemBuilder: (context, index) {
        final b = _bookings[index];
        return Card(
          child: ListTile(
            title: Text(b['customerName'] ?? 'Customer'),
            subtitle: Text('${b['serviceName']} • ${b['date']}'),
            trailing: _buildBookingActions(b, colors),
          ),
        );
      },
    );
  }

  Widget _buildBookingActions(dynamic b, ColorScheme colors) {
    final status = b['status'];
    if (status == 'pending') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(icon: const Icon(Icons.check, color: Colors.green), onPressed: () => _updateBooking(b['id'], 'confirm')),
          IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () => _updateBooking(b['id'], 'cancel')),
        ],
      );
    }
    if (status == 'confirmed') {
      return TextButton(onPressed: () => _updateBooking(b['id'], 'start'), child: const Text('Start'));
    }
    if (status == 'in_progress') {
      return TextButton(onPressed: () => _updateBooking(b['id'], 'complete'), child: const Text('Complete'));
    }
    return Text(status?.toUpperCase() ?? '', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold));
  }

  void _updateBooking(String id, String action) {
    ApiService.updateBookingStatus(id, action).then((_) => _loadAll());
  }

  Widget _buildReviews(ColorScheme colors) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _reviews.length,
      itemBuilder: (context, index) {
        final r = _reviews[index];
        return Card(
          child: ListTile(
            title: Row(
              children: [
                Text(r['reviewerName'] ?? 'Anonymous', style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                Text('${r['rating']} ★', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
              ],
            ),
            subtitle: Text(r['comment'] ?? ''),
          ),
        );
      },
    );
  }
}
