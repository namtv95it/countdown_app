class PresetHoliday {
  final String title;
  final int month;
  final int day;
  final String emoji;
  final int colorValue;
  final String badge;
  final bool isLunar;

  const PresetHoliday({
    required this.title,
    required this.month,
    required this.day,
    required this.emoji,
    required this.colorValue,
    required this.badge,
    this.isLunar = false,
  });
}

class PresetHolidays {
  static const List<PresetHoliday> all = [
    // --- DƯƠNG LỊCH QUỐC TẾ & VIỆT NAM ---
    PresetHoliday(title: 'Tết Dương lịch', month: 1, day: 1, emoji: '🎆', colorValue: 0xFFEF4444, badge: 'Quốc tế'),
    PresetHoliday(title: 'Học sinh - Sinh viên', month: 1, day: 9, emoji: '🎓', colorValue: 0xFF3B82F6, badge: 'Việt Nam'),
    PresetHoliday(title: 'Thành lập Đảng', month: 2, day: 3, emoji: '🇻🇳', colorValue: 0xFFEF4444, badge: 'Việt Nam'),
    PresetHoliday(title: 'Lễ Tình nhân', month: 2, day: 14, emoji: '💝', colorValue: 0xFFEC4899, badge: 'Quốc tế'),
    PresetHoliday(title: 'Thầy thuốc Việt Nam', month: 2, day: 27, emoji: '🩺', colorValue: 0xFF10B981, badge: 'Việt Nam'),
    PresetHoliday(title: 'Quốc tế Phụ nữ', month: 3, day: 8, emoji: '💐', colorValue: 0xFFEC4899, badge: 'Quốc tế'),
    PresetHoliday(title: 'Quốc tế Hạnh phúc', month: 3, day: 20, emoji: '😊', colorValue: 0xFFF59E0B, badge: 'Quốc tế'),
    PresetHoliday(title: 'Thành lập Đoàn', month: 3, day: 26, emoji: '👕', colorValue: 0xFF3B82F6, badge: 'Việt Nam'),
    PresetHoliday(title: 'Cá tháng Tư', month: 4, day: 1, emoji: '🃏', colorValue: 0xFF8B5CF6, badge: 'Quốc tế'),
    PresetHoliday(title: 'Ngày Trái Đất', month: 4, day: 22, emoji: '🌍', colorValue: 0xFF10B981, badge: 'Quốc tế'),
    PresetHoliday(title: 'Giải phóng miền Nam', month: 4, day: 30, emoji: '🕊️', colorValue: 0xFFEF4444, badge: 'Việt Nam'),
    PresetHoliday(title: 'Quốc tế Lao động', month: 5, day: 1, emoji: '👷', colorValue: 0xFFF59E0B, badge: 'Quốc tế'),
    PresetHoliday(title: 'Chiến thắng Điện Biên', month: 5, day: 7, emoji: '⚔️', colorValue: 0xFFEF4444, badge: 'Việt Nam'),
    PresetHoliday(title: 'Sinh nhật Bác', month: 5, day: 19, emoji: '🇻🇳', colorValue: 0xFFEF4444, badge: 'Việt Nam'),
    PresetHoliday(title: 'Quốc tế Thiếu nhi', month: 6, day: 1, emoji: '🎈', colorValue: 0xFFF59E0B, badge: 'Quốc tế'),
    PresetHoliday(title: 'Môi trường Thế giới', month: 6, day: 5, emoji: '🌱', colorValue: 0xFF10B981, badge: 'Quốc tế'),
    PresetHoliday(title: 'Báo chí Cách mạng', month: 6, day: 21, emoji: '📰', colorValue: 0xFF3B82F6, badge: 'Việt Nam'),
    PresetHoliday(title: 'Thương binh Liệt sĩ', month: 7, day: 27, emoji: '🕯️', colorValue: 0xFFEF4444, badge: 'Việt Nam'),
    PresetHoliday(title: 'Cách mạng tháng Tám', month: 8, day: 19, emoji: '🇻🇳', colorValue: 0xFFEF4444, badge: 'Việt Nam'),
    PresetHoliday(title: 'Quốc khánh', month: 9, day: 2, emoji: '🇻🇳', colorValue: 0xFFEF4444, badge: 'Việt Nam'),
    PresetHoliday(title: 'Phụ nữ Việt Nam', month: 10, day: 20, emoji: '🌹', colorValue: 0xFFEC4899, badge: 'Việt Nam'),
    PresetHoliday(title: 'Halloween', month: 10, day: 31, emoji: '🎃', colorValue: 0xFFF59E0B, badge: 'Quốc tế'),
    PresetHoliday(title: 'Quốc tế Nam giới', month: 11, day: 19, emoji: '👨', colorValue: 0xFF3B82F6, badge: 'Quốc tế'),
    PresetHoliday(title: 'Nhà giáo Việt Nam', month: 11, day: 20, emoji: '👩‍🏫', colorValue: 0xFF10B981, badge: 'Việt Nam'),
    PresetHoliday(title: 'Quân đội Nhân dân', month: 12, day: 22, emoji: '🪖', colorValue: 0xFF8B5CF6, badge: 'Việt Nam'),
    PresetHoliday(title: 'Lễ Giáng sinh', month: 12, day: 25, emoji: '🎄', colorValue: 0xFF10B981, badge: 'Quốc tế'),

    // --- ÂM LỊCH ---
    PresetHoliday(title: 'Tết Nguyên đán', month: 1, day: 1, emoji: '🏮', colorValue: 0xFFEF4444, badge: 'Việt Nam', isLunar: true),
    PresetHoliday(title: 'Tết Nguyên tiêu', month: 1, day: 15, emoji: '🌕', colorValue: 0xFFF59E0B, badge: 'Việt Nam', isLunar: true),
    PresetHoliday(title: 'Tết Hàn thực', month: 3, day: 3, emoji: '🍡', colorValue: 0xFF10B981, badge: 'Việt Nam', isLunar: true),
    PresetHoliday(title: 'Giỗ Tổ Hùng Vương', month: 3, day: 10, emoji: '🥁', colorValue: 0xFFEF4444, badge: 'Việt Nam', isLunar: true),
    PresetHoliday(title: 'Lễ Phật Đản', month: 4, day: 15, emoji: '🪷', colorValue: 0xFFF59E0B, badge: 'Việt Nam', isLunar: true),
    PresetHoliday(title: 'Tết Đoan ngọ', month: 5, day: 5, emoji: '🥟', colorValue: 0xFF10B981, badge: 'Việt Nam', isLunar: true),
    PresetHoliday(title: 'Lễ Vu Lan', month: 7, day: 15, emoji: '🙏', colorValue: 0xFF8B5CF6, badge: 'Việt Nam', isLunar: true),
    PresetHoliday(title: 'Tết Trung thu', month: 8, day: 15, emoji: '🥮', colorValue: 0xFFF59E0B, badge: 'Việt Nam', isLunar: true),
    PresetHoliday(title: 'Ông Công Ông Táo', month: 12, day: 23, emoji: '🐟', colorValue: 0xFFEF4444, badge: 'Việt Nam', isLunar: true),
  ];
}
