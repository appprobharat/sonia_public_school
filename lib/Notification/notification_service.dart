import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'sonia_channel',
    'SONIA PUBLIC SCHOOL Notifications',
    description: 'Notifications for SONIA PUBLIC SCHOOL app',
    importance: Importance.high,
  );

  /// 🔹 INITIALIZE (Android + iOS)
  static Future<void> initialize() async {
    // 🔹 Android init
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    // 🔹 iOS init
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    // 🔹 Create Android notification channel
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint("🔔 Notification tapped | payload: ${response.payload}");
        // 👉 navigation can be added later safely
      },
    );

    // 🔹 iOS permission request (IMPORTANT)
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // iOS foreground enable
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  /// 🔹 SHOW NOTIFICATION (Foreground)
  static Future<void> display(RemoteMessage message) async {
    try {
      final notification = message.notification;
      if (notification == null) return;

      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      await _notificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        notification.title ?? 'SONIA PUBLIC SCHOOL',
        notification.body ?? '',
        details,
        payload: message.data.isNotEmpty ? message.data.toString() : null,
      );
    } catch (e) {
      debugPrint("❌ Notification display error: $e");
    }
  }
}
