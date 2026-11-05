# SIM MADIN Storage Setup

Setup Supabase Storage sudah selesai untuk project SIM MADIN.

## Yang sudah dikonfigurasi

### 6 Storage Buckets (Supabase Singapore region)

| Bucket | Public | Max Size | Allowed MIME | RLS Read | RLS Write |
|---|---|---|---|---|---|
| `photos` | ✅ | 5 MB | jpeg/png/webp/gif | public (anon) | staff |
| `materi` | ✅ | 50 MB | pdf/ppt/pptx/doc/docx | public (anon) | staff |
| `pengumuman` | ✅ | 10 MB | pdf/jpeg/png | public (anon) | staff |
| `surat` | ❌ private | 10 MB | pdf | staff (signed URL) | admin-level |
| `tugas` | ❌ private | 10 MB | pdf/jpeg/png | authenticated (signed URL) | guru/admin |
| `ujian` | ❌ private | 10 MB | pdf/jpeg/png | authenticated (signed URL) | guru/admin |

### 24 RLS Policies (4 per bucket: SELECT/INSERT/UPDATE/DELETE)

Mengikuti helper functions existing (`is_staff()`, `is_admin_level()`,
`has_role('GURU')`, `current_wali_id()`, dst) — jadi RLS konsisten dengan
kebijakan tabel lain di project.

### Files

- `supabase/migrations/20240101000007_storage_buckets_and_policies.sql` —
  SQL migration (idempotent, ON CONFLICT DO UPDATE untuk buckets).
- `packages/api_client/lib/storage_service.dart` — `StorageService` class
  + `StorageBucket` constants + `StorageBucketConfig` + Riverpod providers
  (`storageServiceProvider`, `storageBucketConfigProvider`,
  `storageListProvider`).
- `packages/api_client/lib/api_client.dart` — sudah export storage_service.dart.

### Deploy script

- `scripts/deploy_storage_migration.py` — script Python untuk deploy
  migration via Supabase Management API (dipakai untuk initial deploy).

## Cara pakai di Flutter

### 1. Upload file

```dart
import 'package:api_client/api_client.dart';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> uploadMateri(WidgetRef ref, File pdfFile, String mapelId) async {
  final storage = ref.read(storageServiceProvider);
  final bytes = await pdfFile.readAsBytes();
  final path = StorageService.materiPath(mapelId, pdfFile.path.split('/').last);

  final result = await storage.upload(
    bucket: StorageBucket.materi,
    path: path,
    fileBytes: bytes,
    mimeType: 'application/pdf',
  );

  // result.publicUrl  → simpan ke kolom Materi.fileUrl
  // result.path        → simpan ke kolom Materi.filePath (untuk delete nanti)
  print('Public URL: ${result.publicUrl}');
  print('Size: ${result.size} bytes');
}
```

### 2. Upload foto profil santri

```dart
Future<String> uploadSantriPhoto(WidgetRef ref, String santriId, File photo) async {
  final storage = ref.read(storageServiceProvider);
  final bytes = await photo.readAsBytes();
  final ext = photo.path.split('.').last.toLowerCase(); // 'jpg' / 'png'

  final result = await storage.upload(
    bucket: StorageBucket.photos,
    path: StorageService.photoPathSantri(santriId, ext),
    fileBytes: bytes,
    mimeType: ext == 'png' ? 'image/png' : 'image/jpeg',
  );

  return result.publicUrl; // simpan ke Santri.photoUrl
}
```

### 3. Akses file private (surat/tugas/ujian) via signed URL

```dart
Future<String> getSuratUrl(WidgetRef ref, String suratFilePath) async {
  final storage = ref.read(storageServiceProvider);
  // Default expiry 1 jam; untuk surat sensitif bisa pendek (15 menit)
  return await storage.createSignedUrl(
    bucket: StorageBucket.surat,
    path: suratFilePath,
    expiresAt: const Duration(minutes: 15),
  );
}
```

### 4. Delete file

```dart
Future<void> deleteMateri(WidgetRef ref, String filePath) async {
  final storage = ref.read(storageServiceProvider);
  await storage.delete(bucket: StorageBucket.materi, path: filePath);
}
```

### 5. List files dalam folder

```dart
final listAsync = ref.watch(storageListProvider(
  (bucket: StorageBucket.materi, folder: 'matematika'),
));
listAsync.when(
  data: (files) => ListView(
    children: files.map((f) => ListTile(
      title: Text(f.name),
      subtitle: f.size != null ? Text('${(f.size! / 1024).toStringAsFixed(1)} KB') : null,
    )).toList(),
  ),
  loading: () => const CircularProgressIndicator(),
  error: (e, _) => Text('Error: $e'),
);
```

## Verification (already run)

```
✓ 25 SQL statements executed successfully (0 failed)
✓ 6 buckets verified in Supabase
✓ 24 storage policies verified (4 per bucket)

  - materi       PUBLIC  max=50MB  mimes=application/pdf, ...
  - pengumuman   PUBLIC  max=10MB  mimes=application/pdf, image/jpeg, image/png
  - photos       PUBLIC  max=5MB   mimes=image/jpeg, image/png, image/webp, image/gif
  - surat        PRIVATE max=10MB  mimes=application/pdf
  - tugas        PRIVATE max=10MB  mimes=application/pdf, image/jpeg, image/png
  - ujian        PRIVATE max=10MB  mimes=application/pdf, image/jpeg, image/png
```

## Next steps (optional, kalau butuh)

1. **Tambah kolom `filePath` di tabel yang butuh storage** (Materi, Surat,
   Tugas, Ujian, Santri.photoPath, Guru.photoPath, Wali.photoPath). Sudah
   ada `photoUrl` di Santri/Guru/Wali — bisa dipakai langsung.
2. **Update admin screen** (materi_admin, surat, tugas, ujian) untuk
   tambah tombol upload file.
3. **Update mobile_guru** untuk upload materi/tugas/ujian.
4. **Update mobile_wali** untuk menampilkan foto profil & materi.

Free tier Supabase Storage: **1 GB storage + 2 GB bandwidth/bulan** (tanpa
add debit card). Cukup untuk ~200 materi PDF + ~500 foto profil.
