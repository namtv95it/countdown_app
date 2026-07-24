import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/special_occasion.dart';
import '../../services/special_occasion_service.dart';
import 'admin_edit_special_occasion_screen.dart';
import 'admin_assign_products_screen.dart';

class AdminSpecialOccasionsDashboard extends StatefulWidget {
  const AdminSpecialOccasionsDashboard({super.key});

  @override
  State<AdminSpecialOccasionsDashboard> createState() => _AdminSpecialOccasionsDashboardState();
}

class _AdminSpecialOccasionsDashboardState extends State<AdminSpecialOccasionsDashboard> {
  final SpecialOccasionService _occasionService = SpecialOccasionService();

  Future<void> _confirmDelete(SpecialOccasion occ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text('Xác nhận xóa', style: GoogleFonts.quicksand(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('Bạn có chắc chắn muốn xóa "${occ.getName('vi')}"?', style: GoogleFonts.quicksand(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Hủy', style: GoogleFonts.quicksand(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Xóa', style: GoogleFonts.quicksand(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _occasionService.deleteOccasion(occ.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa sự kiện thành công!'), backgroundColor: Colors.green),
        );
      }
    }
  }

  Widget _buildOccasionItem(SpecialOccasion occ) {
    return Card(
      color: Colors.white.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(occ.emoji, style: const TextStyle(fontSize: 24)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        occ.getName('vi'),
                        style: GoogleFonts.quicksand(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ngày: ${occ.getDateLabel('vi')}',
                        style: GoogleFonts.quicksand(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: Colors.white10, height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => AdminEditSpecialOccasionScreen(occasion: occ)));
                    },
                    icon: const Icon(Icons.edit, color: Colors.blueAccent, size: 18),
                    label: Text('Sửa', style: GoogleFonts.quicksand(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.blueAccent.withValues(alpha: 0.1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _confirmDelete(occ),
                    icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18),
                    label: Text('Xóa', style: GoogleFonts.quicksand(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => AdminAssignProductsScreen(occasion: occ)));
                },
                icon: const Icon(Icons.card_giftcard, color: Colors.amberAccent, size: 18),
                label: Text('Gán Sản Phẩm', style: GoogleFonts.quicksand(color: Colors.amberAccent, fontWeight: FontWeight.bold)),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.amberAccent.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Quản lý Sự Kiện', style: GoogleFonts.quicksand(fontWeight: FontWeight.bold, color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<List<SpecialOccasion>>(
        stream: _occasionService.getOccasionsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Lỗi tải dữ liệu', style: GoogleFonts.quicksand(color: Colors.redAccent)));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final occasions = snapshot.data!;
          if (occasions.isEmpty) {
            return const Center(child: Text('Chưa có sự kiện nào.', style: TextStyle(color: Colors.white54)));
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 100),
            itemCount: occasions.length,
            itemBuilder: (context, index) {
              return _buildOccasionItem(occasions[index]);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminEditSpecialOccasionScreen()));
        },
        backgroundColor: const Color(0xFF7C3AED),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Thêm Sự Kiện', style: GoogleFonts.quicksand(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }
}
