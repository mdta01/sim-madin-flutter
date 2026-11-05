// Jadwal — port dari Prisma. Dipakai di dashboard guru + jadwal list.

class JadwalModel {
  const JadwalModel({
    required this.id,
    required this.tahunAjaranId,
    required this.semesterId,
    required this.kelasId,
    required this.mapelId,
    required this.guruId,
    required this.dayOfWeek, // 1=Senin, 7=Minggu
    required this.startTime, // "07:00"
    required this.endTime, // "08:30"
    required this.createdAt,
    required this.updatedAt,
    this.kelasName,
    this.kelasCode,
    this.mapelName,
    this.mapelCode,
    this.guruName,
  });

  final String id;
  final String tahunAjaranId;
  final String semesterId;
  final String kelasId;
  final String mapelId;
  final String guruId;
  final int dayOfWeek;
  final String startTime;
  final String endTime;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? kelasName;
  final String? kelasCode;
  final String? mapelName;
  final String? mapelCode;
  final String? guruName;

  factory JadwalModel.fromJson(Map<String, dynamic> j) => JadwalModel(
        id: j['id'] as String,
        tahunAjaranId: j['tahunAjaranId'] as String,
        semesterId: j['semesterId'] as String,
        kelasId: j['kelasId'] as String,
        mapelId: j['mapelId'] as String,
        guruId: j['guruId'] as String,
        dayOfWeek: (j['dayOfWeek'] as num).toInt(),
        startTime: j['startTime'] as String,
        endTime: j['endTime'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
        updatedAt: DateTime.parse(j['updatedAt'] as String),
        kelasName: j['kelasName'] as String?,
        kelasCode: j['kelasCode'] as String?,
        mapelName: j['mapelName'] as String?,
        mapelCode: j['mapelCode'] as String?,
        guruName: j['guruName'] as String?,
      );
}

/// Helper untuk konversi dayOfWeek int → label.
String dayOfWeekLabel(int day) {
  const days = ['', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
  return day >= 1 && day <= 7 ? days[day] : '?';
}
