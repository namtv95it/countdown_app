import 'dart:math';
import 'package:flutter/material.dart';

class FireworksWidget extends StatefulWidget {
  const FireworksWidget({super.key});

  @override
  State<FireworksWidget> createState() => _FireworksWidgetState();
}

class _FireworksWidgetState extends State<FireworksWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Burst> _bursts = [];
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(() {
        _maybeAddBurst();
        setState(() {});
      });
    _controller.repeat();

    // Seed a few bursts immediately
    for (int i = 0; i < 3; i++) {
      _addBurst(startProgress: _rng.nextDouble());
    }
  }

  void _maybeAddBurst() {
    // Spawn a new burst roughly every 0.8s (staggered by value)
    final v = _controller.value;
    if ((v * 10).toInt() % 2 == 0 && _rng.nextDouble() < 0.04) {
      _addBurst();
    }
    _bursts.removeWhere((b) => b.isDead);
  }

  void _addBurst({double startProgress = 0}) {
    _bursts.add(_Burst(
      x: 0.1 + _rng.nextDouble() * 0.8,
      y: 0.05 + _rng.nextDouble() * 0.5,
      color: _randomColor(),
      particleCount: 14 + _rng.nextInt(10),
      startProgress: startProgress,
      speed: 0.12 + _rng.nextDouble() * 0.08,
    ));
  }

  Color _randomColor() {
    final palette = [
      const Color(0xFFFFD700),
      const Color(0xFFFF6B6B),
      const Color(0xFF6BCB77),
      const Color(0xFF4D96FF),
      const Color(0xFFFF9F43),
      const Color(0xFFEE5A24),
      const Color(0xFFD980FA),
      const Color(0xFFFFFFFF),
    ];
    return palette[_rng.nextInt(palette.length)];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _FireworksPainter(_bursts, _controller.value),
        size: Size.infinite,
      ),
    );
  }
}

class _Burst {
  final double x;
  final double y;
  final Color color;
  final int particleCount;
  final double speed;
  double progress;
  bool isDead = false;

  _Burst({
    required this.x,
    required this.y,
    required this.color,
    required this.particleCount,
    required this.speed,
    double startProgress = 0,
  }) : progress = startProgress;
}

class _FireworksPainter extends CustomPainter {
  final List<_Burst> bursts;
  final double tick;

  _FireworksPainter(this.bursts, this.tick);

  @override
  void paint(Canvas canvas, Size size) {
    for (final burst in bursts) {
      burst.progress = (burst.progress + burst.speed * 0.016).clamp(0.0, 1.0);
      if (burst.progress >= 1.0) {
        burst.isDead = true;
        continue;
      }

      final t = burst.progress; // 0 → 1
      final opacity = t < 0.2
          ? t / 0.2
          : (1.0 - (t - 0.2) / 0.8).clamp(0.0, 1.0);

      final centerX = burst.x * size.width;
      final centerY = burst.y * size.height;
      final maxRadius = size.width * 0.2 * t;

      final paint = Paint()
        ..color = burst.color.withValues(alpha: opacity)
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final dotPaint = Paint()
        ..color = burst.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      for (int i = 0; i < burst.particleCount; i++) {
        final angle = (2 * pi * i) / burst.particleCount;
        final trail = maxRadius * 0.35;
        final tipX = centerX + cos(angle) * maxRadius;
        final tipY = centerY + sin(angle) * maxRadius;
        final tailX = centerX + cos(angle) * (maxRadius - trail).clamp(0, double.infinity);
        final tailY = centerY + sin(angle) * (maxRadius - trail).clamp(0, double.infinity);

        canvas.drawLine(Offset(tailX, tailY), Offset(tipX, tipY), paint);

        // Tip dot
        canvas.drawCircle(Offset(tipX, tipY), 2.5, dotPaint);
      }

      // Center flash
      if (t < 0.15) {
        final flashOpacity = (1.0 - t / 0.15) * 0.8;
        final flashPaint = Paint()
          ..color = Colors.white.withValues(alpha: flashOpacity)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(
          Offset(centerX, centerY),
          6 * (1.0 - t / 0.15),
          flashPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_FireworksPainter old) => true;
}
