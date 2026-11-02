// Pertemuan — port dari Prisma. Dipakai di pertemuan list + auto-complete.

class PertemuanModel {
  const PertemuanModel({
    required this.id,
    required this.tahunAjaranId,
    required this.semesterId,
    required this.kelasId,
    required this.mapelId,
    required this.guruId,
    required this.pertemuanKe,
    required this.date,
    this.topic,
    this.description,
    this.isCompleted = false,
    required this.createdAt,
    required this.updatedAt,
    this.kelasName,
    this.mapelName,
    this.guruName,
    this.absensiCount,
  });

  final String id;
  final String tahunAjaranId;
  final String semesterId;
  final String kelasId;
  final String mapelId;
  final String guruId;
  final int pertemuanKe;
  final DateTime date;
  final String? topic;
  final String? description;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? kelasName;
  final String? mapelName;
  final String? guruName;
  final int? absensiCount;

  factory PertemuanModel.fromJson(Map<String, dynamic> j) => PertemuanModel(
        id: j['id'] as String,
        tahunAjaranId: j['tahunAjaranId'] as String,
        semesterId: j['semesterId'] as String,
        kelasId: j['kelasId'] as String,
        mapelId: j['mapelId'] as String,
        guruId: j['guruId'] as String,
        pertemuanKe: (j['pertemuanKe'] as num).toInt(),
        date: DateTime.parse(j['date'] as String),
        topic: j['topic'] as String?,
        description: j['description'] as String?,
        isCompleted: (j['isCompleted'] as bool?) ?? false,
        createdAt: DateTime.parse(j['createdAt'] as String),
        updatedAt: DateTime.parse(j['updatedAt'] as String),
        kelasName: j['kelasName'] as String?,
        mapelName: j['mapelName'] as String?,
        guruName: j['guruName'] as String?,
        absensiCount: (j['absensiCount'] as num?)?.toInt(),
      );
}
