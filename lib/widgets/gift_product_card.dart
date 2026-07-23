import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/gift_product.dart';
import '../services/localization_service.dart';

class GiftProductCard extends StatelessWidget {
  final GiftProduct gift;
  final Color themeColor;

  const GiftProductCard({
    super.key,
    required this.gift,
    this.themeColor = const Color(0xFF7C3AED), // Default purple
  });

  Color _brighten(Color c) {
    // Nếu màu quá tối (như màu dark purple hoặc blue), ta làm sáng nó lên bằng cách pha thêm màu trắng
    return Color.lerp(c, Colors.white, 0.3) ?? c;
  }

  Future<void> _launchUrl() async {
    final url = gift.affiliateUrl;
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = LocalizationService.languageNotifier.value;
    final name = gift.getName(lang);

    return GestureDetector(
      onTap: _launchUrl,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image & Badges Section
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Image
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                    child: Container(
                      width: double.infinity,
                      color: Colors.white.withValues(alpha: 0.1),
                      child: CachedNetworkImage(
                        imageUrl: gift.imageUrl,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => const Center(
                          child: Icon(Icons.image_not_supported, color: Colors.white38),
                        ),
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                  ),

                  // Gender Badge
                  if (gift.gender.isNotEmpty && gift.gender != 'unisex')
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          gift.gender == 'male'
                              ? Icons.male
                              : Icons.female,
                          color: gift.gender == 'male' ? Colors.blue : Colors.pink,
                          size: 14,
                        ),
                      ),
                    ),

                  // Custom Badge (e.g. HOT, SALE)
                  if (gift.badge.isNotEmpty)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                          ),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, color: Colors.white, size: 10),
                            const SizedBox(width: 2),
                            Text(
                              gift.badge.toUpperCase(),
                              style: GoogleFonts.quicksand(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Content Section
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  // Name
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.quicksand(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Price
                  Text(
                    gift.priceRange,
                    style: GoogleFonts.quicksand(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: _brighten(themeColor),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Button
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: themeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          gift.platform.toLowerCase().contains('tiktok')
                            ? FaIcon(
                                FontAwesomeIcons.tiktok,
                                size: 11,
                                color: _brighten(themeColor),
                              )
                            : Icon(
                                Icons.shopping_bag_rounded,
                                size: 11,
                                color: _brighten(themeColor),
                              ),
                          const SizedBox(width: 4),
                          Text(
                            gift.platform.isNotEmpty ? gift.platform : 'Xem ngay',
                            style: GoogleFonts.quicksand(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _brighten(themeColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
