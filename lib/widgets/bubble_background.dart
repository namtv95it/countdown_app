import 'dart:math';
import 'package:flutter/material.dart';

class BubbleBackground extends StatefulWidget {
  final int bubbleCount;
  final Color bubbleColor;

  const BubbleBackground({
    super.key,
    this.bubbleCount = 30,
    this.bubbleColor = Colors.white,
  });

  @override
  State<BubbleBackground> createState() => _BubbleBackgroundState();
}

class _BubbleBackgroundState extends State<BubbleBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Bubble> _bubbles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bubbles.isEmpty) {
      final size = MediaQuery.of(context).size;
      for (int i = 0; i < widget.bubbleCount; i++) {
        _bubbles.add(Bubble(
          x: _random.nextDouble() * size.width,
          y: _random.nextDouble() * size.height,
          radius: _random.nextDouble() * 25 + 5,
          speed: _random.nextDouble() * 1.0 + 0.2,
          color: widget.bubbleColor.withOpacity(_random.nextDouble() * 0.15 + 0.05),
        ));
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Update bubbles positions
        final size = MediaQuery.of(context).size;
        for (var bubble in _bubbles) {
          bubble.y -= bubble.speed;
          // Thêm dao động ngang mượt mà
          bubble.x += sin(bubble.y * 0.03) * 0.4;
          if (bubble.y < -bubble.radius) {
            bubble.y = size.height + bubble.radius;
            bubble.x = _random.nextDouble() * size.width;
          }
        }

        return CustomPaint(
          painter: BubblePainter(bubbles: _bubbles),
          size: Size.infinite,
        );
      },
    );
  }
}

class Bubble {
  double x;
  double y;
  double radius;
  double speed;
  Color color;

  Bubble({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.color,
  });
}

class BubblePainter extends CustomPainter {
  final List<Bubble> bubbles;

  BubblePainter({required this.bubbles});

  @override
  void paint(Canvas canvas, Size size) {
    for (var bubble in bubbles) {
      final paint = Paint()
        ..color = bubble.color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(bubble.x, bubble.y), bubble.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
