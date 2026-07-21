import 'dart:math';
import 'package:flutter/material.dart';

class EffectBackground extends StatefulWidget {
  final String effectType; // 'none', 'bubbles', 'hearts', 'snow', 'stars', 'meteor'

  const EffectBackground({
    super.key,
    required this.effectType,
  });

  @override
  State<EffectBackground> createState() => _EffectBackgroundState();
}

class _EffectBackgroundState extends State<EffectBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Particle> _particles = [];
  final Random _random = Random();
  String _currentEffect = 'none';

  @override
  void initState() {
    super.initState();
    _currentEffect = widget.effectType;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void didUpdateWidget(EffectBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.effectType != widget.effectType) {
      setState(() {
        _currentEffect = widget.effectType;
        _particles.clear();
      });
      _initParticles();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_particles.isEmpty && _currentEffect != 'none') {
      _initParticles();
    }
  }

  void _initParticles() {
    if (_currentEffect == 'none') return;
    
    final size = MediaQuery.of(context).size;
    final int count = _getParticleCount();
    
    for (int i = 0; i < count; i++) {
      _particles.add(_createParticle(size));
    }
  }

  int _getParticleCount() {
    switch (_currentEffect) {
      case 'bubbles': return 30;
      case 'hearts': return 25;
      case 'snow': return 50;
      case 'stars': return 40;
      case 'meteor': return 15;
      default: return 0;
    }
  }

  Particle _createParticle(Size size) {
    double x = _random.nextDouble() * size.width;
    double y = _random.nextDouble() * size.height;
    
    switch (_currentEffect) {
      case 'bubbles':
        return Particle(
          x: x,
          y: y,
          size: _random.nextDouble() * 25 + 5,
          speedY: -(_random.nextDouble() * 1.0 + 0.2), // Move up
          speedX: 0,
          color: Colors.white.withValues(alpha: _random.nextDouble() * 0.15 + 0.05),
          angle: 0,
          spin: 0,
        );
      case 'hearts':
        return Particle(
          x: x,
          y: y,
          size: _random.nextDouble() * 15 + 10,
          speedY: -(_random.nextDouble() * 1.5 + 0.5), // Move up
          speedX: (_random.nextDouble() - 0.5) * 0.5,
          color: Colors.pinkAccent.withValues(alpha: _random.nextDouble() * 0.4 + 0.2),
          angle: _random.nextDouble() * pi,
          spin: (_random.nextDouble() - 0.5) * 0.05,
        );
      case 'snow':
        return Particle(
          x: x,
          y: y,
          size: _random.nextDouble() * 4 + 2,
          speedY: _random.nextDouble() * 2.0 + 1.0, // Move down
          speedX: (_random.nextDouble() - 0.5) * 1.5,
          color: Colors.white.withValues(alpha: _random.nextDouble() * 0.5 + 0.3),
          angle: 0,
          spin: 0,
        );
      case 'stars':
        return Particle(
          x: x,
          y: y,
          size: _random.nextDouble() * 10 + 5,
          speedY: _random.nextDouble() * 0.2 - 0.1, // Float slowly
          speedX: _random.nextDouble() * 0.2 - 0.1,
          color: Colors.amber.withValues(alpha: _random.nextDouble() * 0.8 + 0.2),
          angle: _random.nextDouble() * pi * 2,
          spin: (_random.nextDouble() - 0.5) * 0.02,
          life: _random.nextDouble() * pi * 2, // Used for twinkling phase
        );
      case 'meteor':
        // Mưa sao băng: xuất phát từ trên xuống vỏ góc chéo sang phải
        double startX = _random.nextDouble() * size.width * 1.5 - size.width * 0.25;
        double startY = _random.nextDouble() * size.height * 0.4 - size.height * 0.1;
        double speed = _random.nextDouble() * 8 + 5; // Tốc độ rơi
        return Particle(
          x: startX,
          y: startY,
          size: _random.nextDouble() * 2.5 + 1.0, // Đường kính nhỏ
          speedX: speed * 0.6, // Lao sang phải
          speedY: speed,       // Lao xuống
          color: Colors.white.withValues(alpha: _random.nextDouble() * 0.6 + 0.4),
          angle: atan2(speed, speed * 0.6), // Góc chéo
          spin: 0,
          life: _random.nextDouble() * 80 + 40, // Độ dài đuôi sơ
        );
      default:
        return Particle(x: 0, y: 0, size: 0, speedY: 0, speedX: 0, color: Colors.transparent, angle: 0, spin: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentEffect == 'none') return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final size = MediaQuery.of(context).size;
        if (size.width == 0 || size.height == 0) return const SizedBox.shrink();
        
        for (var p in _particles) {
          p.x += p.speedX;
          p.y += p.speedY;
          p.angle += p.spin;
          
          if (_currentEffect == 'bubbles') {
            p.x += sin(p.y * 0.03) * 0.4;
          } else if (_currentEffect == 'hearts') {
            p.x += sin(p.y * 0.02) * 0.5;
          } else if (_currentEffect == 'stars') {
            p.life += 0.05; // Twinkle phase speed
          }

          // Reset particle if it goes out of bounds
          if (_currentEffect == 'meteor') {
            // Sao băng re-spawn từ góc trên bên trái khi ra khỏi màn hình
            if (p.x > size.width + 50 || p.y > size.height + 50) {
              final speed = _random.nextDouble() * 8 + 5;
              p.x = _random.nextDouble() * size.width * 1.0 - size.width * 0.4;
              p.y = _random.nextDouble() * size.height * 0.3 - size.height * 0.1;
              p.speedX = speed * 0.6;
              p.speedY = speed;
              p.life = _random.nextDouble() * 80 + 40;
            }
          } else if (p.speedY < 0 && p.y < -p.size) { // Moving up
            p.y = size.height + p.size;
            p.x = _random.nextDouble() * size.width;
          } else if (p.speedY > 0 && p.y > size.height + p.size) { // Moving down
            p.y = -p.size;
            p.x = _random.nextDouble() * size.width;
          }
          
          if (p.x < -p.size) p.x = size.width + p.size;
          if (p.x > size.width + p.size) p.x = -p.size;
        }

        return CustomPaint(
          painter: EffectPainter(particles: _particles, effectType: _currentEffect),
          size: Size.infinite,
        );
      },
    );
  }
}

