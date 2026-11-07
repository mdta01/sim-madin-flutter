// ============================================================================
// SIM MADIN — Supabase Storage Service
// ============================================================================
// Wrapper untuk Supabase Storage API. Konsisten dipakai di semua apps:
//   - admin_desktop (upload materi/surat/pengumuman + foto profil)
//   - mobile_guru   (upload materi/tugas/ujian + foto profil)
//   - mobile_bendahara (upload bukti pembayaran)
//   - mobile_kepala (read-only, signed URL untuk surat)
//   - mobile_wali   (read-only, public URLs untuk foto profil & materi)
//
// 6 buckets di Supabase Storage:
//   photos     (public)  — foto profil santri/guru/wali. Max 5MB.
//   materi     (public)  — PDF/PPT/DOC materi pelajaran. Max 50MB.
//   pengumuman (public)  — lampiran pengumuman. Max 10MB.
//   surat      (private) — PDF surat resmi (admin-only). Max 10MB.
//   tugas      (private) — lampiran tugas (guru upload, siswa baca). Max 10MB.
//   ujian      (private) — lampiran soal ujian (guru upload). Max 10MB.
//
// RLS policies sudah dideploy (lihat migration 20240101000007). Public bucket
// bisa diakses tanpa auth via URL langsung; private bucket harus pakai
// createSignedUrl() dengan expiry pendek (default 1 jam).
// ============================================================================

import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:supabase_client/supabase_client.dart';


/// Nama bucket Supabase Storage. Diset konstan supaya tidak salah ketik.
class StorageBucket {
  StorageBucket._();

  /// Foto profil santri/guru/wali. PUBLIC (anonymous bisa baca).
  static const photos = 'photos';

  /// PDF/PPT/DOC materi pelajaran. PUBLIC.
  static const materi = 'materi';

  /// Lampiran pengumuman (PDF/image). PUBLIC.
  static const pengumuman = 'pengumuman';

  /// PDF surat resmi. PRIVATE (admin-only via signed URL).
  static const surat = 'surat';

  /// Lampiran tugas. PRIVATE (guru upload, siswa baca).
  static const tugas = 'tugas';

  /// Lampiran soal ujian. PRIVATE (guru upload, siswa baca saat ujian).
  static const ujian = 'ujian';

  /// Daftar semua bucket yang dipakai di app.
  static const all = [photos, materi, pengumuman, surat, tugas, ujian];
}

/// Konfigurasi tambahan per bucket (max file size, allowed MIME).
class StorageBucketConfig {
  const StorageBucketConfig({
    required this.name,
    required this.isPublic,
    required this.maxFileSize,
    required this.allowedMimeTypes,
  });

  final String name;
  final bool isPublic;
  final int maxFileSize;
  final List<String> allowedMimeTypes;

  static const Map<String, StorageBucketConfig> configs = {
    StorageBucket.photos: StorageBucketConfig(
      name: StorageBucket.photos,
      isPublic: true,
      maxFileSize: 5 * 1024 * 1024, // 5 MB
      allowedMimeTypes: [
        'image/jpeg',
        'image/png',
        'image/webp',
        'image/gif',
      ],
    ),
    StorageBucket.materi: StorageBucketConfig(
      name: StorageBucket.materi,
      isPublic: true,
      maxFileSize: 50 * 1024 * 1024, // 50 MB
      allowedMimeTypes: [
        'application/pdf',
        'application/vnd.ms-powerpoint',
        'application/vnd.openxmlformats-officedocument.presentationml.presentation',
        'application/msword',
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      ],
    ),
    StorageBucket.pengumuman: StorageBucketConfig(
      name: StorageBucket.pengumuman,
      isPublic: true,
      maxFileSize: 10 * 1024 * 1024, // 10 MB
      allowedMimeTypes: [
        'application/pdf',
        'image/jpeg',
        'image/png',
      ],
    ),
    StorageBucket.surat: StorageBucketConfig(
      name: StorageBucket.surat,
      isPublic: false,
      maxFileSize: 10 * 1024 * 1024, // 10 MB
      allowedMimeTypes: ['application/pdf'],
    ),
    StorageBucket.tugas: StorageBucketConfig(
      name: StorageBucket.tugas,
      isPublic: false,
      maxFileSize: 10 * 1024 * 1024, // 10 MB
      allowedMimeTypes: ['application/pdf', 'image/jpeg', 'image/png'],
    ),
    StorageBucket.ujian: StorageBucketConfig(
      name: StorageBucket.ujian,
      isPublic: false,
      maxFileSize: 10 * 1024 * 1024, // 10 MB
      allowedMimeTypes: ['application/pdf', 'image/jpeg', 'image/png'],
    ),
  };

  /// Cek apakah file dengan ukuran & MIME tertentu valid untuk bucket ini.
  bool isAllowed(int fileSize, String? mimeType) {
    if (fileSize > maxFileSize) return false;
    if (mimeType == null) return false;
    return allowedMimeTypes.contains(mimeType);
  }
}

