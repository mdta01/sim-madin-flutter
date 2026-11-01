// ============================================================================
// Dashboard Screen — list santri (mobile_wali)
// ============================================================================
// TODO Phase 5: implementasi lengkap
//   - Fetch santri list via Serverpod client
//   - Card dengan photo, nama, nis, kelas
//   - Tap → detail (6 tab: Profil, Akademik, Ujian, Keuangan, Notif, Info)
//   - Realtime: subscribe ke Notifikasi + Nilai/Absensi/Tagihan per santri
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SIM MADIN - Wali Santri', style: TextStyle(fontSize: 14)),
            Text('Dashboard', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Keluar',
            onPressed: () {
              // TODO Phase 5: clear session, navigate to /login
            },
          ),
        ],
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.family_restroom, size: 64, color: AppColors.primary),
              SizedBox(height: 16),
              Text(
                'Dashboard Wali Santri',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Coming soon — Phase 5\nAkan menampilkan list anak dengan:\n'
                '• Photo, nama, NIS, kelas\n'
                '• Tap → detail (6 tab: Profil, Akademik, Ujian, Keuangan, Notif, Info)\n'
                '• Realtime notifikasi & updates',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
