// Santri Detail — 6 tabs (Profil, Akademik, Ujian, Keuangan, Notif, Info).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../widgets/feedback_widgets.dart';

class SantriDetailScreen extends ConsumerStatefulWidget {
  const SantriDetailScreen({super.key, required this.santriId});
  final String santriId;
  @override
  ConsumerState<SantriDetailScreen> createState() =>
      _SantriDetailScreenState();
}

class _SantriDetailScreenState extends ConsumerState<SantriDetailScreen> {
  String _activeTab = 'profil';

  static const _tabs = <_TabSpec>[
    _TabSpec(id: 'profil', label: 'Profil', icon: Icons.person_outline),
    _TabSpec(id: 'akademik', label: 'Akademik', icon: Icons.school_outlined),
    _TabSpec(id: 'ujian', label: 'Ujian', icon: Icons.quiz_outlined),
    _TabSpec(id: 'keuangan', label: 'Keuangan', icon: Icons.account_balance_wallet_outlined),
    _TabSpec(id: 'notif', label: 'Notif', icon: Icons.notifications_outlined),
    _TabSpec(id: 'info', label: 'Info', icon: Icons.campaign_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final santriAsync = ref.watch(santriDetailProvider(widget.santriId));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Detail Santri')),
      body: Column(
        children: [
          // Santri header card
          santriAsync.when(
            loading: () => const SizedBox(
                height: 100,
                child: Center(
                    child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2)))),
            error: (e, _) => SizedBox(
                height: 100,
                child: Center(child: Text('Error: ${friendlyError(e)}',
                    style: const TextStyle(color: AppColors.danger)))),
            data: (santri) {
              if (santri == null) {
                return const SizedBox(
                    height: 100,
                    child: Center(child: Text('Santri tidak ditemukan')));
              }
              return Container(
                margin: const EdgeInsets.all(AppSpacing.md),
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: AppColors.white,
                      foregroundColor: AppColors.primary,
                      backgroundImage: santri.photoUrl != null
                          ? NetworkImage(santri.photoUrl!)
                          : null,
                      child: santri.photoUrl == null
                          ? Text(santri.initials,
                              style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold))
                          : null,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(santri.name,
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.white)),
                          Text('NIS: ${santri.nis}',
                              style: const TextStyle(
                                  fontSize: 13, color: AppColors.white)),
                          if (santri.kelasName != null)
                            Text(santri.kelasName!,
                                style: const TextStyle(
                                    fontSize: 13, color: AppColors.white)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          // Tab bar horizontal
          Container(
            color: AppColors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _tabs.map((t) {
                  final active = _activeTab == t.id;
                  return InkWell(
                    onTap: () => setState(() => _activeTab = t.id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md, vertical: AppSpacing.md),
                      decoration: BoxDecoration(
                        border: Border(
                            bottom: BorderSide(
                                color: active
                                    ? AppColors.primary
                                    : Colors.transparent,
                                width: 2)),
                      ),
                      child: Row(
                        children: [
                          Icon(t.icon,
                              size: 18,
                              color: active
                                  ? AppColors.primary
                                  : AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text(t.label,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: active
                                      ? AppColors.primary
                                      : AppColors.textMuted)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          // Tab content
          Expanded(child: _buildTabContent()),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_activeTab) {
      case 'profil':
        return _ProfilTab(santriId: widget.santriId);
      case 'akademik':
        return _AkademikTab(santriId: widget.santriId);
      case 'ujian':
        return _UjianTab(santriId: widget.santriId);
      case 'keuangan':
        return _KeuanganTab(santriId: widget.santriId);
      case 'notif':
        return _NotifTab(santriId: widget.santriId);
      case 'info':
        return _InfoTab();
      default:
        return const SizedBox.shrink();
    }
  }
}

class _TabSpec {
  const _TabSpec(
      {required this.id, required this.label, required this.icon});
  final String id;
  final String label;
  final IconData icon;
}

// === Profil Tab ===
class _ProfilTab extends ConsumerWidget {
  const _ProfilTab({required this.santriId});
  final String santriId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final santriAsync = ref.watch(santriDetailProvider(santriId));
    return santriAsync.when(
      loading: () => const LoadingSkeleton(itemCount: 4),
      error: (e, _) => ErrorView(message: friendlyError(e)),
      data: (s) {
        if (s == null) return const EmptyState(title: 'Santri tidak ditemukan');
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            _infoCard('Nama Lengkap', s.name),
            _infoCard('NIS', s.nis),
            if (s.nisn != null) _infoCard('NISN', s.nisn!),
            _infoCard('Jenis Kelamin', SantriGender.label(s.gender)),
            if (s.birthPlace != null || s.birthDate != null)
              _infoCard('TTL',
                  '${s.birthPlace ?? '-'}, ${s.birthDate != null ? formatDate(s.birthDate) : '-'}'),
            if (s.address != null) _infoCard('Alamat', s.address!),
            if (s.phone != null) _infoCard('Telepon', s.phone!),
            _infoCard('Kelas', s.kelasName ?? '-'),
            _infoCard('Status', s.status),
            _infoCard('Wali', s.waliName ?? '-'),
            if (s.waliPhone != null) _infoCard('Telp. Wali', s.waliPhone!),
            _infoCard('Tgl. Masuk', formatDate(s.entryDate)),
          ],
        );
      },
    );
  }

  Widget _infoCard(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textMuted)),
          ),
          const Text(': '),
          Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}

// === Akademik Tab (absensi + nilai + perkembangan) ===
class _AkademikTab extends ConsumerWidget {
  const _AkademikTab({required this.santriId});
  final String santriId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final absensiAsync = ref.watch(absensiAnakProvider(santriId));
    final nilaiAsync = ref.watch(nilaiAnakProvider(santriId));
    final materiAsync = ref.watch(materiAnakProvider(santriId));

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // Absensi summary
        const Text('Absensi (30 hari terakhir)',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.sm),
        absensiAsync.when(
          loading: () => const SizedBox(
              height: 60,
              child: Center(
                  child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2)))),
          error: (e, _) => Text('Error: ${friendlyError(e)}',
              style: const TextStyle(color: AppColors.danger, fontSize: 12)),
          data: (list) {
            if (list.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Text('Belum ada data absensi',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              );
            }
            final hadir = list
                .where((a) => a.status == AbsensiStatus.hadir)
                .length;
            final sakit =
                list.where((a) => a.status == AbsensiStatus.sakit).length;
            final izin =
                list.where((a) => a.status == AbsensiStatus.izin).length;
            final alfa =
                list.where((a) => a.status == AbsensiStatus.alfa).length;
            return Row(
              children: [
                Expanded(
                    child: _absStat('Hadir', hadir, AppColors.success,
                        AppColors.successLight)),
                Expanded(
                    child: _absStat('Sakit', sakit, AppColors.warning,
                        AppColors.warningLight)),
                Expanded(
                    child: _absStat('Izin', izin, AppColors.info,
                        AppColors.infoLight)),
                Expanded(
                    child: _absStat('Alfa', alfa, AppColors.danger,
                        AppColors.dangerLight)),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.md),
        // Nilai recent
        const Text('Nilai Terbaru',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.sm),
        nilaiAsync.when(
          loading: () => const SizedBox(
              height: 60,
              child: Center(
                  child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2)))),
          error: (e, _) => Text('Error: ${friendlyError(e)}',
              style: const TextStyle(color: AppColors.danger, fontSize: 12)),
          data: (list) {
            if (list.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Text('Belum ada nilai',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              );
            }
            return Column(
              children: list.take(10).map((n) {
                final lulus = isLulus(n.score, n.mapelKkm);
                return Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: ListTile(
                    dense: true,
                    title: Text(n.mapelName ?? '-',
                        style: const TextStyle(fontSize: 13)),
                    subtitle: Text('${n.type} • ${formatDate(n.assessmentDate)}',
                        style: const TextStyle(fontSize: 11)),
                    trailing: Text(n.score.toStringAsFixed(0),
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: lulus
                                ? AppColors.success
                                : AppColors.danger)),
                  ),
                );
              }).toList(),
            );
          },
        ),
        const SizedBox(height: AppSpacing.md),
        // Materi section
        const Text('Materi Pelajaran',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.sm),
        materiAsync.when(
          loading: () => const SizedBox(
              height: 60,
              child: Center(
                  child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2)))),
          error: (e, _) => Text('Error: ${friendlyError(e)}',
              style: const TextStyle(color: AppColors.danger, fontSize: 12)),
          data: (list) {
            if (list.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Text('Belum ada materi',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              );
            }
            return Column(
              children: list.map((m) {
                final hasFile = (m.fileUrl != null && m.fileUrl!.isNotEmpty) ||
                    (m.externalUrl != null && m.externalUrl!.isNotEmpty);
                return Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: ListTile(
                    dense: true,
                    leading: Icon(
                        MateriType.label(m.type) == 'Video'
                            ? Icons.video_library_outlined
                            : MateriType.label(m.type) == 'Link'
                                ? Icons.link
                                : Icons.picture_as_pdf_outlined,
                        size: 22,
                        color: AppColors.primary),
                    title: Text(m.title,
                        style: const TextStyle(fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                        '${m.mapelName ?? '-'} • ${formatDate(m.createdAt)}',
                        style: const TextStyle(fontSize: 11)),
                    trailing: hasFile
                        ? IconButton(
                            icon: const Icon(Icons.download, size: 20),
                            color: AppColors.primary,
                            tooltip: 'Buka file',
                            onPressed: () => _openMateriFile(
                                context, ref, m),
                          )
                        : null,
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _absStat(String label, int count, Color color, Color bg) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Column(
        children: [
          Text('$count',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  /// Buka file materi (PDF/image) atau URL eksternal.
  /// Untuk materi dengan externalUrl, langsung buka URL tersebut.
  /// Untuk materi dengan fileUrl di bucket public (materi), URL sudah public.
  /// Untuk file di bucket private (jarang di wali), perlu signed URL — tidak
  /// terjadi di materi karena bucket materi adalah public.
  Future<void> _openMateriFile(
      BuildContext context, WidgetRef ref, MateriModel m) async {
    String? url;
    if (m.externalUrl != null && m.externalUrl!.isNotEmpty) {
      url = m.externalUrl;
    } else if (m.fileUrl != null && m.fileUrl!.isNotEmpty) {
      url = m.fileUrl;
    }
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Tidak ada file untuk materi ini'),
            backgroundColor: AppColors.warning),
      );
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('URL tidak valid: $url'),
            backgroundColor: AppColors.danger),
      );
      return;
    }
    try {
      final launched = await launchUrl(uri,
          mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Tidak bisa membuka: $url'),
              backgroundColor: AppColors.warning),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error: ${friendlyError(e)}'),
            backgroundColor: AppColors.danger),
      );
    }
  }
}

// === Ujian Tab ===
class _UjianTab extends ConsumerWidget {
  const _UjianTab({required this.santriId});
  final String santriId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncValue = ref.watch(ujianPesertaAnakProvider(santriId));
    return asyncValue.when(
      loading: () => const LoadingSkeleton(itemCount: 4),
      error: (e, _) => ErrorView(message: friendlyError(e)),
      data: (list) {
        if (list.isEmpty) {
          return const EmptyState(
              title: 'Belum ada ujian',
              subtitle: 'Anak belum terdaftar sebagai peserta ujian apapun.',
              icon: Icons.quiz_outlined);
        }
        return ListView.builder(
          itemCount: list.length,
          padding: const EdgeInsets.all(AppSpacing.md),
          itemBuilder: (c, i) {
            final p = list[i];
            return Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: ListTile(
                title: Text('Ujian',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: Text(
                    'Ruang: ${p.ruang ?? '-'} • Pengawas: ${p.pengawas ?? '-'}',
                    style: const TextStyle(fontSize: 12)),
                trailing: p.isHadir
                    ? const StatusChip(
                        label: 'Hadir',
                        color: AppColors.success,
                        bg: AppColors.successLight,
                        compact: true)
                    : const StatusChip(
                        label: 'Absen',
                        color: AppColors.danger,
                        bg: AppColors.dangerLight,
                        compact: true),
                onTap: () {
                  // Hanya peserta yang hadir yang bisa take ujian.
                  if (!p.isHadir) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Anda tercatat absen pada ujian ini. Hubungi pengawas/admin.'),
                          backgroundColor: AppColors.warning),
                    );
                    return;
                  }
                  // Navigasi ke UjianTakeScreen (fullscreen, anti-cheat).
                  context.push(
                      '/dashboard/home/santri/$santriId/ujian/${p.ujianId}/take');
                },
              ),
            );
          },
        );
      },
    );
  }
}

