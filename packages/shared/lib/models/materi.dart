// Materi — port dari Prisma. Dipakai di materi list + create form.

class MateriType {
  static const dokumen = 'DOKUMEN';
  static const video = 'VIDEO';
  static const link = 'LINK';
  static const presentation = 'PRESENTATION';

  static String label(String? t) {
    switch (t) {
      case MateriType.dokumen:
        return 'Dokumen';
      case MateriType.video:
        return 'Video';
      case MateriType.link:
        return 'Link';
      case MateriType.presentation:
        return 'Presentasi';
      default:
        return t ?? '-';
    }
  }
}

class MateriModel {
  const MateriModel({
    required this.id,
    required this.tahunAjaranId,
    required this.semesterId,
    required this.mapelId,
    required this.kelasId,
    required this.guruId,
    required this.title,
    this.description,
    required this.type,
    this.fileUrl,
    this.externalUrl,
    this.pertemuan,
    this.sortOrder = 0,
    this.isPublished = false,
    this.publishedAt,
    this.createdById,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.mapelName,
    this.kelasName,
    this.guruName,
  });

  final String id;
  final String tahunAjaranId;
  final String semesterId;
  final String mapelId;
  final String kelasId;
  final String guruId;
  final String title;
  final String? description;
  final String type;
  final String? fileUrl;
  final String? externalUrl;
  final int? pertemuan;
  final int sortOrder;
  final bool isPublished;
  final DateTime? publishedAt;
  final String? createdById;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String? mapelName;
  final String? kelasName;
  final String? guruName;

  factory MateriModel.fromJson(Map<String, dynamic> j) => MateriModel(
        id: j['id'] as String,
        tahunAjaranId: j['tahunAjaranId'] as String,
        semesterId: j['semesterId'] as String,
        mapelId: j['mapelId'] as String,
        kelasId: j['kelasId'] as String,
        guruId: j['guruId'] as String,
        title: j['title'] as String,
        description: j['description'] as String?,
        type: j['type'] as String,
        fileUrl: j['fileUrl'] as String?,
        externalUrl: j['externalUrl'] as String?,
        pertemuan: (j['pertemuan'] as num?)?.toInt(),
        sortOrder: (j['sortOrder'] as num?)?.toInt() ?? 0,
        isPublished: (j['isPublished'] as bool?) ?? false,
        publishedAt: j['publishedAt'] is String
            ? DateTime.parse(j['publishedAt'] as String)
            : null,
        createdById: j['createdById'] as String?,
        createdAt: DateTime.parse(j['createdAt'] as String),
        updatedAt: DateTime.parse(j['updatedAt'] as String),
        deletedAt: j['deletedAt'] is String
            ? DateTime.parse(j['deletedAt'] as String)
            : null,
        mapelName: j['mapelName'] as String?,
        kelasName: j['kelasName'] as String?,
        guruName: j['guruName'] as String?,
      );
}
