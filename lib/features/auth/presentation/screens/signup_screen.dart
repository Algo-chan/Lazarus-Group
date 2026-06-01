import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:local_service_app/providers/auth_provider.dart';
import 'package:local_service_app/home_screen.dart';
import 'package:local_service_app/features/auth/presentation/screens/login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController(text: '+2519');
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _agreeToTerms = false;
  String _selectedRole = 'customer';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeToTerms) {
      _showSnackBar('Please agree to the Terms & Conditions');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthProvider>();
      await auth.signup(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: _selectedRole,
        phone: _phoneController.text.trim(),
      );
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colors.primary, colors.primary.withOpacity(0.8), colors.primaryContainer],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _buildHeader(colors),
                      const SizedBox(height: 32),
                      _buildFormCard(colors),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colors) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
          child: const Icon(Icons.person_add_rounded, size: 48, color: Colors.white),
        ),
        const SizedBox(height: 16),
        Text('Create Account', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: colors.onPrimary)),
      ],
    );
  }

  Widget _buildFormCard(ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surface.withOpacity(0.95),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 40, offset: const Offset(0, 10))],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildRoleSelector(colors),
            const SizedBox(height: 24),
            _buildTextField(_nameController, 'Full Name', Icons.person_outline, colors),
            const SizedBox(height: 16),
            _buildTextField(_emailController, 'Email Address', Icons.email_outlined, colors, keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 16),
            _buildTextField(_phoneController, 'Phone Number (+2519...)', Icons.phone_android_outlined, colors, keyboardType: TextInputType.phone),
            const SizedBox(height: 16),
            _buildPasswordField(colors),
            const SizedBox(height: 16),
            _buildConfirmPasswordField(colors),
            const SizedBox(height: 12),
            _buildTermsCheckbox(colors),
            const SizedBox(height: 24),
            _buildSignupButton(colors),
            const SizedBox(height: 16),
            _buildLoginLink(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleSelector(ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('I want to...', style: TextStyle(fontWeight: FontWeight.w600, color: colors.onSurface)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _roleOption('customer', 'Find Services', Icons.search, colors),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _roleOption('provider', 'Provide Services', Icons.work_outline, colors),
            ),
          ],
        ),
      ],
    );
  }

  Widget _roleOption(String role, String label, IconData icon, ColorScheme colors) {
    final selected = _selectedRole == role;
    return InkWell(
      onTap: () => setState(() => _selectedRole = role),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? colors.primary : colors.surfaceContainerHighest.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? colors.primary : colors.outline.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? colors.onPrimary : colors.onSurfaceVariant),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: selected ? FontWeight.bold : FontWeight.normal, color: selected ? colors.onPrimary : colors.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, ColorScheme colors, {TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(color: colors.onSurface),
      decoration: _inputDecoration(hint: hint, icon: icon, colors: colors),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Required';
        if (hint.contains('Email') && !v.contains('@')) return 'Invalid email';
        if (hint.contains('Phone') && !RegExp(r'^\+2519\d{8}$').hasMatch(v.replaceAll(' ', ''))) return 'Use format +2519XXXXXXXX';
        return null;
      },
    );
  }

  Widget _buildPasswordField(ColorScheme colors) {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      style: TextStyle(color: colors.onSurface),
      decoration: _inputDecoration(
        hint: 'Password',
        icon: Icons.lock_outlined,
        colors: colors,
        suffix: IconButton(
          icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
      validator: (v) => (v == null || v.length < 6) ? 'Min 6 characters' : null,
    );
  }

  Widget _buildConfirmPasswordField(ColorScheme colors) {
    return TextFormField(
      controller: _confirmPasswordController,
      obscureText: _obscureConfirm,
      decoration: _inputDecoration(
        hint: 'Confirm Password',
        icon: Icons.lock_reset_outlined,
        colors: colors,
        suffix: IconButton(
          icon: Icon(_obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined),
          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
        ),
      ),
      validator: (v) => v != _passwordController.text ? 'Passwords do not match' : null,
    );
  }

  Widget _buildTermsCheckbox(ColorScheme colors) {
    return Row(
      children: [
        Checkbox(value: _agreeToTerms, onChanged: (v) => setState(() => _agreeToTerms = v ?? false)),
        Expanded(child: Text('I agree to Terms & Privacy Policy', style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant))),
      ],
    );
  }

  Widget _buildSignupButton(ColorScheme colors) {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSignup,
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('CREATE ACCOUNT', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildLoginLink(ColorScheme colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Already have an account? ', style: TextStyle(color: colors.onSurfaceVariant)),
        TextButton(
          onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen())),
          child: Text('Sign In', style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({required String hint, required IconData icon, required ColorScheme colors, Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: colors.surfaceContainerHighest.withOpacity(0.3),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colors.primary, width: 1.5)),
    );
  }
}