class Particle {
  double x;
  double y;
  double size;
  double speedX;
  double speedY;
  Color color;
  double angle;
  double spin;
  double life;

  Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speedX,
    required this.speedY,
    required this.color,
    required this.angle,
    required this.spin,
    this.life = 0,
  });
}

class EffectPainter extends CustomPainter {
  final List<Particle> particles;
  final String effectType;

  EffectPainter({required this.particles, required this.effectType});

  @override
  void paint(Canvas canvas, Size size) {
    for (var p in particles) {
      final paint = Paint()
        ..color = p.color
        ..style = PaintingStyle.fill;

      if (effectType == 'bubbles' || effectType == 'snow') {
        canvas.drawCircle(Offset(p.x, p.y), p.size, paint);
      } else if (effectType == 'hearts') {
        _drawHeart(canvas, p, paint);
      } else if (effectType == 'stars') {
        // Twinkling effect
        double opacity = (sin(p.life) + 1) / 2; // 0.0 to 1.0
        paint.color = p.color.withValues(alpha: p.color.a * opacity);
        _drawStar(canvas, p, paint);
      } else if (effectType == 'meteor') {
        _drawMeteor(canvas, p, paint);
      }
    }
  }

  void _drawHeart(Canvas canvas, Particle p, Paint paint) {
    canvas.save();
    canvas.translate(p.x, p.y);
    canvas.rotate(p.angle);
    
    double width = p.size;
    double height = p.size;
    
    Path path = Path();
    path.moveTo(0, height / 4);
    path.cubicTo(-width / 2, -height / 4, -width, height / 2, 0, height);
    path.cubicTo(width, height / 2, width / 2, -height / 4, 0, height / 4);
    
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  void _drawStar(Canvas canvas, Particle p, Paint paint) {
    canvas.save();
    canvas.translate(p.x, p.y);
    canvas.rotate(p.angle);
    
    double r = p.size;
    double innerR = p.size / 2.5;
    int points = 5;
    
    Path path = Path();
    double step = pi / points;
    
    for (int i = 0; i < 2 * points; i++) {
      double radius = (i % 2 == 0) ? r : innerR;
      double angle = i * step - pi / 2;
      double x = radius * cos(angle);
      double y = radius * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;

  void _drawMeteor(Canvas canvas, Particle p, Paint paint) {
    // Vẽ đuôi sơ (gradient từ đầu sáng đến đuôi mờ)
    final double tailLength = p.life; // Độ dài đuôi sơ
    final double angle = atan2(p.speedY, p.speedX);

    // Hướng ngược lại với chiều bay
    final double dx = -cos(angle) * tailLength;
    final double dy = -sin(angle) * tailLength;

    final tailPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.0),
          Colors.cyanAccent.withValues(alpha: 0.6),
          Colors.white.withValues(alpha: 0.95),
        ],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromPoints(
        Offset(p.x + dx, p.y + dy),
        Offset(p.x, p.y),
      ))
      ..strokeWidth = p.size * 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(p.x + dx, p.y + dy),
      Offset(p.x, p.y),
      tailPaint,
    );

    // Vẽ đầu sao băng (hạt sáng nhỏ)
    final headPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.95)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(Offset(p.x, p.y), p.size + 1.5, headPaint);
  }
}
