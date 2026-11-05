// AuditLog — read-only viewer with filter, search, export.
//
// Catatan: provider `auditLogListAdminProvider` di providers_admin_keuangan.dart
// sudah ada tapi tidak join tabel User. Untuk menampilkan kolom User (nama/email),
// kita buat provider screen-local yang join ke User table.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';
import '../../widgets/feedback_widgets.dart';
import '../../widgets/form_widgets.dart';

/// Screen-local provider untuk AuditLog yang sudah join User.
/// Mengembalikan raw Map supaya fleksibel untuk filter entity type + search entityId.
final auditLogViewerProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(realtimeRefreshTick);
  final client = ref.watch(supabaseClientProvider);
  final res = await client
      .from('AuditLog')
      .select('*, User(name, email)')
      .order('createdAt', ascending: false)
      .limit(200);
  return (res as List).cast<Map<String, dynamic>>();
});

/// Entity types yang umum muncul di AuditLog (untuk dropdown filter).
/// Menggunakan List<Map> supaya bisa iterasi dengan mudah.
const List<String> kAuditEntityTypes = [
  'ALL',
  'Santri',
  'Wali',
  'Guru',
  'Kelas',
  'MataPelajaran',
  'Tagihan',
  'Payment',
  'Absensi',
  'Nilai',
  'Rapor',
  'Ujian',
  'Tugas',
  'Materi',
  'Pertemuan',
  'Jadwal',
  'HonorGuru',
  'Kas',
  'User',
  'Role',
  'Announcement',
  'Surat',
  'Alumni',
  'PerkembanganQuran',
  'HafalanKitab',
  'AkhlakPenilaian',
  'Pembinaan',
];

