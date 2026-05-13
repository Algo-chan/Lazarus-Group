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
  List<dynamic> _logs = [];
  List<dynamic> _services = [];
  List<dynamic> _bookings = [];
  bool _isLoading = true;
  String? _error;

  final TextEditingController _searchController = TextEditingController();
  String _userRoleFilter = 'All';

  final TextEditingController _serviceSearchController = TextEditingController();
  String _serviceCategoryFilter = 'All';

  String _bookingStatusFilter = 'All';

  final _storage = SecureStorageService();
  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _serviceSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await _storage.getToken();
      final headers = {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'};

      String usersUrl = ApiConstants.adminUsers;
      Map<String, String> queryParams = {};
      if (_userRoleFilter != 'All') queryParams['role'] = _userRoleFilter.toLowerCase();
      if (_searchController.text.isNotEmpty) queryParams['search'] = _searchController.text;
      if (queryParams.isNotEmpty) {
        usersUrl += '?' + Uri(queryParameters: queryParams).query;
      }

      String servicesUrl = ApiConstants.adminServices;
      Map<String, String> svcParams = {};
      if (_serviceCategoryFilter != 'All') svcParams['category'] = _serviceCategoryFilter;
      if (_serviceSearchController.text.isNotEmpty) svcParams['search'] = _serviceSearchController.text;
      if (svcParams.isNotEmpty) {
        servicesUrl += '?' + Uri(queryParameters: svcParams).query;
      }

      String bookingsUrl = ApiConstants.adminBookings;
      if (_bookingStatusFilter != 'All') {
        bookingsUrl += '?status=$_bookingStatusFilter';
      }

      Future<http.Response?> _safeGet(String url) async {
        try {
          return await http.get(Uri.parse(url), headers: headers);
        } catch (_) {
          return null;
        }
      }

      final results = await Future.wait([
        _safeGet(ApiConstants.adminAnalytics),
        _safeGet(usersUrl),
        _safeGet(ApiConstants.adminPendingProviders),
        _safeGet(ApiConstants.adminLogs),
        _safeGet(servicesUrl),
        _safeGet(bookingsUrl),
      ]);

      void parseField(int index, void Function(dynamic) setter) {
        final res = results[index];
        if (res != null && res.statusCode == 200) {
          try { setter(jsonDecode(res.body)); } catch (_) {}
        }
      }

      _analytics = null; _users = []; _pendingProviders = []; _logs = []; _services = []; _bookings = [];

      parseField(0, (d) => _analytics = d);
      parseField(1, (d) { final u = d['users']; if (u != null) _users = u; });
      parseField(2, (d) => _pendingProviders = d);
      parseField(3, (d) => _logs = d);
      parseField(4, (d) => _services = d);
      parseField(5, (d) => _bookings = d);

      final cats = _services.map((s) => s['category'] as String).toSet().toList()..sort();
      _categories = cats;

      if (_analytics == null && _error == null) {
        _error = 'Failed to load analytics. Is the backend running?';
      }
    } catch (e) {
      _error = 'Connection error: $e';
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(_tabTitles[_currentTab]),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
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

  static const _tabTitles = [
    'Dashboard',
    'User Management',
    'Pending Providers',
    'System Logs',
    'Services',
    'Bookings',
  ];

  Widget _buildDrawer(BuildContext context, AuthProvider auth) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                (auth.user?.name ?? 'A')[0].toUpperCase(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A1A2E),
                ),
              ),
            ),
            accountName: Text(
              auth.user?.name ?? 'Admin',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            accountEmail: Text(auth.user?.email ?? ''),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(0, 'Dashboard', Icons.dashboard),
                _buildDrawerItem(1, 'Users', Icons.people),
                _buildDrawerItem(2, 'Pending Providers', Icons.pending_actions,
                    badge: _pendingProviders.length),
                _buildDrawerItem(3, 'System Logs', Icons.history),
                _buildDrawerItem(4, 'Services', Icons.miscellaneous_services),
                _buildDrawerItem(5, 'Bookings', Icons.calendar_today),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
            onTap: () => auth.logout(),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(int index, String title, IconData icon, {int? badge}) {
    final selected = _currentTab == index;
    return ListTile(
      leading: Icon(icon, color: selected ? const Color(0xFF1A1A2E) : null),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          color: selected ? const Color(0xFF1A1A2E) : null,
        ),
      ),
      selected: selected,
      selectedTileColor: const Color(0xFF1A1A2E).withOpacity(0.08),
      trailing: badge != null && badge > 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$badge',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            )
          : null,
      onTap: () {
        Navigator.pop(context);
        setState(() => _currentTab = index);
      },
    );
  }

  Widget _buildBody() {
    switch (_currentTab) {
      case 0: return _buildAnalyticsOverview();
      case 1: return _buildUserList();
      case 2: return _buildPendingProviders();
      case 3: return _buildSystemLogs();
      case 4: return _buildServicesList();
      case 5: return _buildBookingsList();
      default: return _buildAnalyticsOverview();
    }
  }

  // ---- TAB 0: Analytics Overview ----

  Widget _buildAnalyticsOverview() {
    if (_analytics == null) return const SizedBox();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeBanner(),
          const SizedBox(height: 20),
          Text(
            'System Overview',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildStatGrid(),
        ],
      ),
    );
  }

  Widget _buildWelcomeBanner() {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good Morning' : hour < 17 ? 'Good Afternoon' : 'Good Evening';
    final auth = context.read<AuthProvider>();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: const Color(0xFF1A1A2E).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$greeting, ${auth.user?.name ?? 'Admin'}',
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Here\'s what\'s happening with your platform today.',
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildStatGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _StatCard(
              'Total Users', '${_analytics!['total_users'] ?? 0}',
              Icons.people, const Color(0xFF2196F3),
              onTap: () => setState(() { _currentTab = 1; _userRoleFilter = 'All'; }),
            )),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(
              'Providers', '${_analytics!['total_providers'] ?? 0}',
              Icons.build, const Color(0xFFFF9800),
              onTap: () => setState(() { _currentTab = 1; _userRoleFilter = 'Provider'; }),
            )),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _StatCard(
              'Customers', '${_analytics!['total_customers'] ?? 0}',
              Icons.person, const Color(0xFF4CAF50),
              onTap: () => setState(() { _currentTab = 1; _userRoleFilter = 'Customer'; }),
            )),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(
              'Services', '${_analytics!['total_services'] ?? 0}',
              Icons.miscellaneous_services, const Color(0xFF9C27B0),
              onTap: () => setState(() => _currentTab = 4),
            )),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _StatCard(
              'Bookings', '${_analytics!['total_bookings'] ?? 0}',
              Icons.calendar_today, const Color(0xFF009688),
              onTap: () => setState(() => _currentTab = 5),
            )),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(
              'Pending Apps', '${_pendingProviders.length}',
              Icons.pending_actions, const Color(0xFFF44336),
              onTap: () => setState(() => _currentTab = 2),
            )),
          ],
        ),
      ],
    );
  }

  // ---- TAB 1: User Management ----

  Widget _buildUserList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by name or email...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _loadData();
                    },
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _loadData(),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['All', 'Admin', 'Provider', 'Customer'].map((role) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(role),
                      selected: _userRoleFilter == role,
                      selectedColor: const Color(0xFF1A1A2E),
                      labelStyle: TextStyle(
                        color: _userRoleFilter == role ? Colors.white : null,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _userRoleFilter = role);
                          _loadData();
                        }
                      },
                    ),
                  )).toList(),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _users.isEmpty
            ? const Center(child: Text('No users found matching your criteria.'))
            : ListView.builder(
                itemCount: _users.length,
                itemBuilder: (context, index) {
                  final user = _users[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: CircleAvatar(
                        backgroundColor: _avatarColor(user['role'] ?? 'customer'),
                        child: Text(
                          (user['name'] ?? '?')[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(user['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${user['email']}', style: const TextStyle(fontSize: 13)),
                          if (user['created_at'] != null)
                            Text('Joined: ${_formatTimestamp(user['created_at'])}',
                              style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          RoleBadge(
                            role: UserRole.fromString(user['role'] ?? 'customer'),
                            isActive: user['is_active'] ?? true,
                          ),
                          const SizedBox(width: 8),
                          _buildUserActionMenu(user),
                        ],
                      ),
                    ),
                  );
                },
              ),
        ),
      ],
    );
  }

  Color _avatarColor(String role) {
    switch (role) {
      case 'admin': return const Color(0xFFF44336);
      case 'provider': return const Color(0xFFFF9800);
      default: return const Color(0xFF4CAF50);
    }
  }

  Widget _buildUserActionMenu(dynamic user) {
    return PopupMenuButton<String>(
      onSelected: (value) => _handleUserAction(value, user),
      icon: const Icon(Icons.more_vert, size: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'verify',
          child: ListTile(
            leading: Icon(user['is_verified'] == true ? Icons.cancel : Icons.verified,
                color: Colors.blue, size: 20),
            title: Text(user['is_verified'] == true ? 'Unverify' : 'Verify', style: const TextStyle(fontSize: 14)),
            contentPadding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
        ),
        PopupMenuItem(
          value: 'ban',
          child: ListTile(
            leading: Icon(user['is_active'] == false ? Icons.check_circle : Icons.block,
                color: Colors.red, size: 20),
            title: Text(user['is_active'] == false ? 'Unban' : 'Ban', style: const TextStyle(fontSize: 14)),
            contentPadding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: ListTile(
            leading: Icon(Icons.delete, color: Colors.grey, size: 20),
            title: Text('Delete', style: TextStyle(fontSize: 14)),
            contentPadding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
        ),
      ],
    );
  }

  Future<void> _handleUserAction(String action, dynamic user) async {
    final userId = user['id'];
    final token = await _storage.getToken();
    final headers = {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'};

    try {
      if (action == 'verify') {
        await http.put(
          Uri.parse('${ApiConstants.adminUsers}/$userId/verify'),
          headers: headers,
          body: jsonEncode({'is_verified': !(user['is_verified'] ?? false)}),
        );
      } else if (action == 'ban') {
        await http.put(
          Uri.parse('${ApiConstants.adminUsers}/$userId/ban'),
          headers: headers,
        );
      } else if (action == 'delete') {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Confirm Delete'),
            content: Text('Are you sure you want to delete ${user['name']}? This action cannot be undone.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true), 
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
        if (confirm == true) {
          await http.delete(Uri.parse('${ApiConstants.adminUsers}/$userId'), headers: headers);
        } else {
          return;
        }
      }
      _loadData();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  // ---- TAB 2: Pending Providers ----

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
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _pendingProviders.length,
      itemBuilder: (context, index) {
        final provider = _pendingProviders[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFFF9800),
              child: Text(
                (provider['name'] ?? '?')[0].toUpperCase(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(provider['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(provider['email'] ?? ''),
                if (provider['created_at'] != null)
                  Text('Applied: ${_formatTimestamp(provider['created_at'])}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Tooltip(
                  message: 'Approve',
                  child: IconButton(
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                    onPressed: () => _verifyProvider(provider['id'], true),
                  ),
                ),
                Tooltip(
                  message: 'Reject',
                  child: IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    onPressed: () => _verifyProvider(provider['id'], false),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---- TAB 3: System Logs ----

  Widget _buildSystemLogs() {
    if (_logs.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No activity logs found.', style: TextStyle(fontSize: 16)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Recent Activity (Last 50)',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _logs.length,
            itemBuilder: (context, index) {
              final log = _logs[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getLogColor(log['action']).withOpacity(0.15),
                    child: Icon(_getLogIcon(log['action']),
                        color: _getLogColor(log['action']), size: 20),
                  ),
                  title: Text(
                    _formatLogAction(log['action']),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 2),
                      Text(_getLogDescription(log), style: const TextStyle(fontSize: 13)),
                      const SizedBox(height: 2),
                      Text(
                        _formatTimestamp(log['timestamp']),
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  IconData _getLogIcon(String? action) {
    switch (action) {
      case 'VERIFY_USER': return Icons.verified;
      case 'BAN_USER': return Icons.block;
      case 'UNBAN_USER': return Icons.check_circle;
      case 'DELETE_USER': return Icons.delete_forever;
      case 'DELETE_SERVICE': return Icons.delete_sweep;
      case 'UPDATE_BOOKING_STATUS': return Icons.update;
      default: return Icons.info_outline;
    }
  }

  Color _getLogColor(String? action) {
    switch (action) {
      case 'VERIFY_USER': return Colors.blue;
      case 'BAN_USER': return Colors.red;
      case 'UNBAN_USER': return Colors.green;
      case 'DELETE_USER': return Colors.grey;
      case 'DELETE_SERVICE': return Colors.deepOrange;
      case 'UPDATE_BOOKING_STATUS': return Colors.teal;
      default: return Colors.indigo;
    }
  }

  String _formatLogAction(String? action) {
    if (action == null) return 'Unknown Action';
    return action.split('_').map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase()).join(' ');
  }

  String _getLogDescription(dynamic log) {
    final details = log['details'] ?? {};
    final action = log['action'];
    if (action == 'VERIFY_USER') {
      final verified = details['is_verified'] == true;
      return 'User ${log['target_id']} ${verified ? 'verified' : 'unverified'}';
    } else if (action == 'BAN_USER' || action == 'UNBAN_USER') {
      return '${action == 'BAN_USER' ? 'Banned' : 'Unbanned'} user ${details['email'] ?? log['target_id']}';
    } else if (action == 'DELETE_USER') {
      return 'Deleted user ${details['name']} (${details['email']})';
    } else if (action == 'DELETE_SERVICE') {
      return 'Deleted service "${details['title']}"';
    } else if (action == 'UPDATE_BOOKING_STATUS') {
      return 'Booking ${log['target_id']} status → ${details['status']}';
    }
    return 'Action performed on ${log['target_id']}';
  }

  String _formatTimestamp(String? ts) {
    if (ts == null) return '';
    try {
      final date = DateTime.parse(ts);
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return ts;
    }
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

  // ---- TAB 4: Services Management ----

  Widget _buildServicesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _serviceSearchController,
                decoration: InputDecoration(
                  hintText: 'Search by title or provider...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _serviceSearchController.clear();
                      _loadData();
                    },
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _loadData(),
              ),
              const SizedBox(height: 12),
              if (_categories.isNotEmpty)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['All', ..._categories].map((cat) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(cat),
                        selected: _serviceCategoryFilter == cat,
                        selectedColor: const Color(0xFF9C27B0),
                        labelStyle: TextStyle(
                          color: _serviceCategoryFilter == cat ? Colors.white : null,
                          fontSize: 13,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _serviceCategoryFilter = cat);
                            _loadData();
                          }
                        },
                      ),
                    )).toList(),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: _services.isEmpty
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.miscellaneous_services, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No services found.', style: TextStyle(fontSize: 16)),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _services.length,
                itemBuilder: (context, index) {
                  final svc = _services[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFF9C27B0).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.miscellaneous_services,
                                color: Color(0xFF9C27B0), size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(svc['title'] ?? '',
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                const SizedBox(height: 2),
                                Text('by ${svc['provider'] ?? 'Unknown'}',
                                    style: const TextStyle(fontSize: 13, color: Colors.grey)),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    _buildSmallChip(svc['category'] ?? '', const Color(0xFF9C27B0)),
                                    const SizedBox(width: 8),
                                    Text('\$${svc['price'] ?? 'N/A'}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF4CAF50),
                                          fontSize: 14,
                                        )),
                                    if (svc['verified'] == true) ...[
                                      const SizedBox(width: 8),
                                      const Icon(Icons.verified, size: 14, color: Colors.blue),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'delete') _deleteService(svc['_id'], svc['title'] ?? '');
                            },
                            icon: const Icon(Icons.more_vert, size: 20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'delete',
                                child: ListTile(
                                  leading: Icon(Icons.delete, color: Colors.red, size: 20),
                                  title: Text('Delete', style: TextStyle(fontSize: 14)),
                                  contentPadding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
        ),
      ],
    );
  }

  Widget _buildSmallChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
    );
  }

  Future<void> _deleteService(String serviceId, String title) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Service'),
        content: Text('Are you sure you want to delete "$title"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final token = await _storage.getToken();
      await http.delete(
        Uri.parse('${ApiConstants.adminServices}/$serviceId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      _loadData();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Service deleted'), behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  // ---- TAB 5: Bookings Management ----

  static const _bookingStatuses = ['All', 'pending', 'confirmed', 'in_progress', 'completed', 'cancelled'];

  Widget _buildBookingsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _bookingStatuses.map((status) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(status == 'All' ? 'All' : _formatBookingStatus(status)),
                  selected: _bookingStatusFilter == status,
                  selectedColor: _bookingStatusColor(status),
                  labelStyle: TextStyle(
                    color: _bookingStatusFilter == status ? Colors.white : null,
                    fontSize: 13,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _bookingStatusFilter = status);
                      _loadData();
                    }
                  },
                ),
              )).toList(),
            ),
          ),
        ),
        Expanded(
          child: _bookings.isEmpty
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_today, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No bookings found.', style: TextStyle(fontSize: 16)),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _bookings.length,
                itemBuilder: (context, index) {
                  final booking = _bookings[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: _bookingStatusColor(booking['status'] ?? 'pending').withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _bookingStatusIcon(booking['status'] ?? 'pending'),
                              color: _bookingStatusColor(booking['status'] ?? 'pending'),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(booking['customer_name'] ?? 'Unknown Customer',
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                const SizedBox(height: 2),
                                if (booking['description'] != null && (booking['description'] as String).isNotEmpty)
                                  Text(booking['description'],
                                    maxLines: 1, overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 13, color: Colors.grey)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    _buildBookingStatusBadge(booking['status'] ?? 'pending'),
                                    const Spacer(),
                                    Text(_formatTimestamp(booking['created_at']),
                                        style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (status) => _updateBookingStatus(booking['_id'], status),
                            icon: const Icon(Icons.edit, size: 20),
                            tooltip: 'Change status',
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            itemBuilder: (context) => _bookingStatuses
                              .where((s) => s != 'All' && s != booking['status'])
                              .map((status) => PopupMenuItem(
                                value: status,
                                child: ListTile(
                                  leading: Icon(
                                    _bookingStatusIcon(status),
                                    color: _bookingStatusColor(status),
                                    size: 20,
                                  ),
                                  title: Text(_formatBookingStatus(status), style: const TextStyle(fontSize: 14)),
                                  contentPadding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.compact,
                                ),
                              )).toList(),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
        ),
      ],
    );
  }

  Widget _buildBookingStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: _bookingStatusColor(status).withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _formatBookingStatus(status),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _bookingStatusColor(status),
        ),
      ),
    );
  }

  String _formatBookingStatus(String status) {
    return status.split('_').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
  }

  Color _bookingStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'confirmed': return Colors.blue;
      case 'in_progress': return Colors.purple;
      case 'completed': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData _bookingStatusIcon(String status) {
    switch (status) {
      case 'pending': return Icons.schedule;
      case 'confirmed': return Icons.check_circle_outline;
      case 'in_progress': return Icons.work_outline;
      case 'completed': return Icons.verified;
      case 'cancelled': return Icons.cancel_outlined;
      default: return Icons.help_outline;
    }
  }

  Future<void> _updateBookingStatus(String bookingId, String newStatus) async {
    try {
      final token = await _storage.getToken();
      await http.put(
        Uri.parse('${ApiConstants.adminBookings}/$bookingId/status'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({'status': newStatus}),
      );
      _loadData();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking status updated to ${_formatBookingStatus(newStatus)}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), behavior: SnackBarBehavior.floating),
      );
    }
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard(this.title, this.value, this.icon, this.color, {this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      shadowColor: color.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.75)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Icon(icon, color: Colors.white.withOpacity(0.3), size: 32),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
