import 'dart:convert';
import 'package:flutter/material.dart';

class Anniversary {
  final String id;
  final String title;
  final DateTime date;
  final String emoji;
  final int colorValue;
  final bool isYearly;
  final String note;

  Anniversary({
    required this.id,
    required this.title,
    required this.date,
    this.emoji = '🎉',
    this.colorValue = 0xFF7C3AED,
    this.isYearly = false,
    this.note = '',
  });

  Color get color => Color(colorValue);

  /// Nếu sự kiện lặp hàng năm, trả về ngày gần nhất (năm nay hoặc năm sau)
  DateTime get nextOccurrence {
    if (!isYearly) return date;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime candidate = DateTime(now.year, date.month, date.day);
    if (candidate.isBefore(today)) {
      candidate = DateTime(now.year + 1, date.month, date.day);
    }
    return candidate;
  }

  /// Ngày hiển thị (cho sự kiện hàng năm dùng nextOccurrence)
  DateTime get displayDate => isYearly ? nextOccurrence : date;

  /// Số ngày còn lại (âm = đã qua)
  int get daysRemaining {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(
      displayDate.year,
      displayDate.month,
      displayDate.day,
    );
    return target.difference(today).inDays;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'date': date.toIso8601String(),
      'emoji': emoji,
      'colorValue': colorValue,
      'isYearly': isYearly,
      'note': note,
    };
  }

  factory Anniversary.fromMap(Map<String, dynamic> map) {
    return Anniversary(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      date: DateTime.parse(map['date']),
      emoji: map['emoji'] ?? '🎉',
      colorValue: map['colorValue'] ?? 0xFF7C3AED,
      isYearly: map['isYearly'] ?? false,
      note: map['note'] ?? '',
    );
  }

  Anniversary copyWith({
    String? id,
    String? title,
    DateTime? date,
    String? emoji,
    int? colorValue,
    bool? isYearly,
    String? note,
  }) {
    return Anniversary(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      emoji: emoji ?? this.emoji,
      colorValue: colorValue ?? this.colorValue,
      isYearly: isYearly ?? this.isYearly,
      note: note ?? this.note,
    );
  }

  String toJson() => json.encode(toMap());

  factory Anniversary.fromJson(String source) =>
      Anniversary.fromMap(json.decode(source));
}
