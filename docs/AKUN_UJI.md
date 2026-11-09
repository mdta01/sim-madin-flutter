# Akun Uji & Alur Sinkronisasi Data

Dokumen ini menjelaskan **satu perintah** untuk mengisi seluruh database dengan
data demo yang saling terkait, serta kredensial untuk keempat aplikasi mobile
dan admin desktop.

> ⚠ **Ganti semua password dan PIN sebelum produksi.** Nilai di bawah adalah
> kredensial demo yang tertulis di repositori.

## Satu perintah untuk semuanya

Jalankan di **Supabase SQL Editor** (butuh hak pemilik database, bukan anon):

```sql
SELECT * FROM public.seed_all_demo();
```

### Kalau muncul "column ... does not exist"

Contoh: `ERROR: 42703: column "isPublished" does not exist`.

**Penyebab:** baseline memakai `CREATE TABLE IF NOT EXISTS`. Kalau tabelnya
**sudah ada** — misalnya database dibuat dari skema versi lama, atau baseline
dijalankan sebagian — perintah itu tidak melakukan apa pun, sehingga kolom baru
tidak pernah ditambahkan.

**Perbaikan:** jalankan migrasi rekonsiliasi, yang menambahkan setiap kolom
yang belum ada:

```
supabase/migrations/20240101000033_schema_reconcile.sql
```

Isinya 633 perintah `ALTER TABLE ... ADD COLUMN IF NOT EXISTS` untuk 54 tabel.
Aman: hanya menambah kolom, kolom yang sudah ada dilewati sepenuhnya.

Untuk kasus cepat (hanya kolom `isPublished`), pakai file kecil:

```
docs/sql/cek_dan_perbaiki_skema.sql   (5 KB)
```

Setelah itu jalankan ulang seed:

```sql
SELECT * FROM public.seed_all_demo();
```

> **Jangan** membuat ulang tabel untuk memperbaiki ini — data lama bisa hilang.

### Kalau akun sudah ter-seed tetapi login tetap gagal

Ini kasus paling sering: baris `User` dan peran sudah ada, tetapi **akun login
di `auth.users` tidak terbentuk**, sehingga Supabase Auth menjawab
`Invalid login credentials`. Perbaiki dengan:

```sql
-- 1. lihat kondisi tiap akun
SELECT * FROM public.demo_account_status();

-- 2. perbaiki semuanya sekaligus
SELECT * FROM public.repair_demo_logins();

-- 3. pastikan kolom siap_login = true untuk semua baris
SELECT * FROM public.demo_account_status();
```

Bila masih gagal, telusuri satu akun langkah demi langkah:

```sql
SELECT * FROM public.diagnose_login('mdta@madrasah.com');
```

**Penyebab umum yang ditunjukkan fungsi di atas:**

| Langkah yang `ok = false` | Artinya |
|---|---|
| `1_auth_users` | akun login belum dibuat → jalankan `repair_demo_logins()` |
| `2_password_bcrypt` | password tersimpan bukan bcrypt → jalankan ulang repair |
| `3_email_confirmed` | email belum dikonfirmasi → matikan *Confirm email* di Supabase, atau repair |
| `5_auth_identities` | GoTrue tidak bisa menemukan user → repair |
| `7_peran` | akun bisa login tapi semua layar kosong |

> **Catatan:** Supabase Auth bisa menolak login walau data sudah benar bila
> **Confirm email** aktif. Matikan di *Authentication → Providers → Email*.

Fungsi ini menjalankan seluruh rantai dalam urutan yang benar:

| Langkah | Isi |
|---|---|
| 1 | Akun staf: admin, kepala, bendahara, 2 guru (dengan peran & profil) |
| 2 | Tahun ajaran 2025/2026, 2 semester, 6 kelas, 6 mata pelajaran |
| 3 | Jadwal tiap guru ke kelas & mapel |
| 4 | 2 wali + 2 santri, sudah saling terhubung |
| 5 | Absensi 14 hari, nilai per mapel, tagihan SPP |
| 6 | Materi, tugas, pertemuan |
| 7 | Kas, transaksi kas, honor guru |
| 8 | Pengumuman + notifikasi untuk wali |

