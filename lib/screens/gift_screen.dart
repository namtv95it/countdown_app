import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/gift_products.dart';
import '../models/event_category.dart';
import '../models/gift_product.dart';
import '../services/wish_service.dart';

class GiftScreen extends StatefulWidget {
  /// Nếu được truyền, sẽ tự động chọn danh mục này ở tab Gợi ý quà
  final String? initialCategoryId;

  const GiftScreen({super.key, this.initialCategoryId});

  @override
  State<GiftScreen> createState() => _GiftScreenState();
}

class _GiftScreenState extends State<GiftScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ── Gửi lời chúc ──
  final _senderController = TextEditingController();
  final _receiverController = TextEditingController();
  String _selectedCategoryId = 'birthday';
  List<String> _generatedWishes = [];
  bool _isGenerating = false;
  final _wishScrollController = ScrollController();
  final _wishesHeaderKey = GlobalKey(); // dùng để scroll đến đầu danh sách lời chúc

  // ── Gợi ý quà ──
  String? _filterCategoryId;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: 0, // Gift tab is now index 0
    );
    if (widget.initialCategoryId != null) {
      _filterCategoryId = widget.initialCategoryId;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _senderController.dispose();
    _receiverController.dispose();
    _searchController.dispose();
    _wishScrollController.dispose();
    super.dispose();
  }

  void _generateWishes({bool scrollToTop = false}) {
    if (_senderController.text.trim().isEmpty ||
        _receiverController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vui lòng nhập tên người gửi và người nhận',
              style: GoogleFonts.quicksand()),
          backgroundColor: const Color(0xFF1A1A2E),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    // Ẩn bàn phím
    FocusScope.of(context).unfocus();
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
            Text('Đã copy lời chúc!',
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

  List<GiftProduct> get _filteredProducts {
    var list = _filterCategoryId != null
        ? GiftProducts.byCategory(_filterCategoryId)
        : GiftProducts.all;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((p) =>
              p.name.toLowerCase().contains(q) ||
              p.description.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  // ──────────────────────────────────────────────────────────────
  // BUILD
  // ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildGiftTab(),
                  _buildWishTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('🎁', style: TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 12),
          Text(
            'Quà Tặng',
            style: GoogleFonts.quicksand(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelStyle: GoogleFonts.quicksand(
            fontSize: 14, fontWeight: FontWeight.w700),
        unselectedLabelStyle:
            GoogleFonts.quicksand(fontSize: 14, fontWeight: FontWeight.w500),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white54,
        tabs: const [
          Tab(text: '🛍️ Gợi ý quà'),
          Tab(text: '💌 Lời chúc'),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // TAB 1: Lời chúc
  // ──────────────────────────────────────────────────────────────
  Widget _buildWishTab() {
    return ListView(
      controller: _wishScrollController,
      padding: const EdgeInsets.all(20),
      children: [
        _buildWishForm(),
        const SizedBox(height: 24),
        if (_isGenerating) _buildShimmerWishes(),
        if (!_isGenerating && _generatedWishes.isNotEmpty) ...[
          Text(
            '✨ Lời chúc gợi ý',
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
                    'Tạo lại lời chúc khác',
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
          Text('💌 Tạo lời chúc',
              style: GoogleFonts.quicksand(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Colors.white)),
          const SizedBox(height: 16),

          // Tên bạn
          Text('Tên bạn (xưng)',
              style: GoogleFonts.quicksand(
                  fontSize: 13, color: Colors.white54)),
          const SizedBox(height: 6),
          Container(
            decoration: inputDecoration,
            child: TextField(
              controller: _senderController,
              style: inputStyle,
              decoration: InputDecoration(
                hintText: 'VD: Nam, Lan, anh Hùng...',
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
          Text('Tên người nhận',
              style: GoogleFonts.quicksand(
                  fontSize: 13, color: Colors.white54)),
          const SizedBox(height: 6),
          Container(
            decoration: inputDecoration,
            child: TextField(
              controller: _receiverController,
              style: inputStyle,
              decoration: InputDecoration(
                hintText: 'VD: em Hoa, vợ yêu, mẹ...',
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
          Text('Dịp kỷ niệm',
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
                        child: Text('${c.emoji}  ${c.name}'),
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
                      'Tạo lời chúc',
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
                    Text('Copy',
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
    final products = _filteredProducts;
    final giftCategories = EventCategory.all
        .where((c) => c.canSuggestProducts)
        .toList();

    return Column(
      children: [
        // Search
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white12),
            ),
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.quicksand(
                  fontSize: 14, color: Colors.white),
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm quà tặng...',
                hintStyle: GoogleFonts.quicksand(
                    fontSize: 14, color: Colors.white38),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: Colors.white38, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        child: const Icon(Icons.close_rounded,
                            color: Colors.white38, size: 18),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
        ),

        // Category filter chips
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              _buildFilterChip(null, '🛍️ Tất cả'),
              ...giftCategories
                  .map((c) => _buildFilterChip(c.id, '${c.emoji} ${c.name}')),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Product grid
        Expanded(
          child: products.isEmpty
              ? _buildNoProducts()
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    mainAxisExtent: 290,
                  ),
                  itemCount: products.length,
                  itemBuilder: (ctx, i) =>
                      _buildProductCard(products[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String? categoryId, String label) {
    final isSelected = _filterCategoryId == categoryId;
    return GestureDetector(
      onTap: () => setState(() => _filterCategoryId = categoryId),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        alignment: Alignment.center,
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
                )
              : null,
          color: isSelected ? null : Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : Colors.white.withValues(alpha: 0.15),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color:
                        const Color(0xFF7C3AED).withValues(alpha: 0.3),
                    blurRadius: 8,
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.quicksand(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.white60,
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(GiftProduct product) {
    final cat = EventCategory.findById(product.categoryId);
    return GestureDetector(
      onTap: () => _openUrl(product.affiliateUrl),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Emoji hero
            Stack(
              children: [
                Container(
                  height: 110,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Color(cat.colorValue).withValues(alpha: 0.15),
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(17)),
                  ),
                  child: Center(
                    child: Text(product.emoji,
                        style: const TextStyle(fontSize: 46)),
                  ),
                ),
                if (product.isPopular)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [
                          Color(0xFFEAB308),
                          Color(0xFFF59E0B),
                        ]),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('⭐ Hot',
                          style: GoogleFonts.quicksand(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ),
                  ),
              ],
            ),

            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: GoogleFonts.quicksand(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.description,
                      style: GoogleFonts.quicksand(
                          fontSize: 11,
                          color: Colors.white54,
                          height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Text(
                      product.priceRange,
                      style: GoogleFonts.quicksand(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(cat.colorValue)),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding:
                          const EdgeInsets.symmetric(vertical: 7),
                      decoration: BoxDecoration(
                        color: Color(cat.colorValue)
                            .withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: Color(cat.colorValue)
                                .withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Xem ngay',
                              style: GoogleFonts.quicksand(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color:
                                      Color(cat.colorValue))),
                          const SizedBox(width: 4),
                          Icon(Icons.open_in_new_rounded,
                              size: 12,
                              color: Color(cat.colorValue)),
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

  Widget _buildNoProducts() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🛍️', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 16),
          Text('Không tìm thấy sản phẩm',
              style: GoogleFonts.quicksand(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          const SizedBox(height: 8),
          Text('Thử tìm kiếm từ khóa khác',
              style: GoogleFonts.quicksand(
                  fontSize: 14, color: Colors.white38)),
        ],
      ),
    );
  }
}
