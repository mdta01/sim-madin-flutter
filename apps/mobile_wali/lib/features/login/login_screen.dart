// ============================================================================
// Login Screen — WhatsApp + PIN
// ============================================================================
// TODO Phase 5: implementasi lengkap
//   - OTP request (5/jam rate limit)
//   - bcrypt PIN verify
//   - 5x salah → lockout 15 menit
//   - Blacklist 50 PIN lemah
//   - JWT verify client-side (Hermes-compatible decode — pakai crypto package)
// Saat Phase 1: placeholder UI dengan form, panggil api_client.loginWali
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();
  bool _loading = false;
  bool _showPin = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final phone = normalizeWhatsApp(_phoneController.text);
    final pin = _pinController.text.trim();

    if (phone == null) {
      _showError('Nomor WhatsApp tidak valid');
      return;
    }
    if (!isValidPin(pin)) {
      _showError('PIN harus 6 digit');
      return;
    }
    if (kBlacklistedPins.contains(pin)) {
      _showError('PIN terlalu lemah, silakan ubah di admin');
      return;
    }

    setState(() => _loading = true);
    try {
      // TODO Phase 5: panggil ref.read(apiClientProvider).waliLogin(phone, pin)
      await Future.delayed(const Duration(seconds: 2)); // simulate
      if (!mounted) return;
      context.go('/dashboard');
    } catch (e) {
      _showError('Login gagal: $e');
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              // Logo
              Container(
                width: 120,
                height: 120,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(60),
                ),
                child: const Icon(Icons.mosque, size: 64, color: AppColors.primary),
              ),
              const SizedBox(height: 24),
              const Text(
                'SIM MADIN',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Wali Santri',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 48),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Masuk ke Akun',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Masuk dengan Nomor WhatsApp & PIN',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Nomor WhatsApp',
                          hintText: '08xxx atau 628xxx',
                          prefixIcon: Icon(Icons.phone),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _pinController,
                        keyboardType: TextInputType.number,
                        obscureText: !_showPin,
                        maxLength: 6,
                        decoration: InputDecoration(
                          labelText: 'PIN (6 digit)',
                          hintText: '••••••',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_showPin ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _showPin = !_showPin),
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
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Masuk'),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          // TODO Phase 5: navigate to /forgot-pin
                        },
                        child: const Text('Lupa PIN?'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
