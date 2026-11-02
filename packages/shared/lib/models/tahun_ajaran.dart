// TahunAjaran + Semester — port dari Prisma
// Dipakai sebagai context filter di hampir semua screen Phase 2

class TahunAjaranModel {
  const TahunAjaranModel({
    required this.id,
    required this.code,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.isActive = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String code; // "2025/2026"
  final String name; // "Tahun Ajaran 2025/2026"
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory TahunAjaranModel.fromJson(Map<String, dynamic> j) => TahunAjaranModel(
        id: j['id'] as String,
        code: j['code'] as String,
        name: j['name'] as String,
        startDate: DateTime.parse(j['startDate'] as String),
        endDate: DateTime.parse(j['endDate'] as String),
        isActive: (j['isActive'] as bool?) ?? false,
        createdAt: DateTime.parse(j['createdAt'] as String),
        updatedAt: DateTime.parse(j['updatedAt'] as String),
      );
}

enum SemesterType { ganjil, genap }

class SemesterModel {
  const SemesterModel({
    required this.id,
    required this.tahunAjaranId,
    required this.code,
    required this.name,
    required this.type,
    required this.startDate,
    required this.endDate,
    this.isActive = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String tahunAjaranId;
  final String code; // "2025/2026-GANJIL"
  final String name; // "Ganjil" / "Genap"
  final SemesterType type;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory SemesterModel.fromJson(Map<String, dynamic> j) => SemesterModel(
        id: j['id'] as String,
        tahunAjaranId: j['tahunAjaranId'] as String,
        code: j['code'] as String,
        name: j['name'] as String,
        type: semesterTypeFromString(j['type'] as String),
        startDate: DateTime.parse(j['startDate'] as String),
        endDate: DateTime.parse(j['endDate'] as String),
        isActive: (j['isActive'] as bool?) ?? false,
        createdAt: DateTime.parse(j['createdAt'] as String),
        updatedAt: DateTime.parse(j['updatedAt'] as String),
      );
}

/// Helper parsing "GANJIL"/"GENAP" → SemesterType.
SemesterType semesterTypeFromString(String v) =>
    v.toUpperCase() == 'GENAP' ? SemesterType.genap : SemesterType.ganjil;

String semesterTypeToString(SemesterType t) =>
    t == SemesterType.genap ? 'GENAP' : 'GANJIL';
