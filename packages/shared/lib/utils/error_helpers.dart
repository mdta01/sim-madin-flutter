// ============================================================================
// SIM MADIN — Error Helpers (shared across all apps)
// ============================================================================
// Konversi raw Supabase/Dart exception ke pesan Indonesia yang user-friendly.
// ============================================================================

/// Parse exception → user-friendly Indonesian message.
String friendlyError(dynamic e) {
  final msg = e.toString();

  // Auth errors
  if (msg.contains('Invalid login credentials')) {
    return 'Email atau password salah. Periksa kembali.';
  }
  if (msg.contains('Email not confirmed')) {
    return 'Email belum dikonfirmasi. Hubungi admin untuk aktivasi.';
  }
  if (msg.contains('AuthRetryableFetchException') ||
      msg.contains('SocketException') ||
      msg.contains('Failed host lookup') ||
      msg.contains('errno = 7')) {
    return 'Tidak bisa terhubung ke server. Periksa koneksi internet Anda.';
  }
  if (msg.contains('AuthApiException') && msg.contains('rate limit')) {
    return 'Terlalu banyak percobaan login. Tunggu beberapa menit.';
  }

  // RLS / permission errors
  if (msg.contains('42501') || msg.contains('permission denied')) {
    return 'Akses ditolak. Akun Anda tidak memiliki izin untuk data ini.';
  }
  if (msg.contains('jwt expired')) {
    return 'Sesi telah berakhir. Silakan login kembali.';
  }

  // Network errors
  if (msg.contains('TimeoutException') || msg.contains('timeout')) {
    return 'Koneksi timeout. Periksa internet Anda dan coba lagi.';
  }
  if (msg.contains('HandshakeException') || msg.contains('CERTIFICATE')) {
    return 'Koneksi tidak aman. Hubungi admin.';
  }

  // Database errors
  if (msg.contains('23505') || msg.contains('unique constraint')) {
    return 'Data sudah ada (duplikat). Gunakan nilai lain.';
  }
  if (msg.contains('23503') || msg.contains('foreign key')) {
    return 'Data ini masih terhubung dengan data lain. Hapus data terkait dulu.';
  }
  if (msg.contains('23502') || msg.contains('not-null constraint')) {
    return 'Ada field wajib yang belum diisi.';
  }

  // Default: show short message without stack trace
  final shortMsg = msg.replaceAll(RegExp(r'^Exception:\s*'), '').split('\n').first;
  if (shortMsg.length > 100) {
    return '${shortMsg.substring(0, 97)}...';
  }
  return shortMsg.isEmpty ? 'Terjadi kesalahan. Coba lagi.' : shortMsg;
}
