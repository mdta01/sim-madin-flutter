// ============================================================================
// SIM MADIN — Utility Functions
// ============================================================================
// Sumber: packages/shared/src/utils.ts di proyek lama.
// ============================================================================

import 'package:intl/intl.dart';

// ============================================================================
// PENTING soal locale
// ============================================================================
// `DateFormat(pattern, 'id_ID')` dan `NumberFormat.currency(locale: 'id_ID')`
// MELEMPAR LocaleDataException bila data locale belum diinisialisasi
// ("Locale data has not been initialized, call initializeDateFormatting").
// Paket intl tidak menyertakan data locale secara default.
//
// Aplikasi ini memakai formatDate/formatDateTime/formatRupiah di hampir semua
// layar, tetapi initializeDateFormatting() TIDAK PERNAH dipanggil. Akibatnya
// setiap layar yang menampilkan tanggal melempar exception saat build, dan
// Flutter (mode release) menggantinya dengan kotak abu-abu kosong — persis
// gejala "semua fitur kosong".
//
// Perbaikan berlapis:
//   1. initializeDateFormatting('id_ID') dipanggil di main() tiap aplikasi.
//   2. Helper _localeSafe() di bawah otomatis jatuh ke locale default bila
//      data locale belum siap, sehingga formatting TIDAK PERNAH melempar.
// ============================================================================

/// True setelah initializeDateFormatting('id_ID') berhasil.
bool _idLocaleReady = false;

/// Tandai bahwa data locale Indonesia sudah tersedia.
void markIndonesianLocaleReady() => _idLocaleReady = true;

/// Jalankan [build] dengan locale Indonesia, dengan fallback aman.
///
/// Tidak pernah melempar LocaleDataException: bila 'id_ID' belum siap,
/// memakai locale aktif intl, lalu terakhir 'en_US'.
T _localeSafe<T>(T Function(String locale) build) {
  const id = 'id_ID';
  if (_idLocaleReady) {
    try {
      return build(id);
    } catch (_) {
      // lanjut ke fallback
    }
  }
  try {
    return build(id);
  } catch (_) {
    try {
      return build(Intl.getCurrentLocale());
    } catch (_) {
      return build('en_US');
    }
  }
}

/// Format angka ke Rupiah (Rp 1.234.567).
String formatRupiah(num? amount, {bool withSymbol = true}) {
  if (amount == null) return withSymbol ? 'Rp 0' : '0';
  final formatted = _localeSafe(
    (locale) => NumberFormat.currency(
      locale: locale,
      symbol: withSymbol ? 'Rp ' : '',
      decimalDigits: 0,
    ).format(amount),
  );
  // NumberFormat menyisipkan non-breaking space setelah "Rp".
  return formatted.replaceAll('\u00a0', ' ');
}

/// Parse string Rupiah kembali ke num.
num? parseRupiah(String? text) {
  if (text == null || text.isEmpty) return null;
  final cleaned = text.replaceAll(RegExp(r'[^\d]'), '');
  if (cleaned.isEmpty) return null;
  return num.tryParse(cleaned);
}

/// Format tanggal Indonesia (1 Januari 2026).
String formatDate(DateTime? date, {String pattern = 'd MMMM yyyy'}) {
  if (date == null) return '-';
  return _localeSafe((locale) => DateFormat(pattern, locale).format(date));
}

/// Format tanggal pendek (01/01/2026).
String formatDateShort(DateTime? date) {
  if (date == null) return '-';
  return _localeSafe(
      (locale) => DateFormat('dd/MM/yyyy', locale).format(date));
}

/// Format waktu (14:30 WIB).
String formatTime(DateTime? date) {
  if (date == null) return '-';
  return _localeSafe(
      (locale) => DateFormat('HH:mm', locale).format(date));
}

/// Format datetime lengkap (1 Jan 2026, 14:30).
String formatDateTime(DateTime? date) {
  if (date == null) return '-';
  return _localeSafe(
      (locale) => DateFormat('d MMM yyyy, HH:mm', locale).format(date));
}

