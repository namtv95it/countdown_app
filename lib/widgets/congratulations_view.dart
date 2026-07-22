import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:google_fonts/google_fonts.dart';

class CongratulationsView extends StatefulWidget {
  final String title;

  const CongratulationsView({super.key, required this.title});

  @override
  State<CongratulationsView> createState() => _CongratulationsViewState();
}

class _CongratulationsViewState extends State<CongratulationsView> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 10));
    _confettiController.play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Column(
          children: [
            // ── Chúc mừng: layout gọn gàng, 1 dòng đẹp ──
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [
                  Color(0xFFFFD700),
                  Color(0xFFFFA500),
                  Color(0xFFFFD700),
                ],
              ).createShader(bounds),
              child: Text(
                '🎊 Chúc mừng!',
                style: GoogleFonts.quicksand(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hôm nay là ${widget.title}',
              style: GoogleFonts.quicksand(
                fontSize: 15,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        // Pháo hoa nổ từ trên xuống
        Positioned(
          top: -350, // Nằm tít phía trên cao sát nóc màn hình
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive, // Nổ tỏa ra mọi hướng
            maxBlastForce: 40, // Lực nổ vừa phải
            minBlastForce: 10,
            emissionFrequency: 0.05,
            numberOfParticles: 50, // Nhiều pháo hoa để trông rực rỡ
            gravity: 0.2, // Rơi từ từ xuống
            shouldLoop: false,
            colors: const [
              Colors.green, Colors.blue, Colors.pink, 
              Colors.orange, Colors.purple, Colors.yellow,
            ],
          ),
        ),
      ],
    );
  }
}
