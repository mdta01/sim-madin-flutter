// HonorGuru — port dari Prisma
// Dipakai di Honor Guru monitor screen

class HonorGuruStatus {
  static const draft = 'DRAFT';
  static const disetujui = 'DISETUJUI';
  static const dibayarkan = 'DIBAYARKAN';
  static const all = <String>[draft, disetujui, dibayarkan];

  static String label(String? s) {
    switch (s) {
      case HonorGuruStatus.draft:
        return 'Draft';
      case HonorGuruStatus.disetujui:
        return 'Disetujui';
      case HonorGuruStatus.dibayarkan:
        return 'Dibayarkan';
      default:
        return s ?? '-';
    }
  }
}

class HonorGuruModel {
  const HonorGuruModel({
    required this.id,
    required this.tahunAjaranId,
    required this.semesterId,
    required this.guruId,
    required this.periode,
    required this.periodeLabel,
    this.honorMengajar = 0.0,
    this.insentif = 0.0,
    this.tunjangan = 0.0,
    this.potongan = 0.0,
    this.totalHonor = 0.0,
    this.status = HonorGuruStatus.draft,
    this.paidAt,
    this.kasId,
    this.catatan,
    required this.createdAt,
    required this.updatedAt,
    this.guruName,
    this.guruSpecialization,
  });

  final String id;
  final String tahunAjaranId;
  final String semesterId;
  final String guruId;
  final String periode; // "2025-10" / "GANJIL_2025"
  final String periodeLabel; // "Oktober 2025" / "Semester Ganjil 2025/2026"

  // Komponen honor
  final double honorMengajar;
  final double insentif;
  final double tunjangan;
  final double potongan;
  final double totalHonor;

  // Status
  final String status;
  final DateTime? paidAt;
  final String? kasId;
  final String? catatan;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Denormalized untuk display
  final String? guruName;
  final String? guruSpecialization;

  factory HonorGuruModel.fromJson(Map<String, dynamic> j) => HonorGuruModel(
        id: j['id'] as String,
        tahunAjaranId: j['tahunAjaranId'] as String,
        semesterId: j['semesterId'] as String,
        guruId: j['guruId'] as String,
        periode: j['periode'] as String,
        periodeLabel: j['periodeLabel'] as String,
        honorMengajar: (j['honorMengajar'] as num?)?.toDouble() ?? 0.0,
        insentif: (j['insentif'] as num?)?.toDouble() ?? 0.0,
        tunjangan: (j['tunjangan'] as num?)?.toDouble() ?? 0.0,
        potongan: (j['potongan'] as num?)?.toDouble() ?? 0.0,
        totalHonor: (j['totalHonor'] as num?)?.toDouble() ?? 0.0,
        status: (j['status'] as String?) ?? HonorGuruStatus.draft,
        paidAt: j['paidAt'] is String
            ? DateTime.parse(j['paidAt'] as String)
            : null,
        kasId: j['kasId'] as String?,
        catatan: j['catatan'] as String?,
        createdAt: DateTime.parse(j['createdAt'] as String),
        updatedAt: DateTime.parse(j['updatedAt'] as String),
        guruName: j['guruName'] as String?,
        guruSpecialization: j['guruSpecialization'] as String?,
      );
}

/// Compute total honor bila totalHonor belum di-set server-side.
/// Total = mengajar + insentif + tunjangan - potongan.
double computeTotalHonor(HonorGuruModel h) =>
    h.honorMengajar + h.insentif + h.tunjangan - h.potongan;
