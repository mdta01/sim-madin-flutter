// ============================================================================
// SIM MADIN — Supabase RPC Helpers
// ============================================================================
// Wrapper untuk memanggil Postgres RPC functions yang didefinisikan di
// supabase/migrations/04_rpc_functions_and_triggers.sql.
//
// Dipakai oleh mobile_bendahara (verify/reject payment, create transaksi kas,
// update honor status) dan mobile_wali (submit ujian).
// ============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_client/supabase_client.dart';

/// Result dari RPC verify_payment.
class VerifyPaymentResult {
  const VerifyPaymentResult({
    required this.success,
    required this.message,
    this.newKasBalance = 0,
    this.newTagihanPaid = 0,
    this.newTagihanStatus,
  });

  final bool success;
  final String message;
  final double newKasBalance;
  final double newTagihanPaid;
  final String? newTagihanStatus;
}

/// Result dari RPC submit_ujian.
class SubmitUjianResult {
  const SubmitUjianResult({
    required this.success,
    required this.message,
    this.score = 0,
  });

  final bool success;
  final String message;
  final double score;
}

/// Helper untuk memanggil Postgres RPC functions.
/// Semua method return typed result objects (bukan raw Map).
class SupabaseRpc {
  SupabaseRpc._();

  /// Verify payment (PENDING → VERIFIED).
  /// Atomic: update Payment status + Kas balance + Tagihan paidAmount/status + insert TransaksiKas.
  ///
  /// Dipanggil oleh bendahara saat verify pembayaran.
  /// Gantikan client-side verifyPembayaran() yang non-atomic (race condition).
  static Future<VerifyPaymentResult> verifyPayment(
    WidgetRef ref, {
    required String paymentId,
    String? kasId,
  }) async {
    final client = ref.read(supabaseClientProvider);
    try {
      final res = await client.rpc('verify_payment', params: {
        'p_payment_id': paymentId,
        'p_kas_id': kasId,
      });

      if (res == null) {
        return const VerifyPaymentResult(
            success: false, message: 'Response null dari server');
      }

      final row = res as Map<String, dynamic>;
      return VerifyPaymentResult(
        success: row['success'] == true,
        message: row['message'] as String? ?? 'Unknown',
        newKasBalance:
            (row['new_kas_balance'] as num?)?.toDouble() ?? 0,
        newTagihanPaid:
            (row['new_tagihan_paid'] as num?)?.toDouble() ?? 0,
        newTagihanStatus: row['new_tagihan_status'] as String?,
      );
    } catch (e) {
      return VerifyPaymentResult(
          success: false, message: e.toString());
    }
  }

  /// Reject payment (PENDING → REJECTED).
  /// Safe reject — tidak update Kas/Tagihan.
  static Future<VerifyPaymentResult> rejectPayment(
    WidgetRef ref, {
    required String paymentId,
    String? reason,
  }) async {
    final client = ref.read(supabaseClientProvider);
    try {
      final res = await client.rpc('reject_payment', params: {
        'p_payment_id': paymentId,
        'p_reason': reason,
      });

      if (res == null) {
        return const VerifyPaymentResult(
            success: false, message: 'Response null dari server');
      }

      final row = res as Map<String, dynamic>;
      return VerifyPaymentResult(
        success: row['success'] == true,
        message: row['message'] as String? ?? 'Unknown',
      );
    } catch (e) {
      return VerifyPaymentResult(
          success: false, message: e.toString());
    }
  }

  /// Create transaksi kas (atomic: insert + update Kas balance).
  /// Gantikan client-side createTransaksiKas() yang non-atomic (race condition).
  static Future<({bool success, String transaksiId, double newKasBalance})>
      createTransaksiKas(
    WidgetRef ref, {
    required String kasId,
    required String type, // PEMASUKAN | PENGELUARAN
    required String category,
    required double amount,
    required String description,
    String? reference,
    String? recordedBy,
  }) async {
    final client = ref.read(supabaseClientProvider);
    try {
      final res = await client.rpc('create_transaksi_kas', params: {
        'p_kas_id': kasId,
        'p_type': type,
        'p_category': category,
        'p_amount': amount,
        'p_description': description,
        'p_reference': reference,
        'p_recorded_by': recordedBy,
      });

      if (res == null) {
        return (success: false, transaksiId: '', newKasBalance: 0.0);
      }

      final row = (res as List).first as Map<String, dynamic>;
      return (
        success: row['success'] == true,
        transaksiId: row['transaksi_id'] as String? ?? '',
        newKasBalance:
            (row['new_kas_balance'] as num?)?.toDouble() ?? 0.0,
      );
    } catch (e) {
      return (success: false, transaksiId: '', newKasBalance: 0.0);
    }
  }

  /// Update honor guru status (atomic: update HonorGuru + TransaksiKas + Kas).
  /// Gantikan client-side updateHonorGuruStatus() yang non-atomic.
  static Future<({bool success, String message, double newKasBalance})>
      updateHonorGuruStatus(
    WidgetRef ref, {
    required String honorId,
    required String newStatus, // DISETUJUI | DIBAYARKAN
    String? kasId,
  }) async {
    final client = ref.read(supabaseClientProvider);
    try {
      final res = await client.rpc('update_honor_guru_status', params: {
        'p_honor_id': honorId,
        'p_new_status': newStatus,
        'p_kas_id': kasId,
      });

      if (res == null) {
        return (success: false, message: 'Response null', newKasBalance: 0.0);
      }

      final row = (res as List).first as Map<String, dynamic>;
      return (
        success: row['success'] == true,
        message: row['message'] as String? ?? 'Unknown',
        newKasBalance:
            (row['new_kas_balance'] as num?)?.toDouble() ?? 0.0,
      );
    } catch (e) {
      return (success: false, message: e.toString(), newKasBalance: 0.0);
    }
  }

  /// Submit ujian (atomic: insert jawaban + auto-correct PG + compute score +
  /// update sesi + upsert UjianNilai).
  /// Gantikan client-side submitUjianJawaban() yang non-atomic.
  ///
  /// [answers] format: List<Map<String, dynamic>> dengan keys:
  ///   - 'ujianSoalId': String
  ///   - 'answer': String
  static Future<SubmitUjianResult> submitUjian(
    WidgetRef ref, {
    required String sesiId,
    required List<Map<String, dynamic>> answers,
  }) async {
    final client = ref.read(supabaseClientProvider);
    try {
      // Convert answers ke JSONB format yang diharapkan RPC.
      final jsonAnswers = answers.map((a) => {
            'ujianSoalId': a['ujianSoalId'],
            'answer': a['answer'],
          }).toList();

      final res = await client.rpc('submit_ujian', params: {
        'p_sesi_id': sesiId,
        'p_answers': jsonAnswers,
      });

      if (res == null) {
        return const SubmitUjianResult(
            success: false, message: 'Response null dari server');
      }

      final row = (res as List).first as Map<String, dynamic>;
      return SubmitUjianResult(
        success: row['success'] == true,
        message: row['message'] as String? ?? 'Unknown',
        score: (row['final_score'] as num?)?.toDouble() ?? 0,
      );
    } catch (e) {
      return SubmitUjianResult(
          success: false, message: e.toString());
    }
  }
}
