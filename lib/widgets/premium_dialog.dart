import '../services/localization_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/storage_service.dart';
import '../services/ad_service.dart';
import '../services/promo_service.dart';
import 'success_promo_dialog.dart';

class PremiumDialog extends StatefulWidget {
  final VoidCallback? onPremiumUnlocked;

  const PremiumDialog({super.key, this.onPremiumUnlocked});

  static Future<void> show(BuildContext context, {VoidCallback? onPremiumUnlocked}) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => PremiumDialog(onPremiumUnlocked: onPremiumUnlocked),
    );
  }

  @override
  State<PremiumDialog> createState() => _PremiumDialogState();
}

class _PremiumDialogState extends State<PremiumDialog> {
  final TextEditingController _promoController = TextEditingController();
  bool _isCheckingCode = false;
  String? _promoError;
  bool _showPromoInput = false;

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  Future<void> _redeemPromoCode() async {
    final code = _promoController.text.trim();
    if (code.isEmpty) {
      setState(() => _promoError = 'Vui lòng nhập gift code!');
      return;
    }

    setState(() {
      _isCheckingCode = true;
      _promoError = null;
    });

    final result = await PromoService.redeemCode(code);

    if (!mounted) return;

    setState(() {
      _isCheckingCode = false;
    });

    if (result.success) {
      if (result.matchedCode?.type == PromoType.premium) {
        await StorageService().setPremium(true);
        AdService.isPremium = true;
        widget.onPremiumUnlocked?.call();
      }

      if (mounted) {
        Navigator.pop(context);
        if (result.matchedCode != null) {
          SuccessPromoDialog.show(context, result.matchedCode!);
        }
      }
    } else {
      setState(() {
        _promoError = result.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAlreadyPremium = AdService.isPremium;
    if (isAlreadyPremium) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: const Color(0xFF14142B),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: const Color(0xFFFFD700).withValues(alpha: 0.6),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                blurRadius: 25,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.8),
                blurRadius: 30,
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header Banner
                Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: 120,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFFFFD700),
                            Color(0xFFFF8C00),
                            Color(0xFFEC4899),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white70),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    Positioned(
                      bottom: -32,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFE259), Color(0xFFFF6700)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFA500).withValues(alpha: 0.6),
                              blurRadius: 15,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.workspace_premium_rounded,
                          color: Colors.white,
                          size: 42,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 44),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.stars_rounded, color: Color(0xFFFFD700), size: 22),
                    const SizedBox(width: 6),
                    Text(
                      'TÀI KHOẢN VIP PREMIUM',
                      style: GoogleFonts.quicksand(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF10B981).withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'Đã kích hoạt • Bản quyền Vĩnh viễn',
                        style: GoogleFonts.quicksand(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Cảm ơn bạn đã ủng hộ ứng dụng Đếm ngược Kỷ niệm! Bạn đang tận hưởng 100% các đặc quyền VIP cao cấp nhất:',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.quicksand(
                      fontSize: 13,
                      color: Colors.white70,
                      height: 1.4,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Danh sách đặc quyền đã mở
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      _buildFeatureItem(
                        icon: Icons.check_circle_outline_rounded,
                        title: 'Đã Ẩn 100% Quảng cáo',
                        desc: 'Không bao giờ xuất hiện banner hay video làm phiền',
                        iconColor: const Color(0xFF10B981),
                      ),
                      const SizedBox(height: 12),
                      _buildFeatureItem(
                        icon: Icons.check_circle_outline_rounded,
                        title: 'Đã Mở khóa Tất cả Hiệu ứng Nền',
                        desc: 'Thỏa sức chọn hiệu ứng hình nền độc quyền',
                        iconColor: const Color(0xFF10B981),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 26),

                // Nút Đã kích hoạt
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 6,
                        shadowColor: const Color(0xFFFFD700).withValues(alpha: 0.4),
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Container(
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.workspace_premium_rounded, color: Color(0xFF1A1A2E), size: 22),
                              const SizedBox(width: 8),
                              Text(
                                'BẠN ĐANG LÀ THÀNH VIÊN VIP ✨',
                                style: GoogleFonts.quicksand(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF1A1A2E),
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      );
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: const Color(0xFF14142B),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: const Color(0xFFFFD700).withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withValues(alpha: 0.25),
              blurRadius: 25,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.8),
              blurRadius: 30,
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Banner Gradient với Huy hiệu Vàng
              Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: 120,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF7C3AED),
                          Color(0xFFEC4899),
                          Color(0xFFF59E0B),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Positioned(
                    bottom: -32,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFE259), Color(0xFFFF6700)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFA500).withValues(alpha: 0.5),
                            blurRadius: 15,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.workspace_premium_rounded,
                        color: Colors.white,
                        size: 42,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 44),

              // Tiêu đề & Giá
              Text(
                'MỞ KHÓA PREMIUM VIP',
                style: GoogleFonts.quicksand(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  'Giá ưu đãi: \$2.00 / Sở hữu vĩnh viễn',
                  style: GoogleFonts.quicksand(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFFFD700),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Danh sách đặc quyền Premium
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _buildFeatureItem(
                      icon: Icons.block_rounded,
                      title: 'Ẩn 100% Quảng cáo',
                      desc: 'Trải nghiệm ứng dụng mượt mà không bị gián đoạn',
                      iconColor: const Color(0xFFEF4444),
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureItem(
                      icon: Icons.auto_awesome_rounded,
                      title: 'Mở khóa Tất cả Hiệu ứng Nền',
                      desc: 'Tự do chọn hiệu ứng hình nền độc quyền',
                      iconColor: const Color(0xFFEC4899),
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureItem(
                      icon: Icons.stars_rounded,
                      title: 'Huy hiệu VIP Đặc biệt',
                      desc: 'Tài khoản Premium vĩnh viễn không tính phí hàng tháng',
                      iconColor: const Color(0xFFFFD700),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Nút mua hàng ($2.00)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () async {
                      await StorageService().setPremium(true);
                      AdService.isPremium = true;
                      widget.onPremiumUnlocked?.call();

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.stars_rounded, color: Colors.amber),
                                const SizedBox(width: 10),
                                Text(
                                  '🎉 Bạn đã nâng cấp Premium thành công!',
                                  style: GoogleFonts.quicksand(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: const Color(0xFF10B981),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 8,
                      shadowColor: const Color(0xFFFFA500).withValues(alpha: 0.5),
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.flash_on_rounded, color: Color(0xFF1A1A2E)),
                            const SizedBox(width: 8),
                            Text(
                              'NÂNG CẤP NGAY (\$2.00)',
                              style: GoogleFonts.quicksand(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF1A1A2E),
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Khhu vực nhập Promo Code
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    if (!_showPromoInput)
                      TextButton.icon(
                        onPressed: () {
                          setState(() => _showPromoInput = true);
                        },
                        icon: const Icon(Icons.vpn_key_rounded, size: 16, color: Colors.amber),
                        label: Text(
                          'Bạn có mã kích hoạt hoặc Gift Code?',
                          style: GoogleFonts.quicksand(
                            fontSize: 13,
                            color: Colors.amber,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else ...[
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _promoController,
                              textCapitalization: TextCapitalization.characters,
                              style: GoogleFonts.quicksand(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Nhập gift code',
                                hintStyle: GoogleFonts.quicksand(
                                  color: Colors.white38,
                                  fontSize: 12,
                                ),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.08),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Colors.white24),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Colors.white24),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Colors.amber),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _isCheckingCode ? null : _redeemPromoCode,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7C3AED),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isCheckingCode
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'Áp dụng',
                                    style: GoogleFonts.quicksand(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                      if (_promoError != null) ...[
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _promoError!,
                            style: GoogleFonts.quicksand(
                              color: const Color(0xFFEF4444),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String desc,
    required Color iconColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: iconColor.withValues(alpha: 0.3)),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.quicksand(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: GoogleFonts.quicksand(
                  fontSize: 12,
                  color: Colors.white60,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
