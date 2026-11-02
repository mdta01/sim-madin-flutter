// MataPelajaran — port dari Prisma
// Dipakai di filter dropdown Nilai (per mapel)

class MapelCategory {
  static const diniyah = 'DINIYAH';
  static const umum = 'UMUM';
  static const alQuran = 'AL_QURAN';
  static const all = <String>[diniyah, umum, alQuran];
}

class MataPelajaranModel {
  const MataPelajaranModel({
    required this.id,
    required this.code,
    required this.name,
    required this.category,
    this.description,
    this.kkm = 70.0,
    this.durationMnt = 90,
    this.sortOrder = 0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String code; // "FIKIH"
  final String name; // "Fiqih"
  final String category; // MapelCategory.*
  final String? description;
  final double kkm; // Kriteria Ketuntasan Minimal
  final int durationMnt;
  final int sortOrder;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  factory MataPelajaranModel.fromJson(Map<String, dynamic> j) =>
      MataPelajaranModel(
        id: j['id'] as String,
        code: j['code'] as String,
        name: j['name'] as String,
        category: j['category'] as String,
        description: j['description'] as String?,
        kkm: (j['kkm'] as num?)?.toDouble() ?? 70.0,
        durationMnt: (j['durationMnt'] as num?)?.toInt() ?? 90,
        sortOrder: (j['sortOrder'] as num?)?.toInt() ?? 0,
        isActive: (j['isActive'] as bool?) ?? true,
        createdAt: DateTime.parse(j['createdAt'] as String),
        updatedAt: DateTime.parse(j['updatedAt'] as String),
        deletedAt: j['deletedAt'] is String
            ? DateTime.parse(j['deletedAt'] as String)
            : null,
      );
}
