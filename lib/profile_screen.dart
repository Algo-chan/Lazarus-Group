import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isGuest = false;
  String _userName = 'Guest User';
  String _userEmail = 'Not logged in';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final isGuest = prefs.getBool('isGuest') ?? false;
    
    if (!isGuest) {
      final userStr = prefs.getString('user');
      if (userStr != null) {
        final userData = jsonDecode(userStr);
        setState(() {
          _userName = userData['name'] ?? 'User';
          _userEmail = userData['email'] ?? '';
          _isGuest = false;
        });
      }
    } else {
      setState(() {
        _isGuest = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Avatar & Basic Info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32),
              color: Colors.white,
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: const Color(0xFFFF6B35).withOpacity(0.1),
                    child: Icon(
                      _isGuest ? Icons.person_outline : Icons.person,
                      size: 50,
                      color: const Color(0xFFFF6B35),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _userName,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _userEmail,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            // Menu Options
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  _MenuTile(icon: Icons.history, label: 'My Enquiries', onTap: () {}),
                  const Divider(indent: 56, height: 1),
                  _MenuTile(icon: Icons.favorite_border, label: 'Shortlisted Services', onTap: () {}),
                  const Divider(indent: 56, height: 1),
                  _MenuTile(icon: Icons.settings_outlined, label: 'Settings', onTap: () {}),
                  const Divider(indent: 56, height: 1),
                  _MenuTile(icon: Icons.help_outline, label: 'Help & Support', onTap: () {}),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            // Logout/Login Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await ApiService.logout();
                    if (mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                        (route) => false,
                      );
                    }
                  },
                  icon: Icon(_isGuest ? Icons.login : Icons.logout, color: _isGuest ? Colors.green : Colors.red),
                  label: Text(_isGuest ? 'LOGIN / SIGN UP' : 'LOGOUT', style: TextStyle(color: _isGuest ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: _isGuest ? Colors.green : Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF2D3436)),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }
}
