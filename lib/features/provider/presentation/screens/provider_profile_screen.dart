import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:local_service_app/core/constants/api_constants.dart';
import 'package:local_service_app/core/network/api_client.dart';
import 'package:local_service_app/providers/auth_provider.dart';
import 'package:local_service_app/shared/widgets/confirm_dialog.dart';
import 'package:local_service_app/shared/widgets/loading_widget.dart';
import 'package:local_service_app/shared/widgets/error_display.dart';

class ProviderProfileScreen extends StatefulWidget {
  const ProviderProfileScreen({super.key});

  @override
  State<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends State<ProviderProfileScreen> {
  final _api = ApiClient();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Profile')),
        body: const ErrorDisplay(message: 'User data not available'),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 24),
          _buildAvatar(user['name'], user['profileImage']),
          const SizedBox(height: 16),
          Center(child: Text(user['name'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
          const SizedBox(height: 4),
          if (user['phone'] != null)
            Center(
              child: Text(user['phone'], style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
            ),
          if ((user['email'] as String).isNotEmpty) ...[
            const SizedBox(height: 2),
            Center(
              child: Text(user['email'], style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
            ),
          ],
          const SizedBox(height: 12),
          Center(
            child: _buildVerificationBadge(user['is_verified'] == true),
          ),
          const SizedBox(height: 24),
          _buildStatsRow(user['id']),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: () => _showEditProfileSheet(context, user['name'], user['phone'] ?? '', user['email']),
              icon: const Icon(Icons.edit),
              label: const Text('Edit Profile'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: () => _handleLogout(context),
              icon: const Icon(Icons.logout, color: Color(0xFFDC3545)),
              label: const Text('Logout', style: TextStyle(color: Color(0xFFDC3545))),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFDC3545)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String name, String? imageUrl) {
    return Center(
      child: CircleAvatar(
        radius: 48,
        backgroundColor: const Color(0xFF007BFF),
        backgroundImage: imageUrl != null && imageUrl.isNotEmpty ? NetworkImage(imageUrl) as ImageProvider? : null,
        child: imageUrl == null || imageUrl.isEmpty
            ? Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
              )
            : null,
      ),
    );
  }

  Widget _buildVerificationBadge(bool isVerified) {
    if (isVerified) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF28A745).withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified, size: 18, color: Color(0xFF28A745)),
            SizedBox(width: 6),
            Text('Verified', style: TextStyle(color: Color(0xFF28A745), fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFC107).withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.pending, size: 18, color: Color(0xFFFFC107)),
          SizedBox(width: 6),
          Text('Pending Verification', style: TextStyle(color: Color(0xFFFFC107), fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildStatsRow(String providerId) {
    return FutureBuilder<Map<String, int>>(
      future: _fetchStats(providerId),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? {'services': 0, 'bookings': 0, 'reviews': 0};
        return Row(
          children: [
            _StatItem(label: 'Services', value: stats['services']!.toString()),
            _StatItem(label: 'Bookings', value: stats['bookings']!.toString()),
            _StatItem(label: 'Reviews', value: stats['reviews']!.toString()),
          ],
        );
      },
    );
  }

  Future<Map<String, int>> _fetchStats(String providerId) async {
    try {
      final results = await Future.wait([
        _api.get(ApiConstants.services, queryParams: {'provider_id': providerId}),
        _api.get(ApiConstants.providerBookings),
        _api.get('${ApiConstants.reviews}/provider/$providerId'),
      ]);

      final services = results[0] is Map
          ? (results[0]['services'] as List<dynamic>?).orEmpty.length
          : (results[0] as List<dynamic>?)?.length ?? 0;

      final bookings = results[1] is List
          ? (results[1] as List).length
          : (results[1]['bookings'] as List<dynamic>?)?.length ?? 0;

      final reviews = results[2] is List
          ? (results[2] as List).length
          : (results[2]['reviews'] as List<dynamic>?)?.length ?? 0;

      return {'services': services, 'bookings': bookings, 'reviews': reviews};
    } catch (_) {
      return {'services': 0, 'bookings': 0, 'reviews': 0};
    }
  }

  void _showEditProfileSheet(BuildContext context, String currentName, String currentPhone, String currentEmail) {
    final nameController = TextEditingController(text: currentName);
    final phoneController = TextEditingController(text: currentPhone);
    final bioController = TextEditingController();
    String selectedCity = 'Addis Ababa';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            left: 16, right: 16, top: 24,
          ),
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Edit Profile', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Business Name', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder()),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: bioController,
                    decoration: const InputDecoration(labelText: 'Bio', border: OutlineInputBorder(), alignLabelWithHint: true),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedCity,
                    decoration: const InputDecoration(labelText: 'City', border: OutlineInputBorder()),
                    items: ['Addis Ababa', 'Adama', 'Bahir Dar', 'Dire Dawa', 'Hawassa', 'Jijiga', 'Mekelle', 'Jimma']
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setSheetState(() => selectedCity = v ?? selectedCity),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: () async {
                        try {
                          await _api.put(
                            ApiConstants.updateProfile,
                            body: {
                              'name': nameController.text.trim(),
                              'phone': phoneController.text.trim(),
                              'bio': bioController.text.trim(),
                              'city': selectedCity,
                            },
                          );
                          if (sheetContext.mounted) Navigator.pop(sheetContext);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Profile updated'), backgroundColor: Color(0xFF28A745)),
                            );
                          }
                        } catch (e) {
                          if (sheetContext.mounted) {
                            ScaffoldMessenger.of(sheetContext).showSnackBar(
                              SnackBar(content: Text('Failed to update: $e'), backgroundColor: const Color(0xFFDC3545)),
                            );
                          }
                        }
                      },
                      child: const Text('Save Changes'),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Logout',
      message: 'Are you sure you want to logout?',
      confirmLabel: 'Logout',
      confirmColor: const Color(0xFFDC3545),
    );
    if (confirmed && mounted) {
      if (mounted) context.read<AuthProvider>().logout();
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    }
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF007BFF))),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
        ),
      ),
    );
  }
}

extension _NullableListExt on List<dynamic>? {
  List<dynamic> get orEmpty => this ?? [];
}