/// Hasil upload file ke Supabase Storage.
class StorageUploadResult {
  const StorageUploadResult({
    required this.path,
    required this.publicUrl,
    required this.signedUrl,
    required this.bucket,
    required this.size,
  });

  /// Path object di dalam bucket (cth: 'santri/{santriId}/{timestamp}.jpg').
  final String path;

  /// URL publik (untuk public bucket). Untuk private bucket, ini tetap
  /// return URL tapi akses akan 403 — gunakan [signedUrl] untuk private.
  final String publicUrl;

  /// Signed URL dengan expiry 1 jam (untuk private bucket).
  /// Untuk public bucket, ini = publicUrl.
  final String signedUrl;

  /// Nama bucket tempat file di-upload.
  final String bucket;

  /// Ukuran file dalam bytes.
  final int size;
}

/// Service untuk upload/download/delete file ke Supabase Storage.
///
/// Cara pakai di Riverpod:
/// ```dart
/// final storage = ref.read(storageServiceProvider);
/// final result = await storage.upload(
///   bucket: StorageBucket.materi,
///   path: 'matematika/chapter1.pdf',
///   file: myFile,
///   mimeType: 'application/pdf',
/// );
/// ```
class StorageService {
  StorageService(this._client);

  final SupabaseClient _client;

  // --------------------------------------------------------------------------
  // Upload
  // --------------------------------------------------------------------------

  /// Upload file ke bucket. Otomatis dapat publicUrl + signedUrl.
  ///
  /// [path] = path object di dalam bucket (cth: 'santri/{id}/avatar.jpg').
  /// [fileBytes] = isi file (Uint8List).
  /// [mimeType] = MIME type file (cth: 'application/pdf').
  /// [upsert] = true untuk replace jika path sudah ada.
  ///
  /// Throws [StorageException] jika upload gagal atau file tidak valid.
  Future<StorageUploadResult> upload({
    required String bucket,
    required String path,
    required Uint8List fileBytes,
    required String mimeType,
    bool upsert = false,
  }) async {
    final config = StorageBucketConfig.configs[bucket];
    if (config == null) {
      throw StorageException(
          'Bucket "$bucket" tidak dikenal. Pakai StorageBucket.*');
    }
    if (!config.isAllowed(fileBytes.length, mimeType)) {
      throw StorageException(
          'File tidak valid. Max ${config.maxFileSize ~/ 1024 ~/ 1024}MB, '
          'MIME types: ${config.allowedMimeTypes.join(", ")}. '
          'Got: ${fileBytes.length} bytes, $mimeType.');
    }

    await _client.storage.from(bucket).uploadBinary(
          path,
          fileBytes,
          fileOptions: FileOptions(
            contentType: mimeType,
            upsert: upsert,
            cacheControl: '3600',
          ),
        );

    final publicUrl = _client.storage.from(bucket).getPublicUrl(path);
    final signedUrl = config.isPublic
        ? publicUrl
        : await createSignedUrl(bucket: bucket, path: path);

    return StorageUploadResult(
      path: path,
      publicUrl: publicUrl,
      signedUrl: signedUrl,
      bucket: bucket,
      size: fileBytes.length,
    );
  }

  // --------------------------------------------------------------------------
  // Download
  // --------------------------------------------------------------------------

  /// Download file sebagai bytes.
  Future<Uint8List> download({
    required String bucket,
    required String path,
  }) async {
    return await _client.storage.from(bucket).download(path);
  }

  // --------------------------------------------------------------------------
  // Signed URL (untuk private bucket)
  // --------------------------------------------------------------------------

  /// Buat signed URL untuk private bucket. Default expiry 1 jam.
  Future<String> createSignedUrl({
    required String bucket,
    required String path,
    Duration expiresAt = const Duration(hours: 1),
  }) async {
    final url = await _client.storage.from(bucket).createSignedUrl(
          path,
          expiresAt.inSeconds,
        );
    return url;
  }

  /// Buat multiple signed URLs sekaligus (lebih efisien kalau perlu banyak
  /// file dari bucket private).
  Future<Map<String, String>> createSignedUrls({
    required String bucket,
    required List<String> paths,
    Duration expiresAt = const Duration(hours: 1),
  }) async {
    if (paths.isEmpty) return {};
    final urls = await _client.storage.from(bucket).createSignedUrls(
          paths,
          expiresAt.inSeconds,
        );
    // Response: List<SignedUrl> with fields {path, signedUrl}
    final result = <String, String>{};
    for (final item in urls) {
      result[item.path] = item.signedUrl;
    }
    return result;
  }

  // --------------------------------------------------------------------------
  // Public URL (untuk public bucket — tanpa HTTP call)
  // --------------------------------------------------------------------------

