import 'dart:io';
import 'dart:math';

void main() {
  final file = File('lib/widgets/effect_background.dart');
  String content = file.readAsStringSync().replaceAll('\r\n', '\n');

  // 1. _getParticleCount
  content = content.replaceFirst(
      "case 'sunset_birds': return 25;",
      "case 'sunset_birds': return 25;\n      case 'aurora': return 0;\n      case 'fireflies': return 30;\n      case 'fireworks': return 60;\n      case 'cherry_blossom': return 40;\n      case 'galaxy': return 80;");

  // 2. _createParticle
  final oldCreate = "default:\n        return Particle(x: 0, y: 0, size: 0, speedY: 0, speedX: 0, color: Colors.transparent, angle: 0, spin: 0);";
  final newCreate = """case 'fireflies':
        return Particle(
          x: _random.nextDouble() * size.width,
          y: _random.nextDouble() * size.height,
          size: _random.nextDouble() * 3 + 1.5,
          speedX: _random.nextDouble() * 1.0 - 0.5,
          speedY: _random.nextDouble() * 1.0 - 0.5,
          color: const Color(0xFFCEFF1A).withValues(alpha: 0.8),
          angle: 0,
          spin: 0,
          life: _random.nextDouble() * pi * 2,
        );
      case 'cherry_blossom':
        return Particle(
          x: _random.nextDouble() * size.width,
          y: -(_random.nextDouble() * size.height),
          size: _random.nextDouble() * 12 + 6,
          speedX: _random.nextDouble() * 2 + 1,
          speedY: _random.nextDouble() * 2 + 1.5,
          color: Colors.pinkAccent.withValues(alpha: _random.nextDouble() * 0.4 + 0.4),
          angle: _random.nextDouble() * pi * 2,
          spin: (_random.nextDouble() - 0.5) * 0.1,
          life: 0,
        );
      case 'fireworks':
        return Particle(
          x: _random.nextDouble() * size.width,
          y: size.height + _random.nextDouble() * 100,
          size: _random.nextDouble() * 3 + 1.5,
          speedX: 0,
          speedY: -(_random.nextDouble() * 4 + 6),
          color: HSLColor.fromAHSL(1.0, _random.nextDouble() * 360, 1.0, 0.6).toColor(),
          angle: 0,
          spin: 0,
          life: 0,
        );
      case 'galaxy':
        return Particle(
          x: _random.nextDouble() * size.width,
          y: _random.nextDouble() * size.height,
          size: _random.nextDouble() * 2 + 0.5,
          speedX: (_random.nextDouble() - 0.5) * 2,
          speedY: (_random.nextDouble() - 0.5) * 2,
          color: Colors.white.withValues(alpha: _random.nextDouble() * 0.5 + 0.5),
          angle: 0,
          spin: 0,
          life: _random.nextDouble() * size.width / 2, // distance from center
        );
      default:
        return Particle(x: 0, y: 0, size: 0, speedY: 0, speedX: 0, color: Colors.transparent, angle: 0, spin: 0);""";
  content = content.replaceFirst(oldCreate, newCreate);

  // 3. AnimatedBuilder
  final oldAnim = "} else if (_currentEffect == 'hearts') {";
  final newAnim = """} else if (_currentEffect == 'fireflies') {
            p.x += sin(p.y * 0.02) * 0.5;
            p.y += cos(p.x * 0.02) * 0.5;
            p.life += 0.05;
          } else if (_currentEffect == 'cherry_blossom') {
            p.x += sin(p.y * 0.01) * 1.5;
          } else if (_currentEffect == 'galaxy') {
            double centerX = size.width / 2;
            double centerY = size.height / 2;
            double dx = p.x - centerX;
            double dy = p.y - centerY;
            double dist = sqrt(dx*dx + dy*dy);
            if (dist == 0) dist = 1;
            p.x += (dx / dist) * (dist * 0.02 + 0.5);
            p.y += (dy / dist) * (dist * 0.02 + 0.5);
            p.size = (dist / size.width) * 4 + 0.5;
            if (p.x < 0 || p.x > size.width || p.y < 0 || p.y > size.height) {
              p.x = centerX + (_random.nextDouble() - 0.5) * 20;
              p.y = centerY + (_random.nextDouble() - 0.5) * 20;
            }
          } else if (_currentEffect == 'fireworks') {
            if (p.speedY < 0 && p.life == 0) {
              p.speedY += 0.05;
              if (p.speedY >= -1.0) {
                p.life = 1; 
                p.speedX = (_random.nextDouble() - 0.5) * 6;
                p.speedY = (_random.nextDouble() - 0.5) * 6;
              }
            } else if (p.life > 0) {
              p.speedY += 0.08; 
              p.life += 1;
            }
          } else if (_currentEffect == 'hearts') {""";
  content = content.replaceFirst(oldAnim, newAnim);
  
  // 3.5 Bounds check
  final oldBounds = """} else if (p.speedY > 0 && p.y > size.height + p.size) { // Moving down
            p.y = -p.size;
            p.x = _random.nextDouble() * size.width;
          }""";
  final newBounds = """} else if (p.speedY > 0 && p.y > size.height + p.size) { // Moving down
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
          }""";
  content = content.replaceFirst(oldBounds, newBounds);

  // 4. EffectPainter background calls
  final oldPaint = "if (effectType == 'sunset_birds') _drawSunsetBackground(canvas, size);";
  final newPaint = "if (effectType == 'sunset_birds') _drawSunsetBackground(canvas, size);\n    if (effectType == 'aurora') _drawAuroraBackground(canvas, size);\n    if (effectType == 'galaxy') _drawGalaxyBackground(canvas, size);";
  content = content.replaceFirst(oldPaint, newPaint);

  // 5. EffectPainter drawing items
  final oldDrawItems = "} else if (effectType == 'meteor') {";
  final newDrawItems = """} else if (effectType == 'cherry_blossom') {
        _drawLeaf(canvas, p, paint);
      } else if (effectType == 'fireflies') {
        double opacity = (sin(p.life) + 1) / 2 * 0.8 + 0.2;
        final glowPaint = Paint()
          ..color = p.color.withValues(alpha: opacity * 0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
        canvas.drawCircle(Offset(p.x, p.y), p.size * 2, glowPaint);
        paint.color = Colors.white.withValues(alpha: opacity);
        canvas.drawCircle(Offset(p.x, p.y), p.size * 0.5, paint);
      } else if (effectType == 'galaxy') {
        canvas.drawCircle(Offset(p.x, p.y), p.size, paint);
      } else if (effectType == 'fireworks') {
        if (p.life == 0) { 
          canvas.drawLine(Offset(p.x, p.y), Offset(p.x, p.y + 10), paint..strokeWidth = 2);
        } else { 
          double opacity = 1.0 - (p.life / 100);
          if (opacity < 0) opacity = 0;
          paint.color = p.color.withValues(alpha: opacity);
          canvas.drawCircle(Offset(p.x, p.y), p.size, paint);
        }
      } else if (effectType == 'meteor') {""";
  content = content.replaceFirst(oldDrawItems, newDrawItems);

  // 6. EffectPainter background methods
  final oldMethods = "  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;";
  final newMethods = """  void _drawAuroraBackground(Canvas canvas, Size size) {
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
    
    canvas.drawCircle(
      Offset(size.width/2, size.height/2), 
      size.width * 0.3, 
      Paint()..color = Colors.white.withValues(alpha: 0.1)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40)
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;""";
  content = content.replaceFirst(oldMethods, newMethods);

  file.writeAsStringSync(content);
}
