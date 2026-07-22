import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../data/gift_products.dart';
import '../models/event_category.dart';
import '../models/gift_product.dart';
import '../services/wish_service.dart';
import '../services/ad_service.dart';

class GiftScreen extends StatefulWidget {
  /// Nếu được truyền, sẽ tự động chọn danh mục này ở tab Gợi ý quà
  final String? initialCategoryId;
  final bool isPremium;

  const GiftScreen({super.key, this.initialCategoryId, this.isPremium = false});

  @override
  State<GiftScreen> createState() => _GiftScreenState();
}

class _GiftScreenState extends State<GiftScreen> {
  // ── Gửi lời chúc ──
  final _senderController = TextEditingController();
  final _receiverController = TextEditingController();
  String _selectedCategoryId = 'birthday';
  List<String> _generatedWishes = [];
  bool _isGenerating = false;
  final _wishScrollController = ScrollController();
  final _wishesHeaderKey = GlobalKey(); // dùng để scroll đến đầu danh sách lời chúc

  // ── Gợi ý quà (WebView) ──
  late final WebViewController _webViewController;
  bool _isWebViewLoading = true;

  @override
  void initState() {
    super.initState();
    
    String url = 'https://namtv95it.github.io/countdown_gift_web/';
    if (widget.initialCategoryId != null) {
      url += '?category=${widget.initialCategoryId}';
    }
    
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (mounted) setState(() => _isWebViewLoading = true);
          },
          onPageFinished: (String url) {
            if (mounted) setState(() => _isWebViewLoading = false);
          },
          onNavigationRequest: (NavigationRequest request) {
            // Chỉ cho phép điều hướng nội bộ trên Github Pages
            if (request.url.startsWith('https://namtv95it.github.io')) {
              return NavigationDecision.navigate;
            }
            // Các link bên ngoài (Shopee, web khác) -> mở ứng dụng bên ngoài
            _openUrl(request.url);
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(Uri.parse(url));
  }

  @override
  void dispose() {
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
            FloatingActionButton.small(
            heroTag: 'refresh_fab',
            onPressed: () => _webViewController.reload(),
            backgroundColor: const Color(0xFF1A1A2E),
            foregroundColor: Colors.white70,
            child: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'wish_fab',
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
            icon: const Icon(Icons.mail_rounded, color: Colors.white),
            label: Text(
              'Lời chúc',
              style: GoogleFonts.quicksand(
                fontWeight: FontWeight.w700,
                color: Colors.white,
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
          '💌 Tạo lời chúc',
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
    return Stack(
      children: [
        WebViewWidget(controller: _webViewController),
        if (_isWebViewLoading)
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E).withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEC4899).withValues(alpha: 0.15),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Color(0xFFEC4899),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Đang tải danh sách quà...',
                    style: GoogleFonts.quicksand(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
