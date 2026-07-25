import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'admin_gift_dashboard.dart';
import 'admin_special_occasions_dashboard.dart';
import 'admin_categories_dashboard.dart';
import '../../services/sync_service.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Bảng Điều Khiển',
          style: GoogleFonts.quicksand(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildAdminCard(
              context,
              title: 'Quản lý Quà Tặng',
              subtitle: 'Thêm, sửa, xóa danh sách quà tặng',
              icon: Icons.card_giftcard,
              color: const Color(0xFFEC4899),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminGiftDashboard()),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildAdminCard(
              context,
              title: 'Sự Kiện Đặc Biệt',
              subtitle: 'Quản lý các dịp lễ kỷ niệm (Valentine, 8/3...)',
              icon: Icons.calendar_month,
              color: const Color(0xFF7C3AED),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminSpecialOccasionsDashboard()),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildAdminCard(
              context,
              title: 'Danh Mục Quà Tặng',
              subtitle: 'Quản lý thể loại (Tình yêu, Sinh nhật...)',
              icon: Icons.category_rounded,
              color: const Color(0xFF10B981),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminCategoriesDashboard()),
                );
              },
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: const Color(0xFF1A1A2E),
                      title: Text('Nâng Cấp Phiên Bản Data', style: GoogleFonts.quicksand(color: Colors.white, fontWeight: FontWeight.bold)),
                      content: Text(
                        'Thao tác này sẽ tăng số phiên bản data (version) lên 1 trong Firestore.\n\nTất cả thiết bị người dùng sẽ tự động phát hiện phiên bản mới và tải lại dữ liệu mới nhất (danh mục, quà tặng, v.v...) ở lần mở app kế tiếp.\n\nBạn có muốn tiếp tục?',
                        style: GoogleFonts.quicksand(color: Colors.white70),
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Hủy', style: GoogleFonts.quicksand(color: Colors.white54))),
                        TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Tiếp tục', style: GoogleFonts.quicksand(color: Colors.greenAccent, fontWeight: FontWeight.bold))),
                      ],
                    ),
                  );
                  if (confirm == true && context.mounted) {
                    final result = await SyncService().upgradeDataVersion();
                    if (context.mounted) {
                      final isSuccess = result.startsWith('success');
                      final count = isSuccess ? result.split(':').last : '';
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isSuccess
                              ? '✅ Nâng cấp thành công $count danh mục! Cache đã được xóa.'
                              : '❌ Lỗi: $result'),
                          backgroundColor: isSuccess ? Colors.green : Colors.red,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.system_update_alt_rounded),
                label: Text('Nâng Cấp Phiên Bản Data', style: GoogleFonts.quicksand(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1A2E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.quicksand(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.quicksand(
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
          ],
        ),
      ),
    );
  }
}
