class GiftProduct {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final String priceRange;
  final String categoryId;
  final String affiliateUrl;
  final bool isPopular;

  const GiftProduct({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.priceRange,
    required this.categoryId,
    required this.affiliateUrl,
    this.isPopular = false,
  });
}
