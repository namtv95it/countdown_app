import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/special_occasion.dart';
import '../../models/gift_product.dart';
import '../../services/gift_service.dart';

class AdminAssignProductsScreen extends StatefulWidget {
  final SpecialOccasion occasion;
  
  const AdminAssignProductsScreen({super.key, required this.occasion});

  @override
  State<AdminAssignProductsScreen> createState() => _AdminAssignProductsScreenState();
}

class _AdminAssignProductsScreenState extends State<AdminAssignProductsScreen> {
  final GiftService _giftService = GiftService();
  Set<String> _initialSelectedIds = {};
  Set<String> _currentSelectedIds = {};
  bool _isSaving = false;
  bool _isLoading = true;
  List<GiftProduct> _allGifts = [];

  @override
  void initState() {
    super.initState();
    _loadGifts();
  }

  Future<void> _loadGifts() async {
    // We can just subscribe to the stream or fetch once. Fetching once is easier for checkboxes.
    _giftService.getGiftsStream().first.then((gifts) {
      if (mounted) {
        setState(() {
          _allGifts = gifts;
          // Initially selected products
          final selected = gifts
              .where((g) => g.occasionIds.contains(widget.occasion.id))
              .map((g) => g.id)
              .toSet();
          _initialSelectedIds = Set.from(selected);
          _currentSelectedIds = Set.from(selected);
          _isLoading = false;
        });
      }
    }).catchError((e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi tải sản phẩm: $e')));
      }
    });
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final productsToAdd = _currentSelectedIds.difference(_initialSelectedIds).toList();
      final productsToRemove = _initialSelectedIds.difference(_currentSelectedIds).toList();

      if (productsToAdd.isNotEmpty || productsToRemove.isNotEmpty) {
        await _giftService.updateGiftOccasionBatch(
          widget.occasion.id,
          productsToAdd,
          productsToRemove,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật sản phẩm thành công!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Gán SP cho ${widget.occasion.getName('vi')}', style: GoogleFonts.quicksand(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _allGifts.isEmpty
              ? Center(child: Text('Chưa có sản phẩm nào.', style: GoogleFonts.quicksand(color: Colors.white54)))
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 100, top: 16),
                  itemCount: _allGifts.length,
                  itemBuilder: (context, index) {
                    final gift = _allGifts[index];
                    final isSelected = _currentSelectedIds.contains(gift.id);

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF7C3AED) : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: CheckboxListTile(
                        value: isSelected,
                        activeColor: const Color(0xFF7C3AED),
                        checkColor: Colors.white,
                        title: Text(
                          gift.name['vi'] ?? '',
                          style: GoogleFonts.quicksand(
                            color: Colors.white,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          gift.priceRange,
                          style: GoogleFonts.quicksand(color: Colors.white54, fontSize: 12),
                        ),
                        secondary: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: gift.imageUrl.isNotEmpty
                              ? Image.network(gift.imageUrl, width: 40, height: 40, fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.image, color: Colors.white24))
                              : const Icon(Icons.image, color: Colors.white24),
                        ),
                        onChanged: (bool? checked) {
                          setState(() {
                            if (checked == true) {
                              _currentSelectedIds.add(gift.id);
                            } else {
                              _currentSelectedIds.remove(gift.id);
                            }
                          });
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: _isLoading
          ? null
          : FloatingActionButton.extended(
              onPressed: _isSaving ? null : _save,
              backgroundColor: _isSaving ? Colors.grey : const Color(0xFF7C3AED),
              icon: _isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.save, color: Colors.white),
              label: Text(_isSaving ? 'Đang lưu...' : 'Lưu Thay Đổi', style: GoogleFonts.quicksand(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
    );
  }
}
