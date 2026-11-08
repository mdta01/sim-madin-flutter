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

import 'admin_sidebar.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  // Layar < 900px (HP/tablet kecil): sidebar menjadi Drawer agar konten tidak
  // terhimpit. Desktop tetap memakai sidebar tetap di kiri.
  static const double _kSidebarBreakpoint = 900;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setupAdminRealtime(ref);
    });
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Konfirmasi Keluar', style: AppTextStyles.h3),
        content: Text(
          'Apakah Anda yakin ingin keluar?',
          style: AppTextStyles.body1.copyWith(color: AppColors.textMuted),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Keluar'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: AppColors.white,
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final client = ref.read(supabaseClientProvider);
    // Lepas semua channel realtime SEBELUM signOut. Tanpa ini, channel lama
    // tetap hidup dan setelah login ulang event-nya dobel (dan memory bocor).
    await disposeAppRealtime(ref);
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

    return LayoutBuilder(
      builder: (context, constraints) {
        // Drawer hanya relevan di layar sempit.
        final isNarrow = constraints.maxWidth < _kSidebarBreakpoint;

        return Scaffold(
          key: _scaffoldKey,
          drawer: isNarrow
              ? Drawer(
                  width: 264,
                  backgroundColor: Colors.transparent,
                  child: AdminSidebar(location: location, closeOnTap: true),
                )
              : null,
          body: Row(
            children: [
          // Sidebar tetap — hanya pada layar lebar.
          if (isNarrow) const SizedBox.shrink() else
            AdminSidebar(location: location, width: 240),
          // === Main content area ===
          Expanded(
            child: Column(
              children: [
                // Top bar (ModernCard style)
                ModernCard(
                  elevation: CardElevation.none,
                  backgroundColor: AppColors.white,
                  borderRadius: 0,
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                  child: Row(
                    children: [
                      // Layar sempit: buka drawer yang berisi menu admin.
                      if (isNarrow) ...[
                        IconButton(
                          icon: const Icon(Icons.menu),
                          tooltip: 'Menu',
                          onPressed: () =>
                              _scaffoldKey.currentState?.openDrawer(),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                      ],
                      // Current page title
                      Expanded(
                        child: Text(
                          _pageTitle(location),
                          style: AppTextStyles.h3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Refresh button
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 20),
                        tooltip: 'Refresh Data',
                        onPressed: () => invalidateAdminQueries(ref),
                      ),
                      // User info — klik untuk membuka halaman profil
                      const SizedBox(width: AppSpacing.sm),
                      Tooltip(
                        message: 'Buka profil saya',
                        child: InkWell(
                          onTap: () => context.go('/profile'),
                          borderRadius:
                              BorderRadius.circular(AppRadius.pill),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xs,
                              vertical: 2,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: AppColors.primaryLight,
                                  foregroundColor: AppColors.primary,
                                  child: Text(
                                    userInitial,
                                    style: AppTextStyles.label.copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Text(userEmail, style: AppTextStyles.body2),
                              ],
                            ),
                          ),
                        ),
                      ),
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
                      horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    border: Border(
                        top: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(
                    children: [
                      // Status sebenarnya (bukan teks statis): hijau bila
                      // channel realtime benar-benar tersambung.
                      Builder(
                        builder: (context) {
                          final connected = ref
                              .watch(realtimeSubscribedTables)
                              .isNotEmpty;
                          final events = ref.watch(realtimeEventCount);
                          return Row(
                            children: [
                              Icon(
                                Icons.circle,
                                size: 8,
                                color: connected
                                    ? AppColors.success
                                    : AppColors.warning,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                connected
                                    ? 'Realtime aktif • $events perubahan'
                                    : 'Realtime terputus — data perlu refresh manual',
                                style: AppTextStyles.caption.copyWith(
                                  color: connected
                                      ? AppColors.textMuted
                                      : AppColors.warning,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const Spacer(),
                      Text(
                        'Server: ${SupabaseConfig.url.replaceAll("https://", "").split(".").first}',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
        );
      },
    );
  }

  String _pageTitle(String location) {
    final path = location.replaceAll('/', '');
    final item = AdminMenu.items.where((i) => i.id == path).firstOrNull;
    return item?.label ?? 'Dashboard';
  }
}


