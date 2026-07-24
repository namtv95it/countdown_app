import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/gift_product.dart';
import '../../services/gift_service.dart';
import 'admin_edit_gift_screen.dart';

class AdminGiftDashboard extends StatefulWidget {
  const AdminGiftDashboard({super.key});

  @override
  State<AdminGiftDashboard> createState() => _AdminGiftDashboardState();
}

class _AdminGiftDashboardState extends State<AdminGiftDashboard> {
  final GiftService _giftService = GiftService();
  bool _isReordering = false;
  List<GiftProduct> _reorderList = [];

  Future<void> _confirmDelete(GiftProduct gift) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text('Xác nhận xóa', style: GoogleFonts.quicksand(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('Bạn có chắc chắn muốn xóa "${gift.getName('vi')}"?', style: GoogleFonts.quicksand(color: Colors.white70)),
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
      await _giftService.deleteGift(gift.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa thành công!'), backgroundColor: Colors.green),
        );
      }
    }
  }

  Widget _buildGiftItem(GiftProduct gift, {bool isReordering = false, Key? key}) {
    return Card(
      key: key,
      color: Colors.white.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: gift.imageUrl,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: Colors.white10),
                errorWidget: (context, url, error) => Container(color: Colors.white10, child: const Icon(Icons.error, color: Colors.white54)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    gift.getName('vi'),
                    style: GoogleFonts.quicksand(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Giá: ${gift.priceRange}',
                    style: GoogleFonts.quicksand(color: const Color(0xFFEC4899), fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ưu tiên: ${gift.order}',
                    style: GoogleFonts.quicksand(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (isReordering)
              const Icon(Icons.drag_handle, color: Colors.white54)
            else ...[
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blueAccent),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => AdminEditGiftScreen(gift: gift)));
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.redAccent),
                onPressed: () => _confirmDelete(gift),
              ),
            ],
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
        title: Text('Quản lý Quà Tặng', style: GoogleFonts.quicksand(fontWeight: FontWeight.bold, color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isReordering) ...[
            TextButton(
              onPressed: () {
                setState(() => _isReordering = false);
              },
              child: Text('Hủy', style: GoogleFonts.quicksand(color: Colors.white54, fontWeight: FontWeight.bold)),
            ),
            TextButton(
              onPressed: () async {
                await _giftService.updateGiftsOrder(_reorderList);
                setState(() => _isReordering = false);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã lưu thứ tự!'), backgroundColor: Colors.green),
                  );
                }
              },
              child: Text('Lưu', style: GoogleFonts.quicksand(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
            ),
          ] else
            IconButton(
              icon: const Icon(Icons.sort, color: Colors.white),
              tooltip: 'Sắp xếp thứ tự',
              onPressed: () {
                setState(() => _isReordering = true);
                _reorderList = [];
              },
            ),
        ],
      ),
      body: StreamBuilder<List<GiftProduct>>(
        stream: _giftService.getGiftsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Lỗi tải dữ liệu', style: GoogleFonts.quicksand(color: Colors.redAccent)));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final gifts = snapshot.data!;
          if (_isReordering && _reorderList.isEmpty) {
            _reorderList = List.from(gifts);
          }
          final displayList = _isReordering ? _reorderList : gifts;

          if (displayList.isEmpty) {
            return const Center(child: Text('Chưa có quà tặng nào.', style: TextStyle(color: Colors.white54)));
          }

          if (_isReordering) {
            return ReorderableListView.builder(
              padding: const EdgeInsets.only(bottom: 100),
              itemCount: displayList.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex -= 1;
                  final item = _reorderList.removeAt(oldIndex);
                  _reorderList.insert(newIndex, item);
                });
              },
              itemBuilder: (context, index) {
                final gift = displayList[index];
                return _buildGiftItem(gift, isReordering: true, key: ValueKey(gift.id));
              },
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 100),
            itemCount: displayList.length,
            itemBuilder: (context, index) {
              final gift = displayList[index];
              return _buildGiftItem(gift, key: ValueKey(gift.id));
            },
          );
        },
      ),
      floatingActionButton: _isReordering
          ? null
          : FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminEditGiftScreen()));
              },
              backgroundColor: const Color(0xFFEC4899),
              icon: const Icon(Icons.add),
              label: Text('Thêm Quà', style: GoogleFonts.quicksand(fontWeight: FontWeight.bold)),
            ),
    );
  }
}
