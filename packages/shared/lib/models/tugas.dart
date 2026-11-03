// Tugas + PengumpulanTugas — port dari Prisma.

class TugasType {
  static const individu = 'INDIVIDU';
  static const kelompok = 'KELOMPOK';
}

class TugasStatus {
  static const submitted = 'SUBMITTED';
  static const graded = 'GRADED';
  static const notSubmitted = 'NOT_SUBMITTED';
  static const overdue = 'OVERDUE';
}

class TugasModel {
  const TugasModel({
    required this.id,
    required this.tahunAjaranId,
    required this.semesterId,
    required this.mapelId,
    required this.kelasId,
    required this.guruId,
    this.materiId,
    required this.title,
    this.description,
    required this.type,
    this.fileUrl,
    this.maxScore = 100,
    this.dueDate,
    this.isPublished = false,
    this.publishedAt,
    this.createdById,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.mapelName,
    this.kelasName,
    this.guruName,
    this.submissionCount,
    this.pendingGradeCount,
  });

  final String id;
  final String tahunAjaranId;
  final String semesterId;
  final String mapelId;
  final String kelasId;
  final String guruId;
  final String? materiId;
  final String title;
  final String? description;
  final String type;
  final String? fileUrl;
  final double maxScore;
  final DateTime? dueDate;
  final bool isPublished;
  final DateTime? publishedAt;
  final String? createdById;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String? mapelName;
  final String? kelasName;
  final String? guruName;
  final int? submissionCount;
  final int? pendingGradeCount;

  factory TugasModel.fromJson(Map<String, dynamic> j) => TugasModel(
        id: j['id'] as String,
        tahunAjaranId: j['tahunAjaranId'] as String,
        semesterId: j['semesterId'] as String,
        mapelId: j['mapelId'] as String,
        kelasId: j['kelasId'] as String,
        guruId: j['guruId'] as String,
        materiId: j['materiId'] as String?,
        title: j['title'] as String,
        description: j['description'] as String?,
        type: j['type'] as String,
        fileUrl: j['fileUrl'] as String?,
        maxScore: (j['maxScore'] as num?)?.toDouble() ?? 100,
        dueDate: j['dueDate'] is String
            ? DateTime.parse(j['dueDate'] as String)
            : null,
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
        submissionCount: (j['submissionCount'] as num?)?.toInt(),
        pendingGradeCount: (j['pendingGradeCount'] as num?)?.toInt(),
      );
}

class PengumpulanTugasModel {
  const PengumpulanTugasModel({
    required this.id,
    required this.tugasId,
    required this.santriId,
    this.fileUrl,
    this.textAnswer,
    this.submittedAt,
    required this.status,
    this.score,
    this.feedback,
    this.gradedAt,
    this.gradedById,
    required this.createdAt,
    required this.updatedAt,
    this.santriName,
    this.santriNis,
    this.tugasTitle,
  });

  final String id;
  final String tugasId;
  final String santriId;
  final String? fileUrl;
  final String? textAnswer;
  final DateTime? submittedAt;
  final String status;
  final double? score;
  final String? feedback;
  final DateTime? gradedAt;
  final String? gradedById;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? santriName;
  final String? santriNis;
  final String? tugasTitle;

  factory PengumpulanTugasModel.fromJson(Map<String, dynamic> j) =>
      PengumpulanTugasModel(
        id: j['id'] as String,
        tugasId: j['tugasId'] as String,
        santriId: j['santriId'] as String,
        fileUrl: j['fileUrl'] as String?,
        textAnswer: j['textAnswer'] as String?,
        submittedAt: j['submittedAt'] is String
            ? DateTime.parse(j['submittedAt'] as String)
            : null,
        status: (j['status'] as String?) ?? TugasStatus.notSubmitted,
        score: (j['score'] as num?)?.toDouble(),
        feedback: j['feedback'] as String?,
        gradedAt: j['gradedAt'] is String
            ? DateTime.parse(j['gradedAt'] as String)
            : null,
        gradedById: j['gradedById'] as String?,
        createdAt: DateTime.parse(j['createdAt'] as String),
        updatedAt: DateTime.parse(j['updatedAt'] as String),
        santriName: j['santriName'] as String?,
        santriNis: j['santriNis'] as String?,
        tugasTitle: j['tugasTitle'] as String?,
      );
}
