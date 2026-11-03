// Login Screen — SIM Admin (desktop, Supabase Auth).
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
      context.go('/dashboard');
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
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(48),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left: logo + branding
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/logo-madrasah.png',
                        width: 180,
                        height: 180,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'SIM MADIN',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sistem Informasi Madrasah Diniyah',
                        style: TextStyle(
                          color: AppColors.white.withOpacity(0.8),
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.gold,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Text(
                          'Admin Desktop',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Madrasah Diniyah Miftahul Ulum\nTawangsari, Pujon, Malang',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.white.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 48),
                // Right: login form
                SizedBox(
                  width: 360,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text('Masuk ke Akun',
                              style: TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(
                            'Gunakan email dan password admin',
                            style: TextStyle(
                                fontSize: 13, color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 24),
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              hintText: 'admin@madrasah.id',
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
