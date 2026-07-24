import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/special_occasion.dart';
import '../../models/event_category.dart';
import '../../services/special_occasion_service.dart';

class AdminEditSpecialOccasionScreen extends StatefulWidget {
  final SpecialOccasion? occasion;
  const AdminEditSpecialOccasionScreen({super.key, this.occasion});

  @override
  State<AdminEditSpecialOccasionScreen> createState() => _AdminEditSpecialOccasionScreenState();
}

class _AdminEditSpecialOccasionScreenState extends State<AdminEditSpecialOccasionScreen> {
  final _formKey = GlobalKey<FormState>();
  final SpecialOccasionService _occasionService = SpecialOccasionService();

  late TextEditingController _idController;
  late TextEditingController _nameViController;
  late TextEditingController _nameEnController;
  late TextEditingController _monthController;
  late TextEditingController _dayController;

  String _selectedCategoryId = 'birthday';
  String _selectedGradient = 'linear-gradient(135deg, #EC4899, #BE185D)';
  String _selectedEmoji = '💝';
  bool _isSaving = false;

  static const List<String> _availableEmojis = [
    '💝', '🎂', '🎉', '🎁', '🎈', '💍', '🥂', '🌹', '🎊', '✨', '🔥', '🏆', '⭐', '🌈', '☀️', '🌸', '🎄', '🎃', '🎆', '🎓'
  ];

  static const List<String> _availableGradients = [
    'linear-gradient(135deg, #EC4899, #BE185D)',
    'linear-gradient(135deg, #F472B6, #A855F7)',
    'linear-gradient(135deg, #F59E0B, #EF4444)',
    'linear-gradient(135deg, #3B82F6, #06B6D4)',
    'linear-gradient(135deg, #1D4ED8, #3B82F6)',
    'linear-gradient(135deg, #F59E0B, #D97706)',
    'linear-gradient(135deg, #EC4899, #7C3AED)',
    'linear-gradient(135deg, #10B981, #0EA5E9)',
    'linear-gradient(135deg, #EF4444, #16A34A)',
    'linear-gradient(135deg, #7C3AED, #0EA5E9)',
    'linear-gradient(135deg, #7C3AED, #EC4899)',
    'linear-gradient(135deg, #EF4444, #F59E0B)',
    'linear-gradient(135deg, #14B8A6, #06B6D4)',
    'linear-gradient(135deg, #8B5CF6, #3B82F6)',
    'linear-gradient(135deg, #6366F1, #A855F7)',
    'linear-gradient(135deg, #F43F5E, #FB923C)',
    'linear-gradient(135deg, #FBBF24, #F59E0B)',
    'linear-gradient(135deg, #10B981, #34D399)',
    'linear-gradient(135deg, #3B82F6, #93C5FD)',
    'linear-gradient(135deg, #6B7280, #374151)'
  ];

  @override
  void initState() {
    super.initState();
    final occ = widget.occasion;
    _idController = TextEditingController(text: occ?.id ?? '');
    _nameViController = TextEditingController(text: occ?.nameVi ?? '');
    _nameEnController = TextEditingController(text: occ?.nameEn ?? '');
    _monthController = TextEditingController(text: occ?.month.toString() ?? '1');
    _dayController = TextEditingController(text: occ?.day.toString() ?? '1');
    if (occ != null) {
      _selectedEmoji = occ.emoji.isNotEmpty ? occ.emoji : _availableEmojis.first;
      if (!_availableEmojis.contains(_selectedEmoji)) {
        _selectedEmoji = _availableEmojis.first;
      }
      
      _selectedGradient = occ.gradient.isNotEmpty ? occ.gradient : _availableGradients.first;
      if (!_availableGradients.contains(_selectedGradient)) {
        _selectedGradient = _availableGradients.first; // fallback if not in list
      }
      _selectedCategoryId = occ.categoryId;
      // Safeguard: check if this category actually exists in EventCategory.all
      final exists = EventCategory.all.any((c) => c.id == _selectedCategoryId);
      if (!exists) {
        _selectedCategoryId = 'other';
      }
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameViController.dispose();
    _nameEnController.dispose();

    _monthController.dispose();
    _dayController.dispose();
    super.dispose();
  }

  String _generateId(String nameVi, int day, int month) {
    String str = nameVi.toLowerCase();
    str = str.replaceAll(RegExp(r'[àáạảãâầấậẩẫăằắặẳẵ]'), 'a');
    str = str.replaceAll(RegExp(r'[èéẹẻẽêềếệểễ]'), 'e');
    str = str.replaceAll(RegExp(r'[ìíịỉĩ]'), 'i');
    str = str.replaceAll(RegExp(r'[òóọỏõôồốộổỗơờớợởỡ]'), 'o');
    str = str.replaceAll(RegExp(r'[ùúụủũưừứựửữ]'), 'u');
    str = str.replaceAll(RegExp(r'[ỳýỵỷỹ]'), 'y');
    str = str.replaceAll(RegExp(r'[đ]'), 'd');
    str = str.replaceAll(RegExp(r'[^a-z0-9\s]'), ''); // remove special characters
    str = str.trim().replaceAll(RegExp(r'\s+'), '_'); // replace spaces with _
    
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    final randomStr = String.fromCharCodes(Iterable.generate(
        4, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
        
    return '${str}_$day${month}_$randomStr';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final int month = int.tryParse(_monthController.text) ?? 1;
      final int day = int.tryParse(_dayController.text) ?? 1;
      final String generatedId = widget.occasion?.id ?? _generateId(_nameViController.text, day, month);

      final occ = SpecialOccasion(
        id: generatedId,
        nameVi: _nameViController.text.trim(),
        nameEn: _nameEnController.text.trim(),
        emoji: _selectedEmoji,
        month: month,
        day: day,
        gradient: _selectedGradient,
        categoryId: _selectedCategoryId,
      );

      if (widget.occasion == null) {
        await _occasionService.addOccasion(occ);
      } else {
        await _occasionService.updateOccasion(occ);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lưu sự kiện thành công!'), backgroundColor: Colors.green),
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

  Widget _buildTextField(String label, TextEditingController controller, {bool required = true, bool isNumber = false, String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: GoogleFonts.quicksand(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: GoogleFonts.quicksand(color: Colors.white70),
          hintStyle: GoogleFonts.quicksand(color: Colors.white30),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF7C3AED)),
          ),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.05),
        ),
        validator: required
            ? (value) {
                if (value == null || value.trim().isEmpty) return 'Vui lòng nhập $label';
                return null;
              }
            : null,
      ),
    );
  }

