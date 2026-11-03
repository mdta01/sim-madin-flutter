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
            Image.asset('assets/logo-madrasah.png', width: 140, height: 140, fit: BoxFit.contain),
            const SizedBox(height: 20),
            const Text('SIM MADIN', style: TextStyle(color: AppColors.white, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 2)),
            const SizedBox(height: 4),
            Text('Sistem Informasi Madrasah Diniyah', style: TextStyle(color: AppColors.white.withOpacity(0.8), fontSize: 13)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(20)),
              child: const Text('Wali Santri', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(color: AppColors.white, strokeWidth: 2),
          ],
        ),
      ),
    );
  }
}
