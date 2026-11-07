// Splash Screen — modern design dengan gradient + animasi.
// Logo madrasah + "SIM MADIN" + role badge.
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
  // === APP IDENTITY — ubah per app ===
  static const _roleLabel = 'Guru Madrasah';
  // ====================================

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
    _scaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
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
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    try {
      final user = await ref.read(currentUserProvider.future).timeout(
        const Duration(seconds: 3),
        onTimeout: () => null,
      );
      if (!mounted) return;
      if (user == null) {
        context.go('/login');
        return;
      }

      // Sesi tersimpan belum tentu akun dengan peran yang benar. Pemeriksaan
      // yang sama seperti di layar login harus diulang di sini; tanpa ini,
      // akun yang pernah login (atau perannya dicabut setelah itu) tetap
      // masuk dan hanya melihat layar kosong karena RLS menyaring datanya.
      final allowed =
          await verifyUserRole(ref, roleCode: 'GURU');
      if (!mounted) return;
      if (!allowed) {
        await ref.read(supabaseClientProvider).auth.signOut();
        if (!mounted) return;
        context.go('/login');
        return;
      }

      context.go('/dashboard/home');
    } catch (e) {
      debugPrint('Splash check session error: $e');
      if (!mounted) return;
      context.go('/login');
    }
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
                    // Logo dengan card background (modern look)
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
                    const Text(
                      'SIM MADIN',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Sistem Informasi Madrasah Diniyah',
                      style: TextStyle(
                        color: AppColors.white.withValues(alpha: 0.85),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Role badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg, vertical: AppSpacing.xs + 2),
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gold.withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        _roleLabel,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxxl),
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
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'v1.0.0 • MDTA Miftahul Ulum',
                      style: TextStyle(
                        color: AppColors.white.withValues(alpha: 0.6),
                        fontSize: 10,
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
