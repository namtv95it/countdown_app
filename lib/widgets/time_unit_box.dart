import '../services/localization_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Widget hiển thị một đơn vị đếm ngược (ngày/giờ/phút/giây)
class TimeUnitBox extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const TimeUnitBox({
    super.key,
    required this.value,
    required this.label,
    this.color = const Color(0xFF7C3AED),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: GoogleFonts.quicksand(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.quicksand(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.white54,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
