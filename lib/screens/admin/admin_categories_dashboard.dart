import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/event_category.dart';
import '../../services/sync_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_edit_category_screen.dart';

class AdminCategoriesDashboard extends StatefulWidget {
  const AdminCategoriesDashboard({super.key});

  @override
  State<AdminCategoriesDashboard> createState() => _AdminCategoriesDashboardState();
}

class _AdminCategoriesDashboardState extends State<AdminCategoriesDashboard> {
  Future<void> _confirmDelete(EventCategory cat) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text('Xác nhận xóa', style: GoogleFonts.quicksand(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('Bạn có chắc chắn muốn xóa danh mục "${cat.getName('vi')}"?\n\nLưu ý: Bạn chỉ nên Ẩn danh mục thay vì xóa, để không ảnh hưởng đến các sản phẩm đã gán danh mục này.', style: GoogleFonts.quicksand(color: Colors.white70)),
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
      await FirebaseFirestore.instance.collection('gift_categories').doc(cat.id).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa danh mục!'), backgroundColor: Colors.green),
        );
      }
    }
  }

  Future<void> _toggleActive(EventCategory cat) async {
    await FirebaseFirestore.instance.collection('gift_categories').doc(cat.id).update({
      'isActive': !cat.isActive,
    });
  }

  Widget _buildCategoryItem(EventCategory cat) {
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
                    color: Color(cat.colorValue).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(cat.emoji, style: const TextStyle(fontSize: 24)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              cat.getName('vi'),
                              style: GoogleFonts.quicksand(
                                color: cat.isActive ? Colors.white : Colors.white54,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                decoration: cat.isActive ? null : TextDecoration.lineThrough,
                              ),
                            ),
                          ),
                          Switch(
                            value: cat.isActive,
                            onChanged: (v) => _toggleActive(cat),
                            activeColor: Color(cat.colorValue),
                          ),
                        ],
                      ),
                      Text(
                        'ID: ${cat.id}',
                        style: GoogleFonts.quicksand(color: Colors.white54, fontSize: 12),
                      ),
                      if (cat.canSuggestProducts)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            '💡 Gợi ý quà tặng',
                            style: GoogleFonts.quicksand(color: Colors.amberAccent, fontSize: 12),
                          ),
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
                      Navigator.push(context, MaterialPageRoute(builder: (_) => AdminEditCategoryScreen(category: cat)));
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
                    onPressed: () => _confirmDelete(cat),
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
        title: Text('Quản lý Danh Mục', style: GoogleFonts.quicksand(fontWeight: FontWeight.bold, color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<List<EventCategory>>(
        stream: SyncService().categoriesStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Lỗi tải dữ liệu', style: GoogleFonts.quicksand(color: Colors.redAccent)));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final categories = snapshot.data!;
          if (categories.isEmpty) {
            return const Center(child: Text('Chưa có danh mục nào.', style: TextStyle(color: Colors.white54)));
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 100),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              return _buildCategoryItem(categories[index]);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminEditCategoryScreen()));
        },
        backgroundColor: const Color(0xFF10B981),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Thêm Danh Mục', style: GoogleFonts.quicksand(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }
}
