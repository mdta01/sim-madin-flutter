// Payment — port dari Prisma `Payment`
// Dipakai di Pembayaran monitor screen + Dashboard keuangan chart

class PaymentMethod {
  static const tunai = 'TUNAI';
  static const transfer = 'TRANSFER';
  static const qris = 'QRIS';

  static String label(String? m) {
    switch (m) {
      case PaymentMethod.tunai:
        return 'Tunai';
      case PaymentMethod.transfer:
        return 'Transfer';
      case PaymentMethod.qris:
        return 'QRIS';
      default:
        return m ?? '-';
    }
  }
}

class PaymentStatus {
  static const pending = 'PENDING';
  static const verified = 'VERIFIED';
  static const rejected = 'REJECTED';
  static const all = <String>[pending, verified, rejected];
}

class PaymentModel {
  const PaymentModel({
    required this.id,
    required this.invoiceNo,
    this.tahunAjaranId,
    this.tagihanId,
    this.santriId,
    required this.amount,
    required this.paymentMethod,
    required this.paymentDate,
    this.status = PaymentStatus.verified,
    this.note,
    this.proofUrl,
    this.recordedById,
    this.kasId,
    required this.createdAt,
    required this.updatedAt,
    this.santriName,
    this.santriNis,
    this.tagihanCode,
  });

  final String id;
  final String invoiceNo; // "INV-2025-000001"
  final String? tahunAjaranId;
  final String? tagihanId;
  final String? santriId;
  final double amount;
  final String paymentMethod; // PaymentMethod.*
  final DateTime paymentDate;
  final String status;
  final String? note;
  final String? proofUrl;
  final String? recordedById;
  final String? kasId;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Denormalized untuk display
  final String? santriName;
  final String? santriNis;
  final String? tagihanCode;

  factory PaymentModel.fromJson(Map<String, dynamic> j) => PaymentModel(
        id: j['id'] as String,
        invoiceNo: j['invoiceNo'] as String,
        tahunAjaranId: j['tahunAjaranId'] as String?,
        tagihanId: j['tagihanId'] as String?,
        santriId: j['santriId'] as String?,
        amount: (j['amount'] as num).toDouble(),
        paymentMethod: j['paymentMethod'] as String,
        paymentDate: DateTime.parse(j['paymentDate'] as String),
        status: (j['status'] as String?) ?? PaymentStatus.verified,
        note: j['note'] as String?,
        proofUrl: j['proofUrl'] as String?,
        recordedById: j['recordedById'] as String?,
        kasId: j['kasId'] as String?,
        createdAt: DateTime.parse(j['createdAt'] as String),
        updatedAt: DateTime.parse(j['updatedAt'] as String),
        santriName: j['santriName'] as String?,
        santriNis: j['santriNis'] as String?,
        tagihanCode: j['tagihanCode'] as String?,
      );
}
