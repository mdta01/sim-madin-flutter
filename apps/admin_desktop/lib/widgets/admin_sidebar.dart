// AdminSidebar — isi navigasi admin (34 menu).
//
// Dipisah dari AppShell supaya bisa dipakai dua cara tanpa duplikasi kode:
//   * layar lebar  -> kolom tetap di kiri, dipanggil dengan width: 240
//   * layar sempit -> isi Drawer, dipanggil tanpa width (mengikuti Drawer)
//
// Sebelumnya sidebar di-hardcode 240px di dalam Row, sehingga di layar HP
// konten terhimpit dan tidak ada cara membuka menu.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';

class AdminSidebar extends StatelessWidget {
  const AdminSidebar({
    super.key,
    required this.location,
    this.width,
    this.closeOnTap = false,
  });

  /// Route aktif, mis. '/santri' — dipakai untuk menandai menu terpilih.
  final String location;

  /// Lebar tetap (desktop). `null` = mengikuti parent (Drawer).
  final double? width;

  /// Tutup drawer setelah menu dipilih (dipakai di layar sempit).
  final bool closeOnTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: const BoxDecoration(gradient: AppColors.brandGradient),
  decoration: const BoxDecoration(gradient: AppColors.brandGradient),
  child: Column(
    children: [
      // Logo + app name (header card)
      Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppRadius.md),
                boxShadow: AppColors.cardShadow,
              ),
              child: const Icon(Icons.mosque,
                  color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SIM MADIN',
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    'Admin Desktop',
                    style: AppTextStyles.caption.copyWith(
                      color:
                          AppColors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      Divider(
        color: AppColors.white.withValues(alpha: 0.15),
        height: 1,
      ),
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
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: AppColors.white.withValues(alpha: 0.15),
            ),
          ),
        ),
        child: Text(
          'v1.0.0+1 • Phase 6a',
          style: AppTextStyles.overline.copyWith(
            color: AppColors.white.withValues(alpha: 0.6),
          ),
        ),
      ),
    ],
  ),
  );
  }
}

// ---------------------------------------------------------------------------
// Satu baris menu sidebar.
// ---------------------------------------------------------------------------
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
              horizontal: AppSpacing.lg, vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? AppColors.white.withValues(alpha: 0.18) : null,
            border: Border(
              left: BorderSide(
                color: isActive ? AppColors.gold : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                _iconFor(item.icon),
                size: 18,
                color: isActive
                    ? AppColors.white
                    : AppColors.white.withValues(alpha: 0.75),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  item.label,
                  style: AppTextStyles.body2.copyWith(
                    color: isActive
                        ? AppColors.white
                        : AppColors.white.withValues(alpha: 0.75),
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
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
}

// ALL 34 admin menus are active (Phase 6a-d complete).
const kPhase6aActiveMenus = <String>{
  'dashboard', 'users', 'roles', 'permissions', 'settings',
  'santri', 'guru', 'wali', 'kelas', 'mapel', 'tahun-ajaran',
  'jadwal', 'pertemuan', 'absensi', 'nilai', 'materi', 'tugas',
  'ujian', 'bank-soal', 'kompetensi', 'rapor', 'perkembangan',
  'siklus', 'tagihan', 'pembayaran', 'kas', 'honor-guru',
  'pengumuman', 'notifikasi', 'surat', 'alumni', 'chat', 'qr',
  'audit-log',
};

/// Pemetaan nama ikon dari [AdminMenu] ke Material Icons.
IconData _iconFor(String name) {
  return _kIconMap[name] ?? Icons.radio_button_unchecked;
}

const _kIconMap = <String, IconData>{
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
  'bank-soal': Icons.library_books_outlined,
  'kompetensi': Icons.workspace_premium_outlined,
  'rapor': Icons.description_outlined,
  'perkembangan': Icons.trending_up,
  'pengumuman': Icons.campaign_outlined,
  'notifikasi': Icons.notifications_none,
  'surat': Icons.mail_outline,
  'alumni': Icons.groups_outlined,
  'chat': Icons.chat_bubble_outline,
  'qr': Icons.qr_code_outlined,
  'audit-log': Icons.history,
  'users': Icons.manage_accounts_outlined,
  'roles': Icons.admin_panel_settings_outlined,
  'permissions': Icons.lock_outline,
  'settings': Icons.settings_outlined,
};
