import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/habit.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  Future<void> initialize() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');

    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
      onDidReceiveLocalNotification:
          (int id, String? title, String? body, String? payload) async {
        // ไม่ต้องทำอะไรเพิ่มเติมสำหรับ iOS 10 และก่อนหน้า
      },
    );

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        // จัดการเมื่อมีการแตะที่การแจ้งเตือน
        print('Notification clicked: ${response.payload}');
      },
    );
  }

  Future<bool> requestPermissions() async {
    // สำหรับ iOS
    final bool? result = await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    // สำหรับ Android 13 ขึ้นไป (API level 33)
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    final bool? androidResult =
        await androidImplementation?.requestPermission();

    return result ?? androidResult ?? false;
  }

  // ฟังก์ชั่นสำหรับการแปลงรูปแบบเวลา (ใช้แทน timeOfDay.format(context))
  String _formatTimeOfDay(TimeOfDay timeOfDay) {
    final hour = timeOfDay.hour.toString().padLeft(2, '0');
    final minute = timeOfDay.minute.toString().padLeft(2, '0');
    return '$hour:$minute น.';
  }

  // เมธอดใหม่: ตั้งค่าการแจ้งเตือนสำหรับกิจวัตร
  Future<void> scheduleHabitNotification(
    String id,
    String title,
    String description,
    TimeOfDay notificationTime,
  ) async {
    try {
      // สร้าง ID unique สำหรับการแจ้งเตือน
      final int notificationId =
          int.parse(id.hashCode.toString().substring(0, 5).padLeft(5, '0'));

      // สร้างเวลาแจ้งเตือน (วันนี้ แต่เวลาตามที่กำหนด)
      final now = DateTime.now();
      var scheduledTime = DateTime(
        now.year,
        now.month,
        now.day,
        notificationTime.hour,
        notificationTime.minute,
      );

      // ถ้าเวลาที่กำหนดผ่านไปแล้ว ให้ตั้งค่าเป็นวันพรุ่งนี้
      if (scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(Duration(days: 1));
      }

      // สร้างรายละเอียดการแจ้งเตือนสำหรับ Android
      final AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'habit_reminders', // channel id
        'Habit Reminders', // channel name
        channelDescription: 'Notifications for habit reminders',
        importance: Importance.high,
        priority: Priority.high,
        enableLights: true,
        color: Color(0xFF4361EE),
        ledColor: Color(0xFF4361EE),
        ledOnMs: 1000,
        ledOffMs: 500,
      );

      // สร้างรายละเอียดการแจ้งเตือนสำหรับ iOS
      final DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      // สร้างรายละเอียดการแจ้งเตือนสำหรับทั้ง 2 แพลตฟอร์ม
      final NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      // จัดรูปแบบเวลาเป็นสตริง
      final formattedTime = _formatTimeOfDay(notificationTime);

      // กำหนดการแจ้งเตือนแบบเกิดซ้ำทุกวัน
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        'พร้อมทำ$title เวลา$formattedTime',
        description.isNotEmpty ? description : 'ถึงเวลาทำกิจวัตรของคุณแล้ว!',
        tz.TZDateTime.from(scheduledTime, tz.local),
        platformChannelSpecifics,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // ทำให้เกิดซ้ำทุกวัน
        payload: id, // ส่ง ID ของกิจวัตรไปด้วย
      );
    } catch (e) {
      print('Error scheduling notification: $e');
    }
  }

  // เมธอดเดิม (ปรับปรุงชื่อและพารามิเตอร์)
  Future<void> scheduleHabitReminder(Habit habit) async {
    if (habit.notificationEnabled && habit.notificationTime != null) {
      await scheduleHabitNotification(
        habit.id,
        habit.title,
        habit.description,
        habit.notificationTime!,
      );
    }
  }

  // เมธอดเพื่อแสดงการแจ้งเตือนทดสอบ
  Future<void> showTestNotification() async {
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'test_channel',
      'Test Notifications',
      channelDescription: 'For testing notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    final DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails();

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      0,
      'การทดสอบการแจ้งเตือน',
      'นี่คือการแจ้งเตือนทดสอบ หากคุณเห็นข้อความนี้ แสดงว่าการแจ้งเตือนของคุณทำงานได้อย่างถูกต้อง',
      platformChannelSpecifics,
    );
  }

  // ยกเลิกการแจ้งเตือนเฉพาะกิจวัตร
  Future<void> cancelNotification(String id) async {
    final int notificationId =
        int.parse(id.hashCode.toString().substring(0, 5).padLeft(5, '0'));
    await _flutterLocalNotificationsPlugin.cancel(notificationId);
  }

  // ยกเลิกการแจ้งเตือนทั้งหมด
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  // ยกเลิกการแจ้งเตือนสำหรับกิจวัตร (ให้เรียกใช้ชื่อเดียวกับในฟอร์ม)
  Future<void> cancelHabitReminder(String id) async {
    await cancelNotification(id);
  }

  // ดึงการแจ้งเตือนที่กำลังรอ
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
  }
}
