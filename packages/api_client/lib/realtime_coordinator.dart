// ============================================================================
// SIM MADIN — Realtime coordinator
// ============================================================================
// SATU sumber kebenaran untuk tabel mana yang di-subscribe tiap aplikasi.
//
// Masalah yang diperbaiki file ini:
//   1. mobile_guru subscribe ke tabel `'Pengumuman'` — tabel itu TIDAK ADA
//      (nama sebenarnya `Announcement`). Supabase Realtime tidak error untuk
//      tabel yang tidak dikenal, jadi pengumuman dari admin tidak pernah
//      muncul realtime di app guru — gagal secara diam-diam.
//   2. Banyak tabel referensi/kritis tidak di-subscribe sama sekali
//      (Santri, Guru, Kelas, MataPelajaran, TahunAjaran, Semester,
//      JenisTagihan, Announcement, UjianPeserta, UjianNilai, UjianJawaban,
//      Materi, Wali, User), sehingga data baru dari admin desa tidak
//      auto-refresh di app mobile.
//   3. admin_desktop tidak punya realtime sama sekali, padahal application
//      ini sumber perubahan data — tanpa itu dashboard KPI admin basi dan
//      perubahan dari bendahara/guru tidak terlihat.
//
// Semua daftar di bawah HARUS konsisten dengan:
//   - `supabase/migrations/*_enable_realtime_publication.sql` (publication)
//   - RLS: realtime hanya mengirim baris yang boleh dibaca user tersebut.
// ============================================================================

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_client/supabase_client.dart';

/// Tabel yang selalu dibutuhkan semua aplikasi (master data + sinyal umum).
/// Perubahan di sini memicu refresh provider yang `ref.watch(realtimeTick)`.
const List<String> _kMasterTables = <String>[
  'TahunAjaran',
  'Semester',
  'Kelas',
  'MataPelajaran',
  'Santri',
  'Guru',
  'Wali',
];

/// Tabel yang di-subscribe mobile_wali.
///
/// Fokus: notifikasi, chat, akademik anak, keuangan anak, ujian online.
const List<String> kWaliRealtimeTables = <String>[
  ..._kMasterTables,
  // Komunikasi
  'Notifikasi',
  'Announcement',
  'ChatRoom',
  'ChatMessage',
  // Akademik anak
  'Absensi',
  'Nilai',
  'Materi',
  'Tugas',
  'PengumpulanTugas',
  'Pertemuan',
  // Perkembangan
  'PerkembanganQuran',
  'HafalanKitab',
  'AkhlakPenilaian',
  'Pembinaan',
  // Ujian online
  'Ujian',
  'UjianSoal',
  'UjianPeserta',
  'UjianSesi',
  'UjianJawaban',
  'UjianNilai',
  // Keuangan anak
  'JenisTagihan',
  'Tagihan',
  'Payment',
];

/// Tabel yang di-subscribe mobile_guru.
///
/// Fokus: akademik yang dia ajar + komunikasi wali + ujian.
const List<String> kGuruRealtimeTables = <String>[
  ..._kMasterTables,
  'Jadwal',
  'Pertemuan',
  'Absensi',
  'Nilai',
  'Materi',
  'Tugas',
  'PengumpulanTugas',
  'Kompetensi',
  'Rapor',
  // Ujian & bank soal
  'Ujian',
  'UjianSoal',
  'UjianPeserta',
  'UjianSesi',
  'UjianNilai',
  'BankSoal',
  // Perkembangan
  'PerkembanganQuran',
  'HafalanKitab',
  'AkhlakPenilaian',
  'Pembinaan',
  // Komunikasi
  'ChatRoom',
  'ChatMessage',
  'Announcement',
];

/// Tabel yang di-subscribe mobile_bendahara.
///
/// Fokus: seluruh alur uang (tagihan → pembayaran → kas → honor) plus
/// master data yang dipakai untuk filter.
const List<String> kBendaharaRealtimeTables = <String>[
  ..._kMasterTables,
  'JenisTagihan',
  'Tagihan',
  'Payment',
  'Kas',
  'TransaksiKas',
  'HonorGuru',
  'Announcement',
  'Surat',
];

/// Tabel yang di-subscribe mobile_kepala (read-only monitoring).
///
/// Fokus: semua angka yang dipantau pimpinan.
const List<String> kKepalaRealtimeTables = <String>[
  ..._kMasterTables,
  'Jadwal',
  'Absensi',
  'Nilai',
  'JenisTagihan',
  'Tagihan',
  'Payment',
  'Kas',
  'TransaksiKas',
  'HonorGuru',
  'Announcement',
  'Surat',
  'Ujian',
];

