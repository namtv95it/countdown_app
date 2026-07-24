import 'package:flutter/material.dart';

class SpecialOccasion {
  final String id;
  final String nameVi;
  final String nameEn;
  final String emoji;
  final int month;
  final int day;
  final String gradient;
  final String categoryId;

  SpecialOccasion({
    required this.id,
    required this.nameVi,
    required this.nameEn,
    required this.emoji,
    required this.month,
    required this.day,
    required this.gradient,
    required this.categoryId,
  });

  factory SpecialOccasion.fromFirestore(String id, Map<String, dynamic> data) {
    return SpecialOccasion(
      id: id,
      nameVi: data['nameVi'] ?? '',
      nameEn: data['nameEn'] ?? '',
      emoji: data['emoji'] ?? '',
      month: data['month'] ?? 1,
      day: data['day'] ?? 1,
      gradient: data['gradient'] ?? '',
      categoryId: data['categoryId'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nameVi': nameVi,
      'nameEn': nameEn,
      'emoji': emoji,
      'month': month,
      'day': day,
      'gradient': gradient,
      'categoryId': categoryId,
    };
  }

  String getName(String langCode) => langCode == 'vi' ? nameVi : nameEn;
  
  String getDateLabel(String langCode) {
    if (langCode == 'vi') {
      return '$day tháng $month';
    } else {
      const enMonths = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final monthStr = (month >= 1 && month <= 12) ? enMonths[month - 1] : 'Jan';
      return '$monthStr $day';
    }
  }

  // Convert "linear-gradient(135deg, #EC4899, #BE185D)" to List<Color>
  List<Color> get colors {
    try {
      final matches = RegExp(r'#([A-Fa-f0-9]{6})').allMatches(gradient);
      if (matches.length >= 2) {
        return matches.map((m) {
          final hexString = m.group(1)!;
          return Color(int.parse('FF$hexString', radix: 16));
        }).toList();
      }
    } catch (_) {}
    return [const Color(0xFF7C3AED), const Color(0xFFEC4899)]; // fallback
  }

  // Calculate days remaining
  int get daysRemaining {
    final now = DateTime.now();
    DateTime occDate = DateTime(now.year, month, day);
    if (occDate.isBefore(DateTime(now.year, now.month, now.day))) {
      occDate = DateTime(now.year + 1, month, day);
    }
    return occDate.difference(DateTime(now.year, now.month, now.day)).inDays;
  }

  // Find the closest upcoming occasion from a list of occasions
  static SpecialOccasion? getClosestOccasion(List<SpecialOccasion> occasions) {
    if (occasions.isEmpty) return null;
    SpecialOccasion? closest;
    int minDays = 999999;

    for (var occ in occasions) {
      final days = occ.daysRemaining;
      if (days < minDays) {
        minDays = days;
        closest = occ;
      }
    }
    return closest;
  }
}
