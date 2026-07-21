import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

import '../models/anniversary.dart';
import 'storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();
    final tzInfo = await FlutterTimezone.getLocalTimezone();
    final String timeZoneName = tzInfo.identifier;
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
            requestSoundPermission: false,
            requestBadgePermission: false,
            requestAlertPermission: false);
            
    const InitializationSettings initializationSettings =
        InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsDarwin);

    await _notificationsPlugin.initialize(settings: initializationSettings);
    _isInitialized = true;
  }

  Future<bool> requestPermissions() async {
    if (Platform.isIOS) {
      final bool? result = await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      return result ?? false;
    } else if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      return status.isGranted;
    }
    return false;
  }

  Future<void> scheduleNotifications() async {
    await _notificationsPlugin.cancelAll();

    final prefs = await SharedPreferences.getInstance();
    final bool notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    
    if (!notificationsEnabled) return;

    final int reminderDays = prefs.getInt('reminder_days') ?? 1;
    final int hour = prefs.getInt('notification_hour') ?? 8;
    final int minute = prefs.getInt('notification_minute') ?? 0;
    final bool soundEnabled = prefs.getBool('sound_enabled') ?? true;

    final StorageService storageService = StorageService();
    final List<Anniversary> events = await storageService.getAnniversaries();

    int idCounter = 0;
    final now = DateTime.now();

    for (final event in events) {
      final eventDate = event.displayDate;
      var notificationDate = eventDate.subtract(Duration(days: reminderDays));
      notificationDate = DateTime(
        notificationDate.year,
        notificationDate.month,
        notificationDate.day,
        hour,
        minute,
      );

      if (notificationDate.isBefore(now)) {
        continue;
      }

      await _scheduleNotification(
        id: idCounter++,
        title: 'Sắp tới: ${event.title} ${event.emoji}',
        body: reminderDays == 0 
            ? 'Hôm nay là ngày kỷ niệm của bạn!'
            : 'Còn $reminderDays ngày nữa là tới ngày ${event.title}.',
        scheduledDate: notificationDate,
        playSound: soundEnabled,
      );
    }
  }

  Future<void> scheduleTestNotification() async {
    print('NotificationService: Bắt đầu hẹn giờ test thông báo sau 5 giây...');
    final prefs = await SharedPreferences.getInstance();
    final bool soundEnabled = prefs.getBool('sound_enabled') ?? true;
    
    print('NotificationService: soundEnabled = $soundEnabled');

    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'countdown_events_channel_v3',
      'Sự kiện đếm ngược',
      channelDescription: 'Nhắc nhở sự kiện sắp tới',
      importance: Importance.max,
      priority: Priority.high,
      playSound: soundEnabled,
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.event,
      fullScreenIntent: true,
    );
    
    final DarwinNotificationDetails darwinPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentSound: soundEnabled,
    );
    
    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: darwinPlatformChannelSpecifics,
    );

    final now = DateTime.now();
    await _notificationsPlugin.zonedSchedule(
      id: 9299,
      title: 'Thông báo thử nghiệm',
      body: 'Cấu hình thông báo của bạn đã hoạt động tốt trên Status Bar!',
      scheduledDate: tz.TZDateTime.from(now.add(const Duration(seconds: 5)), tz.local),
      notificationDetails: platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
    print('NotificationService: Đã đăng ký hẹn giờ (chờ 5s nữa sẽ nổ)...');
    
    // Tạo 1 luồng chờ 5 giây tương đương để in log ra màn hình
    Future.delayed(const Duration(seconds: 5), () {
      print('NotificationService: BOOM! Thông báo đáng lẽ đã xuất hiện trên màn hình khóa/status bar lúc này!');
    });
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required bool playSound,
  }) async {
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'countdown_events_channel_v3',
      'Sự kiện đếm ngược',
      channelDescription: 'Nhắc nhở sự kiện sắp tới',
      importance: Importance.max,
      priority: Priority.high,
      playSound: playSound,
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.event,
      fullScreenIntent: true,
    );
    
    final DarwinNotificationDetails darwinPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentSound: playSound,
    );
    
    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: darwinPlatformChannelSpecifics,
    );

    await _notificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails: platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }
}
