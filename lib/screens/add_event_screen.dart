import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/anniversary.dart';
import '../models/event_category.dart';
import '../data/preset_holidays.dart';
import '../services/ad_service.dart';
import '../services/storage_service.dart';

class AddEventScreen extends StatefulWidget {
  final List<Anniversary> existingEvents;

  const AddEventScreen({
    super.key,
    this.existingEvents = const [],
  });

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();

  DateTime? _selectedDate;
  String _selectedCategoryId = 'other';
  int _selectedColorValue = 0xFF64748B;
  bool _isYearly = false;
  bool _isPremiumColorsUnlocked = false;

  String get _selectedEmoji => EventCategory.findById(_selectedCategoryId).emoji;

  @override
  void initState() {
    super.initState();
    _loadPremiumStatus();
  }

  Future<void> _loadPremiumStatus() async {
    final unlocked = await StorageService().isFeatureUnlocked('premium_colors');
    if (mounted) {
      setState(() {
        _isPremiumColorsUnlocked = unlocked;
      });
    }
  }

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
      // Hiển thị quảng cáo toàn màn hình khi lưu sự kiện thành công
      AdService.showInterstitialAd();
      
      final event = Anniversary(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        date: _selectedDate!,
        emoji: _selectedEmoji,
        colorValue: _selectedColorValue,
        isYearly: _isYearly,
        note: _noteController.text.trim(),
        categoryId: _selectedCategoryId,
      );
      Navigator.pop(context, event);
    } else if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade800,
          content: Text('Vui lòng chọn ngày!', style: GoogleFonts.quicksand()),
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
          style: GoogleFonts.quicksand(
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
            // _buildPreviewCard(),
            // const SizedBox(height: 16),
            _buildPresetButton(),
            const SizedBox(height: 24),
            _buildSectionLabel('Tên kỷ niệm'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _titleController,
              hint: 'VD: Sinh nhật vợ yêu...',
              icon: Icons.edit_rounded,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tên' : null,
            ),
            const SizedBox(height: 20),
            _buildSectionLabel('Ngày'),
            const SizedBox(height: 8),
            _buildDatePicker(),
            const SizedBox(height: 20),
            _buildSectionLabel('Danh mục sự kiện'),
            const SizedBox(height: 8),
            _buildCategoryPicker(),
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
                  style: GoogleFonts.quicksand(
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
                  style: GoogleFonts.quicksand(fontSize: 13, color: Colors.white54),
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
              style: GoogleFonts.quicksand(
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
      style: GoogleFonts.quicksand(
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
      style: GoogleFonts.quicksand(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.quicksand(color: Colors.white30),
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
              style: GoogleFonts.quicksand(
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

  Widget _buildCategoryPicker() {
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
        children: EventCategory.all.map((cat) {
          final selected = cat.id == _selectedCategoryId;
          final catColor = Color(cat.colorValue);
          return GestureDetector(
            onTap: () => setState(() {
              _selectedCategoryId = cat.id;
              _selectedColorValue = cat.colorValue;
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: selected
                    ? catColor.withValues(alpha: 0.25)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected
                      ? catColor.withValues(alpha: 0.7)
                      : Colors.white12,
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(cat.emoji, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 6),
                  Text(
                    cat.name,
                    style: GoogleFonts.quicksand(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? Colors.white : Colors.white60,
                    ),
                  ),
                  if (cat.canSuggestProducts) ...[
                    const SizedBox(width: 4),
                    Text('🛍️', style: const TextStyle(fontSize: 10)),
                  ],
                ],
              ),
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
      children: List.generate(_colorOptions.length, (index) {
        final colorVal = _colorOptions[index];
        final selected = colorVal == _selectedColorValue;
        final isPremium = index >= 5;
        final isLocked = isPremium && !_isPremiumColorsUnlocked;

        return GestureDetector(
          onTap: () {
            if (isLocked) {
              _showUnlockColorsDialog(colorVal);
            } else {
              setState(() => _selectedColorValue = colorVal);
            }
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedContainer(
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
              if (isLocked)
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.4),
                  ),
                  child: const Icon(Icons.lock_rounded, color: Colors.white, size: 18),
                ),
            ],
          ),
        );
      }),
    );
  }

  void _showUnlockColorsDialog(int targetColor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.white12),
        ),
        title: Row(
          children: [
            const Icon(Icons.stars_rounded, color: Colors.amber),
            const SizedBox(width: 10),
            Text('Mở khóa Màu Premium',
                style: GoogleFonts.quicksand(
                    color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Text(
          'Xem 1 đoạn video ngắn để mở khóa vĩnh viễn trọn bộ màu nền đặc biệt cho sự kiện này nhé!',
          style: GoogleFonts.quicksand(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy', style: GoogleFonts.quicksand(color: Colors.white54)),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.play_circle_filled_rounded),
            label: Text('Xem Video', style: GoogleFonts.quicksand(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(context); // Đóng dialog
              // Gọi dịch vụ hiển thị quảng cáo
              AdService.showRewardedAd(
                onEarnedReward: () async {
                  await StorageService().unlockFeature('premium_colors');
                  if (mounted) {
                    setState(() {
                      _isPremiumColorsUnlocked = true;
                      _selectedColorValue = targetColor;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('🎉 Đã mở khóa vĩnh viễn bộ màu Premium!'),
                        backgroundColor: const Color(0xFF10B981),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  }
                },
              );
            },
          ),
        ],
      ),
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
                  style: GoogleFonts.quicksand(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Tự động cập nhật sang năm tiếp theo',
                  style: GoogleFonts.quicksand(
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
            style: GoogleFonts.quicksand(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPresetButton() {
    return GestureDetector(
      onTap: _showPresetHolidaysSheet,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF7C3AED).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🌟', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              'Chọn từ ngày lễ có sẵn',
              style: GoogleFonts.quicksand(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF7C3AED),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPresetHolidaysSheet() {
    final Set<PresetHoliday> selectedHolidays = {};

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Color(0xFF1A1A2E),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ngày lễ phổ biến',
                    style: GoogleFonts.quicksand(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        ActionChip(
                          label: const Text('🇻🇳 Chọn Việt Nam'),
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          labelStyle: GoogleFonts.quicksand(color: Colors.white, fontSize: 13),
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          onPressed: () {
                            setModalState(() {
                              for (var h in PresetHolidays.all.where((h) => h.badge == 'Việt Nam')) {
                                if (!widget.existingEvents.any((e) => e.title == h.title)) {
                                  selectedHolidays.add(h);
                                }
                              }
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        ActionChip(
                          label: const Text('🌍 Chọn Quốc tế'),
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          labelStyle: GoogleFonts.quicksand(color: Colors.white, fontSize: 13),
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          onPressed: () {
                            setModalState(() {
                              for (var h in PresetHolidays.all.where((h) => h.badge == 'Quốc tế')) {
                                if (!widget.existingEvents.any((e) => e.title == h.title)) {
                                  selectedHolidays.add(h);
                                }
                              }
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        ActionChip(
                          label: const Text('✕ Bỏ chọn tất cả'),
                          backgroundColor: Colors.white.withValues(alpha: 0.05),
                          labelStyle: GoogleFonts.quicksand(color: Colors.white70, fontSize: 13),
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          onPressed: () {
                            setModalState(() {
                              selectedHolidays.clear();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        _buildPresetSection('Tất cả ngày lễ', PresetHolidays.all, selectedHolidays, setModalState),
                        const SizedBox(height: 100), // padding for bottom bar
                      ],
                    ),
                  ),
                  // Bottom Bar
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                    decoration: BoxDecoration(
                      color: const Color(0xFF12122A),
                      border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 20,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Đã chọn: ${selectedHolidays.length}',
                            style: GoogleFonts.quicksand(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: selectedHolidays.isEmpty ? null : () {
                            // Tạo list Anniversary từ set
                            final now = DateTime.now();
                            final List<Anniversary> resultList = [];
                            
                            for (var h in selectedHolidays) {
                              // Lưu ngày/tháng âm (hoặc dương) vào date,
                              // Anniversary.nextOccurrence sẽ tự tính đúng ngày hiển thị
                              final DateTime storeDate = DateTime(now.year, h.month, h.day);
                              resultList.add(
                                Anniversary(
                                  id: '${DateTime.now().microsecondsSinceEpoch}${resultList.length}',
                                  title: h.title,
                                  date: storeDate,
                                  emoji: h.emoji,
                                  colorValue: h.colorValue,
                                  isYearly: true,
                                  isLunar: h.isLunar,
                                  note: '',
                                  categoryId: h.categoryId,
                                )
                              );
                            }
                            // Đóng modal và trả về List
                            Navigator.pop(context);
                            Navigator.pop(context, resultList);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7C3AED),
                            disabledBackgroundColor: Colors.white12,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            'Thêm ${selectedHolidays.length} ngày',
                            style: GoogleFonts.quicksand(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: selectedHolidays.isEmpty ? Colors.white38 : Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPresetSection(
      String title, List<PresetHoliday> holidays, Set<PresetHoliday> selectedHolidays, StateSetter setModalState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.quicksand(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white54,
          ),
        ),
        const SizedBox(height: 12),
        ...holidays.map((h) => _buildPresetTile(h, selectedHolidays, setModalState)),
      ],
    );
  }

  Widget _buildPresetTile(PresetHoliday h, Set<PresetHoliday> selectedHolidays, StateSetter setModalState) {
    final isAlreadyAdded = widget.existingEvents.any((e) => e.title == h.title);
    final isSelected = selectedHolidays.contains(h);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isAlreadyAdded 
            ? Colors.white.withValues(alpha: 0.02)
            : isSelected 
                ? const Color(0xFF7C3AED).withValues(alpha: 0.15) 
                : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAlreadyAdded
              ? Colors.transparent
              : isSelected 
                  ? const Color(0xFF7C3AED) 
                  : Colors.white12,
        ),
      ),
      child: ListTile(
        tileColor: Colors.transparent,
        splashColor: Colors.white.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Opacity(
          opacity: isAlreadyAdded ? 0.3 : 1.0,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Color(h.colorValue).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(h.emoji, style: const TextStyle(fontSize: 20)),
            ),
          ),
        ),
        title: Text(
          h.title,
          style: GoogleFonts.quicksand(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isAlreadyAdded ? Colors.white38 : Colors.white,
          ),
        ),
        subtitle: Opacity(
          opacity: isAlreadyAdded ? 0.3 : 1.0,
          child: Row(
            children: [
              Text(
                h.isLunar ? '${h.day}/${h.month} (Âm lịch)' : '${h.day}/${h.month}',
                style: GoogleFonts.quicksand(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: h.isLunar
                      ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: h.isLunar
                      ? Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4), width: 0.5)
                      : null,
                ),
                child: Text(
                  h.badge,
                  style: GoogleFonts.quicksand(
                    color: h.isLunar ? const Color(0xFFF59E0B) : Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        trailing: isAlreadyAdded
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Đã thêm',
                  style: GoogleFonts.quicksand(
                    color: Colors.white38,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            : Icon(
                isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                color: isSelected ? const Color(0xFF7C3AED) : Colors.white38,
              ),
        onTap: isAlreadyAdded 
            ? null 
            : () {
                setModalState(() {
                  if (isSelected) {
                    selectedHolidays.remove(h);
                  } else {
                    selectedHolidays.add(h);
                  }
                });
              },
      ),
    );
  }
}
