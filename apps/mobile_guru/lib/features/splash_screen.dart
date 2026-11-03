// Splash Screen — shared template untuk semua mobile apps.
// Logo madrasah + "SIM MADIN" + role badge.
// Call _checkSession() di initState untuk redirect.
//
// Cara pakai: copy file ini ke setiap app, ubah _roleLabel dan _appLabel.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  // === APP IDENTITY — ubah per app ===
  static const _appLabel = 'SIM Kepala';
  static const _roleLabel = 'Guru Madrasah';
  // ====================================

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    final user = await ref.read(currentUserProvider.future);
    if (!mounted) return;
    if (user != null) {
      context.go('/dashboard/home');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo madrasah
            Image.asset(
              'assets/logo-madrasah.png',
              width: 140,
              height: 140,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 20),
            // App name
            const Text(
              'SIM MADIN',
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
              style: TextStyle(
                color: AppColors.white.withOpacity(0.8),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            // Role badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              color: AppColors.white,
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}
