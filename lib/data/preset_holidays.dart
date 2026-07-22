class PresetHoliday {
  final String title; // Lưu key đa ngôn ngữ, vd: 'h_solar_new_year'
  final int month;
  final int day;
  final String emoji;
  final int colorValue;
  final String badge; // 'vn' hoặc 'intl'
  final bool isLunar;
  final String categoryId;

  const PresetHoliday({
    required this.title,
    required this.month,
    required this.day,
    required this.emoji,
    required this.colorValue,
    required this.badge,
    this.isLunar = false,
    this.categoryId = 'other',
  });
}

class PresetHolidays {
  static const List<PresetHoliday> all = [
    // --- DƯƠNG LỊCH QUỐC TẾ & VIỆT NAM ---
    PresetHoliday(title: 'h_solar_new_year', month: 1, day: 1, emoji: '🎆', colorValue: 0xFFEF4444, badge: 'intl', categoryId: 'festival'),
    PresetHoliday(title: 'h_students_day', month: 1, day: 9, emoji: '🎓', colorValue: 0xFF3B82F6, badge: 'vn', categoryId: 'education'),
    PresetHoliday(title: 'h_cpv_day', month: 2, day: 3, emoji: '🇻🇳', colorValue: 0xFFEF4444, badge: 'vn', categoryId: 'national'),
    PresetHoliday(title: 'h_valentine', month: 2, day: 14, emoji: '💝', colorValue: 0xFFEC4899, badge: 'intl', categoryId: 'love'),
    PresetHoliday(title: 'h_vn_doctors_day', month: 2, day: 27, emoji: '🩺', colorValue: 0xFF10B981, badge: 'vn', categoryId: 'profession'),
    PresetHoliday(title: 'h_womens_day', month: 3, day: 8, emoji: '💐', colorValue: 0xFFEC4899, badge: 'intl', categoryId: 'gratitude'),
    PresetHoliday(title: 'h_intl_happiness_day', month: 3, day: 20, emoji: '😊', colorValue: 0xFFF59E0B, badge: 'intl', categoryId: 'awareness'),
    PresetHoliday(title: 'h_hcm_youth_union', month: 3, day: 26, emoji: '👕', colorValue: 0xFF3B82F6, badge: 'vn', categoryId: 'national'),
    PresetHoliday(title: 'h_april_fools', month: 4, day: 1, emoji: '🃏', colorValue: 0xFF8B5CF6, badge: 'intl', categoryId: 'festival'),
    PresetHoliday(title: 'h_earth_day', month: 4, day: 22, emoji: '🌍', colorValue: 0xFF10B981, badge: 'intl', categoryId: 'awareness'),
    PresetHoliday(title: 'h_liberation_day', month: 4, day: 30, emoji: '🕊️', colorValue: 0xFFEF4444, badge: 'vn', categoryId: 'national'),
    PresetHoliday(title: 'h_labor_day', month: 5, day: 1, emoji: '👷', colorValue: 0xFFF59E0B, badge: 'intl', categoryId: 'profession'),
    PresetHoliday(title: 'h_dien_bien_phu', month: 5, day: 7, emoji: '⚔️', colorValue: 0xFFEF4444, badge: 'vn', categoryId: 'national'),
    PresetHoliday(title: 'h_ho_chi_minh_birthday', month: 5, day: 19, emoji: '🇻🇳', colorValue: 0xFFEF4444, badge: 'vn', categoryId: 'national'),
    PresetHoliday(title: 'h_childrens_day', month: 6, day: 1, emoji: '🎈', colorValue: 0xFFF59E0B, badge: 'intl', categoryId: 'family'),
    PresetHoliday(title: 'h_environment_day', month: 6, day: 5, emoji: '🌱', colorValue: 0xFF10B981, badge: 'intl', categoryId: 'awareness'),
    PresetHoliday(title: 'h_vn_press_day', month: 6, day: 21, emoji: '📰', colorValue: 0xFF3B82F6, badge: 'vn', categoryId: 'profession'),
    PresetHoliday(title: 'h_invalids_martyrs_day', month: 7, day: 27, emoji: '🕯️', colorValue: 0xFFEF4444, badge: 'vn', categoryId: 'national'),
    PresetHoliday(title: 'h_august_revolution', month: 8, day: 19, emoji: '🇻🇳', colorValue: 0xFFEF4444, badge: 'vn', categoryId: 'national'),
    PresetHoliday(title: 'h_national_day', month: 9, day: 2, emoji: '🇻🇳', colorValue: 0xFFEF4444, badge: 'vn', categoryId: 'national'),
    PresetHoliday(title: 'h_womens_day_vn', month: 10, day: 20, emoji: '🌹', colorValue: 0xFFEC4899, badge: 'vn', categoryId: 'gratitude'),
    PresetHoliday(title: 'h_halloween', month: 10, day: 31, emoji: '🎃', colorValue: 0xFFF59E0B, badge: 'intl', categoryId: 'festival'),
    PresetHoliday(title: 'h_mens_day', month: 11, day: 19, emoji: '👨', colorValue: 0xFF3B82F6, badge: 'intl', categoryId: 'gratitude'),
    PresetHoliday(title: 'h_teachers_day', month: 11, day: 20, emoji: '👩‍🏫', colorValue: 0xFF10B981, badge: 'vn', categoryId: 'gratitude'),
    PresetHoliday(title: 'h_vn_peoples_army', month: 12, day: 22, emoji: '🎖️', colorValue: 0xFF8B5CF6, badge: 'vn', categoryId: 'profession'),
    PresetHoliday(title: 'h_christmas', month: 12, day: 25, emoji: '🎄', colorValue: 0xFF10B981, badge: 'intl', categoryId: 'festival'),

    // --- ÂM LỊCH ---
    PresetHoliday(title: 'h_lunar_new_year', month: 1, day: 1, emoji: '🏮', colorValue: 0xFFEF4444, badge: 'vn', isLunar: true, categoryId: 'festival'),
    PresetHoliday(title: 'h_lantern_festival', month: 1, day: 15, emoji: '🌕', colorValue: 0xFFF59E0B, badge: 'vn', isLunar: true, categoryId: 'festival'),
    PresetHoliday(title: 'h_cold_food_festival', month: 3, day: 3, emoji: '🍡', colorValue: 0xFF10B981, badge: 'vn', isLunar: true, categoryId: 'festival'),
    PresetHoliday(title: 'h_hung_kings', month: 3, day: 10, emoji: '🥁', colorValue: 0xFFEF4444, badge: 'vn', isLunar: true, categoryId: 'national'),
    PresetHoliday(title: 'h_vesak', month: 4, day: 15, emoji: '🌸', colorValue: 0xFFF59E0B, badge: 'vn', isLunar: true, categoryId: 'festival'),
    PresetHoliday(title: 'h_duanwu', month: 5, day: 5, emoji: '🥟', colorValue: 0xFF10B981, badge: 'vn', isLunar: true, categoryId: 'festival'),
    PresetHoliday(title: 'h_ghost_festival', month: 7, day: 15, emoji: '🙏', colorValue: 0xFF8B5CF6, badge: 'vn', isLunar: true, categoryId: 'family'),
    PresetHoliday(title: 'h_mid_autumn', month: 8, day: 15, emoji: '🥮', colorValue: 0xFFF59E0B, badge: 'vn', isLunar: true, categoryId: 'festival'),
    PresetHoliday(title: 'h_kitchen_gods', month: 12, day: 23, emoji: '🐟', colorValue: 0xFFEF4444, badge: 'vn', isLunar: true, categoryId: 'festival'),
  ];
}
