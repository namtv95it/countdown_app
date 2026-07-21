import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/anniversary.dart';
import '../services/storage_service.dart';
import '../widgets/time_unit_box.dart';


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

  @override
  void initState() {
    super.initState();
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
    final target = widget.anniversary.displayDate;
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
      await _storageService.deleteAnniversary(widget.anniversary.id);
      if (mounted) Navigator.pop(context, null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ann = widget.anniversary;
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

    return Stack(
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
              onPressed: () => Navigator.pop(context, ann),
            ),
            actions: [
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
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
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
          _buildInfoRow(
            Icons.category_rounded,
            'Danh mục',
            '${ann.category.emoji} ${ann.category.name}',
            cardColor,
          ),
          if (ann.category.canSuggestProducts) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 32),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🛍️', style: TextStyle(fontSize: 11)),
                        const SizedBox(width: 4),
                        Text(
                          'Có thể gợi ý quà',
                          style: GoogleFonts.quicksand(
                            fontSize: 11,
                            color: const Color(0xFF10B981),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const Divider(color: Colors.white12, height: 24),
          _buildInfoRow(
            Icons.calendar_today_rounded,
            'Ngày gốc',
            DateFormat('dd/MM/yyyy').format(ann.date),
            cardColor,
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
          _buildInfoRow(
            ann.isYearly ? Icons.repeat_rounded : Icons.event_rounded,
            'Loại sự kiện',
            ann.isYearly ? 'Lặp lại hàng năm' : 'Một lần',
            cardColor,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
      IconData icon, String label, String value, Color cardColor) {
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
          onTap: () async {
            final url = Uri.parse('https://shopee.vn/search?keyword=qu%C3%A0%20t%E1%BA%B7ng');
            if (await canLaunchUrl(url)) {
              await launchUrl(url, mode: LaunchMode.externalApplication);
            }
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
}
