import 'dart:math';
import 'package:flutter/material.dart';

class EffectBackground extends StatefulWidget {
  final String effectType; // 'none', 'bubbles', 'hearts', 'snow', 'stars', 'meteor', etc.

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
  int _lastTickMs = 0;

  @override
  void initState() {
    super.initState();
    _currentEffect = widget.effectType;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    _lastTickMs = DateTime.now().millisecondsSinceEpoch;
    _controller.addListener(_updateParticles);
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
    if (size.width == 0 || size.height == 0) return;
    final int count = _getParticleCount();
    
    _particles.clear();
    for (int i = 0; i < count; i++) {
      _particles.add(_createParticle(size));
    }
  }

  int _getParticleCount() {
    switch (_currentEffect) {
      case 'bubbles': return 25;
      case 'hearts': return 22;
      case 'snow': return 40;
      case 'stars': return 35;
      case 'meteor': return 12;
      case 'rain': return 60;
      case 'rain_ripple': return 30;
      case 'rainbow': return 20;
      case 'waves': return 12;
      case 'leaves': return 20;
      case 'sunset_birds': return 20;
      case 'aurora': return 0;
      case 'fireflies': return 25;
      case 'fireworks': return 50;
      case 'cherry_blossom': return 35;
      case 'galaxy': return 60;
      default: return 0;
    }
  }

