// Kas + TransaksiKas — port dari Prisma
// Dipakai di Laporan Keuangan monitor + Dashboard keuangan chart

class KasType {
  static const tunai = 'TUNAI';
  static const bank = 'BANK';
  static const eWallet = 'E_WALLET';

  static String label(String? t) {
    switch (t) {
      case KasType.tunai:
        return 'Tunai';
      case KasType.bank:
        return 'Bank';
      case KasType.eWallet:
        return 'E-Wallet';
      default:
        return t ?? '-';
    }
  }
}

class KasModel {
  const KasModel({
    required this.id,
    required this.code,
    required this.name,
    this.accountNumber,
    this.bankName,
    required this.type,
    this.balance = 0.0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String code; // "KAS_TUNAI", "BANK_BRI"
  final String name; // "Kas Tunai", "Bank BRI"
  final String? accountNumber;
  final String? bankName;
  final String type; // KasType.*
  final double balance;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory KasModel.fromJson(Map<String, dynamic> j) => KasModel(
        id: j['id'] as String,
        code: j['code'] as String,
        name: j['name'] as String,
        accountNumber: j['accountNumber'] as String?,
        bankName: j['bankName'] as String?,
        type: j['type'] as String,
        balance: (j['balance'] as num?)?.toDouble() ?? 0.0,
        isActive: (j['isActive'] as bool?) ?? true,
        createdAt: DateTime.parse(j['createdAt'] as String),
        updatedAt: DateTime.parse(j['updatedAt'] as String),
      );
}

class TransaksiKasType {
  static const pemasukan = 'PEMASUKAN';
  static const pengeluaran = 'PENGELUARAN';

  static String label(String? t) =>
      t == TransaksiKasType.pemasukan ? 'Pemasukan' : 'Pengeluaran';
}

class TransaksiKasCategory {
  static const pembayaranSantri = 'PEMBAYARAN_SANTRI';
  static const honorGuru = 'HONOR_GURU';
  static const operasional = 'OPERASIONAL';
  static const kegiatan = 'KEGIATAN';
  static const lainLain = 'LAIN_LAIN';

  static String label(String? c) {
    switch (c) {
      case TransaksiKasCategory.pembayaranSantri:
        return 'Pembayaran Santri';
      case TransaksiKasCategory.honorGuru:
        return 'Honor Guru';
      case TransaksiKasCategory.operasional:
        return 'Operasional';
      case TransaksiKasCategory.kegiatan:
        return 'Kegiatan';
      case TransaksiKasCategory.lainLain:
        return 'Lain-lain';
      default:
        return c ?? '-';
    }
  }
}

class TransaksiKasModel {
  const TransaksiKasModel({
    required this.id,
    required this.kasId,
    this.tahunAjaranId,
    required this.type,
    required this.category,
    required this.amount,
    required this.description,
    this.reference,
    this.paymentId,
    this.honorGuruId,
    required this.transaksiDate,
    this.recordedById,
    required this.createdAt,
    required this.updatedAt,
    this.kasName,
    this.kasCode,
  });

  final String id;
  final String kasId;
  final String? tahunAjaranId;
  final String type; // TransaksiKasType.*
  final String category; // TransaksiKasCategory.*
  final double amount;
  final String description;
  final String? reference;
  final String? paymentId;
  final String? honorGuruId;
  final DateTime transaksiDate;
  final String? recordedById;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Denormalized
  final String? kasName;
  final String? kasCode;

  factory TransaksiKasModel.fromJson(Map<String, dynamic> j) =>
      TransaksiKasModel(
        id: j['id'] as String,
        kasId: j['kasId'] as String,
        tahunAjaranId: j['tahunAjaranId'] as String?,
        type: j['type'] as String,
        category: j['category'] as String,
        amount: (j['amount'] as num).toDouble(),
        description: j['description'] as String,
        reference: j['reference'] as String?,
        paymentId: j['paymentId'] as String?,
        honorGuruId: j['honorGuruId'] as String?,
        transaksiDate: DateTime.parse(j['transaksiDate'] as String),
        recordedById: j['recordedById'] as String?,
        createdAt: DateTime.parse(j['createdAt'] as String),
        updatedAt: DateTime.parse(j['updatedAt'] as String),
        kasName: j['kasName'] as String?,
        kasCode: j['kasCode'] as String?,
      );
}
