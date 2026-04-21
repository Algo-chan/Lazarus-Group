import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'signup_screen.dart';
import 'home_screen.dart';
import 'api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final LocalAuthentication auth = LocalAuthentication();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 🔐 Normal Login
  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await ApiService.login(
          _emailController.text,
          _passwordController.text,
        );

        if (_rememberMe) {
          await ApiService.saveUserSession(_emailController.text);
        }

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  // 🔐 Biometric Login
  Future<void> _loginWithBiometrics() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Biometric login is not supported on Web")),
      );
      return;
    }

    try {
      bool canCheck = await auth.canCheckBiometrics;

      if (!canCheck) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Biometric not available")),
          );
        }
        return;
      }

      bool authenticated = await auth.authenticate(
        localizedReason: 'Login using biometrics',
        options: const AuthenticationOptions(biometricOnly: true),
      );

      if (authenticated && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Biometric Error: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0F2027),
              Color(0xFF203A43),
              Color(0xFF2C5364)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // 🔥 Logo
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.handshake_rounded,
                        size: 60, color: Colors.white),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    "Welcome Back",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    "Login to continue",
                    style: TextStyle(color: Colors.white70),
                  ),

                  const SizedBox(height: 32),

                  // 🧊 Glass Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                      ),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Email
                          TextFormField(
                            controller: _emailController,
                            style:
                                const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: "Email",
                              hintStyle: const TextStyle(
                                  color: Colors.white54),
                              prefixIcon: const Icon(Icons.email,
                                  color: Colors.white70),
                              filled: true,
                              fillColor:
                                  Colors.white.withOpacity(0.05),
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator: (value) =>
                                (value == null ||
                                        !value.contains('@'))
                                    ? 'Enter valid email'
                                    : null,
                          ),

                          const SizedBox(height: 20),

                          // Password
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style:
                                const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: "Password",
                              hintStyle: const TextStyle(
                                  color: Colors.white54),
                              prefixIcon: const Icon(Icons.lock,
                                  color: Colors.white70),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.white70,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword =
                                        !_obscurePassword;
                                  });
                                },
                              ),
                              filled: true,
                              fillColor:
                                  Colors.white.withOpacity(0.05),
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator: (value) =>
                                (value == null ||
                                        value.length < 4)
                                    ? 'Enter password'
                                    : null,
                          ),

                          const SizedBox(height: 12),

                          // Remember + Forgot
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Checkbox(
                                    value: _rememberMe,
                                    onChanged: (value) {
                                      setState(() {
                                        _rememberMe = value!;
                                      });
                                    },
                                  ),
                                  const Text("Remember",
                                      style: TextStyle(
                                          color: Colors.white70)),
                                ],
                              ),
                              TextButton(
                                onPressed: () {},
                                child: const Text("Forgot?",
                                    style: TextStyle(
                                        color: Colors.white70)),
                              )
                            ],
                          ),

                          const SizedBox(height: 16),

                          // 🚀 Login Button
                          GestureDetector(
                            onTap: _isLoading
                                ? null
                                : _handleLogin,
                            child: Container(
                              width: double.infinity,
                              padding:
                                  const EdgeInsets.symmetric(
                                      vertical: 16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF00c6ff),
                                    Color(0xFF0072ff)
                                  ],
                                ),
                                borderRadius:
                                    BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: _isLoading
                                    ? const CircularProgressIndicator(
                                        color: Colors.white)
                                    : const Text(
                                        "LOGIN",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight:
                                              FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // 🔐 Biometric
                          OutlinedButton.icon(
                            onPressed: _loginWithBiometrics,
                            icon: const Icon(Icons.fingerprint,
                                color: Colors.white),
                            label: const Text("Biometric Login",
                                style: TextStyle(
                                    color: Colors.white)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                  color: Colors.white24),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Guest
                  TextButton(
                    onPressed: () async {
                      await ApiService.setGuestMode();
                      if (mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const HomeScreen()),
                        );
                      }
                    },
                    child: const Text(
                      "Continue as Guest",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Signup
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      const Text("No account?",
                          style: TextStyle(
                              color: Colors.white70)),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const SignupScreen()),
                          );
                        },
                        child: const Text("Sign Up",
                            style: TextStyle(
                                color: Colors.white)),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