  Particle _createParticle(Size size) {
    double x = _random.nextDouble() * size.width;
    double y = _random.nextDouble() * size.height;
    
    switch (_currentEffect) {
      case 'bubbles':
        return Particle(x: x, y: y, size: _random.nextDouble() * 25 + 5, speedY: -(_random.nextDouble() * 1.0 + 0.2), color: Colors.white.withValues(alpha: _random.nextDouble() * 0.15 + 0.05));
      case 'hearts':
        return Particle(x: x, y: y, size: _random.nextDouble() * 15 + 10, speedY: -(_random.nextDouble() * 1.5 + 0.5), speedX: (_random.nextDouble() - 0.5) * 0.5, color: Colors.pinkAccent.withValues(alpha: _random.nextDouble() * 0.4 + 0.2), angle: _random.nextDouble() * pi, spin: (_random.nextDouble() - 0.5) * 0.05);
      case 'snow':
        return Particle(x: x, y: y, size: _random.nextDouble() * 4 + 2, speedY: _random.nextDouble() * 2.0 + 1.0, speedX: (_random.nextDouble() - 0.5) * 1.5, color: Colors.white.withValues(alpha: _random.nextDouble() * 0.5 + 0.3));
      case 'stars':
        return Particle(x: x, y: y, size: _random.nextDouble() * 10 + 5, speedY: _random.nextDouble() * 0.2 - 0.1, speedX: _random.nextDouble() * 0.2 - 0.1, color: Colors.amber.withValues(alpha: _random.nextDouble() * 0.8 + 0.2), angle: _random.nextDouble() * pi * 2, spin: (_random.nextDouble() - 0.5) * 0.02, life: _random.nextDouble() * pi * 2);
      case 'meteor':
        double startX = _random.nextDouble() * size.width * 1.5 - size.width * 0.25;
        double startY = _random.nextDouble() * size.height * 0.4 - size.height * 0.1;
        double speed = _random.nextDouble() * 8 + 5;
        return Particle(x: startX, y: startY, size: _random.nextDouble() * 2.5 + 1.0, speedX: speed * 0.6, speedY: speed, color: Colors.white.withValues(alpha: _random.nextDouble() * 0.6 + 0.4), life: _random.nextDouble() * 80 + 40);
      case 'rain':
        return Particle(x: x, y: y, size: _random.nextDouble() * 1.5 + 1.0, speedX: _random.nextDouble() * 2.0 + 1.0, speedY: _random.nextDouble() * 15 + 15, color: Colors.white.withValues(alpha: _random.nextDouble() * 0.4 + 0.2));
      case 'rain_ripple':
        return Particle(x: x, y: y, color: Colors.white.withValues(alpha: 0.6));
      case 'rainbow':
        return Particle(x: x, y: y, size: _random.nextDouble() * 5 + 3, speedX: _random.nextDouble() * 0.2 - 0.1, speedY: _random.nextDouble() * 0.2 - 0.1, color: HSLColor.fromAHSL(1.0, _random.nextDouble() * 360, 1.0, 0.7).toColor(), angle: _random.nextDouble() * pi * 2, spin: (_random.nextDouble() - 0.5) * 0.02, life: _random.nextDouble() * pi * 2);
      case 'waves':
        return Particle(x: _random.nextDouble() * size.width, y: size.height * 0.55 + _random.nextDouble() * size.height * 0.45, size: _random.nextDouble() * 4 + 1, speedX: (_random.nextDouble() - 0.5) * 0.6, speedY: -(_random.nextDouble() * 0.4 + 0.15), color: Colors.white.withValues(alpha: _random.nextDouble() * 0.35 + 0.08));
      case 'leaves':
        return Particle(x: _random.nextDouble() * size.width, y: -(_random.nextDouble() * size.height), size: _random.nextDouble() * 15 + 10, speedX: _random.nextDouble() * 2 - 1, speedY: _random.nextDouble() * 2 + 1, color: [Colors.orange[700]!, Colors.orange[400]!, Colors.red[700]!, Colors.yellow[700]!][_random.nextInt(4)], angle: _random.nextDouble() * pi * 2, spin: (_random.nextDouble() - 0.5) * 0.1);
      case 'sunset_birds':
        bool isBird = _particles.length < 8;
        return Particle(x: _random.nextDouble() * size.width, y: _random.nextDouble() * size.height * (isBird ? 0.55 : 0.42), size: _random.nextDouble() * (isBird ? 6 : 1.5) + (isBird ? 4 : 0.5), speedX: isBird ? (_random.nextDouble() * 1.5 + 0.8) : 0, color: (isBird ? Colors.black : Colors.white).withValues(alpha: isBird ? (_random.nextDouble() * 0.2 + 0.7) : 1.0), life: _random.nextDouble() * pi * 2);
      case 'fireflies':
        return Particle(x: _random.nextDouble() * size.width, y: _random.nextDouble() * size.height, size: _random.nextDouble() * 3 + 1.5, speedX: _random.nextDouble() * 1.0 - 0.5, speedY: _random.nextDouble() * 1.0 - 0.5, color: const Color(0xFFCEFF1A).withValues(alpha: 0.8), life: _random.nextDouble() * pi * 2);
      case 'cherry_blossom':
        return Particle(x: _random.nextDouble() * size.width, y: -(_random.nextDouble() * size.height), size: _random.nextDouble() * 12 + 6, speedX: _random.nextDouble() * 2 + 1, speedY: _random.nextDouble() * 2 + 1.5, color: Colors.pinkAccent.withValues(alpha: _random.nextDouble() * 0.4 + 0.4), angle: _random.nextDouble() * pi * 2, spin: (_random.nextDouble() - 0.5) * 0.1);
      case 'fireworks':
        return Particle(x: _random.nextDouble() * size.width, y: size.height + _random.nextDouble() * 100, size: _random.nextDouble() * 3 + 1.5, speedY: -(_random.nextDouble() * 4 + 6), color: HSLColor.fromAHSL(1.0, _random.nextDouble() * 360, 1.0, 0.6).toColor());
      case 'galaxy':
        return Particle(x: _random.nextDouble() * size.width, y: _random.nextDouble() * size.height, size: _random.nextDouble() * 2 + 0.5, speedX: (_random.nextDouble() - 0.5) * 2, speedY: (_random.nextDouble() - 0.5) * 2, color: Colors.white.withValues(alpha: _random.nextDouble() * 0.5 + 0.5), life: _random.nextDouble() * size.width / 2);
      default:
        return Particle(x: 0, y: 0, size: 0, color: Colors.transparent);
    }
  }

