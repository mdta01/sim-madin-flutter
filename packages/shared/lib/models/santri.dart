// Santri — port dari Prisma `Santri`
// Dipakai di Santri list, sebagai FK di Absensi/Nilai/Tagihan/Payment

class SantriStatus {
  static const aktif = 'AKTIF';
  static const lulus = 'LULUS';
  static const pindah = 'PINDAH';
  static const keluar = 'KELUAR';
}

class SantriGender {
  static const l = 'L';
  static const p = 'P';

  static String label(String? g) {
    if (g == SantriGender.l) return 'Laki-laki';
    if (g == SantriGender.p) return 'Perempuan';
    return '-';
  }
}

class SantriModel {
  const SantriModel({
    required this.id,
    required this.nis,
    this.nisn,
    required this.name,
    required this.gender,
    this.birthPlace,
    this.birthDate,
    this.address,
    this.phone,
    this.photoUrl,
    required this.entryDate,
    this.status = SantriStatus.aktif,
    this.waliId,
    this.waliName,
    this.waliPhone,
    this.kelasId,
    this.kelasName,
    this.kelasCode,
    this.tahunAjaranId,
    this.userId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String nis; // Nomor Induk Santri
  final String? nisn;
  final String name;
  final String gender; // SantriGender.*
  final String? birthPlace;
  final DateTime? birthDate;
  final String? address;
  final String? phone;
  final String? photoUrl;
  final DateTime entryDate;
  final String status;
  final String? waliId;
  final String? waliName; // denormalized untuk efisiensi display
  final String? waliPhone;
  final String? kelasId;
  final String? kelasName;
  final String? kelasCode;
  final String? tahunAjaranId;
  final String? userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  factory SantriModel.fromJson(Map<String, dynamic> j) => SantriModel(
        id: j['id'] as String,
        nis: j['nis'] as String,
        nisn: j['nisn'] as String?,
        name: j['name'] as String,
        gender: j['gender'] as String,
        birthPlace: j['birthPlace'] as String?,
        birthDate: j['birthDate'] is String
            ? DateTime.parse(j['birthDate'] as String)
            : null,
        address: j['address'] as String?,
        phone: j['phone'] as String?,
        photoUrl: j['photoUrl'] as String?,
        entryDate: DateTime.parse(j['entryDate'] as String),
        status: (j['status'] as String?) ?? SantriStatus.aktif,
        waliId: j['waliId'] as String?,
        waliName: j['waliName'] as String?,
        waliPhone: j['waliPhone'] as String?,
        kelasId: j['kelasId'] as String?,
        kelasName: j['kelasName'] as String?,
        kelasCode: j['kelasCode'] as String?,
        tahunAjaranId: j['tahunAjaranId'] as String?,
        userId: j['userId'] as String?,
        createdAt: DateTime.parse(j['createdAt'] as String),
        updatedAt: DateTime.parse(j['updatedAt'] as String),
        deletedAt: j['deletedAt'] is String
            ? DateTime.parse(j['deletedAt'] as String)
            : null,
      );

  String get initials => name.isEmpty ? '?' : name[0].toUpperCase();
}