  /// Dapatkan public URL untuk public bucket. Tidak butuh HTTP call.
  /// Untuk private bucket, URL ini tetap return tapi akses 403 — pakai
  /// [createSignedUrl] untuk private.
  String getPublicUrl({
    required String bucket,
    required String path,
  }) {
    return _client.storage.from(bucket).getPublicUrl(path);
  }

  // --------------------------------------------------------------------------
  // Delete
  // --------------------------------------------------------------------------

  /// Hapus satu file.
  Future<void> delete({
    required String bucket,
    required String path,
  }) async {
    await _client.storage.from(bucket).remove([path]);
  }

  /// Hapus multiple file sekaligus.
  Future<void> deleteMany({
    required String bucket,
    required List<String> paths,
  }) async {
    if (paths.isEmpty) return;
    await _client.storage.from(bucket).remove(paths);
  }

  // --------------------------------------------------------------------------
  // List objects dalam folder
  // --------------------------------------------------------------------------

  /// List objects di dalam bucket pada folder tertentu.
  /// Return list of {name, id, size, lastAccess, lastModified}.
  Future<List<StorageObjectInfo>> list({
    required String bucket,
    String? folder,
    int limit = 100,
    String sortByColumn = 'name',
    bool ascending = true,
  }) async {
    final res = await _client.storage.from(bucket).list(
          path: folder,
          searchOptions: SearchOptions(
            limit: limit,
            sortBy: SortBy(
              column: sortByColumn,
              order: ascending ? 'asc' : 'desc',
            ),
          ),
        );
    return res
        .map((f) => StorageObjectInfo(
              name: f.name,
              id: f.id,
              size: f.metadata?['size'] as int?,
              lastModified: f.updatedAt != null
                  ? DateTime.tryParse(f.updatedAt!)
                  : null,
            ))
        .toList();
  }

  // --------------------------------------------------------------------------
  // Helper: generate path berdasarkan entity
  // --------------------------------------------------------------------------

  /// Generate path untuk foto profil santri.
  /// Pattern: photos/santri/{santriId}/{timestamp}.{ext}
  static String photoPathSantri(String santriId, String fileExtension) {
    final ts = DateTime.now().millisecondsSinceEpoch;
    return 'santri/$santriId/$ts.$fileExtension';
  }

  /// Generate path untuk foto profil guru.
  static String photoPathGuru(String guruId, String fileExtension) {
    final ts = DateTime.now().millisecondsSinceEpoch;
    return 'guru/$guruId/$ts.$fileExtension';
  }

  /// Generate path untuk foto profil wali.
  static String photoPathWali(String waliId, String fileExtension) {
    final ts = DateTime.now().millisecondsSinceEpoch;
    return 'wali/$waliId/$ts.$fileExtension';
  }

  /// Generate path untuk file materi.
  /// Pattern: materi/{mapelId}/{originalFilename}
  static String materiPath(String mapelId, String originalFilename) {
    return '$mapelId/${_sanitizeFilename(originalFilename)}';
  }

  /// Generate path untuk lampiran pengumuman.
  /// Pattern: pengumuman/{pengumumanId}/{originalFilename}
  static String pengumumanPath(String pengumumanId, String originalFilename) {
    return '$pengumumanId/${_sanitizeFilename(originalFilename)}';
  }

  /// Generate path untuk PDF surat.
  /// Pattern: surat/{suratId}/{originalFilename}
  static String suratPath(String suratId, String originalFilename) {
    return '$suratId/${_sanitizeFilename(originalFilename)}';
  }

  /// Generate path untuk lampiran tugas.
  /// Pattern: tugas/{tugasId}/{originalFilename}
  static String tugasPath(String tugasId, String originalFilename) {
    return '$tugasId/${_sanitizeFilename(originalFilename)}';
  }

  /// Generate path untuk lampiran soal ujian.
  /// Pattern: ujian/{ujianId}/{soalId}/{originalFilename}
  static String ujianPath(
      String ujianId, String soalId, String originalFilename) {
    return '$ujianId/$soalId/${_sanitizeFilename(originalFilename)}';
  }

  /// Sanitasi nama file: lowercase, replace spasi & special chars.
  static String _sanitizeFilename(String filename) {
    final lower = filename.toLowerCase();
    final sanitized = lower.replaceAll(RegExp(r'[^a-z0-9._-]'), '_');
    return sanitized;
  }
}

/// Info satu object di Supabase Storage (hasil dari list()).
class StorageObjectInfo {
  const StorageObjectInfo({
    required this.name,
    this.id,
    this.size,
    this.lastModified,
  });

  final String name;
  final String? id;
  final int? size;
  final DateTime? lastModified;
}

/// Provider singleton StorageService.
/// Pakai dengan: `final storage = ref.read(storageServiceProvider);`
final storageServiceProvider = Provider<StorageService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return StorageService(client);
});

/// Provider untuk cek konfigurasi bucket (max size, allowed MIME).
/// Provider untuk list objects dalam bucket (auto-refresh via realtime tick).
