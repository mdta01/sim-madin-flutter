// Ujian + BankSoal + UjianPeserta + UjianNilai + UjianSesi + UjianJawaban — port dari Prisma.
// Catatan: UjianStatus + SoalType classes live in constants.dart (Phase 1).
// This file only contains model classes + UjianType constants (simple enum-like).

class UjianType {
  static const uts = 'UTS';
  static const uas = 'UAS';
  static const tugas = 'TUGAS';
  static const quiz = 'QUIZ';
}

class UjianModel {
  const UjianModel({
    required this.id,
    required this.tahunAjaranId,
    required this.semesterId,
    required this.mapelId,
    required this.kelasId,
    required this.guruId,
    required this.title,
    required this.type,
    this.description,
    this.startTime,
    this.endTime,
    this.durationMnt = 90,
    this.ruang,
    this.pengawas,
    this.isPublished = false,
    this.maxScore = 100,
    this.passingScore = 70,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.mapelName,
    this.kelasName,
    this.guruName,
    this.soalCount,
    this.pesertaCount,
  });

  final String id;
  final String tahunAjaranId;
  final String semesterId;
  final String mapelId;
  final String kelasId;
  final String guruId;
  final String title;
  final String type;
  final String? description;
  final DateTime? startTime;
  final DateTime? endTime;
  final int durationMnt;
  final String? ruang;
  final String? pengawas;
  final bool isPublished;
  final double maxScore;
  final double passingScore;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String? mapelName;
  final String? kelasName;
  final String? guruName;
  final int? soalCount;
  final int? pesertaCount;

  factory UjianModel.fromJson(Map<String, dynamic> j) => UjianModel(
        id: j['id'] as String,
        tahunAjaranId: j['tahunAjaranId'] as String,
        semesterId: j['semesterId'] as String,
        mapelId: j['mapelId'] as String,
        kelasId: j['kelasId'] as String,
        guruId: j['guruId'] as String,
        title: j['title'] as String,
        type: j['type'] as String,
        description: j['description'] as String?,
        startTime: j['startTime'] is String
            ? DateTime.parse(j['startTime'] as String)
            : null,
        endTime: j['endTime'] is String
            ? DateTime.parse(j['endTime'] as String)
            : null,
        durationMnt: (j['durationMnt'] as num?)?.toInt() ?? 90,
        ruang: j['ruang'] as String?,
        pengawas: j['pengawas'] as String?,
        isPublished: (j['isPublished'] as bool?) ?? false,
        maxScore: (j['maxScore'] as num?)?.toDouble() ?? 100,
        passingScore: (j['passingScore'] as num?)?.toDouble() ?? 70,
        createdAt: DateTime.parse(j['createdAt'] as String),
        updatedAt: DateTime.parse(j['updatedAt'] as String),
        deletedAt: j['deletedAt'] is String
            ? DateTime.parse(j['deletedAt'] as String)
            : null,
        mapelName: j['mapelName'] as String?,
        kelasName: j['kelasName'] as String?,
        guruName: j['guruName'] as String?,
        soalCount: (j['soalCount'] as num?)?.toInt(),
        pesertaCount: (j['pesertaCount'] as num?)?.toInt(),
      );
}


