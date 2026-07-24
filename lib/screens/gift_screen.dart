import 'dart:async';
import '../services/localization_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/event_category.dart';
import '../models/gift_product.dart';
import '../models/special_occasion.dart';
import '../services/wish_service.dart';
import '../widgets/gift_product_card.dart';
import 'special_occasion_screen.dart';

class GiftScreen extends StatefulWidget {
  /// Nếu được truyền, sẽ tự động chọn danh mục này ở tab Gợi ý quà
  final String? initialCategoryId;
  final bool isPremium;

  const GiftScreen({super.key, this.initialCategoryId, this.isPremium = false});

  @override
  State<GiftScreen> createState() => _GiftScreenState();
}

class _GiftScreenState extends State<GiftScreen> with SingleTickerProviderStateMixin {
  // ── Gửi lời chúc ──
  final _senderController = TextEditingController();
  final _receiverController = TextEditingController();
  String _selectedCategoryId = 'birthday';
  List<String> _generatedWishes = [];
  bool _isGenerating = false;
  final _wishScrollController = ScrollController();
  final _wishesHeaderKey = GlobalKey(); // dùng để scroll đến đầu danh sách lời chúc

  // ── Native Gift Tab ──
  String _giftCategoryFilter = 'all';
  List<SpecialOccasion> _upcomingEvents = [];
  final ScrollController _giftScrollController = ScrollController();
  bool _isLoadingEvent = true;
  Timer? _carouselTimer;
  int _currentCarouselIndex = 0;
  
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;
  
  late Stream<QuerySnapshot> _giftsStream;

  @override
  void initState() {
    super.initState();
    if (widget.initialCategoryId != null) {
      _giftCategoryFilter = widget.initialCategoryId!;
    }
    
    _blinkController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _blinkAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(_blinkController);
    _blinkController.repeat(reverse: true);
    
    _giftsStream = FirebaseFirestore.instance.collection('gifts').orderBy('order').snapshots();
    
    _loadUpcomingEvents();
  }

