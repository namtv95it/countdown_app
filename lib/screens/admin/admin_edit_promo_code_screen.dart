import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminEditPromoCodeScreen extends StatefulWidget {
  final String? docId;
  final Map<String, dynamic>? initialData;

  const AdminEditPromoCodeScreen({
    super.key,
    this.docId,
    this.initialData,
  });

  @override
  State<AdminEditPromoCodeScreen> createState() => _AdminEditPromoCodeScreenState();
}

class _AdminEditPromoCodeScreenState extends State<AdminEditPromoCodeScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _codeController;
  late TextEditingController _descriptionController;
  late TextEditingController _maxUsageController;
  late TextEditingController _durationDaysController;

  String _selectedType = 'premium';
  String? _selectedEffectId;
  DateTime? _expirationDate;

  bool _isSaving = false;

  final List<String> _effects = [
    'hearts',
    'bubbles',
    'snow',
    'stars',
    'meteor',
    'rain',
    'rain_ripple',
    'rainbow',
    'waves',
    'leaves',
    'sunset_birds',
    'aurora',
    'fireflies',
    'fireworks',
    'cherry_blossom',
    'galaxy',
  ];

  @override
  void initState() {
    super.initState();
    final data = widget.initialData;

    _codeController = TextEditingController(text: data?['code'] ?? '');
    _descriptionController = TextEditingController(text: data?['description'] ?? '');
    _maxUsageController = TextEditingController(text: data?['maxUsage']?.toString() ?? '');
    _durationDaysController = TextEditingController(text: data?['durationDays']?.toString() ?? '');

    if (data != null) {
      _selectedType = data['type'] ?? 'premium';
      _selectedEffectId = data['unlockedEffectId'];
      if (data['expirationDate'] != null) {
        _expirationDate = (data['expirationDate'] as Timestamp).toDate();
      }
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _descriptionController.dispose();
    _maxUsageController.dispose();
    _durationDaysController.dispose();
    super.dispose();
  }

  Future<void> _selectExpirationDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _expirationDate ?? now.add(const Duration(days: 30)),
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 10)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF10B981),
              onPrimary: Colors.black,
              surface: Color(0xFF1A1A2E),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_expirationDate ?? now),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFF10B981),
                onPrimary: Colors.black,
                surface: Color(0xFF1A1A2E),
                onSurface: Colors.white,
              ),
            ),
            child: child!,
          );
        },
      );

      if (time != null) {
        setState(() {
          _expirationDate = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final code = _codeController.text.trim().toUpperCase();
      final description = _descriptionController.text.trim();
      final maxUsageVal = _maxUsageController.text.trim();
      final durationDaysVal = _durationDaysController.text.trim();

      final int? maxUsage = maxUsageVal.isNotEmpty ? int.tryParse(maxUsageVal) : null;
      final num? durationDays = durationDaysVal.isNotEmpty ? num.tryParse(durationDaysVal) : null;

      final data = <String, dynamic>{
        'code': code,
        'type': _selectedType,
        'description': description.isNotEmpty ? description : null,
        'maxUsage': maxUsage,
        'durationDays': durationDays,
        'expirationDate': _expirationDate != null ? Timestamp.fromDate(_expirationDate!) : null,
      };

      if (_selectedType == 'giftEffect') {
        data['unlockedEffectId'] = _selectedEffectId;
      } else {
        data['unlockedEffectId'] = FieldValue.delete();
      }

      final docId = widget.docId ?? code; // Use code as doc ID if creating new to prevent duplicates easily

      if (widget.docId == null) {
        // Creating new. Check if code already exists.
        final existingDoc = await FirebaseFirestore.instance.collection('promo_codes').doc(docId).get();
        if (existingDoc.exists && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lỗi: Mã code này đã tồn tại trên hệ thống!'), backgroundColor: Colors.red),
          );
          setState(() => _isSaving = false);
          return;
        }
        data['usedCount'] = 0;
      }

      await FirebaseFirestore.instance.collection('promo_codes').doc(docId).set(data, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.docId == null ? 'Đã thêm promo code thành công!' : 'Đã cập nhật promo code thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi lưu: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.docId == null;
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          isNew ? 'Thêm Promo Code' : 'Sửa Promo Code',
          style: GoogleFonts.quicksand(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Code field
                    Text(
                      'Mã Code * (Tự động in hoa, tối thiểu 5 ký tự)',
                      style: GoogleFonts.quicksand(color: Colors.white70, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _codeController,
                      enabled: isNew, // Can't change code after creation, must delete and recreate
                      style: GoogleFonts.quicksand(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Ví dụ: PREMIUM2026',
                        hintStyle: GoogleFonts.quicksand(color: Colors.white38),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: isNew ? BorderSide.none : const BorderSide(color: Colors.white24),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập mã code';
                        }
                        if (value.trim().length < 5) {
                          return 'Mã code phải từ 5 ký tự trở lên';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Type field
                    Text(
                      'Loại phần quà *',
                      style: GoogleFonts.quicksand(color: Colors.white70, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedType,
                      dropdownColor: const Color(0xFF1A1A2E),
                      style: GoogleFonts.quicksand(color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'premium', child: Text('Premium')),
                        DropdownMenuItem(value: 'giftEffect', child: Text('Hiệu ứng (Gift Effect)')),
                        DropdownMenuItem(value: 'testMode', child: Text('Chế độ Test (Test Mode)')),
                        DropdownMenuItem(value: 'admin', child: Text('Admin Mode')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedType = val;
                            if (_selectedType == 'giftEffect' && _selectedEffectId == null) {
                              _selectedEffectId = _effects.first;
                            }
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Effect Dropdown (conditional)
                    if (_selectedType == 'giftEffect') ...[
                      Text(
                        'Hiệu ứng nhận được *',
                        style: GoogleFonts.quicksand(color: Colors.white70, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedEffectId,
                        dropdownColor: const Color(0xFF1A1A2E),
                        style: GoogleFonts.quicksand(color: Colors.white),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.05),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: _effects.map((eff) {
                          return DropdownMenuItem(value: eff, child: Text(eff));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedEffectId = val);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Description field
                    Text(
                      'Mô tả (Hiển thị khi nhập thành công)',
                      style: GoogleFonts.quicksand(color: Colors.white70, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      style: GoogleFonts.quicksand(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Ví dụ: Nhận bản Premium vĩnh viễn',
                        hintStyle: GoogleFonts.quicksand(color: Colors.white38),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Max Usage
                    Text(
                      'Số lượng giới hạn (Max usages - Trống = Vô hạn)',
                      style: GoogleFonts.quicksand(color: Colors.white70, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _maxUsageController,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.quicksand(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Ví dụ: 100',
                        hintStyle: GoogleFonts.quicksand(color: Colors.white38),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final parsed = int.tryParse(value);
                          if (parsed == null || parsed <= 0) {
                            return 'Vui lòng nhập một số nguyên dương';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Duration Days
                    Text(
                      'Số ngày hiệu lực phần quà (Trống = Vĩnh viễn)',
                      style: GoogleFonts.quicksand(color: Colors.white70, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _durationDaysController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: GoogleFonts.quicksand(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Ví dụ: 30 hoặc 0.5 (12 tiếng)',
                        hintStyle: GoogleFonts.quicksand(color: Colors.white38),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final parsed = double.tryParse(value);
                          if (parsed == null || parsed <= 0) {
                            return 'Vui lòng nhập một số dương';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Expiration Date
                    Text(
                      'Thời hạn phải nhập mã (Hết ngày này không nhập được nữa)',
                      style: GoogleFonts.quicksand(color: Colors.white70, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _selectExpirationDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _expirationDate == null
                                  ? 'Vĩnh viễn (Không hết hạn)'
                                  : DateFormat('dd/MM/yyyy HH:mm').format(_expirationDate!.toLocal()),
                              style: GoogleFonts.quicksand(
                                color: _expirationDate == null ? Colors.white38 : Colors.white,
                              ),
                            ),
                            Row(
                              children: [
                                if (_expirationDate != null)
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: const Icon(Icons.clear, color: Colors.redAccent, size: 20),
                                    onPressed: () {
                                      setState(() => _expirationDate = null);
                                    },
                                  ),
                                const SizedBox(width: 8),
                                const Icon(Icons.calendar_today, color: Color(0xFF10B981)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          'Lưu Lại',
                          style: GoogleFonts.quicksand(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
