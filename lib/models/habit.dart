import 'package:flutter/material.dart';

class Habit {
  String id;
  String title;
  String description;
  final DateTime createdAt;
  final IconData icon;
  List<bool> completedDays;
  Color color;
  TimeOfDay? notificationTime;
  bool notificationEnabled;
  int streak;
  String? category; // เพิ่มฟิลด์หมวดหมู่
  int? priority; // เพิ่มฟิลด์ความสำคัญ (1-3)
  final List<int> frequency; // เพิ่ม property นี้

  Habit({
    required this.id,
    required this.title,
    this.description = '',
    required this.createdAt,
    required this.icon,
    required this.completedDays,
    required this.color,
    this.notificationTime,
    this.notificationEnabled = false,
    this.streak = 0,
    this.category, // เพิ่มพารามิเตอร์สำหรับหมวดหมู่
    this.priority, // เพิ่มพารามิเตอร์สำหรับความสำคัญ
    required this.frequency, // เพิ่มพารามิเตอร์ในคอนสตรัคเตอร์
  });

  // Clone method for creating copies (useful when editing)
  Habit clone() {
    return Habit(
      id: id,
      title: title,
      description: description,
      createdAt: createdAt,
      icon: icon,
      completedDays: List<bool>.from(completedDays),
      color: color,
      notificationTime: notificationTime,
      notificationEnabled: notificationEnabled,
      streak: streak,
      category: category,
      priority: priority,
      frequency: List<int>.from(frequency),
    );
  }

  // Method to toggle completion for a day
  void toggleDay(int dayIndex) {
    if (dayIndex >= 0 && dayIndex < completedDays.length) {
      completedDays[dayIndex] = !completedDays[dayIndex];
      // Update streak after toggling
      calculateStreak();
    }
  }

  // Method to calculate the current streak
  void calculateStreak() {
    streak = 0;
    int currentStreak = 0;

    // Calculate streak from most recent days
    for (int i = completedDays.length - 1; i >= 0; i--) {
      if (completedDays[i]) {
        currentStreak++;
      } else {
        break; // Break at first non-completed day
      }
    }

    streak = currentStreak;
  }

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'completedDays': completedDays,
      'colorValue': color.value,
      'notificationHour': notificationTime?.hour,
      'notificationMinute': notificationTime?.minute,
      'notificationEnabled': notificationEnabled,
      'streak': streak,
      'category': category, // เพิ่มการบันทึกหมวดหมู่
      'priority': priority, // เพิ่มการบันทึกความสำคัญ
      'frequency': frequency, // เพิ่มการบันทึกความถี่
    };
  }

  // Create from JSON when loading from storage
  factory Habit.fromJson(Map<String, dynamic> json) {
    // Convert completedDays from List<dynamic> to List<bool>
    List<bool> completedDaysList = [];
    if (json['completedDays'] != null) {
      for (var day in json['completedDays']) {
        completedDaysList.add(day as bool);
      }
    }

    TimeOfDay? notificationTime;
    if (json['notificationHour'] != null &&
        json['notificationMinute'] != null) {
      notificationTime = TimeOfDay(
        hour: json['notificationHour'],
        minute: json['notificationMinute'],
      );
    }

    return Habit(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      icon: IconData(
        json['iconCodePoint'],
        fontFamily: json['iconFontFamily'],
      ),
      completedDays: completedDaysList,
      color: Color(json['colorValue']),
      notificationTime: notificationTime,
      notificationEnabled: json['notificationEnabled'] ?? false,
      streak: json['streak'] ?? 0,
      category: json['category'], // อ่านหมวดหมู่จาก JSON
      priority: json['priority'], // อ่านความสำคัญจาก JSON
      frequency: (json['frequency'] as List<dynamic>)
          .cast<int>(), // อ่านความถี่จาก JSON
    );
  }
}