// === Keuangan Tab ===
class _KeuanganTab extends ConsumerWidget {
  const _KeuanganTab({required this.santriId});
  final String santriId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagihanAsync = ref.watch(tagihanAnakProvider(santriId));
    final paymentAsync = ref.watch(paymentAnakProvider(santriId));

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        const Text('Tagihan',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.sm),
        tagihanAsync.when(
          loading: () => const SizedBox(
              height: 60,
              child: Center(
                  child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2)))),
          error: (e, _) => Text('Error: ${friendlyError(e)}',
              style: const TextStyle(color: AppColors.danger, fontSize: 12)),
          data: (list) {
            if (list.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Text('🎉 Tidak ada tagihan tertunggak',
                    style: TextStyle(color: AppColors.success, fontSize: 13)),
              );
            }
            final outstanding = list
                .where((t) => t.status != TagihanStatus.lunas)
                .fold<double>(0, (s, t) => s + tagihanOutstanding(t));
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.dangerLight,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: AppColors.danger),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Tunggakan',
                                style: TextStyle(
                                    fontSize: 11, color: AppColors.danger)),
                            Text(formatRupiah(outstanding),
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.danger)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                ...list.take(5).map((t) => Card(
                      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: ListTile(
                        dense: true,
                        title: Text(
                            t.jenisTagihanName ?? 'Tagihan',
                            style: const TextStyle(fontSize: 13)),
                        subtitle: Text(
                            '${formatRupiah(t.amount)} • Sisa: ${formatRupiah(tagihanOutstanding(t))}',
                            style: const TextStyle(fontSize: 11)),
                        trailing: StatusChip(
                          label: t.status == TagihanStatus.lunas
                              ? 'Lunas'
                              : t.status == TagihanStatus.cicil
                                  ? 'Cicil'
                                  : 'Belum',
                          color: t.status == TagihanStatus.lunas
                              ? AppColors.success
                              : t.status == TagihanStatus.cicil
                                  ? AppColors.warning
                                  : AppColors.danger,
                          bg: t.status == TagihanStatus.lunas
                              ? AppColors.successLight
                              : t.status == TagihanStatus.cicil
                                  ? AppColors.warningLight
                                  : AppColors.dangerLight,
                          compact: true,
                        ),
                      ),
                    )),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.md),
        const Text('Riwayat Pembayaran',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.sm),
        paymentAsync.when(
          loading: () => const SizedBox(
              height: 60,
              child: Center(
                  child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2)))),
          error: (e, _) => Text('Error: ${friendlyError(e)}',
              style: const TextStyle(color: AppColors.danger, fontSize: 12)),
          data: (list) {
            if (list.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Text('Belum ada pembayaran',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              );
            }
            return Column(
              children: list.take(10).map((p) {
                return Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: ListTile(
                    dense: true,
                    title: Text(p.invoiceNo,
                        style: const TextStyle(fontSize: 13)),
                    subtitle: Text(
                        '${formatDateTime(p.paymentDate)} • ${PaymentMethod.label(p.paymentMethod)}',
                        style: const TextStyle(fontSize: 11)),
                    trailing: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(formatRupiah(p.amount),
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.success)),
                        StatusChip(
                          label: p.status == PaymentStatus.verified
                              ? 'Verified'
                              : p.status == PaymentStatus.pending
                                  ? 'Pending'
                                  : 'Rejected',
                          color: p.status == PaymentStatus.verified
                              ? AppColors.success
                              : p.status == PaymentStatus.pending
                                  ? AppColors.warning
                                  : AppColors.danger,
                          bg: p.status == PaymentStatus.verified
                              ? AppColors.successLight
                              : p.status == PaymentStatus.pending
                                  ? AppColors.warningLight
                                  : AppColors.dangerLight,
                          compact: true,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

// === Notif Tab ===
class _NotifTab extends ConsumerWidget {
  const _NotifTab({required this.santriId});
  final String santriId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Filter notifikasi per santri (sebelumnya tampilkan semua notifikasi wali).
    final asyncValue = ref.watch(notifikasiAnakProvider(santriId));
    return asyncValue.when(
      loading: () => const LoadingSkeleton(),
      error: (e, _) => ErrorView(message: friendlyError(e)),
      data: (list) {
        if (list.isEmpty) {
          return const EmptyState(
              title: 'Belum ada notifikasi untuk anak ini',
              subtitle: 'Notifikasi terkait anak akan muncul di sini.',
              icon: Icons.notifications_off_outlined);
        }
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(notifikasiAnakProvider(santriId));
            await ref.read(notifikasiAnakProvider(santriId).future);
          },
          child: ListView.builder(
            itemCount: list.length,
            padding: const EdgeInsets.all(AppSpacing.md),
            itemBuilder: (c, i) {
              final n = list[i];
              return Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                color: n.isRead ? null : AppColors.infoLight.withOpacity(0.3),
                child: InkWell(
                  onTap: n.isRead
                      ? null
                      : () async {
                          await markNotifikasiRead(ref, n.id);
                        },
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(n.title,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600)),
                            ),
                            if (!n.isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                    color: AppColors.danger,
                                    shape: BoxShape.circle),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(n.message,
                            style: const TextStyle(fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(formatDateTime(n.createdAt),
                            style: const TextStyle(
                                fontSize: 10, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// === Info Tab (pengumuman) ===
class _InfoTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncValue = ref.watch(pengumumanWaliProvider);
    return asyncValue.when(
      loading: () => const LoadingSkeleton(),
      error: (e, _) => ErrorView(message: friendlyError(e)),
      data: (list) {
        if (list.isEmpty) {
          return const EmptyState(
              title: 'Belum ada pengumuman',
              icon: Icons.campaign_outlined);
        }
        return ListView.builder(
          itemCount: list.length,
          padding: const EdgeInsets.all(AppSpacing.md),
          itemBuilder: (c, i) {
            final p = list[i];
            Color color;
            Color bg;
            switch (p.priority) {
              case AnnouncementPriority.urgent:
                color = AppColors.danger;
                bg = AppColors.dangerLight;
                break;
              case AnnouncementPriority.penting:
                color = AppColors.warning;
                bg = AppColors.warningLight;
                break;
              default:
                color = AppColors.info;
                bg = AppColors.infoLight;
            }
            return Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                              color: bg,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.sm)),
                          child: Text(p.priority,
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: color)),
                        ),
                        if (p.publishedAt != null) ...[
                          const Spacer(),
                          Text(formatDate(p.publishedAt),
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textMuted)),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(p.title,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(p.content, style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
