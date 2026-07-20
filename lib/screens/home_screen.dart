import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import '../models/anniversary.dart';
import '../services/storage_service.dart';
import '../services/ad_service.dart';
import '../widgets/countdown_card.dart';
import '../widgets/time_unit_box.dart';
import '../widgets/fireworks_widget.dart';
import 'add_event_screen.dart';
import 'detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final StorageService _storageService = StorageService();
  List<Anniversary> _anniversaries = [];
  bool _isLoading = true;
  int _currentTab = 0;
  int _featuredIndex = 0;

  // Timer ticking mỗi giây để rebuild countdown
  Timer? _timer;
  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _loadAnniversaries();
    _startTimer();
    _loadBannerAd();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  void _loadBannerAd() {
    if (kIsWeb) return;
    _bannerAd = BannerAd(
      adUnitId: AdService.bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) {
            setState(() {
              _isBannerAdReady = true;
            });
          }
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('BannerAd failed to load: $err');
          _isBannerAdReady = false;
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer?.cancel();
    _bannerAd?.dispose();
    super.dispose();
  }

  Future<void> _loadAnniversaries() async {
    try {
      final data = await _storageService.getAnniversaries();
      setState(() {
        _anniversaries = data;
        _sortAnniversaries();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading anniversaries: $e');
      setState(() {
        _anniversaries = [];
        _isLoading = false;
      });
    }
  }

  /// Tính thời gian còn lại tới 00:00:00 của ngày sự kiện
  Duration _computeRemaining(Anniversary ann) {
    final target = ann.displayDate;
    // Đếm đến đầu ngày (00:00:00) — ngày kỷ niệm bắt đầu
    final targetDt = DateTime(target.year, target.month, target.day);
    final now = DateTime.now();
    return targetDt.isAfter(now) ? targetDt.difference(now) : Duration.zero;
  }

  void _sortAnniversaries() {
    _anniversaries.sort((a, b) {
      final dA = a.daysRemaining;
      final dB = b.daysRemaining;
      if (dA >= 0 && dB >= 0) return dA.compareTo(dB);
      if (dA < 0 && dB < 0) return dB.compareTo(dA);
      return dA >= 0 ? -1 : 1;
    });
  }

  List<Anniversary> get _upcomingList =>
      _anniversaries.where((a) => a.daysRemaining >= 0).toList();

  Anniversary? get _featuredAnniversary {
    final list = _upcomingList;
    if (list.isEmpty) return null;
    return list[_featuredIndex.clamp(0, list.length - 1)];
  }

  Color get _accentColor {
    return _featuredAnniversary?.color ?? const Color(0xFF7C3AED);
  }


  Future<void> _navigateToAdd() async {
    final result = await Navigator.push<dynamic>(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a1, a2) => AddEventScreen(existingEvents: _anniversaries),
        transitionsBuilder: (_, anim, _, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
            child: child,
          );
        },
      ),
    );

    if (result != null) {
      setState(() {
        if (result is Anniversary) {
          _anniversaries.add(result);
        } else if (result is List<Anniversary>) {
          _anniversaries.addAll(result);
        }
        _sortAnniversaries();
        _featuredIndex = 0;
      });
      await _storageService.saveAnniversaries(_anniversaries);
    }
  }

  Future<void> _navigateToDetail(Anniversary item) async {
    final updated = await Navigator.push<Anniversary?>(
      context,
      MaterialPageRoute(builder: (_) => DetailScreen(anniversary: item)),
    );
    if (updated == null) {
      setState(() {
        _anniversaries.removeWhere((a) => a.id == item.id);
        _sortAnniversaries();
        _featuredIndex = 0;
      });
      await _storageService.saveAnniversaries(_anniversaries);
    }
  }

  Future<void> _deleteEvent(Anniversary event) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.white12),
          ),
          title: Text(
            'Xóa kỷ niệm?',
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700, color: Colors.white),
          ),
          content: Text(
            'Bạn có chắc muốn xóa "${event.title}" không?',
            style: GoogleFonts.outfit(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child:
                  Text('Hủy', style: GoogleFonts.outfit(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'Xóa',
                style: GoogleFonts.outfit(
                    color: Colors.red.shade400, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
    if (confirm == true) {
      setState(() {
        _anniversaries.removeWhere((a) => a.id == event.id);
        _sortAnniversaries();
        _featuredIndex = 0;
      });
      await _storageService.saveAnniversaries(_anniversaries);
      
      // Hiển thị quảng cáo toàn màn hình sau khi xóa (Monetization)
      AdService.showInterstitialAd();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
            )
          : _currentTab == 0
              ? _buildHeroTab()
              : _buildAllEventsTab(),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: _currentTab == 1 ? _buildFAB() : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // ─────────────────────────────────────────────────────────
  // TAB 0: Hero — Sự kiện sắp tới nổi bật
  // ─────────────────────────────────────────────────────────
  Widget _buildHeroTab() {
    final featured = _featuredAnniversary;
    final upcoming = _upcomingList;

    if (_anniversaries.isEmpty) return _buildEmptyState();

    if (featured == null) {
      // Chỉ có sự kiện đã qua
      return _buildNoUpcomingState();
    }

    final cardColor = featured.color;
    // cardColor used for background gradient and dot indicator

    return Stack(
      children: [
        // Background gradient theo màu sự kiện
        Positioned.fill(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.3),
                radius: 1.2,
                colors: [
                  cardColor.withValues(alpha: 0.35),
                  const Color(0xFF0D0D1A),
                ],
              ),
            ),
          ),
        ),

        // Particle glow top
        Positioned(
          top: -60,
          left: MediaQuery.of(context).size.width / 2 - 150,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  cardColor.withValues(alpha: 0.25),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // 🎆 Fireworks when it's a celebration day
        if (_upcomingList.any((a) => a.daysRemaining == 0))
          const Positioned.fill(child: FireworksWidget()),

        SafeArea(
          child: Column(
            children: [
              // ── App Bar ──
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _accentColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.favorite_rounded,
                          color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Sắp tới',
                      style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white),
                    ),
                    const Spacer(),
                    if (upcoming.length > 1)
                      Row(
                        children: [
                          if (_featuredIndex > 0)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () {
                                  _pageController.animateToPage(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                                  setState(() => _featuredIndex = 0);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.refresh_rounded, color: Colors.white, size: 14),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Gần nhất',
                                        style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: Text(
                              '${_featuredIndex + 1} / ${upcoming.length}',
                              style: GoogleFonts.outfit(fontSize: 13, color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(width: 12),
                    // Add Button (Header)
                    GestureDetector(
                      onTap: _navigateToAdd,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (index) {
                    setState(() {
                      _featuredIndex = index;
                    });
                  },
                  itemCount: upcoming.length,
                  itemBuilder: (context, index) {
                    final item = upcoming[index];
                    final itemColor = item.color;
                    final days = item.daysRemaining;
                    final isToday = days == 0;
                    final remaining = _computeRemaining(item);
                    final daysLeft = remaining.inDays;
                    final hours = remaining.inHours % 24;
                    final minutes = remaining.inMinutes % 60;
                    final seconds = remaining.inSeconds % 60;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // ── Emoji lớn với glow ──
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.8, end: 1.0),
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.elasticOut,
                            builder: (_, v, child) =>
                                Transform.scale(scale: v, child: child),
                            child: Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: itemColor.withValues(alpha: 0.15),
                                border: Border.all(
                                    color: itemColor.withValues(alpha: 0.5),
                                    width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: itemColor.withValues(alpha: 0.5),
                                    blurRadius: 40,
                                    spreadRadius: 8,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(item.emoji,
                                    style: const TextStyle(fontSize: 52)),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // ── Tên sự kiện ──
                          Text(
                            item.title,
                            style: GoogleFonts.outfit(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.2,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),

                          const SizedBox(height: 8),

                          // ── Ngày ──
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.calendar_today_rounded,
                                  size: 14, color: Colors.white54),
                              const SizedBox(width: 6),
                              Text(
                                DateFormat('dd MMMM yyyy', 'vi')
                                    .format(item.displayDate),
                                style: GoogleFonts.outfit(
                                    fontSize: 15, color: Colors.white54),
                              ),
                              if (item.isYearly) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: itemColor.withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '↺ hàng năm',
                                    style: GoogleFonts.outfit(
                                        fontSize: 11,
                                        color: itemColor,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ],
                          ),

                          const SizedBox(height: 16),

                          if (isToday) ...[
                            // ── Chúc mừng: layout gọn gàng, 1 dòng đẹp ──
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [
                                  Color(0xFFFFD700),
                                  Color(0xFFFFA500),
                                  Color(0xFFFFD700),
                                ],
                              ).createShader(bounds),
                              child: Text(
                                '🎊 Chúc mừng!',
                                style: GoogleFonts.outfit(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Hôm nay là ${item.title}',
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            // Confetti dots row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                for (final c in [
                                  const Color(0xFFFF6B6B),
                                  const Color(0xFFFFD93D),
                                  const Color(0xFF6BCB77),
                                  const Color(0xFF4D96FF),
                                  const Color(0xFFFF9F43),
                                ])
                                  Container(
                                    width: 10,
                                    height: 10,
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    decoration: BoxDecoration(
                                      color: c,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(color: c.withValues(alpha: 0.6), blurRadius: 8),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ] else ...[
                            // ── Badge ngày ──
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              decoration: BoxDecoration(
                                color: itemColor.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: itemColor.withValues(alpha: 0.6),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: itemColor.withValues(alpha: 0.3),
                                    blurRadius: 20,
                                  ),
                                ],
                              ),
                              child: Text(
                                '⏳ Còn $days ngày nữa',
                                style: GoogleFonts.outfit(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // ── Countdown boxes ──
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                TimeUnitBox(
                                  value: daysLeft.toString().padLeft(2, '0'),
                                  label: 'Ngày',
                                  color: itemColor,
                                ),
                                _separator(itemColor),
                                TimeUnitBox(
                                  value: hours.toString().padLeft(2, '0'),
                                  label: 'Giờ',
                                  color: itemColor,
                                ),
                                _separator(itemColor),
                                TimeUnitBox(
                                  value: minutes.toString().padLeft(2, '0'),
                                  label: 'Phút',
                                  color: itemColor,
                                ),
                                _separator(itemColor),
                                TimeUnitBox(
                                  value: seconds.toString().padLeft(2, '0'),
                                  label: 'Giây',
                                  color: itemColor,
                                ),
                              ],
                            ),
                          ],


                          const SizedBox(height: 16),

                          // ── Các nút hành động ──
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (item.category.canSuggestProducts) ...[
                                GestureDetector(
                                  onTap: () {
                                    // TODO: Mở tính năng gợi ý quà tặng
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981)
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                          color: const Color(0xFF10B981)
                                              .withValues(alpha: 0.5)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text('🛍️', style: TextStyle(fontSize: 14)),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Gợi ý quà',
                                          style: GoogleFonts.outfit(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF10B981),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],
                              GestureDetector(
                                onTap: () => _navigateToDetail(item),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: itemColor.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                        color: itemColor.withValues(alpha: 0.5)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Xem chi tiết',
                                        style: GoogleFonts.outfit(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Icon(Icons.arrow_forward_ios_rounded,
                                          color: Colors.white, size: 14),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // ── Dots indicator ──
              if (upcoming.length > 1)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      upcoming.length.clamp(0, 5),
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: i == _featuredIndex ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _featuredIndex
                              ? cardColor
                              : Colors.white24,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 80), // space for FAB + nav
            ],
          ),
        ),
      ],
    );
  }

  Widget _separator(Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        ':',
        style: GoogleFonts.outfit(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }


  // ─────────────────────────────────────────────────────────
  // TAB 1: Tất cả sự kiện
  // ─────────────────────────────────────────────────────────
  Widget _buildAllEventsTab() {
    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: const Color(0xFF0D0D1A),
          expandedHeight: 80,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _accentColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.list_rounded,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                Text(
                  'Tất cả sự kiện',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                color: _accentColor,
              ),
            ),
          ),
        ),
        if (_anniversaries.isEmpty)
          SliverFillRemaining(child: _buildEmptyState())
        else ...[
          // Sắp tới
          if (_upcomingList.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 18,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Sắp tới',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C3AED).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_upcomingList.length}',
                        style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: const Color(0xFF7C3AED),
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    final item = _upcomingList[i];
                    return CountdownCard(
                      anniversary: item,
                      onTap: () => _navigateToDetail(item),
                      onDelete: () => _deleteEvent(item),
                    );
                  },
                  childCount: _upcomingList.length,
                ),
              ),
            ),
          ],

          // Đã qua
          if (_anniversaries.any((a) => a.daysRemaining < 0)) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 18,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Đã qua',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    final past =
                        _anniversaries.where((a) => a.daysRemaining < 0).toList();
                    final item = past[i];
                    return CountdownCard(
                      anniversary: item,
                      onTap: () => _navigateToDetail(item),
                      onDelete: () => _deleteEvent(item),
                    );
                  },
                  childCount:
                      _anniversaries.where((a) => a.daysRemaining < 0).length,
                ),
              ),
            ),
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ],
    ),
    ), // End of Expanded

    ],
    );
  }

  // ─────────────────────────────────────────────────────────
  // Bottom Navigation Bar
  // ─────────────────────────────────────────────────────────
  Widget _buildBottomNav() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isBannerAdReady && _bannerAd != null)
          SafeArea(
            top: false,
            bottom: false,
            child: Container(
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              alignment: Alignment.center,
              margin: const EdgeInsets.only(top: 4, bottom: 4),
              child: AdWidget(ad: _bannerAd!),
            ),
          ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF12122A),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            ),
            boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              _buildNavItem(
                index: 0,
                icon: Icons.star_rounded,
                label: 'Sắp tới',
              ),
              _buildNavItem(
                index: 1,
                icon: Icons.format_list_bulleted_rounded,
                label: 'Tất cả',
                badge: _anniversaries.length,
              ),
            ],
          ),
        ),
      ), // SafeArea
    ), // Container
    ], // children
    ); // Column
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    int? badge,
  }) {
    final isActive = _currentTab == index;
    final accent = _accentColor;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _currentTab = index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              decoration: BoxDecoration(
                color: isActive
                    ? accent.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    icon,
                    color: isActive ? accent : Colors.white38,
                    size: 26,
                  ),
                  if (badge != null && badge > 0)
                    Positioned(
                      top: -4,
                      right: -8,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEC4899),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$badge',
                          style: GoogleFonts.outfit(
                              fontSize: 9,
                              color: Colors.white,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color: isActive ? accent : Colors.white38,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // Empty states
  // ─────────────────────────────────────────────────────────
  Widget _buildFAB() {
    final accent = _accentColor;
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: accent,
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.5),
            blurRadius: 20,
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: _navigateToAdd,
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF7C3AED).withValues(alpha: 0.3),
                  const Color(0xFFEC4899).withValues(alpha: 0.3),
                ],
              ),
            ),
            child: const Center(
              child: Text('💝', style: TextStyle(fontSize: 44)),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Chưa có kỷ niệm nào',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hãy thêm những ngày quan trọng\ncủa bạn để không bao giờ quên!',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 15, color: Colors.white38),
          ),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: _navigateToAdd,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.4),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: Text(
                '+ Thêm ngay',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoUpcomingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📅', style: TextStyle(fontSize: 60)),
          const SizedBox(height: 20),
          Text(
            'Không có sự kiện sắp tới',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tất cả sự kiện đã diễn ra.\nThêm sự kiện mới hoặc xem tab Tất cả.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 14, color: Colors.white38),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => setState(() => _currentTab = 1),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Text(
                'Xem tất cả sự kiện →',
                style: GoogleFonts.outfit(
                    fontSize: 14, color: Colors.white70),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
