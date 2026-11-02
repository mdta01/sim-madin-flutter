// Tagihan + JenisTagihan — port dari Prisma
// Dipakai di Tagihan monitor screen

class TagihanStatus {
  static const belumBayar = 'BELUM_BAYAR';
  static const cicil = 'CICIL';
  static const lunas = 'LUNAS';
  static const all = <String>[belumBayar, cicil, lunas];
}

class JenisTagihanCategory {
  static const rutin = 'RUTIN';
  static const insidental = 'INSIDENTAL';
}

class JenisTagihanModel {
  const JenisTagihanModel({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    this.defaultAmount = 0,
    required this.category,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String code; // "SYAHRIYAH", "UANG_UJIAN", "SERAGAM"
  final String name; // "Syahriyah"
  final String? description;
  final int defaultAmount;
  final String category; // JenisTagihanCategory.*
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory JenisTagihanModel.fromJson(Map<String, dynamic> j) =>
      JenisTagihanModel(
        id: j['id'] as String,
        code: j['code'] as String,
        name: j['name'] as String,
        description: j['description'] as String?,
        defaultAmount: (j['defaultAmount'] as num?)?.toInt() ?? 0,
        category: j['category'] as String,
        isActive: (j['isActive'] as bool?) ?? true,
        createdAt: DateTime.parse(j['createdAt'] as String),
        updatedAt: DateTime.parse(j['updatedAt'] as String),
      );
}

class TagihanModel {
  const TagihanModel({
    required this.id,
    required this.tahunAjaranId,
    required this.santriId,
    this.kelasId,
    required this.jenisTagihanId,
    required this.amount,
    this.paidAmount = 0.0,
    this.description,
    this.dueDate,
    this.status = TagihanStatus.belumBayar,
    required this.createdAt,
    required this.updatedAt,
    this.santriName,
    this.santriNis,
    this.kelasName,
    this.jenisTagihanCode,
    this.jenisTagihanName,
  });

  final String id;
  final String tahunAjaranId;
  final String santriId;
  final String? kelasId;
  final String jenisTagihanId;
  final double amount;
  final double paidAmount;
  final String? description;
  final DateTime? dueDate;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Denormalized
  final String? santriName;
  final String? santriNis;
  final String? kelasName;
  final String? jenisTagihanCode;
  final String? jenisTagihanName;

  factory TagihanModel.fromJson(Map<String, dynamic> j) => TagihanModel(
        id: j['id'] as String,
        tahunAjaranId: j['tahunAjaranId'] as String,
        santriId: j['santriId'] as String,
        kelasId: j['kelasId'] as String?,
        jenisTagihanId: j['jenisTagihanId'] as String,
        amount: (j['amount'] as num).toDouble(),
        paidAmount: (j['paidAmount'] as num?)?.toDouble() ?? 0.0,
        description: j['description'] as String?,
        dueDate: j['dueDate'] is String
            ? DateTime.parse(j['dueDate'] as String)
            : null,
        status: (j['status'] as String?) ?? TagihanStatus.belumBayar,
        createdAt: DateTime.parse(j['createdAt'] as String),
        updatedAt: DateTime.parse(j['updatedAt'] as String),
        santriName: j['santriName'] as String?,
        santriNis: j['santriNis'] as String?,
        kelasName: j['kelasName'] as String?,
        jenisTagihanCode: j['jenisTagihanCode'] as String?,
        jenisTagihanName: j['jenisTagihanName'] as String?,
      );
}

/// Sisa tagihan yang belum dibayar.
double tagihanOutstanding(TagihanModel t) =>
    (t.amount - t.paidAmount).clamp(0.0, double.infinity).toDouble();
