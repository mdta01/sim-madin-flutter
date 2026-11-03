// Login WA + PIN (Phase 5).
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
      _toast('✅ Login berhasil. Selamat datang, ${session.wali.name}!');
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              Container(
                width: 120,
                height: 120,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(60),
                ),
                child:
                    const Icon(Icons.mosque, size: 64, color: AppColors.primary),
              ),
              const SizedBox(height: 24),
              const Text('SIM MADIN',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppColors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('Wali Santri',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.white, fontSize: 16)),
              const SizedBox(height: 48),
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
                      const Text(
                          'Masuk dengan Nomor WhatsApp & PIN',
                          style: TextStyle(
                              fontSize: 13, color: AppColors.textMuted)),
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
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.infoLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Demo (Phase 5 dev mode):\n'
                          '• Login admin via Supabase Auth di app kepala/bendahara/guru untuk setup Wali record + PIN.\n'
                          '• Atau set PIN plain text manual di DB:\n'
                          '  UPDATE "Wali" SET "pinHash" = \'123456\' WHERE phone = \'081234511001\'',
                          style: TextStyle(fontSize: 11, color: AppColors.info),
                        ),
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
