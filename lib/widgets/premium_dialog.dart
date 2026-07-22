import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/storage_service.dart';
import '../services/ad_service.dart';

class PremiumDialog extends StatelessWidget {
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
  Widget build(BuildContext context) {
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
                      icon: Icons.palette_rounded,
                      title: 'Mở khóa Tất cả Màu sắc & Hiệu ứng',
                      desc: 'Tự do chọn màu nền và hiệu ứng hình nền độc quyền',
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
                      // Kích hoạt Premium
                      await StorageService().setPremium(true);
                      AdService.isPremium = true;
                      onPremiumUnlocked?.call();

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

              const SizedBox(height: 8),

              // Nút Khôi phục thanh toán
              TextButton(
                onPressed: () async {
                  await StorageService().setPremium(true);
                  AdService.isPremium = true;
                  onPremiumUnlocked?.call();

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('✅ Đã khôi phục quyền lợi Premium!'),
                        backgroundColor: const Color(0xFF7C3AED),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  }
                },
                child: Text(
                  'Khôi phục mua hàng (Restore Purchases)',
                  style: GoogleFonts.quicksand(
                    fontSize: 12,
                    color: Colors.white54,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),

              const SizedBox(height: 16),
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
