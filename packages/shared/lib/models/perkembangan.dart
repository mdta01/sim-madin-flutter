// Perkembangan santri models — PerkembanganQuran, HafalanKitab,
// AkhlakPenilaian, Pembinaan, CatatanWaliKelas. Port dari Prisma.

class PerkembanganQuranModel {
  const PerkembanganQuranModel({
    required this.id,
    required this.tahunAjaranId,
    required this.semesterId,
    required this.santriId,
    required this.guruId,
    required this.type, // TIQRO | TAHFIDZ | TILAWAH
    this.surah,
    this.juz,
    this.ayatFrom,
    this.ayatTo,
    this.score,
    this.status, // PROGRESS | SELESAI | ULANGI
    this.target,
    this.catatan,
    this.pertemuanDate,
    required this.createdAt,
    required this.updatedAt,
    this.santriName,
    this.guruName,
  });

  final String id;
  final String tahunAjaranId;
  final String semesterId;
  final String santriId;
  final String guruId;
  final String type;
  final String? surah;
  final String? juz;
  final int? ayatFrom;
  final int? ayatTo;
  final double? score;
  final String? status;
  final String? target;
  final String? catatan;
  final DateTime? pertemuanDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? santriName;
  final String? guruName;

  factory PerkembanganQuranModel.fromJson(Map<String, dynamic> j) =>
      PerkembanganQuranModel(
        id: j['id'] as String,
        tahunAjaranId: j['tahunAjaranId'] as String,
        semesterId: j['semesterId'] as String,
        santriId: j['santriId'] as String,
        guruId: j['guruId'] as String,
        type: j['type'] as String,
        surah: j['surah'] as String?,
        juz: j['juz'] as String?,
        ayatFrom: (j['ayatFrom'] as num?)?.toInt(),
        ayatTo: (j['ayatTo'] as num?)?.toInt(),
        score: (j['score'] as num?)?.toDouble(),
        status: j['status'] as String?,
        target: j['target'] as String?,
        catatan: j['catatan'] as String?,
        pertemuanDate: j['pertemuanDate'] is String
            ? DateTime.parse(j['pertemuanDate'] as String)
            : null,
        createdAt: DateTime.parse(j['createdAt'] as String),
        updatedAt: DateTime.parse(j['updatedAt'] as String),
        santriName: j['santriName'] as String?,
        guruName: j['guruName'] as String?,
      );
}

class HafalanKitabModel {
  const HafalanKitabModel({
    required this.id,
    required this.tahunAjaranId,
    required this.semesterId,
    required this.santriId,
    required this.guruId,
    required this.type, // HAFALAN | BACAAN
    required this.kitabName,
    this.halaman,
    this.score,
    this.status,
    this.target,
    this.catatan,
    this.pertemuanDate,
    required this.createdAt,
    required this.updatedAt,
    this.santriName,
    this.guruName,
  });

  final String id;
  final String tahunAjaranId;
  final String semesterId;
  final String santriId;
  final String guruId;
  final String type;
  final String kitabName;
  final int? halaman;
  final double? score;
  final String? status;
  final String? target;
  final String? catatan;
  final DateTime? pertemuanDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? santriName;
  final String? guruName;

  factory HafalanKitabModel.fromJson(Map<String, dynamic> j) =>
      HafalanKitabModel(
        id: j['id'] as String,
        tahunAjaranId: j['tahunAjaranId'] as String,
        semesterId: j['semesterId'] as String,
        santriId: j['santriId'] as String,
        guruId: j['guruId'] as String,
        type: j['type'] as String,
        kitabName: j['kitabName'] as String,
        halaman: (j['halaman'] as num?)?.toInt(),
        score: (j['score'] as num?)?.toDouble(),
        status: j['status'] as String?,
        target: j['target'] as String?,
        catatan: j['catatan'] as String?,
        pertemuanDate: j['pertemuanDate'] is String
            ? DateTime.parse(j['pertemuanDate'] as String)
            : null,
        createdAt: DateTime.parse(j['createdAt'] as String),
        updatedAt: DateTime.parse(j['updatedAt'] as String),
        santriName: j['santriName'] as String?,
        guruName: j['guruName'] as String?,
      );
}

class AkhlakPenilaianModel {
  const AkhlakPenilaianModel({
    required this.id,
    required this.tahunAjaranId,
    required this.semesterId,
    required this.santriId,
    required this.guruId,
    this.adabGuru = 0,
    this.adabOrangTua = 0,
    this.adabTeman = 0,
    this.kedisiplinan = 0,
    this.kebersihan = 0,
    this.tanggungJawab = 0,
    this.rataRata = 0,
    this.predikat,
    this.catatan,
    this.periode,
    this.periodeDate,
    required this.createdAt,
    required this.updatedAt,
    this.santriName,
    this.guruName,
  });

