import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'api_service.dart';

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
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _agreeToTerms = false;

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

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
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
      await ApiService.signup(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(e.toString().replaceFirst('Exception: ', ''));
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
            colors: [
              colors.primary,
              colors.primary.withValues(alpha: 0.8),
              colors.primaryContainer,
            ],
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
                    mainAxisAlignment: MainAxisAlignment.center,
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
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.person_add_rounded, size: 64, color: Colors.white),
        ),
        const SizedBox(height: 24),
        Text(
          'Create Account',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: colors.onPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Join LocalConnect and find expert services near you',
          style: TextStyle(
            fontSize: 15,
            color: colors.onPrimary.withValues(alpha: 0.8),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFormCard(ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 40,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Get Started',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 24),
            _buildNameField(colors),
            const SizedBox(height: 18),
            _buildEmailField(colors),
            const SizedBox(height: 18),
            _buildPasswordField(colors),
            const SizedBox(height: 18),
            _buildConfirmPasswordField(colors),
            const SizedBox(height: 12),
            _buildTermsCheckbox(colors),
            const SizedBox(height: 24),
            _buildSignupButton(colors),
            const SizedBox(height: 20),
            _buildLoginLink(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildNameField(ColorScheme colors) {
    return TextFormField(
      controller: _nameController,
      textInputAction: TextInputAction.next,
      textCapitalization: TextCapitalization.words,
      style: TextStyle(color: colors.onSurface),
      decoration: _inputDecoration(
        hint: 'Full Name',
        icon: Icons.person_outline,
        colors: colors,
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Name is required';
        if (v.trim().length < 2) return 'Name must be at least 2 characters';
        return null;
      },
    );
  }

  Widget _buildEmailField(ColorScheme colors) {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      style: TextStyle(color: colors.onSurface),
      decoration: _inputDecoration(
        hint: 'Email Address',
        icon: Icons.email_outlined,
        colors: colors,
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Email is required';
        if (!v.contains('@')) return 'Enter a valid email address';
        return null;
      },
    );
  }

  Widget _buildPasswordField(ColorScheme colors) {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.next,
      style: TextStyle(color: colors.onSurface),
      decoration: _inputDecoration(
        hint: 'Password',
        icon: Icons.lock_outlined,
        colors: colors,
        suffix: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: colors.onSurface.withValues(alpha: 0.6),
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Password is required';
        if (v.length < 6) return 'Password must be at least 6 characters';
        return null;
      },
    );
  }

  Widget _buildConfirmPasswordField(ColorScheme colors) {
    return TextFormField(
      controller: _confirmPasswordController,
      obscureText: _obscureConfirm,
      textInputAction: TextInputAction.done,
      style: TextStyle(color: colors.onSurface),
      decoration: _inputDecoration(
        hint: 'Confirm Password',
        icon: Icons.lock_reset_outlined,
        colors: colors,
        suffix: IconButton(
          icon: Icon(
            _obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: colors.onSurface.withValues(alpha: 0.6),
          ),
          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
        ),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Please confirm your password';
        if (v != _passwordController.text) return 'Passwords do not match';
        return null;
      },
      onFieldSubmitted: (_) => _handleSignup(),
    );
  }

  Widget _buildTermsCheckbox(ColorScheme colors) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 24,
          width: 24,
          child: Checkbox(
            value: _agreeToTerms,
            onChanged: (v) => setState(() => _agreeToTerms = v ?? false),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text.rich(
            TextSpan(
              text: 'I agree to the ',
              style: TextStyle(fontSize: 13, color: colors.onSurface.withValues(alpha: 0.7)),
              children: [
                TextSpan(
                  text: 'Terms of Service',
                  style: TextStyle(color: colors.primary, fontWeight: FontWeight.w600),
                ),
                TextSpan(text: ' and '),
                TextSpan(
                  text: 'Privacy Policy',
                  style: TextStyle(color: colors.primary, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
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
          disabledBackgroundColor: colors.primary.withValues(alpha: 0.6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: _isLoading
            ? SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: colors.onPrimary,
                ),
              )
            : const Text('CREATE ACCOUNT', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
      ),
    );
  }

  Widget _buildLoginLink(ColorScheme colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Already have an account? ', style: TextStyle(color: colors.onSurface.withValues(alpha: 0.6))),
        TextButton(
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          ),
          child: Text('Sign In', style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    required ColorScheme colors,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: colors.onSurface.withValues(alpha: 0.5)),
      prefixIcon: Icon(icon, color: colors.onSurface.withValues(alpha: 0.5), size: 22),
      suffixIcon: suffix,
      filled: true,
      fillColor: colors.surfaceContainerHighest.withValues(alpha: 0.5),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colors.outline.withValues(alpha: 0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colors.error, width: 1.5),
      ),
    );
  }
}
