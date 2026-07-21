/// Danh mục sự kiện — mỗi sự kiện thuộc 1 danh mục.
/// Mỗi danh mục có emoji, màu, và cờ [canSuggestProducts]
/// để sau này gắn gợi ý mua hàng.
class EventCategory {
  final String id;
  final String name;
  final String emoji;
  final int colorValue;
  final bool canSuggestProducts;
  final List<String> suggestedProductTypes;

  const EventCategory({
    required this.id,
    required this.name,
    required this.emoji,
    required this.colorValue,
    this.canSuggestProducts = false,
    this.suggestedProductTypes = const [],
  });

  /// Tìm category theo [id]. Trả về [other] nếu không tìm thấy.
  static EventCategory findById(String? id) {
    if (id == null || id.isEmpty) return other;
    return all.firstWhere(
      (c) => c.id == id,
      orElse: () => other,
    );
  }

  /// Thử map emoji cũ sang category (backward compatibility).
  static EventCategory fromLegacyEmoji(String emoji) {
    const emojiMap = {
      '💝': 'love',
      '❤️': 'love',
      '💑': 'love',
      '💍': 'wedding',
      '🎂': 'birthday',
      '🎁': 'birthday',
      '👶': 'family',
      '🎄': 'festival',
      '🎃': 'festival',
      '🏮': 'festival',
      '🥮': 'festival',
      '🎓': 'education',
      '💐': 'gratitude',
      '🌹': 'gratitude',
      '🌺': 'gratitude',
      '🏆': 'achievement',
      '🥂': 'achievement',
      '🇻🇳': 'national',
      '🩺': 'profession',
      '👩‍🏫': 'profession',
      '📰': 'profession',
      '🪖': 'profession',
      '👷': 'profession',
      '🌍': 'awareness',
      '🌱': 'awareness',
    };
    final categoryId = emojiMap[emoji];
    if (categoryId != null) return findById(categoryId);
    return other;
  }

  // ──────────────────────────────────────────────────
  // Danh sách tất cả danh mục
  // ──────────────────────────────────────────────────

  static const love = EventCategory(
    id: 'love',
    name: 'Tình yêu',
    emoji: '💝',
    colorValue: 0xFFEC4899,
    canSuggestProducts: true,
    suggestedProductTypes: ['Hoa', 'Chocolate', 'Quà tặng couple', 'Trang sức'],
  );

  static const wedding = EventCategory(
    id: 'wedding',
    name: 'Cưới xin',
    emoji: '💍',
    colorValue: 0xFFF472B6,
    canSuggestProducts: true,
    suggestedProductTypes: ['Nhẫn', 'Quà cưới', 'Trang sức', 'Váy cưới'],
  );

  static const birthday = EventCategory(
    id: 'birthday',
    name: 'Sinh nhật',
    emoji: '🎂',
    colorValue: 0xFF8B5CF6,
    canSuggestProducts: true,
    suggestedProductTypes: ['Bánh kem', 'Quà tặng', 'Thiệp', 'Đồ trang trí'],
  );

  static const family = EventCategory(
    id: 'family',
    name: 'Gia đình',
    emoji: '👨‍👩‍👧',
    colorValue: 0xFF14B8A6,
    canSuggestProducts: true,
    suggestedProductTypes: ['Quà tặng gia đình', 'Album ảnh', 'Đồ gia dụng'],
  );

  static const festival = EventCategory(
    id: 'festival',
    name: 'Lễ hội',
    emoji: '🎄',
    colorValue: 0xFF10B981,
    canSuggestProducts: true,
    suggestedProductTypes: ['Đồ trang trí', 'Bánh', 'Quà lễ hội'],
  );

  static const education = EventCategory(
    id: 'education',
    name: 'Học tập',
    emoji: '🎓',
    colorValue: 0xFF3B82F6,
    canSuggestProducts: true,
    suggestedProductTypes: ['Sách', 'Bút', 'Quà khen thưởng'],
  );

  static const gratitude = EventCategory(
    id: 'gratitude',
    name: 'Tri ân',
    emoji: '💐',
    colorValue: 0xFFF59E0B,
    canSuggestProducts: true,
    suggestedProductTypes: ['Hoa', 'Quà tặng tri ân', 'Thiệp'],
  );

  static const achievement = EventCategory(
    id: 'achievement',
    name: 'Thành tựu',
    emoji: '🏆',
    colorValue: 0xFFEAB308,
    canSuggestProducts: true,
    suggestedProductTypes: ['Quà kỷ niệm', 'Rượu', 'Thiệp chúc mừng'],
  );

  static const national = EventCategory(
    id: 'national',
    name: 'Quốc gia',
    emoji: '🇻🇳',
    colorValue: 0xFFEF4444,
    canSuggestProducts: false,
  );

  static const profession = EventCategory(
    id: 'profession',
    name: 'Nghề nghiệp',
    emoji: '🩺',
    colorValue: 0xFF059669,
    canSuggestProducts: false,
  );

  static const awareness = EventCategory(
    id: 'awareness',
    name: 'Nhận thức',
    emoji: '🌍',
    colorValue: 0xFF06B6D4,
    canSuggestProducts: false,
  );

  static const other = EventCategory(
    id: 'other',
    name: 'Khác',
    emoji: '📅',
    colorValue: 0xFF64748B,
    canSuggestProducts: false,
  );

  static const List<EventCategory> all = [
    love,
    wedding,
    birthday,
    family,
    festival,
    education,
    gratitude,
    achievement,
    national,
    profession,
    awareness,
    other,
  ];
}
