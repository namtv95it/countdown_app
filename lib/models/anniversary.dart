import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lunar/lunar.dart';

class Anniversary {
  final String id;
  final String title;
  final DateTime date; // Nếu isLunar = true, lưu trữ ngày/tháng âm (năm không quan trọng).
  final String emoji;
  final int colorValue;
  final bool isYearly;
  final bool isLunar;
  final String note;

  Anniversary({
    required this.id,
    required this.title,
    required this.date,
    this.emoji = '🎉',
    this.colorValue = 0xFF7C3AED,
    this.isYearly = false,
    this.isLunar = false,
    this.note = '',
  });

  Color get color => Color(colorValue);

  DateTime? _cachedNextOccurrence;
  int? _cachedCalculationDay;

  /// Nếu sự kiện lặp hàng năm, trả về ngày gần nhất (năm nay hoặc năm sau)
  DateTime get nextOccurrence {
    if (!isYearly) return date;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Sử dụng cache nếu đã tính toán trong cùng một ngày
    if (_cachedNextOccurrence != null && _cachedCalculationDay == now.day) {
      return _cachedNextOccurrence!;
    }
    
    DateTime candidate;
    if (isLunar) {
      // date.month và date.day lưu trữ tháng/ngày âm lịch
      Lunar lunar = Lunar.fromYmd(now.year, date.month, date.day);
      Solar solar = lunar.getSolar();
      candidate = DateTime(solar.getYear(), solar.getMonth(), solar.getDay());
      
      if (candidate.isBefore(today)) {
        Lunar nextLunar = Lunar.fromYmd(now.year + 1, date.month, date.day);
        Solar nextSolar = nextLunar.getSolar();
        candidate = DateTime(nextSolar.getYear(), nextSolar.getMonth(), nextSolar.getDay());
      }
    } else {
      candidate = DateTime(now.year, date.month, date.day);
      if (candidate.isBefore(today)) {
        candidate = DateTime(now.year + 1, date.month, date.day);
      }
    }
    
    _cachedNextOccurrence = candidate;
    _cachedCalculationDay = now.day;
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
      'isLunar': isLunar,
      'note': note,
    };
  }

  factory Anniversary.fromMap(Map<String, dynamic> map) {
    return Anniversary(
      id: map['id'] as String,
      title: map['title'] as String,
      date: DateTime.parse(map['date'] as String),
      emoji: map['emoji'] as String? ?? '🎉',
      colorValue: map['colorValue'] as int? ?? 0xFF7C3AED,
      isYearly: map['isYearly'] as bool? ?? false,
      isLunar: map['isLunar'] as bool? ?? false,
      note: map['note'] as String? ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory Anniversary.fromJson(String source) =>
      Anniversary.fromMap(json.decode(source));

  Anniversary copyWith({
    String? id,
    String? title,
    DateTime? date,
    String? emoji,
    int? colorValue,
    bool? isYearly,
    bool? isLunar,
    String? note,
  }) {
    return Anniversary(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      emoji: emoji ?? this.emoji,
      colorValue: colorValue ?? this.colorValue,
      isYearly: isYearly ?? this.isYearly,
      isLunar: isLunar ?? this.isLunar,
      note: note ?? this.note,
    );
  }

}
