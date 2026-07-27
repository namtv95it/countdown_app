import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/special_occasion.dart';
import '../models/gift_product.dart';
import '../widgets/gift_product_card.dart';
import '../services/localization_service.dart';
import '../services/sync_service.dart';

class SpecialOccasionScreen extends StatelessWidget {
  final SpecialOccasion occasion;

  const SpecialOccasionScreen({super.key, required this.occasion});

  @override
  Widget build(BuildContext context) {
    final lang = LocalizationService.languageNotifier.value;
    final colors = occasion.colors;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280.0,
            floating: false,
            pinned: true,
            backgroundColor: colors.first,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              titlePadding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
              title: Text(
                occasion.getName(lang),
                textAlign: TextAlign.center,
                style: GoogleFonts.quicksand(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [const Shadow(color: Colors.black38, blurRadius: 8)],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: colors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  Positioned(
                    top: -50,
                    right: -50,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -40,
                    left: -40,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: colors.last.withValues(alpha: 0.4),
                              blurRadius: 40,
                              spreadRadius: 10,
                            )
                          ],
                        ),
                        child: Text(
                          occasion.emoji,
                          style: const TextStyle(fontSize: 80),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.event, color: Colors.white, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              '${occasion.getDateLabel(lang)} • Còn ${occasion.daysRemaining} ngày',
                              style: GoogleFonts.quicksand(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40), // Push up to avoid title
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: StreamBuilder<List<GiftProduct>>(
              stream: SyncService().giftsStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError && snapshot.error == 'no_internet') {
                  return SliverToBoxAdapter(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.wifi_off, color: Colors.white54, size: 48),
                          const SizedBox(height: 16),
                          Text('Vui lòng kết nối mạng để tải dữ liệu', style: GoogleFonts.quicksand(color: Colors.white70, fontSize: 16)),
                        ],
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const SliverToBoxAdapter(
                    child: Center(child: CircularProgressIndicator(color: Color(0xFFEC4899))),
                  );
                }

                final allGifts = snapshot.data ?? [];
                
                // Lọc quà tặng thuộc sự kiện này (Chỉ lấy sản phẩm đã được gán)
                var gifts = allGifts
                    .where((g) => g.occasionIds.contains(occasion.id))
                    .toList();

                if (gifts.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Center(
                      child: Text('Chưa có món quà nào cho sự kiện này.', style: GoogleFonts.quicksand(color: Colors.white54)),
                    ),
                  );
                }

                return SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.58,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return GiftProductCard(
                        gift: gifts[index],
                        themeColor: colors.first,
                      );
                    },
                    childCount: gifts.length,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
