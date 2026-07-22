import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/anniversary.dart';
import '../models/event_category.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../services/ad_service.dart';
import '../widgets/time_unit_box.dart';
import '../widgets/emoji_picker_sheet.dart';
import '../widgets/ad_premium_dialog.dart';


class DetailScreen extends StatefulWidget {
  final Anniversary anniversary;

  const DetailScreen({super.key, required this.anniversary});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen>
    with SingleTickerProviderStateMixin {
  late Timer _timer;
  late Duration _remaining;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  final StorageService _storageService = StorageService();
  late Anniversary _currentAnniversary;
  bool _hasChanged = false;

  @override
  void initState() {
    super.initState();
    _currentAnniversary = widget.anniversary;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _updateRemaining());
    });
  }

  void _updateRemaining() {
    final target = _currentAnniversary.displayDate;
    // Đếm đến đầu ngày (00:00:00) — ngày kỷ niệm bắt đầu
    final targetDt = DateTime(target.year, target.month, target.day);
    final now = DateTime.now();
    _remaining = targetDt.isAfter(now) ? targetDt.difference(now) : Duration.zero;
  }

  @override
  void dispose() {
    _timer.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _goBack() async {
    if (_hasChanged) {
      final all = await _storageService.getAnniversaries();
      final idx = all.indexWhere((a) => a.id == _currentAnniversary.id);
      if (idx != -1) all[idx] = _currentAnniversary;
      await _storageService.saveAnniversaries(all);
    }
    if (mounted) Navigator.pop(context, _hasChanged ? _currentAnniversary : null);
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.white12),
          ),
          title: Text(
            'Xóa kỷ niệm?',
            style: GoogleFonts.quicksand(
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          content: Text(
            'Bạn có chắc muốn xóa "${widget.anniversary.title}" không?',
            style: GoogleFonts.quicksand(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child:
                  Text('Hủy', style: GoogleFonts.quicksand(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'Xóa',
                style: GoogleFonts.quicksand(
                  color: Colors.red.shade400,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (confirm == true) {
      await _storageService.deleteAnniversary(_currentAnniversary.id);
      if (mounted) Navigator.pop(context, 'deleted');
    }
  }

  Future<void> _pinEvent() async {
    await NotificationService().showPinnedNotification(_currentAnniversary);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('📌 Đã ghim sự kiện lên thanh thông báo!'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ann = _currentAnniversary;
    final cardColor = ann.color;
    final days = ann.daysRemaining;
    final isPast = days < 0;
    final isToday = days == 0;
    final displayDate = ann.displayDate;

    final hours = _remaining.inHours % 24;
    final minutes = _remaining.inMinutes % 60;
    final seconds = _remaining.inSeconds % 60;
    final daysLeft = _remaining.inDays;

    final yearStart = DateTime(displayDate.year, 1, 1);
    final yearEnd = DateTime(displayDate.year + 1, 1, 1);
    final eventInYear =
        DateTime(displayDate.year, displayDate.month, displayDate.day);
    final totalDays = yearEnd.difference(yearStart).inDays;
    final daysSinceYear = eventInYear.difference(yearStart).inDays;
    final yearProgress = daysSinceYear / totalDays;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _goBack();
      },
      child: Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFF0D0D1A),
          body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: const Color(0xFF0D0D1A),
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_rounded,
                color: Colors.white,
              ),
              onPressed: _goBack,
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.push_pin_rounded,
                  color: Colors.white,
                ),
                onPressed: _pinEvent,
              ),
              IconButton(
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red.shade300,
                ),
                onPressed: _confirmDelete,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      cardColor.withValues(alpha: 0.5),
                      const Color(0xFF0D0D1A),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),
                    GestureDetector(
                      onTap: _editEmoji,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          ScaleTransition(
                            scale: _pulseAnimation,
                            child: Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: cardColor.withValues(alpha: 0.2),
                                border: Border.all(
                                  color: cardColor.withValues(alpha: 0.5),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: cardColor.withValues(alpha: 0.4),
                                    blurRadius: 30,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  ann.emoji,
                                  style: const TextStyle(fontSize: 42),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Color(0xFF1A1A2E),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.edit_rounded, color: Colors.white70, size: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: GestureDetector(
                        onTap: _editTitle,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                ann.title,
                                style: GoogleFonts.quicksand(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.edit_rounded, color: Colors.white54, size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      DateFormat('EEEE, dd MMMM yyyy', 'vi').format(displayDate),
                      style: GoogleFonts.quicksand(
                        fontSize: 14,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Badge trạng thái
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isToday
                          ? Colors.amber.shade700
                          : isPast
                              ? Colors.red.shade800.withValues(alpha: 0.7)
                              : cardColor.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: isToday
                            ? Colors.amber.shade300
                            : isPast
                                ? Colors.red.shade300.withValues(alpha: 0.5)
                                : cardColor.withValues(alpha: 0.6),
                      ),
                    ),
                    child: Text(
                      isToday
                          ? '🎊 Hôm nay là ngày kỷ niệm!'
                          : isPast
                              ? '✓ Đã diễn ra ${-days} ngày trước'
                              : '⏳ Còn $days ngày nữa',
                      style: GoogleFonts.quicksand(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // Đếm ngược real-time
                if (isToday) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.4), width: 2),
                    ),
                    child: Column(
                      children: [
                        const Text('🎉', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 12),
                        Text(
                          'Chúc mừng',
                          style: GoogleFonts.quicksand(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.amber,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          ann.title,
                          style: GoogleFonts.quicksand(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Colors.amber,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Chúc bạn một ngày thật ý nghĩa và tràn đầy niềm vui.',
                          style: GoogleFonts.quicksand(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                ] else if (!isPast) ...[
                  Text(
                    'ĐẾM NGƯỢC',
                    style: GoogleFonts.quicksand(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white38,
                      letterSpacing: 2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TimeUnitBox(
                        value: daysLeft.toString().padLeft(2, '0'),
                        label: 'Ngày',
                        color: cardColor,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          ':',
                          style: GoogleFonts.quicksand(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: cardColor,
                          ),
                        ),
                      ),
                      TimeUnitBox(
                        value: hours.toString().padLeft(2, '0'),
                        label: 'Giờ',
                        color: cardColor,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          ':',
                          style: GoogleFonts.quicksand(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: cardColor,
                          ),
                        ),
                      ),
                      TimeUnitBox(
                        value: minutes.toString().padLeft(2, '0'),
                        label: 'Phút',
                        color: cardColor,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          ':',
                          style: GoogleFonts.quicksand(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: cardColor,
                          ),
                        ),
                      ),
                      TimeUnitBox(
                        value: seconds.toString().padLeft(2, '0'),
                        label: 'Giây',
                        color: cardColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                ],

                _buildProgressSection(
                  cardColor: cardColor,
                  yearProgress: yearProgress,
                  displayDate: displayDate,
                ),

                const SizedBox(height: 20),

                _buildInfoSection(ann, cardColor),

                if (ann.note.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildNoteSection(ann, cardColor),
                ],

                if (ann.category.canSuggestProducts) ...[
                  const SizedBox(height: 24),
                  _buildGiftSuggestionButton(cardColor),
                ],

                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    ),
      ],
    ),
    );
  }

  Widget _buildProgressSection({
    required Color cardColor,
    required double yearProgress,
    required DateTime displayDate,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: const Border.fromBorderSide(BorderSide(color: Colors.white12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Vị trí trong năm ${displayDate.year}',
                style: GoogleFonts.quicksand(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
              Text(
                '${(yearProgress * 100).toStringAsFixed(0)}%',
                style: GoogleFonts.quicksand(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: cardColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: yearProgress.clamp(0.0, 1.0),
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(cardColor),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '1 tháng 1',
                style: GoogleFonts.quicksand(fontSize: 11, color: Colors.white30),
              ),
              Text(
                '${displayDate.day}/${displayDate.month}',
                style: GoogleFonts.quicksand(
                  fontSize: 11,
                  color: cardColor.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '31 tháng 12',
                style: GoogleFonts.quicksand(fontSize: 11, color: Colors.white30),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(Anniversary ann, Color cardColor) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: const Border.fromBorderSide(BorderSide(color: Colors.white12)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: _editCategory,
            borderRadius: BorderRadius.circular(16),
            child: _buildInfoRow(
              Icons.category_rounded,
              'Danh mục',
              '${ann.category.emoji} ${ann.category.name}',
              cardColor,
              showEdit: true,
            ),
          ),
          const Divider(color: Colors.white12, height: 24),
          InkWell(
            onTap: _editDate,
            borderRadius: BorderRadius.circular(16),
            child: _buildInfoRow(
              Icons.calendar_today_rounded,
              'Ngày gốc',
              DateFormat('dd/MM/yyyy').format(ann.date),
              cardColor,
              showEdit: true,
            ),
          ),
          if (ann.isYearly) ...[
            const Divider(color: Colors.white12, height: 24),
            _buildInfoRow(
              Icons.event_repeat_rounded,
              'Lần kế tiếp',
              DateFormat('dd/MM/yyyy').format(ann.nextOccurrence),
              cardColor,
            ),
          ],
          const Divider(color: Colors.white12, height: 24),
          Row(
            children: [
              Icon(Icons.repeat_rounded, color: cardColor, size: 20),
              const SizedBox(width: 12),
              Text('Lặp lại hàng năm', style: GoogleFonts.quicksand(fontSize: 14, color: Colors.white54)),
              const Spacer(),
              SizedBox(
                height: 24,
                width: 44,
                child: Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: ann.isYearly,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    activeThumbColor: cardColor,
                    onChanged: (val) {
                      setState(() {
                        _currentAnniversary = Anniversary(
                          id: ann.id, title: ann.title, date: ann.date,
                          emoji: ann.emoji, colorValue: ann.colorValue,
                          isYearly: val, isLunar: ann.isLunar,
                          note: ann.note, categoryId: ann.categoryId,
                        );
                        _hasChanged = true;
                        _updateRemaining();
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white12, height: 24),
          Row(
            children: [
              Icon(Icons.nights_stay_rounded, color: cardColor, size: 20),
              const SizedBox(width: 12),
              Text('Tính theo Âm lịch', style: GoogleFonts.quicksand(fontSize: 14, color: Colors.white54)),
              const Spacer(),
              SizedBox(
                height: 24,
                width: 44,
                child: Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: ann.isLunar,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    activeThumbColor: cardColor,
                    onChanged: (val) {
                      setState(() {
                        _currentAnniversary = Anniversary(
                          id: ann.id, title: ann.title, date: ann.date,
                          emoji: ann.emoji, colorValue: ann.colorValue,
                          isYearly: ann.isYearly, isLunar: val,
                          note: ann.note, categoryId: ann.categoryId,
                        );
                        _hasChanged = true;
                        _updateRemaining();
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white12, height: 24),
          InkWell(
            onTap: _editColor,
            borderRadius: BorderRadius.circular(16),
            child: Row(
              children: [
                Icon(Icons.palette_rounded, color: cardColor, size: 20),
                const SizedBox(width: 12),
                Text('Màu sắc', style: GoogleFonts.quicksand(fontSize: 14, color: Colors.white54)),
                const Spacer(),
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: cardColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white30, width: 1.5),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right_rounded, color: Colors.white30, size: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
      IconData icon, String label, String value, Color cardColor, {bool showEdit = false}) {
    return Row(
      children: [
        Icon(icon, color: cardColor, size: 20),
        const SizedBox(width: 12),
        Text(
          label,
          style: GoogleFonts.quicksand(fontSize: 14, color: Colors.white54),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.quicksand(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        if (showEdit) ...[
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, color: Colors.white24, size: 18),
        ],
      ],
    );
  }

  Widget _buildNoteSection(Anniversary ann, Color cardColor) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cardColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.notes_rounded, color: cardColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              ann.note,
              style: GoogleFonts.quicksand(
                fontSize: 14,
                color: Colors.white70,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGiftSuggestionButton(Color cardColor) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cardColor.withValues(alpha: 0.2), cardColor.withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cardColor.withValues(alpha: 0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            // Đóng DetailScreen và báo cho HomeScreen mở tab Quà tặng
            Navigator.pop(context, 'gift:${_currentAnniversary.category.id}');
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cardColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gợi ý quà tặng',
                        style: GoogleFonts.quicksand(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tìm món quà ý nghĩa nhất',
                        style: GoogleFonts.quicksand(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.open_in_new_rounded, color: Colors.white.withValues(alpha: 0.5), size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _editEmoji() {
    EmojiPickerSheet.show(context, onEmojiSelected: (emoji) {
      if (emoji == _currentAnniversary.emoji) return;
      
      void applyEmoji() {
        setState(() {
          _currentAnniversary = Anniversary(
            id: _currentAnniversary.id,
            title: _currentAnniversary.title,
            date: _currentAnniversary.date,
            emoji: emoji,
            colorValue: _currentAnniversary.colorValue,
            isYearly: _currentAnniversary.isYearly,
            isLunar: _currentAnniversary.isLunar,
            note: _currentAnniversary.note,
            categoryId: _currentAnniversary.categoryId,
          );
          _hasChanged = true;
          _updateRemaining();
        });
      }

      if (!AdService.isPremium) {
        AdPremiumDialog.show(
          context,
          title: 'Biểu tượng tùy chỉnh',
          message: 'Xem 1 đoạn video quảng cáo ngắn hoặc Nâng cấp Premium để sử dụng biểu tượng tuyệt đẹp nhé!',
          icon: Icons.auto_awesome_rounded,
          onAdWatched: applyEmoji,
        );
      } else {
        applyEmoji();
      }
    });
  }

  Future<void> _editTitle() async {
    final controller = TextEditingController(text: _currentAnniversary.title);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Đổi tên sự kiện', style: GoogleFonts.quicksand(color: Colors.white, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          style: GoogleFonts.quicksand(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy', style: GoogleFonts.quicksand(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text('Lưu', style: GoogleFonts.quicksand(color: const Color(0xFFEC4899), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (newTitle != null && newTitle.isNotEmpty && newTitle != _currentAnniversary.title) {
      setState(() {
        _currentAnniversary = Anniversary(
          id: _currentAnniversary.id,
          title: newTitle,
          date: _currentAnniversary.date,
          emoji: _currentAnniversary.emoji,
          colorValue: _currentAnniversary.colorValue,
          isYearly: _currentAnniversary.isYearly,
          isLunar: _currentAnniversary.isLunar,
          note: _currentAnniversary.note,
          categoryId: _currentAnniversary.categoryId,
        );
        _hasChanged = true;
        _updateRemaining();
      });
    }
  }

  Future<void> _editDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _currentAnniversary.date,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: _currentAnniversary.color,
              surface: const Color(0xFF1A1A2E),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _currentAnniversary.date) {
      setState(() {
        _currentAnniversary = Anniversary(
          id: _currentAnniversary.id,
          title: _currentAnniversary.title,
          date: picked,
          emoji: _currentAnniversary.emoji,
          colorValue: _currentAnniversary.colorValue,
          isYearly: _currentAnniversary.isYearly,
          isLunar: _currentAnniversary.isLunar,
          note: _currentAnniversary.note,
          categoryId: _currentAnniversary.categoryId,
        );
        _hasChanged = true;
        _updateRemaining();
      });
    }
  }

  void _editCategory() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A2E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Chọn danh mục', style: GoogleFonts.quicksand(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 20),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: EventCategory.all.length,
                itemBuilder: (context, index) {
                  final cat = EventCategory.all[index];
                  return ListTile(
                    leading: Text(cat.emoji, style: const TextStyle(fontSize: 24)),
                    title: Text(cat.name, style: GoogleFonts.quicksand(color: Colors.white)),
                    onTap: () {
                      setState(() {
                        _currentAnniversary = Anniversary(
                          id: _currentAnniversary.id,
                          title: _currentAnniversary.title,
                          date: _currentAnniversary.date,
                          emoji: cat.emoji,
                          colorValue: cat.colorValue,
                          isYearly: _currentAnniversary.isYearly,
                          isLunar: _currentAnniversary.isLunar,
                          note: _currentAnniversary.note,
                          categoryId: cat.id,
                        );
                        _hasChanged = true;
                        _updateRemaining();
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editColor() {
    const colorOptions = [
      0xFF7C3AED, 0xFFEC4899, 0xFF06B6D4, 0xFF10B981,
      0xFFF59E0B, 0xFFEF4444, 0xFF8B5CF6, 0xFF3B82F6,
      0xFFFF6B6B, 0xFF4ECDC4,
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A2E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            Text('Chọn màu sắc', style: GoogleFonts.quicksand(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 24),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              alignment: WrapAlignment.center,
              children: colorOptions.map((colorVal) {
                final isSelected = colorVal == _currentAnniversary.colorValue;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentAnniversary = Anniversary(
                        id: _currentAnniversary.id,
                        title: _currentAnniversary.title,
                        date: _currentAnniversary.date,
                        emoji: _currentAnniversary.emoji,
                        colorValue: colorVal,
                        isYearly: _currentAnniversary.isYearly,
                        isLunar: _currentAnniversary.isLunar,
                        note: _currentAnniversary.note,
                        categoryId: _currentAnniversary.categoryId,
                      );
                      _hasChanged = true;
                      _updateRemaining();
                    });
                    Navigator.pop(context);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Color(colorVal),
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 3)
                          : Border.all(color: Colors.transparent, width: 3),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Color(colorVal).withValues(alpha: 0.6),
                                blurRadius: 12,
                                spreadRadius: 2,
                              )
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 22)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

}