/// Tabel yang di-subscribe admin_desktop.
///
/// Admin adalah sumber perubahan utama, tapi tetap butuh realtime supaya
/// perubahan dari bendahara (verifikasi bayar), guru (nilai/absensi), dan
/// wali (chat, upload bukti) langsung terlihat tanpa klik refresh.
const List<String> kAdminRealtimeTables = <String>[
  ..._kMasterTables,
  'User',
  'UserRole',
  'Role',
  'RolePermission',
  'Jadwal',
  'Pertemuan',
  'Absensi',
  'Nilai',
  'Rapor',
  'Kompetensi',
  'Materi',
  'Tugas',
  'PengumpulanTugas',
  'BankSoal',
  'Ujian',
  'UjianSoal',
  'UjianPeserta',
  'UjianNilai',
  'PerkembanganQuran',
  'HafalanKitab',
  'AkhlakPenilaian',
  'Pembinaan',
  'JenisTagihan',
  'Tagihan',
  'Payment',
  'Kas',
  'TransaksiKas',
  'HonorGuru',
  'Announcement',
  'Notifikasi',
  'Surat',
  'ChatRoom',
  'ChatMessage',
  'Alumni',
  'AuditLog',
  'SystemSetting',
];

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

/// Naik setiap ada perubahan realtime. Semua provider data yang
/// `ref.watch(realtimeTick)` akan otomatis refetch.
final realtimeTick = StateProvider<int>((_) => 0);

/// Jumlah event realtime yang diterima sejak app dibuka — dipakai untuk
/// indikator "Realtime aktif" di UI supaya statusnya bisa diverifikasi user,
/// bukan sekadar tulisan statis.
final realtimeEventCount = StateProvider<int>((_) => 0);

/// Tabel yang sedang di-subscribe (untuk debugging/indikator status).
final realtimeSubscribedTables = StateProvider<List<String>>((_) => const []);

/// Channel aktif — disimpan supaya bisa di-unsubscribe saat logout
/// (mencegah memory leak + event dobel setelah login ulang).
final realtimeChannelsState =
    StateProvider<List<RealtimeChannel>>((_) => const []);

// ---------------------------------------------------------------------------
// Setup / teardown
// ---------------------------------------------------------------------------

/// Inti start/stop, dipisah dari tipe ref supaya bisa dipakai baik oleh
/// `Ref` (di dalam provider) maupun `WidgetRef` (di dalam widget).
Future<void> _startCore({
  required SupabaseClient client,
  required List<String> tables,
  required Future<void> Function() teardown,
  required void Function(List<RealtimeChannel> channels) onChannels,
  required void Function(List<String> tables) onSubscribed,
  required void Function() onEvent,
}) async {
  await teardown();

  final channels = <RealtimeChannel>[];
  final subscribed = <String>[];

  for (final table in tables) {
    try {
      final channel = subscribeToTable(
        client: client,
        table: table,
        onPayload: (_) => onEvent(),
      );
      channels.add(channel);
      subscribed.add(table);
    } catch (_) {
      // Realtime bersifat best-effort: kalau satu tabel gagal (RLS/network),
      // tabel lain tetap jalan dan UI masih bisa pull-to-refresh manual.
    }
  }

  onChannels(channels);
  onSubscribed(subscribed);
}

Future<void> _stopCore(
  List<RealtimeChannel> channels,
  void Function(List<RealtimeChannel>) onChannels,
  void Function(List<String>) onSubscribed,
) async {
  if (channels.isNotEmpty) {
    await Future.wait(channels.map((c) async {
      try {
        await c.unsubscribe();
      } catch (_) {
        // Best-effort.
      }
    }));
  }
  onChannels(const []);
  onSubscribed(const []);
}

/// Subscribe ke [tables] dari dalam sebuah provider (`Ref`).
Future<void> startRealtime(Ref ref, {required List<String> tables}) {
  return _startCore(
    client: ref.read(supabaseClientProvider),
    tables: tables,
    teardown: () => stopRealtime(ref),
    onChannels: (c) => ref.read(realtimeChannelsState.notifier).state = c,
    onSubscribed: (t) =>
        ref.read(realtimeSubscribedTables.notifier).state = t,
    onEvent: () {
      ref.read(realtimeTick.notifier).state++;
      ref.read(realtimeEventCount.notifier).state++;
    },
  );
}

/// Subscribe ke [tables] dari widget (`WidgetRef`) — dipanggil di initState
/// dashboard tiap aplikasi.
void startAppRealtime(WidgetRef ref, {required List<String> tables}) {
  unawaited(_startCore(
    client: ref.read(supabaseClientProvider),
    tables: tables,
    teardown: () => stopAppRealtime(ref),
    onChannels: (c) => ref.read(realtimeChannelsState.notifier).state = c,
    onSubscribed: (t) =>
        ref.read(realtimeSubscribedTables.notifier).state = t,
    onEvent: () {
      ref.read(realtimeTick.notifier).state++;
      ref.read(realtimeEventCount.notifier).state++;
    },
  ));
}

/// Unsubscribe semua channel dari dalam provider.
Future<void> stopRealtime(Ref ref) => _stopCore(
      ref.read(realtimeChannelsState),
      (c) => ref.read(realtimeChannelsState.notifier).state = c,
      (t) => ref.read(realtimeSubscribedTables.notifier).state = t,
    );

/// Unsubscribe semua channel dari widget (dipanggil saat logout).
Future<void> stopAppRealtime(WidgetRef ref) => _stopCore(
      ref.read(realtimeChannelsState),
      (c) => ref.read(realtimeChannelsState.notifier).state = c,
      (t) => ref.read(realtimeSubscribedTables.notifier).state = t,
    );
