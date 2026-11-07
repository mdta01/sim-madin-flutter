// Login Screen — SIM Admin (desktop, Supabase Auth).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';
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

      // ── GATE ROLE ──────────────────────────────────────────────────────
      // Sebelumnya SIAPA SAJA yang punya akun valid (termasuk wali dan guru)
      // bisa masuk ke aplikasi admin dan melihat struktur 34 modul. RLS
      // memang menyaring datanya, tetapi UI administratif tidak boleh
      // terbuka untuk peran non-staf.
      final access = await resolveAccountAccess(client);
      if (!access.allowed) {
        await client.auth.signOut();
        if (!mounted) return;
        _showError(access.message ?? 'Akun tidak berhak memakai aplikasi ini.');
        return;
      }

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
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.brandGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xxxl),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // === Left: logo + branding ===
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Logo dalam Container putih modern
                            Container(
                              width: 160,
                              height: 160,
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.xxl),
                                boxShadow: AppColors.elevatedShadow,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.lg),
                                child: Image.asset(
                                  'assets/logo-madrasah.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            Text(
                              'SIM MADIN',
                              style: AppTextStyles.display2
                                  .copyWith(color: AppColors.white),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Sistem Informasi Madrasah Diniyah',
                              style: AppTextStyles.body1.copyWith(
                                color: AppColors.white
                                    .withValues(alpha: 0.85),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            ModernChip(
                              label: 'Admin Desktop',
                              color: AppColors.white,
                              bg: AppColors.gold,
                              icon: Icons.shield_outlined,
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            Text(
                              'Madrasah Diniyah Miftahul Ulum\nTawangsari, Pujon, Malang',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.body3.copyWith(
                                color:
                                    AppColors.white.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xxxl),
                      // === Right: login form dalam ModernCard ===
                      SizedBox(
                        width: 380,
                        child: ModernCard(
                          elevation: CardElevation.level2,
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text('Masuk ke Akun', style: AppTextStyles.h2),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'Gunakan email dan password admin',
                                style: AppTextStyles.body2
                                    .copyWith(color: AppColors.textMuted),
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              TextField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  hintText: 'admin@madrasah.id',
                                  prefixIcon: Icon(Icons.email_outlined),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              TextField(
                                controller: _passwordController,
                                obscureText: !_showPassword,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon:
                                      const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    icon: Icon(_showPassword
                                        ? Icons.visibility_off
                                        : Icons.visibility),
                                    onPressed: () => setState(
                                        () => _showPassword = !_showPassword),
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              FilledButton.icon(
                                onPressed: _loading ? null : _handleLogin,
                                icon: _loading
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.white,
                                        ),
                                      )
                                    : const Icon(Icons.login, size: 18),
                                label: Text(_loading ? 'Memproses…' : 'Masuk'),
                              ),
                            ],
                          ),
                        ),
                      ),
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
}
