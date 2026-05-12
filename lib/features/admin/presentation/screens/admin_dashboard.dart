import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:local_service_app/core/constants/api_constants.dart';
import 'package:local_service_app/core/enums/user_role.dart';
import 'package:local_service_app/core/services/secure_storage_service.dart';
import 'package:local_service_app/shared/widgets/role_badge.dart';
import 'package:local_service_app/shared/widgets/loading_widget.dart';
import 'package:local_service_app/shared/widgets/error_display.dart';
import 'package:local_service_app/features/auth/presentation/providers/auth_provider.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentTab = 0;
  Map<String, dynamic>? _analytics;
  List<dynamic> _users = [];
  List<dynamic> _pendingProviders = [];
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
        http.get(Uri.parse(ApiConstants.adminAnalytics), headers: headers),
        http.get(Uri.parse(ApiConstants.adminUsers), headers: headers),
        http.get(Uri.parse(ApiConstants.adminPendingProviders), headers: headers),
      ]);

      _analytics = jsonDecode(results[0].body);
      _users = jsonDecode(results[1].body)['users'] ?? [];
      _pendingProviders = jsonDecode(results[2].body);
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
        title: const Text('Admin Panel'),
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
          ? const LoadingWidget(message: 'Loading admin data...')
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
                (auth.user?.name ?? 'A')[0].toUpperCase(),
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
              ),
            ),
            accountName: Text(auth.user?.name ?? 'Admin'),
            accountEmail: Text(auth.user?.email ?? ''),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Colors.red, Colors.redAccent]),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            selected: _currentTab == 0,
            onTap: () => setState(() => _currentTab = 0),
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Users'),
            selected: _currentTab == 1,
            onTap: () => setState(() => _currentTab = 1),
          ),
          ListTile(
            leading: const Icon(Icons.pending_actions),
            title: Text('Pending Providers (${_pendingProviders.length})'),
            selected: _currentTab == 2,
            onTap: () => setState(() => _currentTab = 2),
          ),
          ListTile(
            leading: const Icon(Icons.analytics),
            title: const Text('Analytics'),
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
        return _buildAnalyticsOverview();
      case 1:
        return _buildUserList();
      case 2:
        return _buildPendingProviders();
      case 3:
        return _buildDetailedAnalytics();
      default:
        return _buildAnalyticsOverview();
    }
  }

  Widget _buildAnalyticsOverview() {
    if (_analytics == null) return const SizedBox();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('System Overview', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _StatCard('Total Users', '${_analytics!['total_users'] ?? 0}', Icons.people, Colors.blue)),
              const SizedBox(width: 12),
              Expanded(child: _StatCard('Providers', '${_analytics!['total_providers'] ?? 0}', Icons.build, Colors.orange)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _StatCard('Customers', '${_analytics!['total_customers'] ?? 0}', Icons.person, Colors.green)),
              const SizedBox(width: 12),
              Expanded(child: _StatCard('Services', '${_analytics!['total_services'] ?? 0}', Icons.miscellaneous_services, Colors.purple)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _StatCard('Bookings', '${_analytics!['total_bookings'] ?? 0}', Icons.calendar_today, Colors.teal)),
              const SizedBox(width: 12),
              Expanded(child: _StatCard('Verified', '${_analytics!['verified_providers'] ?? 0}', Icons.verified, Colors.indigo)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text('All Users (${_users.length})', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _users.length,
            itemBuilder: (context, index) {
              final user = _users[index];
              return ListTile(
                leading: CircleAvatar(child: Text((user['name'] ?? '?')[0].toUpperCase())),
                title: Text(user['name'] ?? ''),
                subtitle: Text('${user['email']}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RoleBadge(role: UserRole.fromString(user['role'] ?? 'customer')),
                    const SizedBox(width: 8),
                    if (user['is_verified'] == true)
                      const Icon(Icons.verified, color: Colors.blue, size: 18),
                    if (user['is_active'] == false)
                      const Icon(Icons.block, color: Colors.red, size: 18),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPendingProviders() {
    if (_pendingProviders.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text('No pending provider approvals', style: TextStyle(fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _pendingProviders.length,
      itemBuilder: (context, index) {
        final provider = _pendingProviders[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(child: Text((provider['name'] ?? '?')[0].toUpperCase())),
            title: Text(provider['name'] ?? ''),
            subtitle: Text(provider['email'] ?? ''),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check_circle, color: Colors.green),
                  onPressed: () => _verifyProvider(provider['id'], true),
                ),
                IconButton(
                  icon: const Icon(Icons.cancel, color: Colors.red),
                  onPressed: () => _verifyProvider(provider['id'], false),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailedAnalytics() {
    if (_analytics == null) return const SizedBox();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Detailed Analytics', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: _analytics!.entries.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatKey(e.key), style: const TextStyle(fontSize: 16)),
                      Text('${e.value}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                )).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatKey(String key) {
    return key.split('_').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
  }

  Future<void> _verifyProvider(String userId, bool verified) async {
    try {
      final token = await _storage.getToken();
      await http.put(
        Uri.parse('${ApiConstants.adminUsers}/$userId/verify'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({'is_verified': verified}),
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
