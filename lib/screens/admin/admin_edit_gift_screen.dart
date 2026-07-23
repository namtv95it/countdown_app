import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/gift_product.dart';
import '../../services/gift_service.dart';

class AdminEditGiftScreen extends StatefulWidget {
  final GiftProduct? gift;

  const AdminEditGiftScreen({super.key, this.gift});

  @override
  State<AdminEditGiftScreen> createState() => _AdminEditGiftScreenState();
}

class _AdminEditGiftScreenState extends State<AdminEditGiftScreen> {
  final _formKey = GlobalKey<FormState>();
  final GiftService _giftService = GiftService();
  
  bool _isSaving = false;

  final TextEditingController _nameViCtrl = TextEditingController();
  final TextEditingController _nameEnCtrl = TextEditingController();
  final TextEditingController _priceCtrl = TextEditingController();
  final TextEditingController _urlCtrl = TextEditingController();
  final TextEditingController _imageUrlCtrl = TextEditingController();

  String _selectedGender = 'unisex';
  String _selectedPlatform = 'Shopee';
  String _selectedBadge = '';
  
  // Example categories, should match data.js structure
  final List<String> _availableCategories = [
    'birthday', 'love', 'anniversary', 'holiday', 'mid_autumn', 'children_day', 'womens_day'
  ];
  final List<String> _selectedCategories = [];

  @override
  void initState() {
    super.initState();
    if (widget.gift != null) {
      final g = widget.gift!;
      _nameViCtrl.text = g.name['vi'] ?? '';
      _nameEnCtrl.text = g.name['en'] ?? '';
      _priceCtrl.text = g.priceRange;
      _selectedPlatform = (['Shopee', 'Tiktok Shop', 'Lazada', 'Tiki', 'Khác'].contains(g.platform)) ? g.platform : 'Khác';
      _urlCtrl.text = g.affiliateUrl;
      _imageUrlCtrl.text = g.imageUrl;
      _selectedBadge = g.badge;
      _selectedGender = g.gender;
      _selectedCategories.addAll(g.categoryIds);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_imageUrlCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập Link Ảnh sản phẩm!'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final gift = GiftProduct(
        id: widget.gift?.id ?? '',
        categoryIds: _selectedCategories,
        name: {'vi': _nameViCtrl.text, 'en': _nameEnCtrl.text},
        description: {'vi': '', 'en': ''},
        priceRange: _priceCtrl.text,
        imageUrl: _imageUrlCtrl.text.trim(),
        badge: _selectedBadge,
        gender: _selectedGender,
        platform: _selectedPlatform,
        affiliateUrl: _urlCtrl.text,
        order: widget.gift?.order ?? 99999,
      );

      if (widget.gift == null) {
        await _giftService.addGift(gift);
      } else {
        await _giftService.updateGift(widget.gift!.id, gift);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã lưu thành công!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildTextField(TextEditingController ctrl, String label, bool isRequired, {TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: GoogleFonts.quicksand(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.quicksand(color: Colors.white54),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      validator: (val) {
        if (isRequired && (val == null || val.isEmpty)) return 'Không được để trống';
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(widget.gift == null ? 'Thêm Quà Mới' : 'Sửa Quà Tặng', style: GoogleFonts.quicksand(fontWeight: FontWeight.bold, color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFEC4899)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        child: _imageUrlCtrl.text.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: CachedNetworkImage(
                                  imageUrl: _imageUrlCtrl.text,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                                  errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.white54),
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.image, color: Colors.white54, size: 40),
                                  const SizedBox(height: 8),
                                  Text('Preview Ảnh', style: GoogleFonts.quicksand(color: Colors.white54, fontSize: 12)),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildTextField(_imageUrlCtrl, 'Link Ảnh (URL)', true),
                    const SizedBox(height: 16),
                    _buildTextField(_nameViCtrl, 'Tên Tiếng Việt', true),
                    const SizedBox(height: 16),
                    _buildTextField(_nameEnCtrl, 'Tên Tiếng Anh', true),
                    const SizedBox(height: 16),
                    _buildTextField(_priceCtrl, 'Mức giá (vd: 350k - 600k)', true),
                    const SizedBox(height: 16),
                    
                    Text('Nền tảng mua hàng', style: GoogleFonts.quicksand(color: Colors.white70, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedPlatform,
                      dropdownColor: const Color(0xFF1A1A2E),
                      style: GoogleFonts.quicksand(color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Shopee', child: Text('Shopee')),
                        DropdownMenuItem(value: 'Tiktok Shop', child: Text('Tiktok Shop')),
                        DropdownMenuItem(value: 'Lazada', child: Text('Lazada')),
                        DropdownMenuItem(value: 'Tiki', child: Text('Tiki')),
                        DropdownMenuItem(value: 'Khác', child: Text('Khác')),
                      ],
                      onChanged: (val) => setState(() => _selectedPlatform = val!),
                    ),
                    
                    const SizedBox(height: 16),
                    _buildTextField(_urlCtrl, 'Link Affiliate (Mua hàng)', true),
                    const SizedBox(height: 16),
                    Text('Huy hiệu (Badge)', style: GoogleFonts.quicksand(color: Colors.white70, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedBadge,
                      dropdownColor: const Color(0xFF1A1A2E),
                      style: GoogleFonts.quicksand(color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      items: const [
                        DropdownMenuItem(value: '', child: Text('Không có')),
                        DropdownMenuItem(value: 'HOT', child: Text('HOT')),
                        DropdownMenuItem(value: 'SALE', child: Text('SALE')),
                        DropdownMenuItem(value: 'SPECIAL', child: Text('SPECIAL')),
                        DropdownMenuItem(value: 'NEW', child: Text('NEW')),
                      ],
                      onChanged: (val) => setState(() => _selectedBadge = val!),
                    ),
                    const SizedBox(height: 24),
                    Text('Giới tính phù hợp', style: GoogleFonts.quicksand(color: Colors.white70, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedGender,
                      dropdownColor: const Color(0xFF1A1A2E),
                      style: GoogleFonts.quicksand(color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'unisex', child: Text('Unisex (Cả hai)')),
                        DropdownMenuItem(value: 'male', child: Text('Nam')),
                        DropdownMenuItem(value: 'female', child: Text('Nữ')),
                      ],
                      onChanged: (val) => setState(() => _selectedGender = val!),
                    ),
                    const SizedBox(height: 24),
                    Text('Danh mục', style: GoogleFonts.quicksand(color: Colors.white70, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _availableCategories.map((cat) {
                        final isSelected = _selectedCategories.contains(cat);
                        return FilterChip(
                          label: Text(cat, style: TextStyle(color: isSelected ? Colors.white : Colors.white54)),
                          selected: isSelected,
                          selectedColor: const Color(0xFF7C3AED),
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedCategories.add(cat);
                              } else {
                                _selectedCategories.remove(cat);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEC4899),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text('LƯU QUÀ TẶNG', style: GoogleFonts.quicksand(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
