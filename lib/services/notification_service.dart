import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io' show Platform;
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    await requestPermission();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(settings);
    _initialized = true;
  }

  static Future<void> _requestPermissions() async {
    await _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  static Future<void> showUpdateApprovedNotification({
    required String title,
    required String body,
    required String type,
    required String severity,
    required String location,
  }) async {
    await init();

    const androidDetails = AndroidNotificationDetails(
      'update_alerts',
      'Update Alerts',
      channelDescription: 'Notifications for approved updates',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final notificationBody = '$body\nLocation: $location';

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'New Alert: $title',
      notificationBody,
      details,
      payload: 'update_approved',
    );
  }

  static Future<void> requestPermission() async {
    // For iOS
    if (Platform.isIOS) {
      final iosImplementation = _notifications
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      
      final granted = await iosImplementation?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      
      if (granted == false) {
        print('iOS notification permissions not granted');
      }
    }
    
    // For Android
    if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      if (status.isDenied) {
        // Request the permission
        final result = await Permission.notification.request();
        if (result.isDenied) {
          print('Android notification permissions not granted');
        }
      }
    }
  }
}
