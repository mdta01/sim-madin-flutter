// ============================================================================
// SplashScreen — cek session wali (WA+PIN custom auth, bukan Supabase Auth)
// ============================================================================

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
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    // Wali login pakai WA+PIN (custom auth), bukan Supabase Auth.
    // Cek token dari secure storage directly (skip JWT verify — pseudo-token
    // dari loginWali() tidak punya JWT signature yang valid).
    try {
      final storage = ref.read(authStorageProvider);
      final token = await storage.getWaliToken();
      final waliJson = await storage.getWaliData();
      final santriJson = await storage.getWaliSantriList();
      if (!mounted) return;

      if (token != null && waliJson != null && santriJson != null) {
        final wali = WaliModel.fromJson(waliJson);
        final santriModels = santriJson
            .map((s) => SantriModel.fromJson(s as Map<String, dynamic>))
            .toList();
        ref.read(waliSessionProvider.notifier).state = TypedWaliSession(
          token: token,
          wali: wali,
          santriList: santriModels,
        );
        context.go('/dashboard/home');
      } else {
        context.go('/login');
      }
    } catch (_) {
      if (!mounted) return;
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
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(60),
              ),
              child:
                  const Icon(Icons.mosque, size: 64, color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            const Text('SIM MADIN',
                style: TextStyle(
                    color: AppColors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Wali Santri',
                style: TextStyle(color: AppColors.white, fontSize: 16)),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
                color: AppColors.white, strokeWidth: 2),
          ],
        ),
      ),
    );
  }
}
