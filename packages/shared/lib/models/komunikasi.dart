// Announcement (pengumuman), Wali, SantriWali, ChatRoom, ChatMessage — port dari Prisma.

class AnnouncementPriority {
  static const normal = 'NORMAL';
  static const penting = 'PENTING';
  static const urgent = 'URGENT';
}

class AnnouncementAudience {
  static const all = 'ALL';
  static const wali = 'WALI';
  static const guru = 'GURU';
  static const santri = 'SANTRI';
}

class AnnouncementModel {
  const AnnouncementModel({
    required this.id,
    required this.title,
    required this.content,
    this.priority = AnnouncementPriority.normal,
    this.audience = AnnouncementAudience.all,
    this.publishedAt,
    this.createdById,
    required this.createdAt,
    required this.updatedAt,
    this.createdByName,
  });

  final String id;
  final String title;
  final String content;
  final String priority;
  final String audience;
  final DateTime? publishedAt;
  final String? createdById;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdByName;

  factory AnnouncementModel.fromJson(Map<String, dynamic> j) =>
      AnnouncementModel(
        id: j['id'] as String,
        title: j['title'] as String,
        content: j['content'] as String,
        priority: (j['priority'] as String?) ?? AnnouncementPriority.normal,
        audience: (j['audience'] as String?) ?? AnnouncementAudience.all,
        publishedAt: j['publishedAt'] is String
            ? DateTime.parse(j['publishedAt'] as String)
            : null,
        createdById: j['createdById'] as String?,
        createdAt: DateTime.parse(j['createdAt'] as String),
        updatedAt: DateTime.parse(j['updatedAt'] as String),
        createdByName: j['createdByName'] as String?,
      );
}

class WaliActivationStatus {
  static const pendingNoPhone = 'PENDING_NO_PHONE';
  static const pending = 'PENDING';
  static const active = 'ACTIVE';
  static const suspended = 'SUSPENDED';
}

