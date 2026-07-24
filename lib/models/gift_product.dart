class GiftProduct {
  final String id;
  final Map<String, String> name;
  final Map<String, String> description;
  final String priceRange;
  final List<String> categoryIds;
  final String affiliateUrl;
  final String imageUrl;
  final String badge;
  final String gender;
  final String platform;
  final int order;
  final List<String> occasionIds;

  const GiftProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.priceRange,
    required this.categoryIds,
    required this.affiliateUrl,
    required this.imageUrl,
    required this.badge,
    required this.gender,
    required this.platform,
    required this.order,
    this.occasionIds = const [],
  });

  String getName(String langCode) {
    return name[langCode] ?? name['vi'] ?? '';
  }

  String getDescription(String langCode) {
    return description[langCode] ?? description['vi'] ?? '';
  }

  factory GiftProduct.fromFirestore(String id, Map<String, dynamic> data) {
    return GiftProduct(
      id: id,
      name: Map<String, String>.from(data['name'] ?? {}),
      description: Map<String, String>.from(data['description'] ?? {}),
      priceRange: data['priceRange'] ?? '',
      categoryIds: List<String>.from(data['categoryIds'] ?? []),
      affiliateUrl: data['affiliateUrl'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      badge: data['badge'] ?? '',
      gender: data['gender'] ?? 'unisex',
      platform: data['platform'] ?? 'Khác',
      order: data['order'] ?? 99999,
      occasionIds: List<String>.from(data['occasionIds'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'priceRange': priceRange,
      'categoryIds': categoryIds,
      'affiliateUrl': affiliateUrl,
      'imageUrl': imageUrl,
      'badge': badge,
      'gender': gender,
      'platform': platform,
      'order': order,
      'occasionIds': occasionIds,
    };
  }
}
