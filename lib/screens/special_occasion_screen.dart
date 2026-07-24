import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/special_occasion.dart';
import '../models/gift_product.dart';
import '../widgets/gift_product_card.dart';
import '../services/localization_service.dart';

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
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            backgroundColor: colors.first,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                occasion.getName(lang),
                style: GoogleFonts.quicksand(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: colors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        occasion.emoji,
                        style: const TextStyle(fontSize: 64),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${occasion.getDateLabel(lang)} - Còn ${occasion.daysRemaining} ngày',
                        style: GoogleFonts.quicksand(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('gifts').orderBy('order').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return SliverToBoxAdapter(
                    child: Center(child: Text('Đã có lỗi xảy ra', style: GoogleFonts.quicksand(color: Colors.white))),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverToBoxAdapter(
                    child: Center(child: CircularProgressIndicator(color: Color(0xFFEC4899))),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                
                // Lọc quà tặng thuộc sự kiện này
                var gifts = docs.map((d) {
                  final data = d.data() as Map<String, dynamic>;
                  return GiftProduct.fromFirestore(d.id, data);
                }).where((g) => g.occasionIds.contains(occasion.id)).toList();

                // Nếu không có quà nào gán riêng cho occasion, dùng categoryId làm fallback
                if (gifts.isEmpty) {
                  gifts = docs.map((d) {
                    final data = d.data() as Map<String, dynamic>;
                    return GiftProduct.fromFirestore(d.id, data);
                  }).where((g) => g.categoryIds.contains(occasion.categoryId)).toList();
                }

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
                    childAspectRatio: 0.65,
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