  Widget _buildDateField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () async {
          final initialDate = DateTime(DateTime.now().year, int.tryParse(_monthController.text) ?? 1, int.tryParse(_dayController.text) ?? 1);
          final picked = await showDatePicker(
            context: context,
            initialDate: initialDate,
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
            helpText: 'Chọn ngày diễn ra sự kiện',
            builder: (context, child) {
              return Theme(
                data: ThemeData.dark().copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: Color(0xFF7C3AED),
                    onPrimary: Colors.white,
                    surface: Color(0xFF1A1A2E),
                    onSurface: Colors.white,
                  ),
                ),
                child: child!,
              );
            },
          );
          if (picked != null) {
            setState(() {
              _monthController.text = picked.month.toString();
              _dayController.text = picked.day.toString();
            });
          }
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'Ngày diễn ra',
            labelStyle: GoogleFonts.quicksand(color: Colors.white70),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ngày ${_dayController.text} tháng ${_monthController.text}',
                style: GoogleFonts.quicksand(color: Colors.white, fontSize: 16),
              ),
              const Icon(Icons.calendar_month, color: Colors.white70),
            ],
          ),
        ),
      ),
    );
  }

  List<Color> _parseCssGradient(String gradient) {
    try {
      final matches = RegExp(r'#([A-Fa-f0-9]{6})').allMatches(gradient);
      if (matches.length >= 2) {
        return matches.map((m) {
          final hexString = m.group(1)!;
          return Color(int.parse('FF$hexString', radix: 16));
        }).toList();
      }
    } catch (_) {}
    return [const Color(0xFF7C3AED), const Color(0xFFEC4899)];
  }

  Widget _buildEmojiSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text('Biểu tượng (Emoji):', style: GoogleFonts.quicksand(color: Colors.white70, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        GridView.extent(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          maxCrossAxisExtent: 56,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: _availableEmojis.map((emoji) {
            final isSelected = _selectedEmoji == emoji;
            return GestureDetector(
              onTap: () => setState(() => _selectedEmoji = emoji),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF7C3AED) : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF7C3AED) : Colors.white.withValues(alpha: 0.1),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [BoxShadow(color: const Color(0xFF7C3AED).withValues(alpha: 0.4), blurRadius: 8, spreadRadius: 1)]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(emoji, style: const TextStyle(fontSize: 20)),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildGradientSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text('Màu nền hiển thị:', style: GoogleFonts.quicksand(color: Colors.white70, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        GridView.extent(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          maxCrossAxisExtent: 64,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: _availableGradients.map((grad) {
            final colors = _parseCssGradient(grad);
            final isSelected = _selectedGradient == grad;
            return GestureDetector(
              onTap: () => setState(() => _selectedGradient = grad),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.1),
                    width: isSelected ? 3 : 1,
                  ),
                  boxShadow: isSelected
                      ? [BoxShadow(color: colors.first.withValues(alpha: 0.5), blurRadius: 8, spreadRadius: 2)]
                      : null,
                ),
                child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Cho phép quản trị viên chọn bất kỳ danh mục nào, hoặc chỉ danh mục có canSuggestProducts.
    // Ở đây, hiển thị tất cả danh mục để tránh lỗi missing DropdownMenuItem.
    final categories = EventCategory.all;

    // Safeguard the selected value again during build just in case.
    if (!categories.any((c) => c.id == _selectedCategoryId)) {
      _selectedCategoryId = 'other';
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.occasion == null ? 'Thêm Sự Kiện' : 'Sửa Sự Kiện',
          style: GoogleFonts.quicksand(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  _buildTextField('Tên (Tiếng Việt)', _nameViController),
                  _buildTextField('Tên (Tiếng Anh)', _nameEnController),
                  _buildDateField(),
                  
                  const SizedBox(height: 16),
                  _buildEmojiSelector(),
                  _buildGradientSelector(),
                  
                  const SizedBox(height: 8),
                  Text('Danh mục gốc:', style: GoogleFonts.quicksand(color: Colors.white70, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategoryId,
                    dropdownColor: const Color(0xFF1A1A2E),
                    style: GoogleFonts.quicksand(color: Colors.white),
                    decoration: InputDecoration(
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF7C3AED)),
                      ),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                    ),
                    items: categories.map((cat) {
                      return DropdownMenuItem(
                        value: cat.id,
                        child: Text('${cat.emoji} ${cat.name}'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCategoryId = val);
                    },
                  ),
                  
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        'LƯU LẠI',
                        style: GoogleFonts.quicksand(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}
