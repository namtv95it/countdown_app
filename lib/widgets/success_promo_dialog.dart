import '../services/localization_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/promo_service.dart';

class SuccessPromoDialog extends StatelessWidget {
  final PromoCode promoCode;

  const SuccessPromoDialog({super.key, required this.promoCode});

  static Future<void> show(BuildContext context, PromoCode promoCode) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => SuccessPromoDialog(promoCode: promoCode),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 380),
        decoration: BoxDecoration(
          color: const Color(0xFF14142B),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: const Color(0xFF10B981).withValues(alpha: 0.6),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withValues(alpha: 0.3),
              blurRadius: 25,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.8),
              blurRadius: 30,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Banner
            Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 110,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF059669),
                        Color(0xFF10B981),
                        Color(0xFFFFD700),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                Positioned(
                  bottom: -30,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFE259), Color(0xFF10B981)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.5),
                          blurRadius: 15,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.stars_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 42),

            // Tiêu đề
            Text(
              '🎉 CHÚC MỪNG BẠN!',
              style: GoogleFonts.quicksand(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: const Color(0xFFFFD700),
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 4),
            const SizedBox(height: 4),
            Text(
              promoCode.type == PromoType.premium
                  ? 'Kích Hoạt Tài Khoản VIP Thành Công'
                  : 'Kích Hoạt Gift Code Thành Công',
              style: GoogleFonts.quicksand(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 16),

            // Lời chúc mừng
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                promoCode.type == PromoType.premium
                    ? 'Chào mừng bạn gia nhập thành viên VIP Premium! Từ bây giờ, ứng dụng của bạn đã sẵn sàng với 100% tính năng cao cấp không có quảng cáo.'
                    : 'Chúc mừng bạn đã mở khóa thành công ${promoCode.description}! Hiệu ứng mới đã được áp dụng và sẵn sàng để sử dụng.',
                textAlign: TextAlign.center,
                style: GoogleFonts.quicksand(
                  fontSize: 13,
                  color: Colors.white70,
                  height: 1.4,
                ),
              ),
            ),

            const SizedBox(height: 18),

            // Thẻ chi tiết gói
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                children: [
                  _buildDetailRow(
                    icon: Icons.card_giftcard_rounded,
                    label: 'Gói kích hoạt:',
                    value: promoCode.description,
                    valueColor: const Color(0xFF10B981),
                  ),
                  const Divider(color: Colors.white12, height: 16),
                  _buildDetailRow(
                    icon: Icons.vpn_key_rounded,
                    label: 'Mã sử dụng:',
                    value: promoCode.code,
                    valueColor: const Color(0xFFFFD700),
                  ),
                  const Divider(color: Colors.white12, height: 16),
                  _buildDetailRow(
                    icon: Icons.all_inclusive_rounded,
                    label: 'Thời hạn sử dụng:',
                    value: 'Vĩnh viễn ✨',
                    valueColor: const Color(0xFFFFD700),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Nút Khám phá ngay
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 6,
                    shadowColor: const Color(0xFF10B981).withValues(alpha: 0.4),
                  ),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF059669), Color(0xFF10B981)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'KHÁM PHÁ NGAY',
                            style: GoogleFonts.quicksand(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
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

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: valueColor),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.quicksand(
            fontSize: 12,
            color: Colors.white60,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.quicksand(
            fontSize: 13,
            color: valueColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
