// ============================================================================
// App Router (mobile_wali) — go_router setup
// ============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import 'package:shared/shared.dart';

import '../features/dashboard/dashboard_screen.dart';
import '../features/login/login_screen.dart';
import '../features/splash_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(child: Text('Halaman tidak ditemukan: ${state.error}')),
    ),
  );
});
