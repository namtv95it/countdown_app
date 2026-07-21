import 'dart:io';

void main() {
  final file = File('lib/widgets/effect_background.dart');
  String content = file.readAsStringSync();

  final old_count = '''  int _getParticleCount() {
    switch (_currentEffect) {
      case 'bubbles': return 30;
      case 'hearts': return 25;
      case 'snow': return 50;
      case 'stars': return 40;
      case 'meteor': return 15;
      case 'rain': return 70;
      case 'rain_ripple': return 40;
      case 'rainbow': return 25;
      default: return 0;
    }
  }''';

  final new_count = '''  int _getParticleCount() {
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
  }''';
  content = content.replaceFirst(old_count, new_count);

  final old_default = '''      default:
        return Particle(x: 0, y: 0, size: 0, speedY: 0, speedX: 0, color: Colors.transparent, angle: 0, spin: 0);
    }
  }''';
  final new_default = '''      case 'waves':
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
  }''';
  content = content.replaceFirst(old_default, new_default);

  final old_anim = '''          if (_currentEffect == 'bubbles') {
            p.x += sin(p.y * 0.03) * 0.4;
          } else if (_currentEffect == 'hearts') {''';
  final new_anim = '''          if (_currentEffect == 'bubbles') {
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
          } else if (_currentEffect == 'hearts') {''';
  content = content.replaceFirst(old_anim, new_anim);

  final old_custom_paint = '''        return CustomPaint(
          painter: EffectPainter(particles: _particles, effectType: _currentEffect),
          size: Size.infinite,
        );''';
  final new_custom_paint = '''        return CustomPaint(
          painter: EffectPainter(particles: _particles, effectType: _currentEffect, time: _controller.value),
          size: Size.infinite,
        );''';
  content = content.replaceFirst(old_custom_paint, new_custom_paint);

  final old_painter = '''class EffectPainter extends CustomPainter {
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
      } else if (effectType == 'meteor') {''';
  final new_painter = '''class EffectPainter extends CustomPainter {
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
      } else if (effectType == 'meteor') {''';
  content = content.replaceFirst(old_painter, new_painter);

  final old_end = '''  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}''';
  final new_end = '''  void _drawLeaf(Canvas canvas, Particle p, Paint paint) {
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

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}''';
  content = content.replaceFirst(old_end, new_end);

  file.writeAsStringSync(content);
  print('Done replacing!');
}
