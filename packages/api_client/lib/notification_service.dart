// ============================================================================
// SIM MADIN — Firebase Cloud Messaging (FCM) Notification Service
// ============================================================================
// Handle push notification untuk semua mobile apps.
// - Foreground: tampilkan local notification banner
// - Background: system notification (otomatis oleh FCM)
// - Tap: navigate ke screen terkait
//
// FCM token disimpan ke tabel User.fcmToken untuk push dari server.
// ============================================================================

import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_client/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Provider untuk NotificationService singleton.
/// Pakai SupabaseClient langsung (bukan WidgetRef) supaya type-safe.
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref.read(supabaseClientProvider));
});

/// Callback untuk background message handler (harus top-level function).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('🔔 Background message: ${message.notification?.title}');
}

class NotificationService {
  NotificationService(this._client);

  final SupabaseClient _client;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'sim_madin_notifications';
  static const String _channelName = 'SIM MADIN Notifications';
  static const String _channelDesc =
      'Notifikasi SIM MADIN: nilai, tagihan, chat, pengumuman';

  bool _initialized = false;

  /// Initialize Firebase + FCM + local notifications.
  /// Panggil di main.dart sebelum runApp.
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // 1. Initialize Firebase
      await Firebase.initializeApp();

      // 2. Set background message handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 3. Setup local notifications (untuk foreground messages)
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );
      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTap,
      );

      // 4. Create Android notification channel
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              _channelId,
              _channelName,
              description: _channelDesc,
              importance: Importance.high,
            ),
          );

      // 5. Request permission (Android: otomatis granted, iOS: prompt)
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // 6. Listen to foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // 7. Listen to notification tap (when app is in background and user taps)
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);

      // 8. Get initial message (when app is launched from notification)
      final initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageTap(initialMessage);
      }

      _initialized = true;
      debugPrint('✅ NotificationService initialized');
    } catch (e) {
      debugPrint('❌ NotificationService init error: $e');
    }
  }

  /// Get FCM token dan simpan ke database.
  /// Panggil setelah login berhasil.
  Future<String?> getAndSaveToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return null;

      // Save ke Supabase User table
      final client = _client;
      final currentUser = client.auth.currentUser;
      if (currentUser != null) {
        await client.from('User').update({
          'fcmToken': token,
          'updatedAt': DateTime.now().toIso8601String(),
        }).eq('firebaseUid', currentUser.id);
        debugPrint('✅ FCM token saved to User table');
      }

      // Listen to token refresh
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        if (currentUser != null) {
          await client.from('User').update({
            'fcmToken': newToken,
            'updatedAt': DateTime.now().toIso8601String(),
          }).eq('firebaseUid', currentUser.id);
          debugPrint('✅ FCM token refreshed & saved');
        }
      });

      return token;
    } catch (e) {
      debugPrint('❌ FCM token error: $e');
      return null;
    }
  }

  /// Handle foreground message — tampilkan local notification.
  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      notification.title ?? 'SIM MADIN',
      notification.body ?? '',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  /// Global navigator key untuk navigate dari notification tap.
  /// Set dari main.dart: notificationServiceProvider.navigatorKey = navigatorKey;
  GlobalKey<NavigatorState>? navigatorKey;

  /// Handle notification tap — navigate ke screen terkait.
  void _handleMessageTap(RemoteMessage message) {
    final data = message.data;
    debugPrint('🔔 Notification tap: $data');
    _navigateFromData(data);
  }

  /// Handle local notification tap.
  void _onNotificationTap(NotificationResponse response) {
    if (response.payload == null) return;
    try {
      final data = jsonDecode(response.payload!) as Map<String, dynamic>;
      debugPrint('🔔 Local notification tap: $data');
      _navigateFromData(data);
    } catch (_) {}
  }

  /// Navigate ke screen berdasarkan notification data.
  void _navigateFromData(Map<String, dynamic> data) {
    if (navigatorKey?.currentContext == null) return;
    final context = navigatorKey!.currentContext!;
    final type = data['type'] as String?;
    final santriId = data['santriId'] as String?;
    final entityId = data['entityId'] as String?;

    switch (type) {
      case 'NILAI':
      case 'ABSENSI':
      case 'PERKEMBANGAN':
      case 'TAGIHAN':
      case 'PAYMENT':
        // Navigate ke santri detail (kalau ada santriId)
        if (santriId != null && santriId.isNotEmpty) {
          GoRouter.of(context)
              .push('/dashboard/home/santri/$santriId');
        } else {
          GoRouter.of(context).go('/dashboard/home');
        }
        break;
      case 'CHAT':
        // Navigate ke chat room (kalau ada entityId = roomId)
        if (entityId != null && entityId.isNotEmpty) {
          GoRouter.of(context).push('/dashboard/chat/$entityId');
        } else {
          GoRouter.of(context).go('/dashboard/chat');
        }
        break;
      case 'PENGUMUMAN':
        GoRouter.of(context).go('/dashboard/home');
        break;
      default:
        GoRouter.of(context).go('/dashboard/home');
    }
  }

  /// Unsubscribe dari topic (mis. saat logout).
  Future<void> unsubscribeFromTopic(String topic) async {
    await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
  }

  /// Subscribe ke topic (mis. 'all_users', 'wali', 'guru').
  Future<void> subscribeToTopic(String topic) async {
    await FirebaseMessaging.instance.subscribeToTopic(topic);
  }

  /// Cleanup saat logout — delete FCM token dari DB.
  Future<void> clearToken() async {
    try {
      final client = _client;
      final currentUser = client.auth.currentUser;
      if (currentUser != null) {
        await client.from('User').update({
          'fcmToken': null,
          'updatedAt': DateTime.now().toIso8601String(),
        }).eq('firebaseUid', currentUser.id);
        await FirebaseMessaging.instance.deleteToken();
        debugPrint('✅ FCM token cleared');
      }
    } catch (e) {
      debugPrint('❌ Clear FCM token error: $e');
    }
  }
}
