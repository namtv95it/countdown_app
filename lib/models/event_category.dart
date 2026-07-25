/// Danh mục sự kiện — mỗi sự kiện thuộc 1 danh mục.
/// Hỗ trợ đọc/ghi từ Firestore (collection: gift_categories)
class EventCategory {
  final String id;
  final String name;
  final String nameEn;
  final String emoji;
  final int colorValue;
  final bool canSuggestProducts;
  final List<String> suggestedProductTypes;
  final int order;
  final bool isActive;

  const EventCategory({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.emoji,
    required this.colorValue,
    this.canSuggestProducts = false,
    this.suggestedProductTypes = const [],
    this.order = 99,
    this.isActive = true,
  });

  /// Trả về tên theo ngôn ngữ
  String getName(String lang) => lang == 'en' ? nameEn : name;

  /// Tìm category theo [id]. Trả về [other] nếu không tìm thấy.
  static EventCategory findById(String? id, {List<EventCategory>? fromList}) {
    final list = fromList ?? defaultCategories;
    if (id == null || id.isEmpty) return other;
    return list.firstWhere(
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
  // JSON Serialization (Firestore)
  // ──────────────────────────────────────────────────

  factory EventCategory.fromJson(Map<String, dynamic> json) {
    return EventCategory(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      nameEn: json['nameEn'] as String? ?? '',
      emoji: json['emoji'] as String? ?? '📅',
      colorValue: (json['colorValue'] as num?)?.toInt() ?? 0xFF64748B,
      canSuggestProducts: json['canSuggestProducts'] as bool? ?? false,
      suggestedProductTypes: List<String>.from(json['suggestedProductTypes'] ?? []),
      order: (json['order'] as num?)?.toInt() ?? 99,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nameEn': nameEn,
      'emoji': emoji,
      'colorValue': colorValue,
      'canSuggestProducts': canSuggestProducts,
      'suggestedProductTypes': suggestedProductTypes,
      'order': order,
      'isActive': isActive,
    };
  }

  EventCategory copyWith({
    String? id,
    String? name,
    String? nameEn,
    String? emoji,
    int? colorValue,
    bool? canSuggestProducts,
    List<String>? suggestedProductTypes,
    int? order,
    bool? isActive,
  }) {
    return EventCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      nameEn: nameEn ?? this.nameEn,
      emoji: emoji ?? this.emoji,
      colorValue: colorValue ?? this.colorValue,
      canSuggestProducts: canSuggestProducts ?? this.canSuggestProducts,
      suggestedProductTypes: suggestedProductTypes ?? this.suggestedProductTypes,
      order: order ?? this.order,
      isActive: isActive ?? this.isActive,
    );
  }

  // ──────────────────────────────────────────────────
  // Dữ liệu mặc định (fallback khi offline)
  // ──────────────────────────────────────────────────

  static const love = EventCategory(
    id: 'love', name: 'Tình yêu', nameEn: 'Love', emoji: '💝',
    colorValue: 0xFFEC4899, canSuggestProducts: true, order: 1,
    suggestedProductTypes: ['Hoa', 'Chocolate', 'Quà tặng couple', 'Trang sức'],
  );

  static const wedding = EventCategory(
    id: 'wedding', name: 'Cưới xin', nameEn: 'Wedding', emoji: '💍',
    colorValue: 0xFFF472B6, canSuggestProducts: true, order: 2,
    suggestedProductTypes: ['Nhẫn', 'Quà cưới', 'Trang sức', 'Váy cưới'],
  );

  static const birthday = EventCategory(
    id: 'birthday', name: 'Sinh nhật', nameEn: 'Birthday', emoji: '🎂',
    colorValue: 0xFF8B5CF6, canSuggestProducts: true, order: 3,
    suggestedProductTypes: ['Bánh kem', 'Quà tặng', 'Thiệp', 'Đồ trang trí'],
  );

  static const family = EventCategory(
    id: 'family', name: 'Gia đình', nameEn: 'Family', emoji: '👨‍👩‍👧',
    colorValue: 0xFF14B8A6, canSuggestProducts: true, order: 4,
    suggestedProductTypes: ['Quà tặng gia đình', 'Album ảnh', 'Đồ gia dụng'],
  );

  static const festival = EventCategory(
    id: 'festival', name: 'Lễ hội', nameEn: 'Festival', emoji: '🎄',
    colorValue: 0xFF10B981, canSuggestProducts: true, order: 5,
    suggestedProductTypes: ['Đồ trang trí', 'Bánh', 'Quà lễ hội'],
  );

  static const education = EventCategory(
    id: 'education', name: 'Học tập', nameEn: 'Education', emoji: '🎓',
    colorValue: 0xFF3B82F6, canSuggestProducts: true, order: 6,
    suggestedProductTypes: ['Sách', 'Bút', 'Quà khen thưởng'],
  );

  static const gratitude = EventCategory(
    id: 'gratitude', name: 'Tri ân', nameEn: 'Gratitude', emoji: '💐',
    colorValue: 0xFFF59E0B, canSuggestProducts: true, order: 7,
    suggestedProductTypes: ['Hoa', 'Quà tặng tri ân', 'Thiệp'],
  );

  static const achievement = EventCategory(
    id: 'achievement', name: 'Thành tựu', nameEn: 'Achievement', emoji: '🏆',
    colorValue: 0xFFEAB308, canSuggestProducts: true, order: 8,
    suggestedProductTypes: ['Quà kỷ niệm', 'Rượu', 'Thiệp chúc mừng'],
  );

  static const national = EventCategory(
    id: 'national', name: 'Quốc gia', nameEn: 'National', emoji: '🇻🇳',
    colorValue: 0xFFEF4444, canSuggestProducts: false, order: 9,
  );

  static const profession = EventCategory(
    id: 'profession', name: 'Nghề nghiệp', nameEn: 'Profession', emoji: '🩺',
    colorValue: 0xFF059669, canSuggestProducts: false, order: 10,
  );

  static const holiday = EventCategory(
    id: 'holiday', name: 'Kỳ nghỉ', nameEn: 'Holiday', emoji: '🏖️',
    colorValue: 0xFFEF4444, canSuggestProducts: true, order: 11,
    suggestedProductTypes: ['Quà du lịch', 'Quà kỷ niệm', 'Đồ ăn'],
  );

  static const midAutumn = EventCategory(
    id: 'mid_autumn', name: 'Trung thu', nameEn: 'Mid-Autumn', emoji: '🥮',
    colorValue: 0xFFF59E0B, canSuggestProducts: true, order: 12,
    suggestedProductTypes: ['Bánh trung thu', 'Lồng đèn', 'Quà thiếu nhi'],
  );

  static const awareness = EventCategory(
    id: 'awareness', name: 'Nhận thức', nameEn: 'Awareness', emoji: '🌍',
    colorValue: 0xFF06B6D4, canSuggestProducts: false, order: 13,
  );

  static const other = EventCategory(
    id: 'other', name: 'Khác', nameEn: 'Other', emoji: '📅',
    colorValue: 0xFF64748B, canSuggestProducts: false, order: 99,
  );

  /// Danh sách mặc định - dùng làm fallback khi offline
  static const List<EventCategory> defaultCategories = [
    love, wedding, birthday, family, festival, education,
    gratitude, achievement, national, profession, holiday,
    midAutumn, awareness, other,
  ];

  /// Backward compat alias
  static const List<EventCategory> all = defaultCategories;
}
