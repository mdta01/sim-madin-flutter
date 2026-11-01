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
    final user = await ref.read(currentUserProvider.future);
    if (!mounted) return;
    if (user != null) {
      context.go('/dashboard');
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
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(60),
              ),
              child: const Icon(Icons.mosque, size: 64, color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            const Text(
              'SIM MADIN',
              style: TextStyle(color: AppColors.white, fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Kepala Madrasah',
              style: TextStyle(color: AppColors.white, fontSize: 16),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(color: AppColors.white, strokeWidth: 2),
          ],
        ),
      ),
    );
  }
}