Aman dijalankan berulang — setiap langkah memeriksa data yang sudah ada.

## Kredensial

### Admin — bisa dipakai dari HP atau laptop

Admin tersedia dalam **dua bentuk**, keduanya memakai akun yang sama:

| Bentuk | Cara pakai |
|---|---|
| **APK `admin_desktop.apk`** | unduh dari halaman rilis, pasang di HP seperti aplikasi biasa |
| **Web (browser)** | buka URL hosting Flutter web, login di browser HP/laptop |

APK sengaja disediakan karena tidak semua pengelola madrasah punya laptop.
Di layar HP, menu samping otomatis berubah menjadi tombol ☰ (drawer).

### Akun admin

| Email | Password | Peran |
|---|---|---|
| `mdta@madrasah.com` | `admin@mdta01` | `SUPER_ADMIN` + `ADMIN` |

### Staf (aplikasi mobile kepala / bendahara / guru)

Didaftarkan oleh admin, login memakai **email + password**.

| Email | Password | Peran | Aplikasi |
|---|---|---|---|
| `kepala@madrasah.com` | `kepala123` | `KEPALA` | `mobile_kepala` |
| `bendahara@madrasah.com` | `bendahara123` | `BENDAHARA` | `mobile_bendahara` |
| `guru@madrasah.com` | `guru123` | `GURU` — Ustadz Ahmad Fauzi | `mobile_guru` |
| `guru2@madrasah.com` | `guru123` | `GURU` — Ustadzah Siti Aminah | `mobile_guru` |

### Wali (aplikasi `mobile_wali`)

Login memakai **nomor WhatsApp + PIN 6 digit** — bukan email.

| Nomor WhatsApp | PIN | Wali | Anak |
|---|---|---|---|
| `081234567801` | `123456` | Bapak Abdullah | Muhammad Fauzan (NIS 2025001) |
| `081234567802` | `123456` | Bapak Hasan | Aisyah Nur Fadhilah (NIS 2025002) |

Nomor boleh diketik dalam format apa pun: `0812…`, `62812…`, atau `+62812…`.

---

## Alur produksi: admin sebagai pusat data

### 1. Admin menambah akun staf

Di **admin desktop → Users → "Tambah Akun Staf"**:

1. Isi email, password, nama, nomor WhatsApp.
2. Pilih peran (Kepala / Bendahara / Guru / Admin).
3. Bila memilih **Guru**, isi NIP dan bidang (opsional) — profil `Guru`
   otomatis dibuatkan.
4. Serahkan email & password ke staf yang bersangkutan.

Staf tersebut langsung bisa login di aplikasi mobile sesuai perannya.

> **Catatan penting untuk guru:** akun guru butuh **profil `Guru`** dan
> **jadwal**, bukan hanya peran. Tanpa jadwal, `is_guru_of_kelas()` selalu
> `false` sehingga absensi dan nilai tidak bisa diisi. Tambahkan jadwal di
> **admin desktop → Jadwal**.

### 2. Admin menambah santri & wali

Admin mendaftarkan santri beserta data wali dan **nomor WhatsApp**-nya. Nomor
inilah yang nanti dipakai wali untuk aktivasi dan login.

### 3. Wali melakukan aktivasi pertama

1. Buka `mobile_wali` → **Aktivasi Akun**.
2. Masukkan nomor WhatsApp yang didaftarkan admin.
3. Aplikasi memeriksa nomor tersebut **ada di data admin**, lalu menampilkan
   **nama wali + nama anak** sebagai konfirmasi.