  final String id;
  final String tahunAjaranId;
  final String semesterId;
  final String santriId;
  final String guruId;
  final double adabGuru;
  final double adabOrangTua;
  final double adabTeman;
  final double kedisiplinan;
  final double kebersihan;
  final double tanggungJawab;
  final double rataRata;
  final String? predikat;
  final String? catatan;
  final String? periode;
  final DateTime? periodeDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? santriName;
  final String? guruName;

  factory AkhlakPenilaianModel.fromJson(Map<String, dynamic> j) =>
      AkhlakPenilaianModel(
        id: j['id'] as String,
        tahunAjaranId: j['tahunAjaranId'] as String,
        semesterId: j['semesterId'] as String,
        santriId: j['santriId'] as String,
        guruId: j['guruId'] as String,
        adabGuru: (j['adabGuru'] as num?)?.toDouble() ?? 0,
        adabOrangTua: (j['adabOrangTua'] as num?)?.toDouble() ?? 0,
        adabTeman: (j['adabTeman'] as num?)?.toDouble() ?? 0,
        kedisiplinan: (j['kedisiplinan'] as num?)?.toDouble() ?? 0,
        kebersihan: (j['kebersihan'] as num?)?.toDouble() ?? 0,
        tanggungJawab: (j['tanggungJawab'] as num?)?.toDouble() ?? 0,
        rataRata: (j['rataRata'] as num?)?.toDouble() ?? 0,
        predikat: j['predikat'] as String?,
        catatan: j['catatan'] as String?,
        periode: j['periode'] as String?,
        periodeDate: j['periodeDate'] is String
            ? DateTime.parse(j['periodeDate'] as String)
            : null,
        createdAt: DateTime.parse(j['createdAt'] as String),
        updatedAt: DateTime.parse(j['updatedAt'] as String),
        santriName: j['santriName'] as String?,
        guruName: j['guruName'] as String?,
      );
}

class PembinaanSeverity {
  static const ringan = 'RINGAN';
  static const sedang = 'SEDANG';
  static const berat = 'BERAT';
}

class PembinaanStatus {
  static const open = 'OPEN';
  static const inProgress = 'IN_PROGRESS';
  static const resolved = 'RESOLVED';
}

class PembinaanModel {
  const PembinaanModel({
    required this.id,
    required this.tahunAjaranId,
    required this.semesterId,
    required this.santriId,
    required this.guruId,
    required this.type, // PEMBERIAN | TEGURAN | HUKUMAN | APEL
    required this.category,
    required this.title,
    this.description,
    this.severity = PembinaanSeverity.ringan,
    this.tindakan,
    this.status = PembinaanStatus.open,
    this.resolvedAt,
    this.resolvedById,
    required this.createdAt,
    required this.updatedAt,
    this.santriName,
    this.guruName,
  });

  final String id;
  final String tahunAjaranId;
  final String semesterId;
  final String santriId;
  final String guruId;
  final String type;
  final String category;
  final String title;
  final String? description;
  final String severity;
  final String? tindakan;
  final String status;
  final DateTime? resolvedAt;
  final String? resolvedById;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? santriName;
  final String? guruName;

  factory PembinaanModel.fromJson(Map<String, dynamic> j) => PembinaanModel(
        id: j['id'] as String,
        tahunAjaranId: j['tahunAjaranId'] as String,
        semesterId: j['semesterId'] as String,
        santriId: j['santriId'] as String,
        guruId: j['guruId'] as String,
        type: j['type'] as String,
        category: j['category'] as String,
        title: j['title'] as String,
        description: j['description'] as String?,
        severity: (j['severity'] as String?) ?? PembinaanSeverity.ringan,
        tindakan: j['tindakan'] as String?,
        status: (j['status'] as String?) ?? PembinaanStatus.open,
        resolvedAt: j['resolvedAt'] is String
            ? DateTime.parse(j['resolvedAt'] as String)
            : null,
        resolvedById: j['resolvedById'] as String?,
        createdAt: DateTime.parse(j['createdAt'] as String),
        updatedAt: DateTime.parse(j['updatedAt'] as String),
        santriName: j['santriName'] as String?,
        guruName: j['guruName'] as String?,
      );
}