class AuditLogScreen extends ConsumerStatefulWidget {
  const AuditLogScreen({super.key});
  @override
  ConsumerState<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends ConsumerState<AuditLogScreen> {
  String _entityFilter = 'ALL';
  final _searchCtrl = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(auditLogViewerProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header + toolbar (filter, search, export)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: const Icon(Icons.history,
                          size: 20, color: AppColors.primary),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text('Audit Log', style: AppTextStyles.h3),
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.infoLight,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text('Read-only',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.infoDark)),
                    ),
                    const Spacer(),
                    OutlinedButton.icon(
                      onPressed: _exportToClipboard,
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('Copy to Clipboard'),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    IconButton(
                      tooltip: 'Refresh',
                      icon: const Icon(Icons.refresh),
                      onPressed: () =>
                          ref.invalidate(auditLogViewerProvider),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                // Filter row
                Row(
                  children: [
                    SizedBox(
                      width: 240,
                      child: FormFieldLabel(
                        label: 'Entity Type',
                        child:
                            DropdownButtonFormField<String>(
                          value: _entityFilter,
                          decoration: const InputDecoration(
                              isDense: true, border: OutlineInputBorder()),
                          items: kAuditEntityTypes
                              .map((t) => DropdownMenuItem(
                                  value: t, child: Text(t == 'ALL' ? 'All Entities' : t)))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _entityFilter = v ?? 'ALL'),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: FormFieldLabel(
                        label: 'Search by Entity ID',
                        child: TextField(
                          controller: _searchCtrl,
                          decoration: const InputDecoration(
                            hintText: 'cth: cuid atau sebagian ID...',
                            prefixIcon: Icon(Icons.search, size: 18),
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (v) => setState(
                              () => _search = v.trim().toLowerCase()),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Body (table)
          Expanded(
            child: async.when(
              loading: () => const ModernLoadingSkeleton(itemCount: 10),
              error: (e, _) => ModernErrorView(
                message: friendlyError(e),
                onRetry: () => ref.invalidate(auditLogViewerProvider),
              ),
              data: (list) {
                final filtered = _applyFilters(list);
                if (filtered.isEmpty) {
                  return const ModernEmptyState(
                    title: 'Tidak ada audit log',
                    subtitle:
                        'Belum ada aktivitas yang tercatat untuk filter saat ini.',
                    icon: Icons.history_toggle_off,
                  );
                }
                return _buildTable(filtered);
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _applyFilters(List<Map<String, dynamic>> list) {
    var out = list;
    if (_entityFilter != 'ALL') {
      out = out.where((row) {
        final entity = (row['entity'] as String?) ?? '';
        return entity == _entityFilter;
      }).toList();
    }
    if (_search.isNotEmpty) {
      out = out.where((row) {
        final eid = (row['entityId'] as String?) ?? '';
        return eid.toLowerCase().contains(_search);
      }).toList();
    }
    return out;
  }

  Widget _buildTable(List<Map<String, dynamic>> list) {
    return ModernCard(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      padding: EdgeInsets.zero,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Timestamp')),
              DataColumn(label: Text('User')),
              DataColumn(label: Text('Action')),
              DataColumn(label: Text('Entity Type')),
              DataColumn(label: Text('Entity ID')),
              DataColumn(label: Text('Details')),
            ],
            rows: list.map(_rowFromMap).toList(),
            headingRowHeight: 48,
            dataRowMinHeight: 48,
            dataRowMaxHeight: 64,
            columnSpacing: 24,
            horizontalMargin: 16,
          ),
        ),
      ),
    );
  }

  DataRow _rowFromMap(Map<String, dynamic> row) {
    final action = (row['action'] as String?) ?? '-';
    final entity = (row['entity'] as String?) ?? '-';
    final entityId = row['entityId'] as String?;
    final details = row['details'] as String?;
    final createdAtRaw = row['createdAt'];
    final createdAt = createdAtRaw is String
        ? DateTime.tryParse(createdAtRaw) ?? DateTime.now()
        : DateTime.now();
    final user = row['User'] as Map<String, dynamic>?;
    final userName = (user?['name'] as String?) ?? '-';
    final userEmail = (user?['email'] as String?) ?? '';

    return DataRow(cells: [
      DataCell(Text(formatDateTime(createdAt),
          style: AppTextStyles.body3.copyWith(color: AppColors.textMuted))),
      DataCell(Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.primaryLight,
            child: Text(
              userName.isNotEmpty ? userName[0].toUpperCase() : '?',
              style: AppTextStyles.label
                  .copyWith(color: AppColors.primary, fontSize: 12),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(userName, style: AppTextStyles.body2),
              if (userEmail.isNotEmpty)
                Text(userEmail,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textMuted)),
            ],
          ),
        ],
      )),
      DataCell(StatusChip(
        label: action,
        color: _actionColor(action),
        bg: _actionBg(action),
        compact: true,
      )),
      DataCell(Text(entity,
          style: AppTextStyles.body2.copyWith(fontWeight: FontWeight.w500))),
      DataCell(Text(entityId ?? '-',
          style: AppTextStyles.body3.copyWith(fontFamily: 'monospace'))),
      DataCell(ConstrainedBox(
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.28),
        child: Text(
          details ?? '-',
          style: AppTextStyles.body3,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      )),
    ]);
  }

  Color _actionColor(String action) {
    switch (action.toUpperCase()) {
      case 'CREATE':
      case 'INSERT':
        return AppColors.success;
      case 'UPDATE':
      case 'PATCH':
        return AppColors.warning;
      case 'DELETE':
        return AppColors.danger;
      case 'LOGIN':
      case 'LOGOUT':
        return AppColors.info;
      default:
        return AppColors.info;
    }
  }

  Color _actionBg(String action) {
    switch (action.toUpperCase()) {
      case 'CREATE':
      case 'INSERT':
        return AppColors.successLight;
      case 'UPDATE':
      case 'PATCH':
        return AppColors.warningLight;
      case 'DELETE':
        return AppColors.dangerLight;
      case 'LOGIN':
      case 'LOGOUT':
        return AppColors.infoLight;
      default:
        return AppColors.infoLight;
    }
  }

  /// Copy all visible (filtered) audit logs ke clipboard sebagai TSV
  /// (tab-separated values) supaya bisa di-paste ke Excel/Google Sheets.
  Future<void> _exportToClipboard() async {
    final async = ref.read(auditLogViewerProvider);
    final list = async.maybeWhen(data: (d) => d, orElse: () => []);
    final filtered = _applyFilters(list);
    if (filtered.isEmpty) {
      _toast('Tidak ada data untuk di-export', true);
      return;
    }
    final buf = StringBuffer();
    buf.writeln(
        'Timestamp\tUser\tEmail\tAction\tEntity Type\tEntity ID\tDetails');
    for (final row in filtered) {
      final createdAtRaw = row['createdAt'];
      final createdAt = createdAtRaw is String
          ? (DateTime.tryParse(createdAtRaw)?.toString() ?? '')
          : '';
      final user = row['User'] as Map<String, dynamic>?;
      final userName = (user?['name'] as String?) ?? '';
      final userEmail = (user?['email'] as String?) ?? '';
      final action = (row['action'] as String?) ?? '';
      final entity = (row['entity'] as String?) ?? '';
      final entityId = (row['entityId'] as String?) ?? '';
      final details = (row['details'] as String?) ?? '';
      final sanitize = (String s) => s.replaceAll('\t', ' ').replaceAll('\n', ' ');
      buf.writeln([
        createdAt,
        sanitize(userName),
        sanitize(userEmail),
        sanitize(action),
        sanitize(entity),
        sanitize(entityId),
        sanitize(details),
      ].join('\t'));
    }
    await Clipboard.setData(ClipboardData(text: buf.toString()));
    _toast('✅ ${filtered.length} baris audit log disalin ke clipboard');
  }

  void _toast(String msg, [bool isError = false]) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.danger : AppColors.success,
    ));
  }
}
