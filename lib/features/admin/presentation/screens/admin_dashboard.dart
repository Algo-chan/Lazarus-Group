import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:local_service_app/api_service.dart';
import 'package:local_service_app/providers/auth_provider.dart';
import 'package:local_service_app/core/enums/user_role.dart';
import 'package:local_service_app/shared/widgets/role_badge.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentTab = 0;
  Map<String, dynamic>? _stats;
  List<dynamic> _users = [];
  List<dynamic> _pendingProviders = [];
  List<dynamic> _logs = [];
  List<dynamic> _services = [];
  List<dynamic> _bookings = [];
  bool _isLoading = true;

  final _searchController = TextEditingController();
  String _userRoleFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      final List<Future<dynamic>> futures = [
        ApiService.getAdminStats(),
        ApiService.getAdminUsers(role: _userRoleFilter == 'All' ? null : _userRoleFilter, search: _searchController.text),
        ApiService.getPendingProviders(),
        ApiService.getAuditLogs(),
        ApiService.getServices(),
        ApiService.getProviderBookings(),
      ];
      final results = await Future.wait(futures);

      if (mounted) {
        setState(() {
          _stats = results[0] as Map<String, dynamic>?;
          _users = results[1] as List<dynamic>? ?? [];
          _pendingProviders = results[2] as List<dynamic>? ?? [];
          _logs = results[3] as List<dynamic>? ?? [];
          _services = results[4] as List<dynamic>? ?? [];
          _bookings = results[5] as List<dynamic>? ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading admin data: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final auth = context.read<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Console', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAllData),
          IconButton(icon: const Icon(Icons.logout), onPressed: () => auth.logout()),
        ],
      ),
      drawer: _buildDrawer(colors, auth),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildTabBody(colors),
    );
  }

  Widget _buildDrawer(ColorScheme colors, AuthProvider auth) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(auth.currentUser?['name'] ?? 'Admin'),
            accountEmail: Text(auth.currentUser?['email'] ?? ''),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(auth.currentUser?['name']?[0] ?? 'A', style: TextStyle(color: colors.primary, fontSize: 24, fontWeight: FontWeight.bold)),
            ),
            decoration: BoxDecoration(color: colors.primary),
          ),
          _drawerItem(0, 'Overview', Icons.dashboard),
          _drawerItem(1, 'User Management', Icons.people),
          _drawerItem(2, 'Pending Providers', Icons.verified_user, badge: _pendingProviders.length),
          _drawerItem(3, 'Audit Logs', Icons.list_alt),
          _drawerItem(4, 'Service Control', Icons.build),
          _drawerItem(5, 'Global Bookings', Icons.calendar_today),
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
        setState(() => _currentTab = index);
        Navigator.pop(context);
      },
    );
  }

  Widget _buildTabBody(ColorScheme colors) {
    switch (_currentTab) {
      case 0: return _buildOverview(colors);
      case 1: return _buildUsers(colors);
      case 2: return _buildPending(colors);
      case 3: return _buildLogs(colors);
      case 4: return _buildServices(colors);
      case 5: return _buildBookings(colors);
      default: return const Center(child: Text('Tab under construction'));
    }
  }

  Widget _buildOverview(ColorScheme colors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Platform Stats', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: [
              _statCard('Total Users', '${_stats?['total_users'] ?? 0}', Colors.blue),
              _statCard('Providers', '${_stats?['total_providers'] ?? 0}', Colors.orange),
              _statCard('Customers', '${_stats?['total_customers'] ?? 0}', Colors.green),
              _statCard('Bookings', '${_stats?['total_bookings'] ?? 0}', Colors.purple),
              _statCard('Verified', '${_stats?['verified_providers'] ?? 0}', Colors.cyan),
              _statCard('Services', '${_stats?['total_services'] ?? 0}', Colors.indigo),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Card(
      elevation: 0,
      color: color.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: color.withOpacity(0.2))),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: color.withOpacity(0.8))),
        ],
      ),
    );
  }

  Widget _buildUsers(ColorScheme colors) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search users...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onSubmitted: (_) => _loadAllData(),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _users.length,
            itemBuilder: (context, index) {
              final user = _users[index];
              return ListTile(
                leading: CircleAvatar(child: Text(user['name']?[0] ?? 'U')),
                title: Text(user['name'] ?? ''),
                subtitle: Text(user['email'] ?? ''),
                trailing: RoleBadge(role: UserRole.fromString(user['role'] ?? 'customer'), isActive: user['is_active']),
                onTap: () => _showUserActions(user),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showUserActions(dynamic user) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Wrap(
        children: [
          ListTile(
            leading: Icon(user['is_verified'] ? Icons.cancel : Icons.verified, color: Colors.blue),
            title: Text(user['is_verified'] ? 'Unverify' : 'Verify'),
            onTap: () {
              ApiService.verifyProvider(user['id'], !user['is_verified']).then((_) => _loadAllData());
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(user['is_active'] ? Icons.block : Icons.check_circle, color: Colors.red),
            title: Text(user['is_active'] ? 'Ban' : 'Unban'),
            onTap: () {
              ApiService.banUser(user['id']).then((_) => _loadAllData());
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPending(ColorScheme colors) {
    return ListView.builder(
      itemCount: _pendingProviders.length,
      itemBuilder: (context, index) {
        final p = _pendingProviders[index];
        return ListTile(
          title: Text(p['name'] ?? ''),
          subtitle: Text(p['email'] ?? ''),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(icon: const Icon(Icons.check, color: Colors.green), onPressed: () => ApiService.verifyProvider(p['id'], true).then((_) => _loadAllData())),
              IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () {}),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLogs(ColorScheme colors) {
    return ListView.builder(
      itemCount: _logs.length,
      itemBuilder: (context, index) {
        final log = _logs[index];
        return ListTile(
          dense: true,
          title: Text(log['action'] ?? ''),
          subtitle: Text('${log['details']}\n${log['timestamp']}'),
        );
      },
    );
  }

  Widget _buildServices(ColorScheme colors) {
    return ListView.builder(
      itemCount: _services.length,
      itemBuilder: (context, index) {
        final s = _services[index];
        return ListTile(
          title: Text(s['title'] ?? ''),
          subtitle: Text(s['provider'] ?? ''),
          trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => ApiService.deleteService(s['id']).then((_) => _loadAllData())),
        );
      },
    );
  }

  Widget _buildBookings(ColorScheme colors) {
    return ListView.builder(
      itemCount: _bookings.length,
      itemBuilder: (context, index) {
        final b = _bookings[index];
        return ListTile(
          title: Text(b['serviceName'] ?? ''),
          subtitle: Text('${b['customerName']} - ${b['status']}'),
        );
      },
    );
  }
}
