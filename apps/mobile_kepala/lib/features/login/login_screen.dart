// Login Screen — shared template untuk semua mobile apps.
// Logo madrasah + "SIM MADIN" + role badge + form login (Supabase Auth).
//
// Cara pakai: copy file ini ke setiap app, ubah _roleLabel.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import 'package:supabase_client/supabase_client.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  // === APP IDENTITY — ubah per app ===
  static const _roleLabel = 'Kepala Madrasah';
  // ====================================

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _showPassword = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (!isValidEmail(email)) {
      _showError('Email tidak valid');
      return;
    }
    if (password.length < 6) {
      _showError('Password minimal 6 karakter');
      return;
    }

    setState(() => _loading = true);
    try {
      final client = ref.read(supabaseClientProvider);
      await client.auth.signInWithPassword(email: email, password: password);
      if (!mounted) return;
      context.go('/dashboard/home');
    } catch (e) {
      _showError(friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.danger),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - 48,
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  // === Logo + Branding ===
                  Center(
                    child: Column(children: [
                      // Logo madrasah
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          'assets/logo-madrasah.png',
                          width: 120,
                          height: 120,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // App name
                      const Text(
                        'SIM MADIN',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sistem Informasi Madrasah Diniyah',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.white.withOpacity(0.8),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Role badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.gold,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _roleLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 32),
                  // === Login Card ===
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Masuk ke Akun',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Gunakan email dan password yang terdaftar',
                            style: TextStyle(
                                fontSize: 13, color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 24),
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              hintText: 'nama@madrasah.id',
                              prefixIcon: Icon(Icons.email),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _passwordController,
                            obscureText: !_showPassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(_showPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility),
                                onPressed: () => setState(
                                    () => _showPassword = !_showPassword),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _loading ? null : _handleLogin,
                            child: _loading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))
                                : const Text('Masuk'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  // === Footer ===
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      'Madrasah Diniyah Miftahul Ulum\nTawangsari, Pujon, Malang',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.white.withOpacity(0.5),
                        fontSize: 11,
                      ),
                    ),
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
