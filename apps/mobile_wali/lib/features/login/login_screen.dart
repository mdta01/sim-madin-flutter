// Login Screen — SIM Wali (WA+PIN auth, custom branding).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';

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
    final phone = _phoneController.text.trim();
    final pin = _pinController.text;
    if (phone.isEmpty) {
      _toast('Nomor WhatsApp wajib diisi', isError: true);
      return;
    }
    if (pin.length != 6) {
      _toast('PIN harus 6 digit', isError: true);
      return;
    }
    setState(() => _loading = true);
    try {
      final session = await loginWali(ref, phone: phone, pin: pin);
      if (!mounted) return;
      _toast('✅ Selamat datang, ${session.wali.name}!');
      context.go('/dashboard/home');
    } catch (e) {
      if (mounted) _toast(friendlyError(e), isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toast(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(msg),
          backgroundColor: isError ? AppColors.danger : AppColors.success),
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.gold,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Wali Santri',
                          style: TextStyle(
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
                          const Text('Masuk ke Akun',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(
                            'Masuk dengan Nomor WhatsApp & PIN',
                            style: TextStyle(
                                fontSize: 13, color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 24),
                          TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Nomor WhatsApp',
                              hintText: '08xxx atau 628xxx',
                              prefixIcon: Icon(Icons.call),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _pinController,
                            obscureText: !_showPin,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                letterSpacing: 8, fontSize: 20),
                            decoration: InputDecoration(
                              labelText: 'PIN (6 digit)',
                              hintText: '••••••',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(_showPin
                                    ? Icons.visibility_off
                                    : Icons.visibility),
                                onPressed: () =>
                                    setState(() => _showPin = !_showPin),
                              ),
                              counterText: '',
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
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () => context.push('/forgot-pin'),
                            child: const Text('Lupa PIN?'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
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
