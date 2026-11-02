// Absensi — port dari Prisma `Absensi`
// Dipakai di Absensi monitor screen

class AbsensiStatus {
  static const hadir = 'HADIR';
  static const sakit = 'SAKIT';
  static const izin = 'IZIN';
  static const alfa = 'ALFA';

  static const all = <String>[hadir, sakit, izin, alfa];
}

class AbsensiModel {
  const AbsensiModel({
    required this.id,
    required this.tahunAjaranId,
    required this.santriId,
    required this.kelasId,
    required this.date,
    required this.status,
    this.note,
    this.recordedByGuruId,
    required this.createdAt,
    required this.updatedAt,
    this.santriName,
    this.santriNis,
    this.kelasName,
    this.kelasCode,
  });

  final String id;
  final String tahunAjaranId;
  final String santriId;
  final String kelasId;
  final DateTime date;
  final String status; // AbsensiStatus.*
  final String? note;
  final String? recordedByGuruId;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Denormalized untuk efisiensi display
  final String? santriName;
  final String? santriNis;
  final String? kelasName;
  final String? kelasCode;

  factory AbsensiModel.fromJson(Map<String, dynamic> j) => AbsensiModel(
        id: j['id'] as String,
        tahunAjaranId: j['tahunAjaranId'] as String,
        santriId: j['santriId'] as String,
        kelasId: j['kelasId'] as String,
        date: DateTime.parse(j['date'] as String),
        status: (j['status'] as String?) ?? AbsensiStatus.hadir,
        note: j['note'] as String?,
        recordedByGuruId: j['recordedByGuruId'] as String?,
        createdAt: DateTime.parse(j['createdAt'] as String),
        updatedAt: DateTime.parse(j['updatedAt'] as String),
        santriName: j['santriName'] as String?,
        santriNis: j['santriNis'] as String?,
        kelasName: j['kelasName'] as String?,
        kelasCode: j['kelasCode'] as String?,
      );
}
