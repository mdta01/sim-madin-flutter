// Permissions matrix editor — 60 codes (15 modules × 4 actions).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';

import '../../widgets/feedback_widgets.dart';

class PermissionsScreen extends ConsumerWidget {
  const PermissionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionsAsync = ref.watch(permissionListProvider);
    final rolesAsync = ref.watch(roleListProvider);
    final matrixAsync = ref.watch(allRolePermissionsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: permissionsAsync.when(
        loading: () => const LoadingSkeleton(itemCount: 6),
        error: (e, _) => ErrorView(
            message: e.toString(),
            onRetry: () => ref.invalidate(permissionListProvider)),
        data: (permissions) {
          if (permissions.isEmpty) {
            return const EmptyState(
                title: 'Belum ada permission',
                subtitle: 'Permission seed belum dijalankan.',
                icon: Icons.lock_outline);
          }

          // Group by module
          final grouped = <String, List<PermissionModel>>{};
          for (final p in permissions) {
            final module = p.code.split(':')[0];
            grouped.putIfAbsent(module, () => []).add(p);
          }

          final roles = rolesAsync.maybeWhen(
              data: (list) => list, orElse: () => []);
          final matrix = matrixAsync.maybeWhen(
              data: (m) => m, orElse: () => {});

          return roles.isEmpty
              ? const EmptyState(
                  title: 'Belum ada role',
                  subtitle: 'Buat role dulu di menu Roles',
                  icon: Icons.admin_panel_settings_outlined)
              : ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    // Header info
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.infoLight,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info, color: AppColors.info),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Permission Matrix — ${permissions.length} permission codes × ${roles.length} roles. '
                              'Toggle chip untuk grant/revoke permission per role.',
                              style: const TextStyle(
                                  fontSize: 13, color: AppColors.info),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            tooltip: 'Refresh',
                            onPressed: () {
                              ref.invalidate(allRolePermissionsProvider);
                              ref.invalidate(permissionListProvider);
                              ref.invalidate(roleListProvider);
                            },
                          ),
                        ],
                      ),
                    ),
                    // Matrix table
                    ...grouped.entries.map((entry) {
                      final module = entry.key;
                      final perms = entry.value;
                      return Card(
                        margin: const EdgeInsets.only(
                            bottom: AppSpacing.md),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Module header
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.sm,
                                    vertical: AppSpacing.xs),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.sm),
                                ),
                                child: Text(module.toUpperCase(),
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary)),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              // Table: each row = permission, each col = role
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  columns: [
                                    const DataColumn(
                                        label: Text('Permission')),
                                    ...roles.map((r) => DataColumn(
                                        label: Text(r.code,
                                            style: const TextStyle(
                                                fontSize: 11)))),
                                  ],
                                  rows: perms.map((p) {
                                    return DataRow(cells: [
                                      DataCell(Row(
                                        children: [
                                          Icon(_actionIcon(
                                              p.code.split(':')[1]),
                                              size: 16,
                                              color: AppColors.textMuted),
                                          const SizedBox(width: 6),
                                          Text(p.name,
                                              style: const TextStyle(
                                                  fontSize: 12)),
                                        ],
                                      )),
                                      ...roles.map((r) {
                                        final rolePerms =
                                            matrix[r.id] ?? <String>{};
                                        final granted =
                                            rolePerms.contains(p.id);
                                        return DataCell(
                                          Center(
                                            child: IconButton(
                                              icon: Icon(
                                                granted
                                                    ? Icons.check_circle
                                                    : Icons.circle_outlined,
                                                color: granted
                                                    ? AppColors.success
                                                    : AppColors.border,
                                                size: 20,
                                              ),
                                              tooltip: granted
                                                  ? 'Revoke'
                                                  : 'Grant',
                                              onPressed: () async {
                                                try {
                                                  if (granted) {
                                                    await revokePermissionFromRole(
                                                        ref,
                                                        roleId: r.id,
                                                        permissionId: p.id);
                  ref.invalidate(allRolePermissionsProvider);
                                                    if (!context.mounted)
                                                      return;
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                          content: Text(
                                                              '✅ Revoke ${p.code} dari ${r.code}'),
                                                          backgroundColor:
                                                              AppColors
                                                                  .warning),
                                                    );
                                                  } else {
                                                    await grantPermissionToRole(
                                                        ref,
                                                        roleId: r.id,
                                                        permissionId: p.id);
                  ref.invalidate(allRolePermissionsProvider);
                                                    if (!context.mounted)
                                                      return;
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                          content: Text(
                                                              '✅ Grant ${p.code} ke ${r.code}'),
                                                          backgroundColor:
                                                              AppColors
                                                                  .success),
                                                    );
                                                  }
                                                } catch (e) {
                                                  if (!context.mounted)
                                                    return;
                                                  ScaffoldMessenger.of(
                                                          context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                        content: Text(
                                                            'Gagal: $e'),
                                                        backgroundColor:
                                                            AppColors.danger),
                                                  );
                                                }
                                              },
                                            ),
                                          ),
                                        );
                                      }),
                                    ]);
                                  }).toList(),
                                  headingRowHeight: 40,
                                  dataRowMinHeight: 36,
                                  dataRowMaxHeight: 44,
                                  columnSpacing: 16,
                                  horizontalMargin: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                );
        },
      ),
    );
  }

  IconData _actionIcon(String action) {
    switch (action) {
      case 'view':
        return Icons.visibility;
      case 'create':
        return Icons.add_circle_outline;
      case 'edit':
        return Icons.edit;
      case 'delete':
        return Icons.delete_outline;
      default:
        return Icons.lock_outline;
    }
  }
}