  Future<void> _loadUpcomingEvents() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('special_occasions').get();
      if (snap.docs.isNotEmpty) {
        final occasions = snap.docs.map((d) => SpecialOccasion.fromFirestore(d.id, d.data())).toList();
        final upcoming = SpecialOccasion.getUpcomingOccasions(occasions, limit: 5);
        
        if (mounted) {
          setState(() {
            _upcomingEvents = upcoming;
            _isLoadingEvent = false;
          });
          if (upcoming.length > 1) {
            _startCarouselTimer();
          }
        }
      } else {
        if (mounted) {
          setState(() => _isLoadingEvent = false);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingEvent = false);
    }
  }

  void _startCarouselTimer() {
    _carouselTimer?.cancel();
    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        int nextPage = _pageController.page!.round() + 1;
        if (nextPage >= _upcomingEvents.length) {
          nextPage = 0;
        }
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _blinkController.dispose();
    _carouselTimer?.cancel();
    _pageController.dispose();
    _senderController.dispose();
    _receiverController.dispose();
    _wishScrollController.dispose();
    super.dispose();
  }

  void _generateWishes({bool scrollToTop = false}) {
    if (_senderController.text.trim().isEmpty ||
        _receiverController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t('enter_sender_receiver'),
              style: GoogleFonts.quicksand()),
          backgroundColor: const Color(0xFF1A1A2E),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    // Ẩn bàn phím triệt để
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _isGenerating = true);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() {
        _generatedWishes = WishService.generateWishes(
          sender: _senderController.text,
          receiver: _receiverController.text,
          categoryId: _selectedCategoryId,
        );
        _isGenerating = false;
      });
      // Scroll đến đầu danh sách lời chúc sau khi render xong
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final ctx = _wishesHeaderKey.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeInOut,
            alignment: 0.0, // canh lên đầu viewport
          );
        }
      });
    });
  }

  void _copyWish(String wish) {
    Clipboard.setData(ClipboardData(text: wish));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Text('✅ ', style: TextStyle(fontSize: 16)),
            Text(t('wish_copied'),
                style: GoogleFonts.quicksand(fontWeight: FontWeight.w600)),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }



  // ──────────────────────────────────────────────────────────────
  // BUILD
  // ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {

    // Giảm padding nếu đã nâng cấp premium vì quảng cáo bị ẩn
    final double fabBottomPadding = widget.isPremium ? 90.0 : 150.0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: fabBottomPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
          //   FloatingActionButton.small(
          //   heroTag: 'refresh_fab',
          //   onPressed: () => _webViewController.reload(),
          //   backgroundColor: const Color(0xFF1A1A2E),
          //   foregroundColor: Colors.white70,
          //   child: const Icon(Icons.refresh_rounded),
          // ),
          const SizedBox(height: 12),
          SizedBox(
            height: 42,
            child: FloatingActionButton.extended(
              heroTag: 'wish_fab',
              extendedPadding: const EdgeInsets.symmetric(horizontal: 14),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  showDragHandle: true,
                  backgroundColor: const Color(0xFF1A1A2E),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  builder: (context) => FractionallySizedBox(
                    heightFactor: 0.95,
                    child: _buildWishTab(),
                  ),
                );
              },
              backgroundColor: const Color(0xFFEC4899),
              icon: const Icon(Icons.mail_rounded, color: Colors.white, size: 18),
              label: Text(
                t('wish_button_short'),
                style: GoogleFonts.quicksand(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
      ),
      body: SafeArea(
        bottom: false,
        child: _buildGiftTab(),
      ),
    );
  }


  // ──────────────────────────────────────────────────────────────
  // Lời chúc (BottomSheet Content)
  // ──────────────────────────────────────────────────────────────
  Widget _buildWishTab() {
    return ListView(
      controller: _wishScrollController,
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          t('wish_button'),
          style: GoogleFonts.quicksand(
            fontSize: 26, 
            fontWeight: FontWeight.w900, 
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        _buildWishForm(),
        const SizedBox(height: 24),
        if (_isGenerating) _buildShimmerWishes(),
        if (!_isGenerating && _generatedWishes.isNotEmpty) ...[
          Text(
            t('suggested_wishes'),
            key: _wishesHeaderKey,
            style: GoogleFonts.quicksand(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white),
          ),
          const SizedBox(height: 12),
          ..._generatedWishes.map((w) => _buildWishCard(w)),
          const SizedBox(height: 8),
          // Nút Tạo lại ở cuối danh sách
          GestureDetector(
            onTap: () => _generateWishes(scrollToTop: true),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.refresh_rounded,
                      color: Colors.white54, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    t('regenerate_wish'),
                    style: GoogleFonts.quicksand(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white60),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildWishForm() {
    const inputDecoration = BoxDecoration(
      color: Color(0xFF1A1A2E),
      borderRadius: BorderRadius.all(Radius.circular(14)),
    );
    final inputStyle = GoogleFonts.quicksand(
        fontSize: 15, color: Colors.white, fontWeight: FontWeight.w500);
    final hintStyle = GoogleFonts.quicksand(
        fontSize: 15, color: Colors.white38, fontWeight: FontWeight.w400);

    // Categories that support wishes
    final wishCategories = EventCategory.all
        .where((c) =>
            c.id != 'national' && c.id != 'awareness' && c.id != 'profession')
        .toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tên bạn
          Text(t('your_name'),
              style: GoogleFonts.quicksand(
                  fontSize: 13, color: Colors.white54)),
          const SizedBox(height: 6),
          Container(
            decoration: inputDecoration,
            child: TextField(
              controller: _senderController,
              style: inputStyle,
              decoration: InputDecoration(
                hintText: t('sender_hint'),
                hintStyle: hintStyle,
                prefixIcon:
                    const Icon(Icons.person_rounded, color: Colors.white38),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Tên người nhận
          Text(t('receiver_name'),
              style: GoogleFonts.quicksand(
                  fontSize: 13, color: Colors.white54)),
          const SizedBox(height: 6),
          Container(
            decoration: inputDecoration,
            child: TextField(
              controller: _receiverController,
              style: inputStyle,
              decoration: InputDecoration(
                hintText: t('receiver_hint'),
                hintStyle: hintStyle,
                prefixIcon: const Icon(Icons.favorite_rounded,
                    color: Colors.white38),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Dịp
          Text(t('anniversary_occasion'),
              style: GoogleFonts.quicksand(
                  fontSize: 13, color: Colors.white54)),
          const SizedBox(height: 6),
          Container(
            decoration: inputDecoration,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: DropdownButton<String>(
              value: _selectedCategoryId,
              isExpanded: true,
              dropdownColor: const Color(0xFF1A1A2E),
              underline: const SizedBox(),
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: Colors.white54),
              style: inputStyle,
              items: wishCategories
                  .map((c) => DropdownMenuItem(
                        value: c.id,
                        child: Text('${c.emoji}  ${t('cat_${c.id}')}'),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedCategoryId = v);
              },
            ),
          ),
          const SizedBox(height: 20),

          // Nút tạo
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: _generateWishes,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color:
                          const Color(0xFF7C3AED).withValues(alpha: 0.4),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('✨ ', style: TextStyle(fontSize: 16)),
                    Text(
                      t('create_wish'),
                      style: GoogleFonts.quicksand(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWishCard(String wish) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            wish,
            style: GoogleFonts.quicksand(
                fontSize: 14,
                color: Colors.white,
                height: 1.7,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => _copyWish(wish),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color:
                      const Color(0xFF7C3AED).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: const Color(0xFF7C3AED)
                          .withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.copy_rounded,
                        color: Color(0xFFA78BFA), size: 14),
                    const SizedBox(width: 6),
                    Text(t('copy'),
                        style: GoogleFonts.quicksand(
                            fontSize: 13,
                            color: const Color(0xFFA78BFA),
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerWishes() {
    return Column(
      children: List.generate(
        3,
        (i) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: const Color(0xFF7C3AED).withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // TAB 2: Gợi ý quà
  // ──────────────────────────────────────────────────────────────
  Widget _buildGiftTab() {
    return Column(
      children: [
        // 1. Banner Sự Kiện
        if (!_isLoadingEvent && _upcomingEvents.isNotEmpty)
          _buildEventCarousel(),

        // 2. Filter Bar
        _buildCategoryFilterBar(),

        // 3. Grid Sản phẩm (StreamBuilder)
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _giftsStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text('Đã có lỗi xảy ra', style: GoogleFonts.quicksand(color: Colors.white)),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFFEC4899)));
              }

              final docs = snapshot.data?.docs ?? [];
              
              // Lọc thủ công client-side (vì array-contains không support kết hợp orderBy order tốt)
              final gifts = docs.map((d) {
                final data = d.data() as Map<String, dynamic>;
                return GiftProduct.fromFirestore(d.id, data);
              }).where((g) {
                if (_giftCategoryFilter == 'all') return true;
                return g.categoryIds.contains(_giftCategoryFilter);
              }).toList();

              if (gifts.isEmpty) {
                return Center(
                  child: Text('Không có món quà nào phù hợp.', style: GoogleFonts.quicksand(color: Colors.white54)),
                );
              }

              return GridView.builder(
                controller: _giftScrollController,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 250),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.65,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: gifts.length,
                itemBuilder: (context, index) {
                  final gift = gifts[index];
                  final catId = gift.categoryIds.isNotEmpty ? gift.categoryIds.first : null;
                  final catColor = EventCategory.findById(catId).colorValue;
                  // Nếu màu quá tối (như màu dark purple của một số danh mục), có thể mix thêm màu trắng hoặc dùng một màu sáng hơn. 
                  // Tạm thời mình cứ dùng màu của category, nếu category "all" thì dùng màu có sẵn.
                  return GiftProductCard(
                    gift: gift,
                    themeColor: Color(catColor),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  final PageController _pageController = PageController(viewportFraction: 0.93);

  Widget _buildEventCarousel() {
    return Column(
      children: [
        SizedBox(
          height: 120,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentCarouselIndex = index;
              });
            },
            itemCount: _upcomingEvents.length,
        itemBuilder: (context, index) {
          final event = _upcomingEvents[index];
          final lang = LocalizationService.languageNotifier.value;
          final colors = event.colors;

          return GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => SpecialOccasionScreen(occasion: event)));
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: colors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Text(event.emoji, style: const TextStyle(fontSize: 24)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          event.getName(lang),
                          style: GoogleFonts.quicksand(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.calendar_month, color: Colors.white70, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              event.getDateLabel(lang),
                              style: GoogleFonts.quicksand(
                                color: Colors.white70,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        FadeTransition(
                          opacity: _blinkAnimation,
                          child: Text(
                            'Khám phá ngay >>',
                            style: GoogleFonts.quicksand(
                              color: Colors.yellowAccent,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'CÒN',
                          style: GoogleFonts.quicksand(
                            color: Colors.white70,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '${event.daysRemaining}',
                              style: GoogleFonts.quicksand(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 22,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              'NGÀY',
                              style: GoogleFonts.quicksand(
                                color: Colors.white70,
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ),
    if (_upcomingEvents.length > 1) ...[
      const SizedBox(height: 8),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          _upcomingEvents.length,
          (index) => AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: _currentCarouselIndex == index ? 16 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: _currentCarouselIndex == index
                  ? Colors.pinkAccent
                  : Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      ),
    ],
    ],
    );
  }

  Widget _buildCategoryFilterBar() {
    final categories = EventCategory.all.where((c) => c.canSuggestProducts).toList();
    
    return Container(
      height: 46,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildFilterChip('all', 'Tất cả', null, const Color(0xFF8B5CF6)),
          ...categories.map((c) => _buildFilterChip(c.id, c.name, c.emoji, Color(c.colorValue))),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String id, String name, String? emoji, Color color) {
    final isSelected = _giftCategoryFilter == id;
    return GestureDetector(
      onTap: () {
        setState(() {
          _giftCategoryFilter = id;
          // Cuộn lên top mượt mà
          if (_giftScrollController.hasClients) {
            _giftScrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.3),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (emoji != null) ...[
              Text(emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
            ],
            Text(
              name,
              style: GoogleFonts.quicksand(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
