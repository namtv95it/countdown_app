import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/anniversary.dart';

class AddEventScreen extends StatefulWidget {
  const AddEventScreen({super.key});

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();

  DateTime? _selectedDate;
  String _selectedEmoji = '🎉';
  int _selectedColorValue = 0xFF7C3AED;
  bool _isYearly = false;

  static const List<String> _emojiList = [
    '🎉', '🎂', '💑', '💍', '🎓', '🏆', '🌸', '💝',
    '🎊', '🌟', '🥂', '🎁', '🏠', '✈️', '🌈', '❤️',
    '🎵', '🌺', '🎄', '🙏', '🤝', '👶', '🐾', '📅',
  ];

  static const List<int> _colorOptions = [
    0xFF7C3AED,
    0xFFEC4899,
    0xFF06B6D4,
    0xFF10B981,
    0xFFF59E0B,
    0xFFEF4444,
    0xFF8B5CF6,
    0xFF3B82F6,
    0xFFFF6B6B,
    0xFF4ECDC4,
  ];

  void _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF7C3AED),
              onPrimary: Colors.white,
              surface: Color(0xFF1A1A2E),
              onSurface: Colors.white,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: Color(0xFF1A1A2E),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _saveEvent() {
    if (_formKey.currentState!.validate() && _selectedDate != null) {
      final event = Anniversary(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        date: _selectedDate!,
        emoji: _selectedEmoji,
        colorValue: _selectedColorValue,
        isYearly: _isYearly,
        note: _noteController.text.trim(),
      );
      Navigator.pop(context, event);
    } else if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade800,
          content: Text('Vui lòng chọn ngày!', style: GoogleFonts.outfit()),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D1A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Thêm Kỷ niệm',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildPreviewCard(),
            const SizedBox(height: 28),
            _buildSectionLabel('Tên kỷ niệm'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _titleController,
              hint: 'VD: Sinh nhật bạn thân...',
              icon: Icons.edit_rounded,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tên' : null,
            ),
            const SizedBox(height: 20),
            _buildSectionLabel('Ngày'),
            const SizedBox(height: 8),
            _buildDatePicker(),
            const SizedBox(height: 20),
            _buildSectionLabel('Biểu tượng'),
            const SizedBox(height: 8),
            _buildEmojiPicker(),
            const SizedBox(height: 20),
            _buildSectionLabel('Màu sắc'),
            const SizedBox(height: 8),
            _buildColorPicker(),
            const SizedBox(height: 20),
            _buildYearlyToggle(),
            const SizedBox(height: 20),
            _buildSectionLabel('Ghi chú (tùy chọn)'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _noteController,
              hint: 'Thêm ghi chú cho kỷ niệm này...',
              icon: Icons.notes_rounded,
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            _buildSaveButton(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewCard() {
    final cardColor = Color(_selectedColorValue);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cardColor.withValues(alpha: 0.3),
            cardColor.withValues(alpha: 0.1),
          ],
        ),
        border: Border.all(color: cardColor.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Row(
        children: [
          Text(_selectedEmoji, style: const TextStyle(fontSize: 36)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _titleController.text.isEmpty
                      ? 'Tên kỷ niệm...'
                      : _titleController.text,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _titleController.text.isEmpty
                        ? Colors.white38
                        : Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedDate == null
                      ? 'Chưa chọn ngày'
                      : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                  style: GoogleFonts.outfit(fontSize: 13, color: Colors.white54),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: cardColor.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Preview',
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: cardColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.white54,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      onChanged: (_) => setState(() {}),
      validator: validator,
      style: GoogleFonts.outfit(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.outfit(color: Colors.white30),
        prefixIcon: Icon(icon, color: Colors.white38, size: 20),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.07),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.red.shade400),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _selectedDate != null
                ? const Color(0xFF7C3AED).withValues(alpha: 0.5)
                : Colors.white12,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_month_rounded,
              color: Color(0xFF7C3AED),
              size: 22,
            ),
            const SizedBox(width: 12),
            Text(
              _selectedDate == null
                  ? 'Chọn ngày...'
                  : DateFormat('EEEE, dd MMMM yyyy', 'vi')
                      .format(_selectedDate!),
              style: GoogleFonts.outfit(
                fontSize: 15,
                color: _selectedDate == null ? Colors.white30 : Colors.white,
                fontWeight: _selectedDate != null
                    ? FontWeight.w600
                    : FontWeight.w400,
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded, color: Colors.white30),
          ],
        ),
      ),
    );
  }

  Widget _buildEmojiPicker() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: const Border.fromBorderSide(BorderSide(color: Colors.white12)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _emojiList.map((emoji) {
          final selected = emoji == _selectedEmoji;
          return GestureDetector(
            onTap: () => setState(() => _selectedEmoji = emoji),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: selected
                    ? Color(_selectedColorValue).withValues(alpha: 0.3)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: selected
                    ? Border.all(
                        color:
                            Color(_selectedColorValue).withValues(alpha: 0.7),
                        width: 1.5,
                      )
                    : null,
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 24)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildColorPicker() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _colorOptions.map((colorVal) {
        final selected = colorVal == _selectedColorValue;
        return GestureDetector(
          onTap: () => setState(() => _selectedColorValue = colorVal),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Color(colorVal),
              shape: BoxShape.circle,
              border: selected
                  ? Border.all(color: Colors.white, width: 2.5)
                  : Border.all(color: Colors.transparent, width: 2.5),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: Color(colorVal).withValues(alpha: 0.6),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: selected
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildYearlyToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: const Border.fromBorderSide(BorderSide(color: Colors.white12)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.repeat_rounded,
            color: Color(0xFF7C3AED),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lặp lại hàng năm',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Tự động cập nhật sang năm tiếp theo',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: Colors.white38,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isYearly,
            onChanged: (v) => setState(() => _isYearly = v),
            activeThumbColor: Colors.white,
            activeTrackColor: const Color(0xFF7C3AED),
            inactiveTrackColor: Colors.white12,
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _saveEvent,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.5),
              blurRadius: 20,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Center(
          child: Text(
            'Lưu Kỷ niệm ✨',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