  void _updateParticles() {
    if (!mounted || _currentEffect == 'none' || _particles.isEmpty) return;
    
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    double dt = (nowMs - _lastTickMs) / 1000.0;
    _lastTickMs = nowMs;

    if (dt <= 0.0 || dt > 0.05) dt = 1.0 / 60.0;
    final double factor = dt * 60.0;

    final size = MediaQuery.of(context).size;
    if (size.width == 0 || size.height == 0) return;

    for (var p in _particles) {
      p.x += p.speedX * factor;
      p.y += p.speedY * factor;
      p.angle += p.spin * factor;
      
      if (_currentEffect == 'bubbles') {
        p.x += sin(p.y * 0.03) * 0.4 * factor;
      } else if (_currentEffect == 'waves') {
        p.x += sin(p.y * 0.02) * 0.8 * factor;
      } else if (_currentEffect == 'leaves') {
        p.x += sin(p.y * 0.01) * 2.0 * factor;
      } else if (_currentEffect == 'sunset_birds') {
        if (p.speedX > 0.5) {
          p.y += sin(p.x * 0.02) * 0.3 * factor;
          p.life += 0.15 * factor;
        } else {
          p.life += 0.02 * factor;
        }
      } else if (_currentEffect == 'fireflies') {
        p.x += sin(p.y * 0.02) * 0.5 * factor;
        p.y += cos(p.x * 0.02) * 0.5 * factor;
        p.life += 0.05 * factor;
      } else if (_currentEffect == 'cherry_blossom') {
        p.x += sin(p.y * 0.01) * 1.5 * factor;
      } else if (_currentEffect == 'galaxy') {
        double centerX = size.width / 2;
        double centerY = size.height / 2;
        double dx = p.x - centerX;
        double dy = p.y - centerY;
        double dist = sqrt(dx * dx + dy * dy);
        if (dist == 0) dist = 1;
        p.x += (dx / dist) * (dist * 0.03 + 0.6) * factor;
        p.y += (dy / dist) * (dist * 0.03 + 0.6) * factor;
        p.size = (dist / size.width) * 2.2 + 0.3;
        if (p.x < 0 || p.x > size.width || p.y < 0 || p.y > size.height) {
          p.x = centerX + (_random.nextDouble() - 0.5) * 10;
          p.y = centerY + (_random.nextDouble() - 0.5) * 10;
        }
      } else if (_currentEffect == 'fireworks') {
        if (p.speedY < 0 && p.life == 0) {
          p.speedY += 0.05 * factor;
          if (p.speedY >= -1.0) {
            p.life = 1; 
            p.speedX = (_random.nextDouble() - 0.5) * 6;
            p.speedY = (_random.nextDouble() - 0.5) * 6;
          }
        } else if (p.life > 0) {
          p.speedY += 0.08 * factor; 
          p.life += 1 * factor;
        }
      } else if (_currentEffect == 'hearts') {
        p.x += sin(p.y * 0.02) * 0.5 * factor;
      } else if (_currentEffect == 'stars') {
        p.life += 0.05 * factor;
      } else if (_currentEffect == 'rain_ripple') {
        p.life += 0.04 * factor;
        if (p.life > 5) {
          p.life = 0;
          p.x = _random.nextDouble() * size.width;
          p.y = _random.nextDouble() * size.height;
        }
      } else if (_currentEffect == 'rainbow') {
        p.life += 0.03 * factor;
      }

      if (_currentEffect == 'meteor') {
        if (p.x > size.width + 50 || p.y > size.height + 50) {
          final speed = _random.nextDouble() * 8 + 5;
          p.x = _random.nextDouble() * size.width * 1.0 - size.width * 0.4;
          p.y = _random.nextDouble() * size.height * 0.3 - size.height * 0.1;
          p.speedX = speed * 0.6;
          p.speedY = speed;
          p.life = _random.nextDouble() * 80 + 40;
        }
      } else if (p.speedY < 0 && p.y < -p.size) {
        p.y = size.height + p.size;
        p.x = _random.nextDouble() * size.width;
      } else if (p.speedY > 0 && p.y > size.height + p.size) {
        if (_currentEffect == 'fireworks') {
          p.y = size.height + _random.nextDouble() * 100;
          p.x = _random.nextDouble() * size.width;
          p.speedX = 0;
          p.speedY = -(_random.nextDouble() * 4 + 6);
          p.life = 0;
          p.color = HSLColor.fromAHSL(1.0, _random.nextDouble() * 360, 1.0, 0.6).toColor();
        } else {
          p.y = -p.size;
          p.x = _random.nextDouble() * size.width;
        }
      }
      
      if (p.x < -p.size) p.x = size.width + p.size;
      if (p.x > size.width + p.size) p.x = -p.size;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_updateParticles);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentEffect == 'none') return const SizedBox.shrink();

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final timeSec = (_lastTickMs % 3600000) / 1000.0;
          return CustomPaint(
            painter: EffectPainter(
              particles: _particles,
              effectType: _currentEffect,
              time: timeSec,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class Particle {
  double x, y, size, speedX, speedY, angle, spin, life;
  Color color;

  Particle({
    this.x = 0, this.y = 0, this.size = 0, this.speedX = 0, this.speedY = 0,
    required this.color, this.angle = 0, this.spin = 0, this.life = 0,
  });
}

class EffectPainter extends CustomPainter {
  final List<Particle> particles;
  final String effectType;
  final double time;
  final Paint _sharedPaint = Paint();
  static final Path _unitHeartPath = _createUnitHeartPath();
  static final Path _unitStarPath = _createUnitStarPath();
  static final Path _unitLeafPath = _createUnitLeafPath();
  static final Path _unitBirdPath = _createUnitBirdPath();

  EffectPainter({required this.particles, required this.effectType, this.time = 0});

  static Path _createUnitHeartPath() {
    Path path = Path();
    path.moveTo(0, 0.25);
    path.cubicTo(-0.5, -0.25, -1.0, 0.5, 0, 1.0);
    path.cubicTo(1.0, 0.5, 0.5, -0.25, 0, 0.25);
    return path;
  }

  static Path _createUnitStarPath() {
    Path path = Path();
    int points = 5;
    double step = pi / points;
    for (int i = 0; i < 2 * points; i++) {
      double radius = (i % 2 == 0) ? 1.0 : 0.4;
      double angle = i * step - pi / 2;
      path.lineTo(radius * cos(angle), radius * sin(angle));
    }
    path.close();
    return path;
  }

  static Path _createUnitLeafPath() {
    Path path = Path();
    path.moveTo(0, -1.0);
    path.quadraticBezierTo(1.0, -0.5, 0, 1.0);
    path.quadraticBezierTo(-1.0, -0.5, 0, -1.0);
    return path;
  }

  static Path _createUnitBirdPath() {
    Path path = Path();
    path.moveTo(-1.0, 0);
    path.quadraticBezierTo(-0.5, 0.3, 0, 0.3);
    path.quadraticBezierTo(0.5, 0.3, 1.0, 0);
    path.quadraticBezierTo(0.5, 0.5, 0, 0.5);
    path.quadraticBezierTo(-0.5, 0.5, -1.0, 0);
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (effectType == 'waves') _drawOceanBackground(canvas, size);
    if (effectType == 'sunset_birds') _drawSunsetBackground(canvas, size);
    if (effectType == 'aurora') _drawAuroraBackground(canvas, size);
    if (effectType == 'galaxy') _drawGalaxyBackground(canvas, size);

    for (var p in particles) {
      _sharedPaint
        ..color = p.color
        ..style = PaintingStyle.fill
        ..maskFilter = null
        ..shader = null
        ..strokeWidth = 0;

      if (effectType == 'bubbles' || effectType == 'snow') {
        canvas.drawCircle(Offset(p.x, p.y), p.size, _sharedPaint);
      } else if (effectType == 'hearts') {
        _drawHeart(canvas, p, _sharedPaint);
      } else if (effectType == 'stars') {
        double opacity = (sin(p.life) + 1) / 2;
        _sharedPaint.color = p.color.withValues(alpha: p.color.a * opacity);
        _drawStar(canvas, p, _sharedPaint);
      } else if (effectType == 'waves') {
        canvas.drawCircle(Offset(p.x, p.y), p.size, _sharedPaint);
      } else if (effectType == 'leaves') {
        _drawLeaf(canvas, p, _sharedPaint);
      } else if (effectType == 'sunset_birds') {
        if (p.speedX > 0.5) {
          _drawBird(canvas, p, _sharedPaint);
        } else {
          double opacity = (sin(p.life) + 1) / 2;
          _sharedPaint.color = p.color.withValues(alpha: p.color.a * opacity);
          canvas.drawCircle(Offset(p.x, p.y), p.size, _sharedPaint);
        }
      } else if (effectType == 'cherry_blossom') {
        _drawLeaf(canvas, p, _sharedPaint);
      } else if (effectType == 'fireflies') {
        double opacity = (sin(p.life) + 1) / 2 * 0.8 + 0.2;
        final glowPaint = Paint()
          ..color = p.color.withValues(alpha: opacity * 0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
        canvas.drawCircle(Offset(p.x, p.y), p.size * 2, glowPaint);
        _sharedPaint.color = Colors.white.withValues(alpha: opacity);
        canvas.drawCircle(Offset(p.x, p.y), p.size * 0.5, _sharedPaint);
      } else if (effectType == 'galaxy') {
        canvas.drawCircle(Offset(p.x, p.y), p.size, _sharedPaint);
      } else if (effectType == 'fireworks') {
        if (p.life == 0) { 
          _sharedPaint.strokeWidth = 2;
          _sharedPaint.style = PaintingStyle.stroke;
          canvas.drawLine(Offset(p.x, p.y), Offset(p.x, p.y + 10), _sharedPaint);
        } else { 
          double opacity = 1.0 - (p.life / 100);
          if (opacity < 0) opacity = 0;
          _sharedPaint.color = p.color.withValues(alpha: opacity);
          canvas.drawCircle(Offset(p.x, p.y), p.size, _sharedPaint);
        }
      } else if (effectType == 'meteor') {
        _drawMeteor(canvas, p, _sharedPaint);
      } else if (effectType == 'rain') {
        _sharedPaint.strokeWidth = p.size;
        _sharedPaint.strokeCap = StrokeCap.round;
        _sharedPaint.style = PaintingStyle.stroke;
        canvas.drawLine(Offset(p.x, p.y), Offset(p.x - p.speedX * 2, p.y - p.speedY * 0.8), _sharedPaint);
      } else if (effectType == 'rain_ripple') {
        double maxRadius = 40.0;
        double radius = p.life * 12;
        if (radius > 0 && radius < maxRadius) {
          double opacity = 1.0 - (radius / maxRadius);
          if (opacity < 0) opacity = 0;
          _sharedPaint.style = PaintingStyle.stroke;
          _sharedPaint.strokeWidth = 1.5;
          _sharedPaint.color = p.color.withValues(alpha: opacity * p.color.a);
          canvas.drawOval(Rect.fromCenter(center: Offset(p.x, p.y), width: radius * 2, height: radius), _sharedPaint);
        }
      } else if (effectType == 'rainbow') {
        if (p == particles.first) {
           double baseRadius = size.width * 0.8;
           Offset center = Offset(size.width * 0.5, size.height * 0.7);
           double pulse = (sin(p.life) + 1.0) / 2.0; 
           double baseAlpha = 0.3 + pulse * 0.3;
           List<Color> colors = [Colors.red, Colors.orange, Colors.yellow, Colors.green, Colors.blue, Colors.indigo, Colors.purple];
           for (int i = 0; i < colors.length; i++) {
             final rainbowPaint = Paint()
               ..style = PaintingStyle.stroke
               ..strokeWidth = 14.0
               ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10.0)
               ..color = colors[i].withValues(alpha: baseAlpha);
             canvas.drawArc(Rect.fromCircle(center: center, radius: baseRadius - (i * 12.0)), pi * 1.1, pi * 0.8, false, rainbowPaint);
           }
        } else {
           double opacity = (sin(p.life) + 1) / 2;
           _sharedPaint.color = p.color.withValues(alpha: p.color.a * opacity);
           _drawStar(canvas, p, _sharedPaint);
        }
      }
    }
  }

  void _drawHeart(Canvas canvas, Particle p, Paint paint) {
    canvas.save();
    canvas.translate(p.x, p.y);
    canvas.rotate(p.angle);
    canvas.scale(p.size, p.size);
    canvas.drawPath(_unitHeartPath, paint);
    canvas.restore();
  }

  void _drawStar(Canvas canvas, Particle p, Paint paint) {
    canvas.save();
    canvas.translate(p.x, p.y);
    canvas.rotate(p.angle);
    canvas.scale(p.size, p.size);
    canvas.drawPath(_unitStarPath, paint);
    canvas.restore();
  }

  void _drawLeaf(Canvas canvas, Particle p, Paint paint) {
    canvas.save();
    canvas.translate(p.x, p.y);
    canvas.rotate(p.angle);
    canvas.scale(p.size, p.size);
    canvas.drawPath(_unitLeafPath, paint);
    canvas.restore();
  }

  void _drawBird(Canvas canvas, Particle p, Paint paint) {
    canvas.save();
    canvas.translate(p.x, p.y);
    canvas.scale(p.size, p.size);
    canvas.drawPath(_unitBirdPath, paint);
    canvas.restore();
  }

  void _drawMeteor(Canvas canvas, Particle p, Paint paint) {
    final double tailLength = p.life;
    final double angle = atan2(p.speedY, p.speedX);
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

    final headPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.95)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(Offset(p.x, p.y), p.size + 1.5, headPaint);
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
  }

  void _drawAuroraBackground(Canvas canvas, Size size) {
    final Rect rect = Rect.fromLTRB(0, 0, size.width, size.height);
    final Paint bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [const Color(0xFF0B0C10), const Color(0xFF1F2833)],
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);

    void drawAuroraLayer(Color color, double yOffset, double amplitude, double frequency, double speed) {
      final Path path = Path();
      path.moveTo(0, size.height);
      path.lineTo(0, size.height * yOffset);
      for (double x = 0; x <= size.width; x += 10) {
        double y = size.height * yOffset + sin(x * frequency + time * speed * pi * 2) * amplitude;
        path.lineTo(x, y);
      }
      path.lineTo(size.width, size.height);
      path.close();
      canvas.drawPath(path, Paint()
        ..color = color
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20.0));
    }

    drawAuroraLayer(const Color(0xFF45A29E).withValues(alpha: 0.3), 0.3, 40, 0.01, 0.5);
    drawAuroraLayer(const Color(0xFF66FCF1).withValues(alpha: 0.2), 0.4, 50, 0.015, -0.3);
    drawAuroraLayer(const Color(0xFF8A2BE2).withValues(alpha: 0.15), 0.5, 60, 0.008, 0.4);
    
    final Path forest = Path();
    forest.moveTo(0, size.height);
    for (double x = 0; x <= size.width; x += 20) {
      forest.lineTo(x, size.height - 30 - sin(x * 123) * 20);
      forest.lineTo(x + 10, size.height);
    }
    forest.close();
    canvas.drawPath(forest, Paint()..color = Colors.black);
  }

  void _drawGalaxyBackground(Canvas canvas, Size size) {
    final Rect rect = Rect.fromLTRB(0, 0, size.width, size.height);
    final Paint bgPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.2,
        colors: [
          const Color(0xFF2C1045),
          const Color(0xFF120822),
          const Color(0xFF05020A),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);
    
    final Offset center = Offset(size.width / 2, size.height / 2);
    final Paint coreGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF9C27B0).withValues(alpha: 0.15),
          const Color(0xFF00E5FF).withValues(alpha: 0.08),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: size.width * 0.25));
    canvas.drawCircle(center, size.width * 0.25, coreGlow);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
