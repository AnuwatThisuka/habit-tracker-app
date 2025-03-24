import 'package:flutter/material.dart';
import 'package:habit_app/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService with ChangeNotifier {
  static const String _darkModeKey = 'darkMode';
  static const String _defaultReminderTimeHourKey = 'defaultReminderTimeHour';
  static const String _defaultReminderTimeMinuteKey =
      'defaultReminderTimeMinute';
  static const String _isFirstTimeUserKey = 'isFirstTimeUser'; // เพิ่มค่าคีย์
  static const String _notificationsEnabledKey =
      'notificationsEnabled'; // เพิ่มค่าคีย์

  SharedPreferences? _prefs;
  bool? _isDarkMode;
  bool? _isFirstTimeUser;
  TimeOfDay? _defaultReminderTime;
  bool? _notificationsEnabled = true;

  SettingsService() {
    _loadPreferences();
  }

  bool? get isDarkMode => _isDarkMode;
  bool? get notificationsEnabled => _notificationsEnabled;
  bool get isFirstTimeUser =>
      _isFirstTimeUser ?? false; // แก้ไขเพื่อให้ค่าเริ่มต้นเป็น false
  TimeOfDay? get defaultReminderTime => _defaultReminderTime;

  Future<void> _loadPreferences() async {
    _prefs = await SharedPreferences.getInstance();

    _isFirstTimeUser = !_prefs!.containsKey(_isFirstTimeUserKey);

    // โหลดค่าธีม
    if (_prefs!.containsKey(_darkModeKey)) {
      _isDarkMode = _prefs!.getBool(_darkModeKey);
    } else {
      _isDarkMode = null; // ใช้ค่าเริ่มต้นของระบบ
    }

    // โหลดค่าการแจ้งเตือน
    if (_prefs!.containsKey(_notificationsEnabledKey)) {
      _notificationsEnabled = _prefs!.getBool(_notificationsEnabledKey);
    } else {
      _notificationsEnabled = true; // ค่าเริ่มต้นเป็น true
    }

    // โหลดค่าเวลาแจ้งเตือนเริ่มต้น
    if (_prefs!.containsKey(_defaultReminderTimeHourKey) &&
        _prefs!.containsKey(_defaultReminderTimeMinuteKey)) {
      final hour = _prefs!.getInt(_defaultReminderTimeHourKey)!;
      final minute = _prefs!.getInt(_defaultReminderTimeMinuteKey)!;
      _defaultReminderTime = TimeOfDay(hour: hour, minute: minute);
    } else {
      _defaultReminderTime =
          TimeOfDay(hour: 20, minute: 0); // ค่าเริ่มต้น 20:00
    }

    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool? value) async {
    if (_notificationsEnabled == value) return;

    _notificationsEnabled = value;
    notifyListeners();

    // บันทึกค่าลงใน SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove('notifications_enabled');
    } else {
      await prefs.setBool('notifications_enabled', value);
    }

    // ถ้าปิดการแจ้งเตือน ให้ยกเลิกการแจ้งเตือนทั้งหมด
    if (value == false) {
      await NotificationService().cancelAllNotifications();
    }
  }

  Future<void> setDarkMode(bool? value) async {
    _isDarkMode = value;
    if (value == null) {
      await _prefs?.remove(_darkModeKey);
    } else {
      await _prefs?.setBool(_darkModeKey, value);
    }
    notifyListeners();
  }

  // เพิ่มเมธอดนี้
  Future<void> setFirstTimeUser(bool value) async {
    _isFirstTimeUser = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_first_time_user', value);
    notifyListeners();
  }

  Future<void> setDefaultReminderTime(TimeOfDay time) async {
    _defaultReminderTime = time;
    await _prefs?.setInt(_defaultReminderTimeHourKey, time.hour);
    await _prefs?.setInt(_defaultReminderTimeMinuteKey, time.minute);
    notifyListeners();
  }

  // เพิ่มเมธอดสำหรับการตั้งค่าเริ่มต้นใน NotificationService
  void resetToDefaults() async {
    _isDarkMode = null;
    _defaultReminderTime = TimeOfDay(hour: 20, minute: 0);

    await _prefs?.remove(_darkModeKey);
    await _prefs?.setInt(_defaultReminderTimeHourKey, 20);
    await _prefs?.setInt(_defaultReminderTimeMinuteKey, 0);
    await _prefs?.setBool(_notificationsEnabledKey, true);

    notifyListeners();
  }
}
