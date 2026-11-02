// Kelas — port dari Prisma
// Dipakai di filter dropdown Santri/Absensi/Nilai

class KelasModel {
  const KelasModel({
    required this.id,
    required this.code,
    required this.name,
    required this.level,
    this.description,
    this.capacity = 30,
    this.sortOrder = 0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.waliKelasId,
    this.waliKelasName,
  });

  final String id;
  final String code; // "MDA-1A"
  final String name; // "Kelas 1 Madrasah A"
  final String level; // "MDA-1" | "MDA-2" | ... | "MDI-1"
  final String? description;
  final int capacity;
  final int sortOrder;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  // Relations (nullable, diisi hanya kalau di-join di query)
  final String? waliKelasId;
  final String? waliKelasName; // denormalized dari Guru.name

  factory KelasModel.fromJson(Map<String, dynamic> j) => KelasModel(
        id: j['id'] as String,
        code: j['code'] as String,
        name: j['name'] as String,
        level: j['level'] as String,
        description: j['description'] as String?,
        capacity: (j['capacity'] as num?)?.toInt() ?? 30,
        sortOrder: (j['sortOrder'] as num?)?.toInt() ?? 0,
        isActive: (j['isActive'] as bool?) ?? true,
        createdAt: DateTime.parse(j['createdAt'] as String),
        updatedAt: DateTime.parse(j['updatedAt'] as String),
        deletedAt: j['deletedAt'] is String
            ? DateTime.parse(j['deletedAt'] as String)
            : null,
        waliKelasId: j['waliKelasId'] as String?,
        waliKelasName: j['waliKelasName'] as String?,
      );
}
