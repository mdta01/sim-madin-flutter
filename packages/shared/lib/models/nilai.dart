// Nilai — port dari Prisma `Nilai`
// Dipakai di Nilai monitor screen

class NilaiType {
  static const harian = 'HARIAN';
  static const tugas = 'TUGAS';
  static const uts = 'UTS';
  static const uas = 'UAS';
  static const praktik = 'PRAKTIK';
  static const all = <String>[harian, tugas, uts, uas, praktik];
}

class NilaiModel {
  const NilaiModel({
    required this.id,
    required this.tahunAjaranId,
    required this.semesterId,
    required this.santriId,
    required this.kelasId,
    required this.mapelId,
    this.guruId,
    this.kompetensiId,
    required this.type,
    required this.score,
    this.notes,
    required this.assessmentDate,
    required this.createdAt,
    required this.updatedAt,
    this.santriName,
    this.santriNis,
    this.kelasName,
    this.mapelName,
    this.mapelKkm,
  });

  final String id;
  final String tahunAjaranId;
  final String semesterId;
  final String santriId;
  final String kelasId;
  final String mapelId;
  final String? guruId;
  final String? kompetensiId;
  final String type; // NilaiType.*
  final double score;
  final String? notes;
  final DateTime assessmentDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Denormalized untuk display
  final String? santriName;
  final String? santriNis;
  final String? kelasName;
  final String? mapelName;
  final double? mapelKkm;

  factory NilaiModel.fromJson(Map<String, dynamic> j) => NilaiModel(
        id: j['id'] as String,
        tahunAjaranId: j['tahunAjaranId'] as String,
        semesterId: j['semesterId'] as String,
        santriId: j['santriId'] as String,
        kelasId: j['kelasId'] as String,
        mapelId: j['mapelId'] as String,
        guruId: j['guruId'] as String?,
        kompetensiId: j['kompetensiId'] as String?,
        type: j['type'] as String,
        score: (j['score'] as num).toDouble(),
        notes: j['notes'] as String?,
        assessmentDate: DateTime.parse(j['assessmentDate'] as String),
        createdAt: DateTime.parse(j['createdAt'] as String),
        updatedAt: DateTime.parse(j['updatedAt'] as String),
        santriName: j['santriName'] as String?,
        santriNis: j['santriNis'] as String?,
        kelasName: j['kelasName'] as String?,
        mapelName: j['mapelName'] as String?,
        mapelKkm: (j['mapelKkm'] as num?)?.toDouble(),
      );
}

/// Apakah nilai lulus KKM. Default KKM 70.0 bila null.
bool isLulus(double score, [double? kkm]) => score >= (kkm ?? 70.0);
