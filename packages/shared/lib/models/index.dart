// Models barrel — Phase 2+ (mobile_kepala read-only screens)
//
// Catatan: model ini di-port dari Prisma schema di repo sim-madin (TS lama).
// Field relations di-denormalize sebagai field nullable terpisah (e.g. `santriName`)
// supaya tidak perlu nested serialization kompleks di query Supabase.

export 'user.dart';
export 'tahun_ajaran.dart';
export 'kelas.dart';
export 'mata_pelajaran.dart';
export 'santri.dart';
export 'guru.dart';
export 'absensi.dart';
export 'nilai.dart';
export 'tagihan.dart';
export 'payment.dart';
export 'kas.dart';
export 'honor_guru.dart';

// Phase 4 — mobile_guru models
export 'jadwal.dart';
export 'materi.dart';
export 'tugas.dart';
export 'pertemuan.dart';
export 'ujian.dart';
export 'perkembangan.dart';
export 'komunikasi.dart';