/// Format relative time (5 menit lalu, 2 jam lalu, kemarin).
String formatRelativeTime(DateTime? date) {
  if (date == null) return '-';
  final now = DateTime.now();
  final diff = now.difference(date);

  if (diff.inSeconds < 60) return 'baru saja';
  if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
  if (diff.inHours < 24) return '${diff.inHours} jam lalu';
  if (diff.inDays == 1) return 'kemarin';
  if (diff.inDays < 7) return '${diff.inDays} hari lalu';
  if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} minggu lalu';
  if (diff.inDays < 365) return '${(diff.inDays / 30).floor()} bulan lalu';
  return '${(diff.inDays / 365).floor()} tahun lalu';
}

/// Normalisasi nomor WhatsApp.
/// Input diterima: 08xxx, 628xxx, +628xxx, 8xxx.
/// Output: 628xxx (tanpa +, tanpa spasi, tanpa -).
String? normalizeWhatsApp(String? input) {
  if (input == null) return null;
  var trimmed = input.replaceAll(RegExp(r'[\s\-()]'), '').trim();
  if (trimmed.startsWith('+62')) {
    trimmed = trimmed.substring(1);
  } else if (trimmed.startsWith('08')) {
    trimmed = '628${trimmed.substring(2)}';
  } else if (trimmed.startsWith('8')) {
    trimmed = '62$trimmed';
  } else if (!trimmed.startsWith('62')) {
    return null;
  }
  if (!RegExp(r'^\d{10,15}$').hasMatch(trimmed)) return null;
  return trimmed;
}

/// Format nomor WhatsApp untuk display (08xxx).
String formatPhoneDisplay(String? phone) {
  if (phone == null || phone.isEmpty) return '-';
  if (phone.startsWith('62')) {
    return '0${phone.substring(2)}';
  }
  return phone;
}

/// Inisial nama dari 2 kata pertama (mis. "Bapak Ali" → "BA").
String getInitials(String? name) {
  if (name == null || name.isEmpty) return '?';
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.length == 1) return parts[0][0].toUpperCase();
  return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
}

/// Pluralize sederhana: '1 santri', '5 santri'.
String pluralize(int count, String singular, [String? plural]) {
  if (count == 1) return '$count $singular';
  return '$count ${plural ?? singular}';
}

/// Generate random OTP 6 digit.
String generateOtp() {
  final now = DateTime.now().millisecondsSinceEpoch;
  return (now % 1000000).toString().padLeft(6, '0');
}

/// Validasi format email.
bool isValidEmail(String? email) {
  if (email == null || email.isEmpty) return false;
  return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
}

/// Validasi PIN 6 digit.
bool isValidPin(String? pin) {
  if (pin == null) return false;
  if (!RegExp(r'^\d{6}$').hasMatch(pin)) return false;
  return true;
}

/// Hitung persentase kehadiran.
double hitungPersentaseHadir({required int hadir, required int total}) {
  if (total == 0) return 0;
  return (hadir / total) * 100;
}

/// Hitung rata-rata nilai list.
double hitungRataRata(List<num> nilai) {
  if (nilai.isEmpty) return 0;
  final sum = nilai.reduce((a, b) => a + b);
  return sum / nilai.length;
}

/// Fisher-Yates shuffle (untuk ujian: acak urutan soal & option).
List<T> fisherYatesShuffle<T>(List<T> list, {int? seed}) {
  final rng = seed == null ? DateTime.now().millisecondsSinceEpoch : seed;
  final random = _SeededRandom(rng);
  final result = List<T>.from(list);
  for (var i = result.length - 1; i > 0; i--) {
    final j = random.nextInt(i + 1);
    final tmp = result[i];
    result[i] = result[j];
    result[j] = tmp;
  }
  return result;
}

class _SeededRandom {
  _SeededRandom(this._seed);
  int _seed;

  int nextInt(int max) {
    _seed = (_seed * 1103515245 + 12345) & 0x7FFFFFFF;
    return _seed % max;
  }
}

/// Trim dan collapse whitespace.
String collapseWhitespace(String text) {
  return text.replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// Capitalize first letter.
String capitalize(String text) {
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1);
}

/// Snake_case ke Title Case.
String snakeToTitle(String snake) {
  return snake
      .split('_')
      .map((w) => w.isEmpty ? w : capitalize(w))
      .join(' ');
}
