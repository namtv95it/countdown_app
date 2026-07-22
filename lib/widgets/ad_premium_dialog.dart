import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/ad_service.dart';
import 'premium_dialog.dart';

class AdPremiumDialog extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final VoidCallback onAdWatched;

  const AdPremiumDialog({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    required this.onAdWatched,
  });

  static void show(
    BuildContext context, {
    required String title,
    required String message,
    required IconData icon,
    required VoidCallback onAdWatched,
  }) {
    showDialog(
      context: context,
      builder: (context) => AdPremiumDialog(
        title: title,
        message: message,
        icon: icon,
        onAdWatched: onAdWatched,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E36),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(icon, color: Colors.amber),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.quicksand(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: GoogleFonts.quicksand(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.workspace_premium_rounded, color: Colors.amber, size: 20),
              label: Text(
                'Nâng cấp Premium (\$2.00)',
                style: GoogleFonts.quicksand(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                  fontSize: 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF14142B),
                elevation: 0,
                side: const BorderSide(color: Colors.amber, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.pop(context);
                PremiumDialog.show(
                  context,
                  onPremiumUnlocked: () {
                    // Trigger action automatically if premium is purchased.
                    onAdWatched();
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.play_circle_filled_rounded, size: 20, color: Colors.white),
              label: Text(
                'Xem Quảng Cáo (Miễn phí)',
                style: GoogleFonts.quicksand(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.pop(context);
                AdService.showRewardedAd(
                  onEarnedReward: onAdWatched,
                );
              },
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Hủy', style: GoogleFonts.quicksand(color: Colors.white54)),
        ),
      ],
    );
  }
}