class BankSoalModel {
  const BankSoalModel({
    required this.id,
    required this.mapelId,
    required this.tahunAjaranId,
    required this.guruId,
    required this.code,
    required this.type,
    required this.question,
    this.options, // JSON string for PG
    this.correctAnswer,
    this.answerKey,
    this.bobot = 1.0,
    this.difficulty,
    this.kompetensiId,
    this.tags,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String mapelId;
  final String tahunAjaranId;
  final String guruId;
  final String code;
  final String type;
  final String question;
  final String? options;
  final String? correctAnswer;
  final String? answerKey;
  final double bobot;
  final String? difficulty;
  final String? kompetensiId;
  final String? tags;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory BankSoalModel.fromJson(Map<String, dynamic> j) => BankSoalModel(
        id: j['id'] as String,
        mapelId: j['mapelId'] as String,
        tahunAjaranId: j['tahunAjaranId'] as String,
        guruId: j['guruId'] as String,
        code: j['code'] as String,
        type: j['type'] as String,
        question: j['question'] as String,
        options: j['options'] as String?,
        correctAnswer: j['correctAnswer'] as String?,
        answerKey: j['answerKey'] as String?,
        bobot: (j['bobot'] as num?)?.toDouble() ?? 1.0,
        difficulty: j['difficulty'] as String?,
        kompetensiId: j['kompetensiId'] as String?,
        tags: j['tags'] as String?,
        isActive: (j['isActive'] as bool?) ?? true,
        createdAt: DateTime.parse(j['createdAt'] as String),
        updatedAt: DateTime.parse(j['updatedAt'] as String),
      );
}

class UjianSoalModel {
  const UjianSoalModel({
    required this.id,
    required this.ujianId,
    required this.bankSoalId,
    required this.urutan,
    this.bobot = 1.0,
    required this.createdAt,
    this.question,
    this.type,
    this.options,
  });

  final String id;
  final String ujianId;
  final String bankSoalId;
  final int urutan;
  final double bobot;
  final DateTime createdAt;
  final String? question;
  final String? type;
  final String? options;

  factory UjianSoalModel.fromJson(Map<String, dynamic> j) => UjianSoalModel(
        id: j['id'] as String,
        ujianId: j['ujianId'] as String,
        bankSoalId: j['bankSoalId'] as String,
        urutan: (j['urutan'] as num).toInt(),
        bobot: (j['bobot'] as num?)?.toDouble() ?? 1.0,
        createdAt: DateTime.parse(j['createdAt'] as String),
        question: j['question'] as String?,
        type: j['type'] as String?,
        options: j['options'] as String?,
      );
}

class UjianPesertaModel {
  const UjianPesertaModel({
    required this.id,
    required this.ujianId,
    required this.santriId,
    this.ruang,
    this.pengawas,
    this.isHadir = true,
    this.catatan,
    required this.createdAt,
    this.santriName,
    this.santriNis,
  });

  final String id;
  final String ujianId;
  final String santriId;
  final String? ruang;
  final String? pengawas;
  final bool isHadir;
  final String? catatan;
  final DateTime createdAt;
  final String? santriName;
  final String? santriNis;

  factory UjianPesertaModel.fromJson(Map<String, dynamic> j) =>
      UjianPesertaModel(
        id: j['id'] as String,
        ujianId: j['ujianId'] as String,
        santriId: j['santriId'] as String,
        ruang: j['ruang'] as String?,
        pengawas: j['pengawas'] as String?,
        isHadir: (j['isHadir'] as bool?) ?? true,
        catatan: j['catatan'] as String?,
        createdAt: DateTime.parse(j['createdAt'] as String),
        santriName: j['santriName'] as String?,
        santriNis: j['santriNis'] as String?,
      );
}

class UjianNilaiModel {
  const UjianNilaiModel({
    required this.id,
    required this.ujianId,
    required this.santriId,
    this.score,
    this.scoreUts,
    this.scoreUas,
    this.scorePraktik,
    this.notes,
    this.gradedById,
    this.gradedAt,
    this.isAutoCorrect = false,
    required this.createdAt,
    required this.updatedAt,
    this.santriName,
    this.santriNis,
  });

  final String id;
  final String ujianId;
  final String santriId;
  final double? score;
  final double? scoreUts;
  final double? scoreUas;
  final double? scorePraktik;
  final String? notes;
  final String? gradedById;
  final DateTime? gradedAt;
  final bool isAutoCorrect;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? santriName;
  final String? santriNis;

  factory UjianNilaiModel.fromJson(Map<String, dynamic> j) => UjianNilaiModel(
        id: j['id'] as String,
        ujianId: j['ujianId'] as String,
        santriId: j['santriId'] as String,
        score: (j['score'] as num?)?.toDouble(),
        scoreUts: (j['scoreUts'] as num?)?.toDouble(),
        scoreUas: (j['scoreUas'] as num?)?.toDouble(),
        scorePraktik: (j['scorePraktik'] as num?)?.toDouble(),
        notes: j['notes'] as String?,
        gradedById: j['gradedById'] as String?,
        gradedAt: j['gradedAt'] is String
            ? DateTime.parse(j['gradedAt'] as String)
            : null,
        isAutoCorrect: (j['isAutoCorrect'] as bool?) ?? false,
        createdAt: DateTime.parse(j['createdAt'] as String),
        updatedAt: DateTime.parse(j['updatedAt'] as String),
        santriName: j['santriName'] as String?,
        santriNis: j['santriNis'] as String?,
      );
}
