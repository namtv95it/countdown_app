import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/event_category.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class AdminEditCategoryScreen extends StatefulWidget {
  final EventCategory? category;
  const AdminEditCategoryScreen({super.key, this.category});

  @override
  State<AdminEditCategoryScreen> createState() => _AdminEditCategoryScreenState();
}

class _AdminEditCategoryScreenState extends State<AdminEditCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _idController;
  late TextEditingController _nameController;
  late TextEditingController _nameEnController;
  late TextEditingController _emojiController;
  late TextEditingController _orderController;
  
  late Color _currentColor;
  late bool _canSuggestProducts;
  late bool _isActive;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final c = widget.category;
    _idController = TextEditingController(text: c?.id ?? '');
    _nameController = TextEditingController(text: c?.name ?? '');
    _nameEnController = TextEditingController(text: c?.nameEn ?? '');
    _emojiController = TextEditingController(text: c?.emoji ?? '📅');
    _orderController = TextEditingController(text: (c?.order ?? 99).toString());
    
    _currentColor = c != null ? Color(c.colorValue) : const Color(0xFF10B981);
    _canSuggestProducts = c?.canSuggestProducts ?? true;
    _isActive = c?.isActive ?? true;
  }

  void _pickColor() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text('Chọn Màu', style: GoogleFonts.quicksand(color: Colors.white)),
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: _currentColor,
            onColorChanged: (c) {
              setState(() => _currentColor = c);
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Xong'),
          )
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final docId = widget.category?.id ?? _idController.text.trim();
      final data = {
        'id': docId,
        'name': _nameController.text.trim(),
        'nameEn': _nameEnController.text.trim(),
        'emoji': _emojiController.text.trim(),
        'colorValue': _currentColor.value,
        'canSuggestProducts': _canSuggestProducts,
        'suggestedProductTypes': widget.category?.suggestedProductTypes ?? [],
        'order': int.tryParse(_orderController.text.trim()) ?? 99,
        'isActive': _isActive,
      };

      await FirebaseFirestore.instance.collection('gift_categories').doc(docId).set(data, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã lưu thành công!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.category != null;
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(isEdit ? 'Sửa Danh Mục' : 'Thêm Danh Mục', style: GoogleFonts.quicksand(fontWeight: FontWeight.bold, color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField(_idController, 'ID (Ví dụ: birthday)', enabled: !isEdit),
                    const SizedBox(height: 16),
                    _buildTextField(_nameController, 'Tên (Tiếng Việt)'),
                    const SizedBox(height: 16),
                    _buildTextField(_nameEnController, 'Tên (Tiếng Anh)'),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildTextField(_emojiController, 'Emoji (Ví dụ: 🎂)')),
                        const SizedBox(width: 16),
                        Expanded(
                          child: GestureDetector(
                            onTap: _pickColor,
                            child: Container(
                              height: 60,
                              decoration: BoxDecoration(
                                color: _currentColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: _currentColor),
                              ),
                              child: Center(
                                child: Text('Chọn Màu', style: TextStyle(color: _currentColor, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(_orderController, 'Thứ tự hiển thị (1, 2, 3...)', isNumber: true),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: Text('Gợi ý quà tặng', style: GoogleFonts.quicksand(color: Colors.white, fontWeight: FontWeight.w600)),
                      subtitle: Text('Hiển thị trong tab Gợi ý quà tặng', style: GoogleFonts.quicksand(color: Colors.white54, fontSize: 12)),
                      value: _canSuggestProducts,
                      activeColor: const Color(0xFF10B981),
                      onChanged: (v) => setState(() => _canSuggestProducts = v),
                      contentPadding: EdgeInsets.zero,
                    ),
                    SwitchListTile(
                      title: Text('Kích hoạt', style: GoogleFonts.quicksand(color: Colors.white, fontWeight: FontWeight.w600)),
                      subtitle: Text('Hiển thị danh mục này trên App/Web', style: GoogleFonts.quicksand(color: Colors.white54, fontSize: 12)),
                      value: _isActive,
                      activeColor: const Color(0xFF10B981),
                      onChanged: (v) => setState(() => _isActive = v),
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text('Lưu Danh Mục', style: GoogleFonts.quicksand(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool isNumber = false, bool enabled = true}) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      validator: (v) => v!.trim().isEmpty ? 'Bắt buộc' : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
    );
  }
}