4. Buat PIN 6 digit, lalu ketik ulang sebagai **konfirmasi PIN**.
5. PIN tersimpan (bcrypt) pada baris wali yang terhubung dengan nomor itu.
6. Login memakai nomor + PIN.

Aturan PIN yang ditolak server:

- bukan 6 digit angka
- konfirmasi tidak sama
- terlalu mudah ditebak (`000000`, `123456`, `112233`, `123123`, dst.)
- wali **sudah** punya PIN → harus lewat jalur Lupa PIN, supaya orang lain
  yang tahu nomornya tidak bisa menimpa PIN

### 4. Wali lupa PIN

**Login → Lupa PIN** → OTP dikirim via WhatsApp → verifikasi OTP → buat PIN
baru. OTP berlaku 5 menit, maksimal 5 permintaan per jam, dan 5 kali salah PIN
mengunci akun 15 menit.

> Agar OTP terlihat saat menguji tanpa gateway WhatsApp, nyalakan
> `SystemSetting` dengan key `OTP_DEBUG` = `true`. **Matikan di produksi.**

### 5. Admin menghapus akun

Di **admin desktop → Users → ikon hapus**:

- Kredensial login (`auth.users`) **dihapus** → akun tidak bisa lagi masuk ke
  aplikasi mobile.
- Peran dinonaktifkan, PIN wali dicabut, profil guru dinonaktifkan.
- Data historis (absensi, nilai, pembayaran) **tetap utuh**.
- Opsi "hapus permanen" menghapus baris `User`; otomatis ditolak bila akun
  punya jejak historis.

Akun yang terlanjur terhapus bisa diaktifkan kembali:

```sql
SELECT * FROM public.admin_restore_account('guru@madrasah.com');
```

---

## Memeriksa kondisi akun

```sql
-- Ringkasan semua akun: peran, profil guru, profil wali, jumlah anak
SELECT * FROM public.access_audit();

-- Telusuri satu akun, lihat langkah mana yang putus
SELECT * FROM public.diagnose_account_access('guru@madrasah.com');

-- Khusus wali: apakah PIN dan tautan santri sudah benar?
SELECT * FROM public.check_wali_link((SELECT id FROM "Wali" LIMIT 1));

-- Status aktivasi semua wali
SELECT * FROM public.wali_activation_report();
```

Kolom `roles` bernilai `— TANPA PERAN —` berarti akun itu akan melihat semua
data kosong, karena RLS menyaring seluruh baris tanpa pesan error.

## Pesan galat login wali dan penyebabnya

| Pesan | Penyebab |
|---|---|
| `Nomor ini belum terdaftar` | admin belum mendaftarkan nomor tersebut |
| `PIN sudah pernah dibuat` | jalankan alur Lupa PIN, bukan aktivasi |
| `PIN salah. Sisa percobaan: N` | 5 kali salah → kunci 15 menit |
| `Akun belum aktif (status: PENDING)` | status wali belum `ACTIVE` |
| Login berhasil tapi dashboard kosong | tidak ada `SantriWali` dengan `canAccess = true` |

## Fungsi SQL yang tersedia

| Fungsi | Kegunaan |
|---|---|
| `seed_all_demo()` | isi seluruh data demo (satu perintah) |
| `seed_demo_data()` | hanya data akademik & keuangan |
| `admin_create_staff_account()` | buat akun staf + peran + profil guru |
| `admin_delete_account()` | hapus akun & cabut akses login |
| `admin_restore_account()` | aktifkan kembali akun |
| `wali_check_registration()` | cek nomor terdaftar (tanpa efek samping) |
| `wali_activate()` | aktivasi pertama: set PIN + konfirmasi |
| `wali_login()` | login wali (nomor + PIN) |
| `wali_request_otp()` / `wali_verify_otp()` / `wali_reset_pin()` | lupa PIN |
| `access_audit()` / `diagnose_account_access()` | diagnostik |
| `create_wali_test_account()` | buat akun wali uji cepat |