class WaliModel {
  const WaliModel({
    required this.id,
    this.userId,
    required this.name,
    this.nik,
    this.phone,
    this.email,
    this.occupation,
    this.address,
    this.relationship = 'WALI',
    this.activationStatus = WaliActivationStatus.pending,
    // Auth & OTP
    this.pinHash,
    this.otpCode,
    this.otpExpiresAt,
    this.otpAttempts = 0,
    this.otpRequestCount = 0,
    this.otpRequestResetAt,
    this.failedLoginAttempts = 0,
    this.lockedUntil,
    this.lastLoginAt,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String? userId;
  final String name;
  final String? nik;
  final String? phone;
  final String? email;
  final String? occupation;
  final String? address;
  final String relationship;
  final String activationStatus;

  // Auth & OTP fields (Phase 5)
  final String? pinHash; // PIN 6-digit (DEV: plain; prod: bcrypt hash)
  final String? otpCode; // OTP aktif saat ini
  final DateTime? otpExpiresAt; // OTP expiry (5 menit)
  final int otpAttempts; // attempt verify OTP salah
  final int otpRequestCount; // anti-spam: max 5/jam
  final DateTime? otpRequestResetAt; // reset counter setelah 1 jam
  final int failedLoginAttempts; // PIN salah counter (max 5 → lock 15 menit)
  final DateTime? lockedUntil; // auto-lock timestamp
  final DateTime? lastLoginAt;

  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  factory WaliModel.fromJson(Map<String, dynamic> j) => WaliModel(
        id: j['id'] as String,
        userId: j['userId'] as String?,
        name: j['name'] as String,
        nik: j['nik'] as String?,
        phone: j['phone'] as String?,
        email: j['email'] as String?,
        occupation: j['occupation'] as String?,
        address: j['address'] as String?,
        relationship: (j['relationship'] as String?) ?? 'WALI',
        activationStatus:
            (j['activationStatus'] as String?) ?? WaliActivationStatus.pending,
        pinHash: j['pinHash'] as String?,
        otpCode: j['otpCode'] as String?,
        otpExpiresAt: j['otpExpiresAt'] is String
            ? DateTime.parse(j['otpExpiresAt'] as String)
            : null,
        otpAttempts: (j['otpAttempts'] as num?)?.toInt() ?? 0,
        otpRequestCount: (j['otpRequestCount'] as num?)?.toInt() ?? 0,
        otpRequestResetAt: j['otpRequestResetAt'] is String
            ? DateTime.parse(j['otpRequestResetAt'] as String)
            : null,
        failedLoginAttempts:
            (j['failedLoginAttempts'] as num?)?.toInt() ?? 0,
        lockedUntil: j['lockedUntil'] is String
            ? DateTime.parse(j['lockedUntil'] as String)
            : null,
        lastLoginAt: j['lastLoginAt'] is String
            ? DateTime.parse(j['lastLoginAt'] as String)
            : null,
        createdAt: DateTime.parse(j['createdAt'] as String),
        updatedAt: DateTime.parse(j['updatedAt'] as String),
        deletedAt: j['deletedAt'] is String
            ? DateTime.parse(j['deletedAt'] as String)
            : null,
      );
}

class SantriWaliModel {
  const SantriWaliModel({
    required this.id,
    required this.santriId,
    required this.waliId,
    required this.relationship,
    this.isPrimary = false,
    this.canAccess = true,
    required this.createdAt,
    this.santriName,
    this.waliName,
    this.waliPhone,
  });

  final String id;
  final String santriId;
  final String waliId;
  final String relationship;
  final bool isPrimary;
  final bool canAccess;
  final DateTime createdAt;
  final String? santriName;
  final String? waliName;
  final String? waliPhone;

  factory SantriWaliModel.fromJson(Map<String, dynamic> j) => SantriWaliModel(
        id: j['id'] as String,
        santriId: j['santriId'] as String,
        waliId: j['waliId'] as String,
        relationship: j['relationship'] as String,
        isPrimary: (j['isPrimary'] as bool?) ?? false,
        canAccess: (j['canAccess'] as bool?) ?? true,
        createdAt: DateTime.parse(j['createdAt'] as String),
        santriName: j['santriName'] as String?,
        waliName: j['waliName'] as String?,
        waliPhone: j['waliPhone'] as String?,
      );
}

class ChatRoomType {
  static const waliGuru = 'WALI_GURU';
  static const waliWali = 'WALI_WALI';
  static const group = 'GROUP';

  static String label(String? t) {
    switch (t) {
      case ChatRoomType.waliGuru:
        return 'Wali ↔ Guru';
      case ChatRoomType.waliWali:
        return 'Wali ↔ Wali';
      case ChatRoomType.group:
        return 'Grup';
      default:
        return t ?? '-';
    }
  }
}

class ChatRoomModel {
  const ChatRoomModel({
    required this.id,
    required this.type,
    this.waliId,
    this.guruId,
    this.santriId,
    this.title,
    this.lastMessageAt,
    this.lastMessage,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.waliName,
    this.guruName,
    this.santriName,
    this.messageCount = 0,
  });

  final String id;
  final String type;
  final String? waliId;
  final String? guruId;
  final String? santriId;
  final String? title;
  final DateTime? lastMessageAt;
  final String? lastMessage;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? waliName;
  final String? guruName;
  final String? santriName;
  final int messageCount;

  factory ChatRoomModel.fromJson(Map<String, dynamic> j) => ChatRoomModel(
        id: j['id'] as String,
        type: j['type'] as String,
        waliId: j['waliId'] as String?,
        guruId: j['guruId'] as String?,
        santriId: j['santriId'] as String?,
        title: j['title'] as String?,
        lastMessageAt: j['lastMessageAt'] is String
            ? DateTime.parse(j['lastMessageAt'] as String)
            : null,
        lastMessage: j['lastMessage'] as String?,
        isActive: (j['isActive'] as bool?) ?? true,
        createdAt: DateTime.parse(j['createdAt'] as String),
        updatedAt: DateTime.parse(j['updatedAt'] as String),
        waliName: j['waliName'] as String?,
        guruName: j['guruName'] as String?,
        santriName: j['santriName'] as String?,
        messageCount: (j['messageCount'] as num?)?.toInt() ?? 0,
      );
}

class ChatSenderType {
  static const wali = 'WALI';
  static const guru = 'GURU';
  static const user = 'USER';
}

class ChatMessageModel {
  const ChatMessageModel({
    required this.id,
    required this.chatRoomId,
    required this.senderType,
    this.senderWaliId,
    this.senderGuruId,
    this.senderUserId,
    required this.message,
    this.attachments, // JSON string
    this.isRead = false,
    this.readAt,
    required this.createdAt,
    this.senderName,
  });

  final String id;
  final String chatRoomId;
  final String senderType;
  final String? senderWaliId;
  final String? senderGuruId;
  final String? senderUserId;
  final String message;
  final String? attachments;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;
  final String? senderName;

  factory ChatMessageModel.fromJson(Map<String, dynamic> j) =>
      ChatMessageModel(
        id: j['id'] as String,
        chatRoomId: j['chatRoomId'] as String,
        senderType: j['senderType'] as String,
        senderWaliId: j['senderWaliId'] as String?,
        senderGuruId: j['senderGuruId'] as String?,
        senderUserId: j['senderUserId'] as String?,
        message: j['message'] as String,
        attachments: j['attachments'] as String?,
        isRead: (j['isRead'] as bool?) ?? false,
        readAt: j['readAt'] is String
            ? DateTime.parse(j['readAt'] as String)
            : null,
        createdAt: DateTime.parse(j['createdAt'] as String),
        senderName: j['senderName'] as String?,
      );
}
