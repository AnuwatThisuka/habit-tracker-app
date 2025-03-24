import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:habit_app/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/habit.dart';
import 'package:uuid/uuid.dart';

class HabitService extends ChangeNotifier {
  final _notificationService = NotificationService();

  List<Habit> _habits = [];
  final String _storageKey = 'habits';
  var uuid = Uuid();
  bool _isLoading = true;

  List<Habit> get habits => _habits;
  bool get isLoading => _isLoading;

  HabitService() {
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    _isLoading = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final habitsJson = prefs.getStringList(_storageKey) ?? [];

      _habits = habitsJson
          .map((habitJson) => Habit.fromJson(jsonDecode(habitJson)))
          .toList();

      // ตรวจสอบและทำให้แน่ใจว่าทุก habit มี completedDays ที่มีขนาดเพียงพอ
      _ensureCompletedDaysLength();
    } catch (e) {
      debugPrint('Error loading habits: $e');
      _habits = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveHabits() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final habitsJson =
          _habits.map((habit) => jsonEncode(habit.toJson())).toList();

      await prefs.setStringList(_storageKey, habitsJson);
    } catch (e) {
      debugPrint('Error saving habits: $e');
    }
  }

  // ทำให้แน่ใจว่า completedDays มีจำนวนเพียงพอสำหรับวันนี้
  void _ensureCompletedDaysLength() {
    final now = DateTime.now();

    for (var habit in _habits) {
      final daysRequired = now.difference(habit.createdAt).inDays + 1;

      // ถ้ามีวันไม่พอ ให้เพิ่มวันที่เหลือ
      if (habit.completedDays.length < daysRequired) {
        final daysToAdd = daysRequired - habit.completedDays.length;
        habit.completedDays.addAll(List.filled(daysToAdd, false));
      }

      // อัปเดต streak
      _updateStreak(habit);
    }
  }

  Future<void> addHabit(Habit habit) async {
    try {
      habit.id = uuid.v4();

      // ทำให้แน่ใจว่ามีพื้นที่เพียงพอสำหรับวันนี้
      final now = DateTime.now();
      final daysRequired = now.difference(habit.createdAt).inDays + 1;

      if (habit.completedDays.isEmpty) {
        habit.completedDays = List.filled(daysRequired, false);
      }

      _habits.add(habit);
      await _saveHabits();

      if (habit.notificationEnabled && habit.notificationTime != null) {
        await _notificationService.scheduleHabitReminder(habit);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error adding habit: $e');
      rethrow; // ส่งต่อข้อผิดพลาดให้ UI จัดการ
    }
  }

  Future<void> updateHabit(Habit habit) async {
    try {
      final index = _habits.indexWhere((h) => h.id == habit.id);
      if (index != -1) {
        // เก็บวันที่ทำสำเร็จไว้
        final completedDays = _habits[index].completedDays;
        habit.completedDays = completedDays;

        _habits[index] = habit;

        // อัปเดต streak
        _updateStreak(_habits[index]);

        await _saveHabits();

        // ยกเลิกการแจ้งเตือนเดิมก่อน
        await _notificationService.cancelHabitReminder(habit.id);

        // ตั้งค่าการแจ้งเตือนใหม่ ถ้าเปิดใช้งาน
        if (habit.notificationEnabled && habit.notificationTime != null) {
          await _notificationService.scheduleHabitReminder(habit);
        }

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating habit: $e');
      rethrow; // ส่งต่อข้อผิดพลาดให้ UI จัดการ
    }
  }

  Future<void> deleteHabit(String id) async {
    try {
      // ยกเลิกการแจ้งเตือนก่อนลบ
      await _notificationService.cancelHabitReminder(id);

      _habits.removeWhere((habit) => habit.id == id);
      await _saveHabits();
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting habit: $e');
      rethrow;
    }
  }

  Future<void> toggleHabitCompletion(String id, int dayIndex) async {
    try {
      final index = _habits.indexWhere((h) => h.id == id);
      if (index != -1) {
        // ถ้า completedDays ไม่มีขนาดเพียงพอ
        if (dayIndex >= _habits[index].completedDays.length) {
          final daysToAdd = dayIndex + 1 - _habits[index].completedDays.length;
          _habits[index].completedDays.addAll(List.filled(daysToAdd, false));
        }

        _habits[index].completedDays[dayIndex] =
            !_habits[index].completedDays[dayIndex];

        // อัพเดท streak
        _updateStreak(_habits[index]);

        await _saveHabits();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error toggling habit completion: $e');
    }
  }

  void _updateStreak(Habit habit) {
    try {
      int streak = 0;
      final today = DateTime.now().difference(habit.createdAt).inDays;

      // ตรวจสอบว่า completedDays มีขนาดเพียงพอ
      if (habit.completedDays.length <= today) {
        final daysToAdd = today + 1 - habit.completedDays.length;
        habit.completedDays.addAll(List.filled(daysToAdd, false));
      }

      // ตรวจสอบวันนี้ก่อน
      if (habit.completedDays[today]) {
        streak = 1;

        // นับย้อนหลังจากเมื่อวาน
        for (int i = today - 1; i >= 0; i--) {
          if (i < habit.completedDays.length && habit.completedDays[i]) {
            streak++;
          } else {
            break;
          }
        }
      } else {
        // นับย้อนหลังจากเมื่อวาน
        for (int i = today - 1; i >= 0; i--) {
          if (i < habit.completedDays.length && habit.completedDays[i]) {
            streak++;
          } else {
            break;
          }
        }
      }

      habit.streak = streak;
    } catch (e) {
      debugPrint('Error updating streak: $e');
    }
  }

  // เมธอดใหม่: เรียงลำดับกิจวัตรตามชื่อ
  void sortHabitsByName({bool ascending = true}) {
    _habits.sort((a, b) =>
        ascending ? a.title.compareTo(b.title) : b.title.compareTo(a.title));
    notifyListeners();
  }

  // เมธอดใหม่: เรียงลำดับกิจวัตรตาม streak
  void sortHabitsByStreak({bool ascending = false}) {
    _habits.sort((a, b) => ascending
        ? a.streak.compareTo(b.streak)
        : b.streak.compareTo(a.streak));
    notifyListeners();
  }

  // เมธอดใหม่: นับจำนวนกิจวัตรที่ทำสำเร็จวันนี้
  int getCompletedTodayCount() {
    final now = DateTime.now();
    int count = 0;

    for (var habit in _habits) {
      final dayIndex = now.difference(habit.createdAt).inDays;
      if (dayIndex < habit.completedDays.length &&
          habit.completedDays[dayIndex]) {
        count++;
      }
    }

    return count;
  }

  // เมธอดใหม่: รีเซ็ตข้อมูลทั้งหมด (สำหรับการทดสอบหรือเริ่มต้นใหม่)
  Future<void> resetAllData() async {
    try {
      for (var habit in _habits) {
        await _notificationService.cancelHabitReminder(habit.id);
      }

      _habits = [];
      await _saveHabits();
      notifyListeners();
    } catch (e) {
      debugPrint('Error resetting data: $e');
    }
  }

  Future<void> refreshHabits() async {
    // รีเฟรชข้อมูลจาก storage
    await _loadHabits();
    // อัพเดท streak และความเสร็จสมบูรณ์
    _ensureCompletedDaysLength();
    notifyListeners();
  }

  void sortHabitsByCreationDate({bool ascending = false}) {
    _habits.sort((a, b) => ascending
        ? a.createdAt.compareTo(b.createdAt)
        : b.createdAt.compareTo(a.createdAt));
    notifyListeners();
  }
}
