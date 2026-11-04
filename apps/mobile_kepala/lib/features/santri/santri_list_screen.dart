// Santri list — read-only monitor (Tab 2 di bottom nav).
// Search by name/NIS, tap card untuk detail dialog.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';

import '../../widgets/feedback_views.dart';
import '../../widgets/status_chip.dart';

class SantriListScreen extends ConsumerStatefulWidget {
  const SantriListScreen({super.key});

  @override
  ConsumerState<SantriListScreen> createState() => _SantriListScreenState();
}

class _SantriListScreenState extends ConsumerState<SantriListScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final santriAsync = ref.watch(santriListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Data Santri')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Cari santri (nama / NIS)',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : const Icon(Icons.filter_list),
              ),
              onChanged: (v) => setState(() => _query = v.toLowerCase().trim()),
            ),
          ),
          Expanded(
            child: santriAsync.when(
              loading: () => const LoadingSkeleton(),
              error: (err, _) => ErrorView(
                message: err.toString(),
                onRetry: () => ref.invalidate(santriListProvider),
              ),
              data: (list) {
                final filtered = _query.isEmpty
                    ? list
                    : list
                        .where((s) =>
                            s.name.toLowerCase().contains(_query) ||
                            s.nis.toLowerCase().contains(_query))
                        .toList();
                if (filtered.isEmpty) {
                  return EmptyState(
                    title: _query.isEmpty
                        ? 'Belum ada data santri'
                        : 'Tidak ditemukan',
                    subtitle: _query.isEmpty ? null : 'Coba kata kunci lain',
                    onRefresh: () => ref.invalidate(santriListProvider),
                  );
                }
                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    ref.invalidate(santriListProvider);
                    await ref.read(santriListProvider.future);
                  },
                  child: ListView.builder(
                    itemCount: filtered.length,
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    itemBuilder: (context, i) {
                      final s = filtered[i];
                      return _SantriCard(santri: s);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SantriCard extends StatelessWidget {
  const _SantriCard({required this.santri});

  final SantriModel santri;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryLight,
          foregroundColor: AppColors.primary,
          child: Text(santri.initials),
        ),
        title: Text(
          santri.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('NIS: ${santri.nis} • ${santri.kelasName ?? '-'}'),
            Text('Wali: ${santri.waliName ?? '-'}${santri.waliPhone != null ? ' (${santri.waliPhone})' : ''}'),
          ],
        ),
        trailing: StatusChip(
          status: santri.status,
          style: santri.status == SantriStatus.aktif
              ? const StatusStyle(
                  label: 'Aktif',
                  color: AppColors.success,
                  bg: AppColors.successLight,
                )
              : StatusStyle(
                  label: santri.status,
                  color: AppColors.danger,
                  bg: AppColors.dangerLight,
                ),
          compact: true,
        ),
        onTap: () => _showDetail(context, santri),
      ),
    );
  }

  void _showDetail(BuildContext context, SantriModel s) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(s.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _DetailRow(label: 'NIS', value: s.nis),
              if (s.nisn != null) _DetailRow(label: 'NISN', value: s.nisn!),
              _DetailRow(label: 'Gender', value: SantriGender.label(s.gender)),
              _DetailRow(label: 'Kelas', value: s.kelasName ?? '-'),
              _DetailRow(label: 'Status', value: s.status),
              if (s.birthPlace != null || s.birthDate != null)
                _DetailRow(
                  label: 'TTL',
                  value:
                      '${s.birthPlace ?? '-'}, ${s.birthDate != null ? formatDate(s.birthDate) : '-'}',
                ),
              if (s.address != null) _DetailRow(label: 'Alamat', value: s.address!),
              if (s.phone != null) _DetailRow(label: 'Telepon', value: s.phone!),
              _DetailRow(label: 'Wali', value: s.waliName ?? '-'),
              if (s.waliPhone != null)
                _DetailRow(label: 'Telp. Wali', value: s.waliPhone!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.text,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
