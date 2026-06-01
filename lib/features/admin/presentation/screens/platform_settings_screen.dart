import 'package:flutter/material.dart';
import 'package:local_service_app/core/services/secure_storage_service.dart';

class PlatformSettingsScreen extends StatefulWidget {
  const PlatformSettingsScreen({super.key});

  @override
  State<PlatformSettingsScreen> createState() => _PlatformSettingsScreenState();
}

class _PlatformSettingsScreenState extends State<PlatformSettingsScreen> {
  bool _maintenanceMode = false;
  bool _guestBrowsing = true;
  bool _newRegistrations = true;
  bool _providerSignups = true;
  bool _isToggling = false;

  final List<String> _categories = [
    'Plumbing',
    'Electrical',
    'Cleaning',
    'Moving',
    'Carpentry',
    'Gardening',
    'Painting',
    'HVAC',
  ];
  final TextEditingController _categoryController = TextEditingController();

  @override
  void dispose() {
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _onToggle(Future<void> Function() action) async {
    if (_isToggling) return;
    setState(() => _isToggling = true);
    await Future.delayed(const Duration(milliseconds: 400));
    await action();
    if (mounted) setState(() => _isToggling = false);
  }

  Future<void> _saveSettings() async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved successfully'),
          backgroundColor: Color(0xFF28A745),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _addCategory() {
    final text = _categoryController.text.trim();
    if (text.isEmpty) return;
    if (_categories.contains(text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Category already exists'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() {
      _categories.add(text);
      _categories.sort();
      _categoryController.clear();
    });
  }

  void _removeCategory(String category) {
    setState(() => _categories.remove(category));
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _settingsTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(10),
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 13,
          ),
        ),
        value: value,
        onChanged: _isToggling
            ? null
            : (v) {
                setState(() {
                  if (title == 'Maintenance Mode') _maintenanceMode = v;
                  if (title == 'Guest Browsing') _guestBrowsing = v;
                  if (title == 'New Registrations') _newRegistrations = v;
                  if (title == 'Provider Signups') _providerSignups = v;
                });
                _onToggle(() async {});
              },
        activeColor: const Color(0xFF007BFF),
        inactiveThumbColor: Colors.grey,
        inactiveTrackColor: Colors.grey.withValues(alpha: 0.3),
      ),
    );
  }

  Widget _buildCategoryChips() {
    if (_categories.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'No categories added yet.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 14,
          ),
        ),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _categories.map((cat) {
        return Chip(
          label: Text(
            cat,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
          deleteIcon: const Icon(Icons.close, size: 16, color: Colors.white70),
          onDeleted: () => _removeCategory(cat),
          backgroundColor: const Color(0xFF0F3460),
          side: BorderSide.none,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(horizontal: 4),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('PLATFORM CONTROLS'),
          _settingsTile(
            title: 'Maintenance Mode',
            subtitle: 'Put the platform in maintenance mode. Only admins can access.',
            value: _maintenanceMode,
            onChanged: (v) {},
          ),
          _settingsTile(
            title: 'Guest Browsing',
            subtitle: 'Allow unauthenticated users to browse services.',
            value: _guestBrowsing,
            onChanged: (v) {},
          ),
          _settingsTile(
            title: 'New Registrations',
            subtitle: 'Allow new users to create accounts.',
            value: _newRegistrations,
            onChanged: (v) {},
          ),
          _settingsTile(
            title: 'Provider Signups',
            subtitle: 'Allow providers to register on the platform.',
            value: _providerSignups,
            onChanged: (v) {},
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: _isToggling ? null : _saveSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007BFF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _isToggling
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 32),
          _sectionHeader('CATEGORY MANAGEMENT'),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF16213E),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Manage service categories',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _categoryController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Enter category name',
                          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                          filled: true,
                          fillColor: const Color(0xFF1A1A2E),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        onSubmitted: (_) => _addCategory(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: _addCategory,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF007BFF),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                        ),
                        child: const Text('Add'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildCategoryChips(),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
