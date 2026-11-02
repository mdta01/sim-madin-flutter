// Guru — port dari Prisma `Guru`
// Dipakai di Honor Guru monitor + santri.waliKelas display

class GuruStatus {
  static const aktif = 'AKTIF';
  static const cuti = 'CUTI';
  static const keluar = 'KELUAR';
}

class GuruModel {
  const GuruModel({
    required this.id,
    this.userId,
    this.nip,
    this.nuptk,
    required this.name,
    required this.gender,
    this.birthPlace,
    this.birthDate,
    this.address,
    this.phone,
    this.email,
    this.photoUrl,
    required this.joinDate,
    this.specialization,
    this.status = GuruStatus.aktif,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String? userId;
  final String? nip;
  final String? nuptk;
  final String name;
  final String gender; // "L" | "P"
  final String? birthPlace;
  final DateTime? birthDate;
  final String? address;
  final String? phone;
  final String? email;
  final String? photoUrl;
  final DateTime joinDate;
  final String? specialization; // "Tahfidz", "Fiqih", dll
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  factory GuruModel.fromJson(Map<String, dynamic> j) => GuruModel(
        id: j['id'] as String,
        userId: j['userId'] as String?,
        nip: j['nip'] as String?,
        nuptk: j['nuptk'] as String?,
        name: j['name'] as String,
        gender: j['gender'] as String,
        birthPlace: j['birthPlace'] as String?,
        birthDate: j['birthDate'] is String
            ? DateTime.parse(j['birthDate'] as String)
            : null,
        address: j['address'] as String?,
        phone: j['phone'] as String?,
        email: j['email'] as String?,
        photoUrl: j['photoUrl'] as String?,
        joinDate: DateTime.parse(j['joinDate'] as String),
        specialization: j['specialization'] as String?,
        status: (j['status'] as String?) ?? GuruStatus.aktif,
        createdAt: DateTime.parse(j['createdAt'] as String),
        updatedAt: DateTime.parse(j['updatedAt'] as String),
        deletedAt: j['deletedAt'] is String
            ? DateTime.parse(j['deletedAt'] as String)
            : null,
      );

  String get initials => name.isEmpty ? '?' : name[0].toUpperCase();
}
