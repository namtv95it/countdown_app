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
      case 'rain': return 70;
      case 'rain_ripple': return 40;
      case 'rainbow': return 25;
      case 'waves': return 15;
      case 'leaves': return 25;
      case 'sunset_birds': return 25;
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
          life: _random.nextDouble() * 80 + 40, // Độ dài đuôi sao
        );
      case 'rain':
        return Particle(
          x: x,
          y: y,
          size: _random.nextDouble() * 1.5 + 1.0,
          speedX: _random.nextDouble() * 2.0 + 1.0,
          speedY: _random.nextDouble() * 15 + 15,
          color: Colors.white.withValues(alpha: _random.nextDouble() * 0.4 + 0.2),
          angle: 0,
          spin: 0,
        );
      case 'rain_ripple':
        return Particle(
          x: x,
          y: y,
          size: 0,
          speedX: 0,
          speedY: 0,
          color: Colors.white.withValues(alpha: 0.6),
          angle: 0,
          spin: 0,
          life: _random.nextDouble() * 5, // Khởi tạo thời điểm xuất hiện ngẫu nhiên
        );
      case 'rainbow':
        return Particle(
          x: x,
          y: y,
          size: _random.nextDouble() * 5 + 3,
          speedX: _random.nextDouble() * 0.2 - 0.1,
          speedY: _random.nextDouble() * 0.2 - 0.1,
          color: HSLColor.fromAHSL(1.0, _random.nextDouble() * 360, 1.0, 0.7).toColor(),
          angle: _random.nextDouble() * pi * 2,
          spin: (_random.nextDouble() - 0.5) * 0.02,
          life: _random.nextDouble() * pi * 2,
        );
      case 'waves':
        return Particle(
          x: _random.nextDouble() * size.width,
          y: size.height * 0.55 + _random.nextDouble() * size.height * 0.45,
          size: _random.nextDouble() * 4 + 1,
          speedX: (_random.nextDouble() - 0.5) * 0.6,
          speedY: -(_random.nextDouble() * 0.4 + 0.15),
          color: Colors.white.withValues(alpha: _random.nextDouble() * 0.35 + 0.08),
          angle: 0,
          spin: 0,
          life: 0,
        );
      case 'leaves':
        return Particle(
          x: _random.nextDouble() * size.width,
          y: -(_random.nextDouble() * size.height),
          size: _random.nextDouble() * 15 + 10,
          speedX: _random.nextDouble() * 2 - 1,
          speedY: _random.nextDouble() * 2 + 1,
          color: [
            Colors.orange[700]!,
            Colors.orange[400]!,
            Colors.red[700]!,
            Colors.yellow[700]!,
          ][_random.nextInt(4)],
          angle: _random.nextDouble() * pi * 2,
          spin: (_random.nextDouble() - 0.5) * 0.1,
          life: 0,
        );
      case 'sunset_birds':
        bool isBird = _particles.length < 8;
        if (isBird) {
          return Particle(
            x: _random.nextDouble() * size.width,
            y: _random.nextDouble() * size.height * 0.55,
            size: _random.nextDouble() * 6 + 4,
            speedX: _random.nextDouble() * 1.5 + 0.8,
            speedY: 0,
            color: Colors.black.withValues(alpha: _random.nextDouble() * 0.2 + 0.7),
            angle: 0,
            spin: 0,
            life: _random.nextDouble() * pi * 2,
          );
        } else {
          return Particle(
            x: _random.nextDouble() * size.width,
            y: _random.nextDouble() * size.height * 0.42,
            size: _random.nextDouble() * 1.5 + 0.5,
            speedX: 0,
            speedY: 0,
            color: Colors.white.withValues(alpha: 1.0),
            angle: 0,
            spin: 0,
            life: _random.nextDouble() * pi * 2,
          );
        }
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
          } else if (_currentEffect == 'waves') {
            p.x += sin(p.y * 0.02) * 0.8;
          } else if (_currentEffect == 'leaves') {
            p.x += sin(p.y * 0.01) * 2;
          } else if (_currentEffect == 'sunset_birds') {
            if (p.speedX > 0.5) {
              p.y += sin(p.x * 0.02) * 0.3;
              p.life += 0.15;
            } else {
              p.life += 0.02;
            }
          } else if (_currentEffect == 'hearts') {
            p.x += sin(p.y * 0.02) * 0.5;
          } else if (_currentEffect == 'stars') {
            p.life += 0.05; // Twinkle phase speed
          } else if (_currentEffect == 'rain_ripple') {
            p.life += 0.04;
            if (p.life > 5) {
              p.life = 0;
              p.x = _random.nextDouble() * size.width;
              p.y = _random.nextDouble() * size.height;
            }
          } else if (_currentEffect == 'rainbow') {
            p.life += 0.03;
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
          painter: EffectPainter(particles: _particles, effectType: _currentEffect, time: _controller.value),
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
  final double time;

  EffectPainter({required this.particles, required this.effectType, this.time = 0});

  @override
  void paint(Canvas canvas, Size size) {
    if (effectType == 'waves') _drawOceanBackground(canvas, size);
    if (effectType == 'sunset_birds') _drawSunsetBackground(canvas, size);

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
      } else if (effectType == 'waves') {
        canvas.drawCircle(Offset(p.x, p.y), p.size, paint);
      } else if (effectType == 'leaves') {
        _drawLeaf(canvas, p, paint);
      } else if (effectType == 'sunset_birds') {
        if (p.speedX > 0.5) {
          _drawBird(canvas, p, paint);
        } else {
          double opacity = (sin(p.life) + 1) / 2;
          paint.color = p.color.withValues(alpha: p.color.a * opacity);
          canvas.drawCircle(Offset(p.x, p.y), p.size, paint);
        }
      } else if (effectType == 'meteor') {
        _drawMeteor(canvas, p, paint);
      } else if (effectType == 'rain') {
        paint.strokeWidth = p.size;
        paint.strokeCap = StrokeCap.round;
        canvas.drawLine(
          Offset(p.x, p.y),
          Offset(p.x - p.speedX * 1.5, p.y - p.speedY * 1.5),
          paint,
        );
      } else if (effectType == 'rain_ripple') {
        double maxRadius = 40.0;
        double radius = p.life * 12;
        if (radius > 0 && radius < maxRadius) {
          double opacity = 1.0 - (radius / maxRadius);
          if (opacity < 0) opacity = 0;
          paint.style = PaintingStyle.stroke;
          paint.strokeWidth = 1.5;
          paint.color = p.color.withValues(alpha: opacity * p.color.a);
          canvas.drawOval(Rect.fromCenter(center: Offset(p.x, p.y), width: radius * 2, height: radius), paint);
        }
      } else if (effectType == 'rainbow') {
        if (p == particles.first) {
           double baseRadius = size.width * 0.8;
           Offset center = Offset(size.width * 0.5, size.height * 0.7);
           double pulse = (sin(p.life) + 1.0) / 2.0; 
           double baseAlpha = 0.3 + pulse * 0.3;
           
           List<Color> colors = [
             Colors.red, Colors.orange, Colors.yellow, Colors.green, Colors.blue, Colors.indigo, Colors.purple
           ];
           
           for (int i = 0; i < colors.length; i++) {
             double currentRadius = baseRadius - (i * 12.0);
             Rect rect = Rect.fromCircle(center: center, radius: currentRadius);
             final rainbowPaint = Paint()
               ..style = PaintingStyle.stroke
               ..strokeWidth = 14.0
               ..strokeCap = StrokeCap.round
               ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10.0)
               ..color = colors[i].withValues(alpha: baseAlpha);
               
             canvas.drawArc(rect, pi * 1.1, pi * 0.8, false, rainbowPaint);
           }
        } else {
           double opacity = (sin(p.life) + 1) / 2;
           paint.color = p.color.withValues(alpha: p.color.a * opacity);
           _drawStar(canvas, p, paint);
        }
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
          Colors.purpleAccent.withValues(alpha: 0.6),
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

  void _drawLeaf(Canvas canvas, Particle p, Paint paint) {
    canvas.save();
    canvas.translate(p.x, p.y);
    canvas.rotate(p.angle);
    Path path = Path();
    double s = p.size;
    path.moveTo(0, -s);
    path.quadraticBezierTo(s, -s/2, 0, s);
    path.quadraticBezierTo(-s, -s/2, 0, -s);
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  void _drawBird(Canvas canvas, Particle p, Paint paint) {
    canvas.save();
    canvas.translate(p.x, p.y);
    double s = p.size;
    double wingY = sin(p.life) * s * 0.8;
    Path path = Path();
    path.moveTo(-s, 0);
    path.quadraticBezierTo(-s/2, wingY, 0, s/3);
    path.quadraticBezierTo(s/2, wingY, s, 0);
    path.quadraticBezierTo(s/2, wingY + s/2, 0, s/2);
    path.quadraticBezierTo(-s/2, wingY + s/2, -s, 0);
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  void _drawOceanBackground(Canvas canvas, Size size) {
    final double oceanTop = size.height * 0.6;
    final oceanRect = Rect.fromLTRB(0, oceanTop, size.width, size.height);
    final oceanPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF006994).withValues(alpha: 0.8),
          const Color(0xFF003B5C).withValues(alpha: 0.9),
        ],
      ).createShader(oceanRect);
    canvas.drawRect(oceanRect, oceanPaint);

    void drawWaveLayer(Color color, double heightOffset, double speed, double amplitude) {
      final Path path = Path();
      path.moveTo(0, size.height);
      path.lineTo(0, oceanTop + heightOffset);
      for (double x = 0; x <= size.width; x += 10) {
        double y = oceanTop + heightOffset + sin((x / (size.width / 2.5)) + (time * speed * pi * 2)) * amplitude;
        path.lineTo(x, y);
      }
      path.lineTo(size.width, size.height);
      path.close();
      canvas.drawPath(path, Paint()..color = color);
    }
    drawWaveLayer(const Color(0xFF0077BE).withValues(alpha: 0.5), 10, 1.2, 15);
    drawWaveLayer(const Color(0xFF005B96).withValues(alpha: 0.6), 25, 0.8, 20);
    drawWaveLayer(const Color(0xFF003B5C).withValues(alpha: 0.7), 45, 1.5, 12);
  }

  void _drawSunsetBackground(Canvas canvas, Size size) {
    final bgRect = Rect.fromLTRB(0, 0, size.width, size.height);
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF2B1055).withValues(alpha: 0.8),
          const Color(0xFF75225E).withValues(alpha: 0.8),
          const Color(0xFFB54559).withValues(alpha: 0.8),
          const Color(0xFFE27B58).withValues(alpha: 0.8),
          const Color(0xFFFFB56B).withValues(alpha: 0.8),
        ],
        stops: const [0.0, 0.3, 0.6, 0.8, 1.0],
      ).createShader(bgRect);
    canvas.drawRect(bgRect, bgPaint);

    final Offset sunCenter = Offset(size.width * 0.5, size.height * 0.65);
    final double sunRadius = size.width * 0.25;

    final sunGlowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.8),
          const Color(0xFFFFD180).withValues(alpha: 0.6),
          const Color(0xFFFF8A65).withValues(alpha: 0.2),
          const Color(0xFFFF8A65).withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.3, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: sunCenter, radius: sunRadius * 2.5));
    canvas.drawCircle(sunCenter, sunRadius * 2.5, sunGlowPaint);

    final sunPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFF9C4), Color(0xFFFFCC80), Color(0xFFFF8A65)],
      ).createShader(Rect.fromCircle(center: sunCenter, radius: sunRadius));
    canvas.drawCircle(sunCenter, sunRadius, sunPaint);

    canvas.save();
    canvas.translate(sunCenter.dx, sunCenter.dy);
    canvas.rotate(time * pi * 2 * 0.1);
    final rayPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;
    for (int i = 0; i < 12; i++) {
      canvas.rotate((pi * 2) / 12);
      final Path ray = Path();
      ray.moveTo(-5, 0);
      ray.lineTo(0, -size.height * 0.8);
      ray.lineTo(5, 0);
      ray.close();
      canvas.drawPath(ray, rayPaint);
    }
    canvas.restore();

    void drawMountains(Color color, double heightBase, double amplitude, double frequency, double phase) {
      final Path path = Path();
      path.moveTo(0, size.height);
      path.lineTo(0, heightBase);
      for (double x = 0; x <= size.width; x += 5) {
        double y = heightBase - (sin(x * frequency + phase) * amplitude) - (sin(x * frequency * 2.5) * amplitude * 0.3);
        path.lineTo(x, y);
      }
      path.lineTo(size.width, size.height);
      path.close();
      canvas.drawPath(path, Paint()..color = color);
    }
    drawMountains(const Color(0xFF38154D).withValues(alpha: 0.9), size.height * 0.75, 40, 0.005, 0);
    drawMountains(const Color(0xFF1E0A2D).withValues(alpha: 0.95), size.height * 0.85, 30, 0.008, 2);
    drawMountains(Colors.black.withValues(alpha: 0.8), size.height * 0.95, 20, 0.012, 1);
  }

}
