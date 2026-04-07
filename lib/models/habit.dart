import 'package:flutter/foundation.dart';

@immutable
class Habit {
  final String id;
  final String title;
  final String? subtitle;
  final bool isCompleted;
  final bool isBonus;
  final DateTime date;

  const Habit({
    required this.id,
    required this.title,
    this.subtitle,
    this.isCompleted = false,
    this.isBonus = false,
    required this.date,
  });

  Habit copyWith({
    String? id,
    String? title,
    String? subtitle,
    bool? isCompleted,
    bool? isBonus,
    DateTime? date,
  }) {
    return Habit(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      isCompleted: isCompleted ?? this.isCompleted,
      isBonus: isBonus ?? this.isBonus,
      date: date ?? this.date,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'is_completed': isCompleted,
      'is_bonus': isBonus,
      'date': date.toIso8601String(),
    };
  }

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'],
      title: json['title'],
      subtitle: json['subtitle'],
      isCompleted: json['is_completed'] ?? false,
      isBonus: json['is_bonus'] ?? false,
      date: DateTime.parse(json['date']),
    );
  }
}
