// AppShell — sidebar navigation (desktop pattern).
// Mengandung:
//   - Sidebar kiri dengan logo + menu items (34 dari AdminMenu.items di shared)
//   - Top bar dengan current user info + logout
//   - Content area (child)
//   - Status bar bawah (realtime info)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import 'package:supabase_client/supabase_client.dart';
import 'package:api_client/api_client.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setupKepalaRealtime(ref);
    });
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Konfirmasi Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: AppColors.white),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final client = ref.read(supabaseClientProvider);
    await client.auth.signOut();
    // ignore: unused_result
    await ref.read(authStorageProvider).clear();
    invalidateAdminQueries(ref);
    if (!mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final client = ref.watch(supabaseClientProvider);
    final userEmail = client.auth.currentUser?.email ?? '-';
    final userInitial = userEmail.isNotEmpty ? userEmail[0].toUpperCase() : '?';

    final location = GoRouterState.of(context).matchedLocation;

    return Scaffold(
      body: Row(
        children: [
          // === Sidebar ===
          Container(
            width: 240,
            color: AppColors.primary,
            child: Column(
              children: [
                // Logo + app name
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: const Icon(Icons.mosque,
                            color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('SIM MADIN',
                                style: TextStyle(
                                    color: AppColors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold)),
                            Text('Admin Desktop',
                                style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white24, height: 1),
                // Menu items (scrollable)
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm),
                    itemCount: AdminMenu.items.length,
                    itemBuilder: (c, i) {
                      final item = AdminMenu.items[i];
                      final isActive = location == '/${item.id}' ||
                          (item.id == 'dashboard' && location == '/dashboard');
                      final isPhase6a = kPhase6aActiveMenus.contains(item.id);

                      return _SidebarItem(
                        item: item,
                        isActive: isActive,
                        onTap: isPhase6a
                            ? () => context.go('/${item.id}')
                            : () => context.go('/${item.id}'),
                      );
                    },
                  ),
                ),
                // Footer: version
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.white24)),
                  ),
                  child: const Text(
                    'v1.0.0+1 • Phase 6a',
                    style: TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
          // === Main content area ===
          Expanded(
            child: Column(
              children: [
                // Top bar
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    border: Border(bottom: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(
                    children: [
                      // Current page title
                      Expanded(
                        child: Text(
                          _pageTitle(location),
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                      // Refresh button
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 20),
                        tooltip: 'Refresh Data',
                        onPressed: () => invalidateAdminQueries(ref),
                      ),
                      // User info
                      const SizedBox(width: AppSpacing.sm),
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.primaryLight,
                        foregroundColor: AppColors.primary,
                        child: Text(userInitial,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(userEmail,
                          style: const TextStyle(fontSize: 13)),
                      const SizedBox(width: AppSpacing.sm),
                      IconButton(
                        icon: const Icon(Icons.logout, size: 20),
                        tooltip: 'Keluar',
                        onPressed: _handleLogout,
                      ),
                    ],
                  ),
                ),
                // Content
                Expanded(child: widget.child),
                // Status bar (bottom)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    border: Border(top: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.circle,
                          size: 8, color: AppColors.success),
                      const SizedBox(width: 6),
                      const Text('Realtime aktif',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.textMuted)),
                      const Spacer(),
                      Text(
                          'Server: ${SupabaseConfig.url.replaceAll("https://", "").split(".").first}',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _pageTitle(String location) {
    final path = location.replaceAll('/', '');
    final item = AdminMenu.items.where((i) => i.id == path).firstOrNull;
    return item?.label ?? 'Dashboard';
  }
}

/// ALL 34 admin menus are active (Phase 6a-d complete).
const kPhase6aActiveMenus = <String>{
  'dashboard', 'users', 'roles', 'permissions', 'settings',
  'santri', 'guru', 'wali', 'kelas', 'mapel', 'tahun-ajaran',
  'jadwal', 'pertemuan', 'absensi', 'nilai', 'materi', 'tugas',
  'ujian', 'bank-soal', 'kompetensi', 'rapor', 'perkembangan',
  'siklus', 'tagihan', 'pembayaran', 'kas', 'honor-guru',
  'pengumuman', 'notifikasi', 'surat', 'alumni', 'chat', 'qr',
  'audit-log',
};

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  final AdminMenuItem item;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isPhase6a = kPhase6aActiveMenus.contains(item.id);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: isActive ? Colors.white.withOpacity(0.15) : null,
            border: Border(
                left: BorderSide(
                    color: isActive ? AppColors.gold : Colors.transparent,
                    width: 3)),
          ),
          child: Row(
            children: [
              Icon(
                _getIcon(item.icon),
                size: 18,
                color: isActive
                    ? AppColors.white
                    : Colors.white70,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    color: isActive
                        ? AppColors.white
                        : Colors.white70,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!isPhase6a)
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                      color: AppColors.gold, shape: BoxShape.circle),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIcon(String iconName) {
    // Map nama icon dari AdminMenu ke Material Icons
    const iconMap = <String, IconData>{
      'dashboard': Icons.dashboard_outlined,
      'santri': Icons.people_outline,
      'wali': Icons.family_restroom,
      'guru': Icons.school_outlined,
      'kelas': Icons.class_outlined,
      'mapel': Icons.book_outlined,
      'jadwal': Icons.calendar_month_outlined,
      'pertemuan': Icons.event_outlined,
      'absensi': Icons.check_circle_outline,
      'nilai': Icons.star_outline,
      'tahun-ajaran': Icons.date_range,
      'siklus': Icons.loop,
      'tagihan': Icons.receipt_long_outlined,
      'pembayaran': Icons.payment_outlined,
      'kas': Icons.account_balance_wallet_outlined,
      'honor-guru': Icons.monetization_on_outlined,
      'tugas': Icons.assignment_outlined,
      'materi': Icons.folder_outlined,
      'ujian': Icons.quiz_outlined,
      'bank-soal': Icons.question_answer_outlined,
      'rapor': Icons.description_outlined,
      'kompetensi': Icons.workspace_premium_outlined,
      'pengumuman': Icons.campaign_outlined,
      'notifikasi': Icons.notifications_outlined,
      'surat': Icons.mail_outlined,
      'perkembangan': Icons.trending_up,
      'alumni': Icons.verified_outlined,
      'chat': Icons.chat_outlined,
      'qr': Icons.qr_code,
      'audit-log': Icons.history,
      'users': Icons.manage_accounts_outlined,
      'roles': Icons.admin_panel_settings_outlined,
      'permissions': Icons.lock_outline,
      'settings': Icons.settings_outlined,
    };
    return iconMap[item.icon] ?? Icons.circle_outlined;
  }
}
