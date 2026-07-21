import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/anniversary.dart';

/// Card hiển thị một kỷ niệm trong danh sách
class CountdownCard extends StatelessWidget {
  final Anniversary anniversary;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool isFeatured;

  const CountdownCard({
    super.key,
    required this.anniversary,
    this.onTap,
    this.onDelete,
    this.isFeatured = false,
  });

  @override
  Widget build(BuildContext context) {
    final days = anniversary.daysRemaining;
    final isPast = days < 0;
    final isToday = days == 0;

    final cardColor = anniversary.color;
    final displayDate = anniversary.displayDate;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(
          vertical: isFeatured ? 0 : 6,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isFeatured ? 24 : 18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cardColor.withValues(alpha: 0.25),
              cardColor.withValues(alpha: 0.08),
            ],
          ),
          border: Border.all(
            color: cardColor.withValues(alpha: 0.4),
            width: isFeatured ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: cardColor.withValues(alpha: 0.2),
              blurRadius: isFeatured ? 20 : 8,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(isFeatured ? 24 : 18),
          child: Stack(
            children: [
              // Gradient glow phía trên bên phải
              Positioned(
                top: -20,
                right: -20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cardColor.withValues(alpha: 0.15),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(isFeatured ? 20 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Emoji
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: cardColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            anniversary.emoji,
                            style: TextStyle(fontSize: isFeatured ? 28 : 22),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Title + date
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                anniversary.title,
                                style: GoogleFonts.quicksand(
                                  fontSize: isFeatured ? 20 : 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today_rounded,
                                    size: 12,
                                    color: Colors.white54,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    DateFormat('dd/MM/yyyy').format(displayDate),
                                    style: GoogleFonts.quicksand(
                                      fontSize: 13,
                                      color: Colors.white54,
                                    ),
                                  ),
                                  if (anniversary.isYearly) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: cardColor.withValues(alpha: 0.3),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '↺ năm',
                                        style: GoogleFonts.quicksand(
                                          fontSize: 10,
                                          color: cardColor.withValues(alpha: 0.9),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                  if (anniversary.category.canSuggestProducts) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '🛍️ Quà',
                                        style: GoogleFonts.quicksand(
                                          fontSize: 10,
                                          color: const Color(0xFF10B981),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Nút xóa
                        if (onDelete != null)
                          IconButton(
                            onPressed: onDelete,
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.white38,
                              size: 20,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Countdown badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _badgeColor(isToday, isPast, cardColor),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _countdownText(days),
                        style: GoogleFonts.quicksand(
                          fontSize: isFeatured ? 16 : 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (anniversary.note.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        anniversary.note,
                        style: GoogleFonts.quicksand(
                          fontSize: 13,
                          color: Colors.white54,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _badgeColor(bool isToday, bool isPast, Color card) {
    if (isToday) return Colors.amber.shade700;
    if (isPast) return Colors.red.shade800.withValues(alpha: 0.7);
    return card.withValues(alpha: 0.4);
  }

  String _countdownText(int days) {
    if (days == 0) return '🎊 Hôm nay!';
    if (days > 0) return '⏳ Còn $days ngày';
    return '✓ Đã qua ${-days} ngày';
  }
}
