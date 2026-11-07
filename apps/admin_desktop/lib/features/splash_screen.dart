import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';

import 'package:api_client/api_client.dart';
import 'package:supabase_client/supabase_client.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
    _scaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );
    _animController.forward();
    _checkSession();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _checkSession() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    final client = ref.read(supabaseClientProvider);

    // Sesi tersimpan? Kalau tidak, langsung ke login.
    if (client.auth.currentSession == null) {
      if (mounted) context.go('/login');
      return;
    }

    // Sesi ADA, tetapi itu belum berarti akun ini staf. Pemeriksaan yang sama
    // dengan layar login HARUS dijalankan juga di sini — kalau tidak, akun
    // non-staf yang pernah login di perangkat ini akan langsung masuk ke
    // dashboard setiap aplikasi dibuka.
    AccountAccess access;
    try {
      access = await resolveAccountAccess(client);
    } catch (e) {
      access = AccountAccess.denied('Gagal memverifikasi hak akses: $e');
    }

    if (!mounted) return;

    if (!access.allowed) {
      await client.auth.signOut();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(access.message ?? 'Akun tidak berhak memakai aplikasi ini.'),
          backgroundColor: AppColors.danger,
          duration: const Duration(seconds: 6),
        ),
      );
      context.go('/login');
      return;
    }

    context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.brandGradient),
        child: SafeArea(
          child: Center(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: ScaleTransition(
                scale: _scaleAnim,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo dalam Container putih modern
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(AppRadius.xxl),
                        boxShadow: AppColors.elevatedShadow,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Image.asset(
                          'assets/logo-madrasah.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    // App name — display2 white
                    Text(
                      'SIM MADIN',
                      style: AppTextStyles.display2
                          .copyWith(color: AppColors.white),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Sistem Informasi Madrasah Diniyah',
                      style: AppTextStyles.body2.copyWith(
                        color: AppColors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Role badge — ModernChip
                    ModernChip(
                      label: 'Admin Desktop',
                      color: AppColors.white,
                      bg: AppColors.gold,
                      icon: Icons.shield_outlined,
                    ),
                    const SizedBox(height: AppSpacing.xxxl),
                    // Loading indicator dengan background tint
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        color: AppColors.white.withValues(alpha: 0.9),
                        strokeWidth: 2.5,
                        backgroundColor:
                            AppColors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    // Version footer
                    Text(
                      'v1.0.0+1 • MDTA Miftahul Ulum',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
