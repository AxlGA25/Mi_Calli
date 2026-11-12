// Layer 1 — Pirámides del Valle de Teotihuacán (fondo).
//
// CustomPainter que dibuja la silueta de la Pirámide del Sol y la
// Pirámide de la Luna usando paths vectoriales (sin assets de imagen).
// El color se adapta a la fase horaria y al clima emocional.

import 'package:flutter/material.dart';

import 'package:mi_calli/core/audio/ambient_audio_models.dart';
import 'package:mi_calli/features/1_sanctuary_journal/models/prehispanic_emotion.dart';

/// Clave global para acceder a esta capa en tests.
final GlobalKey valleyPyramidsLayerKey = GlobalKey(debugLabel: 'valleyPyramidsLayer');

/// Widget que muestra las pirámides de fondo del Valle.
class ValleyPyramidsBackgroundLayer extends StatelessWidget {
  const ValleyPyramidsBackgroundLayer({
    super.key,
    required this.timePhase,
    this.emotionOverride,
  });

  /// Fase horaria actual (dawn, day, dusk, night).
  final ValleyTimePhase timePhase;

  /// Clima emocional que sobrescribe la atmósfera (opcional).
  final PrehispanicEmotion? emotionOverride;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final pyramidColor = _resolvePyramidColor();

    return CustomPaint(
      size: size,
      painter: _PyramidsPainter(
        timePhase: timePhase,
        emotionOverride: emotionOverride,
        pyramidColor: pyramidColor,
      ),
    );
  }

  Color _resolvePyramidColor() {
    return switch (timePhase) {
      ValleyTimePhase.dawn => const Color(0xFF3D3D5C).withValues(alpha: 0.8),
      ValleyTimePhase.day => const Color(0xFF8B7355).withValues(alpha: 0.9),
      ValleyTimePhase.dusk => const Color(0xFF4A2C4E).withValues(alpha: 0.85),
      ValleyTimePhase.night => const Color(0xFF1A1A2E).withValues(alpha: 0.9),
    };
  }
}

/// Painter que dibuja las pirámides con paths vectoriales.
class _PyramidsPainter extends CustomPainter {
  _PyramidsPainter({
    required this.timePhase,
    this.emotionOverride,
    required this.pyramidColor,
  });

  final ValleyTimePhase timePhase;
  final PrehispanicEmotion? emotionOverride;
  final Color pyramidColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = pyramidColor
      ..style = PaintingStyle.fill;

    // Dibujar Pirámide del Sol (más grande, a la derecha)
    _drawPyramidOfTheSun(canvas, size, paint);

    // Dibujar Pirámide de la Luna (más pequeña, a la izquierda, más lejos)
    _drawPyramidOfTheMoon(canvas, size, paint);

    // Dibujar Templo de los Códices (al costado izquierdo de la Calzada, entre ambas pirámides)
    _drawTemploDeLosCodices(canvas, size, paint);

    // Dibujar Calzada de los Muertos (línea conectando ambas)
    _drawAvenueOfTheDead(canvas, size);
  }

  void _drawPyramidOfTheSun(Canvas canvas, Size size, Paint paint) {
    // Pirámide del Sol: base ancha, 5 niveles escalonados
    final baseWidth = size.width * 0.45;
    final baseHeight = size.height * 0.35;
    final centerX = size.width * 0.68;
    final baseY = size.height * 0.68;

    final path = Path();
    final levelCount = 5;

    for (var level = 0; level < levelCount; level++) {
      final levelProgress = level / levelCount;
      final levelWidth = baseWidth * (1.0 - levelProgress * 0.7);
      final levelHeight = baseHeight / levelCount;
      final levelY = baseY - level * levelHeight;
      final levelCenterX = centerX;

      // Escalones trapezoidales
      final leftX = levelCenterX - levelWidth / 2;
      final rightX = levelCenterX + levelWidth / 2;

      if (level == 0) {
        path.moveTo(leftX, levelY + levelHeight);
        path.lineTo(leftX, levelY);
        path.lineTo(rightX, levelY);
        path.lineTo(rightX, levelY + levelHeight);
      } else {
        path.lineTo(rightX, levelY);
        path.lineTo(rightX, levelY + levelHeight);
        path.lineTo(leftX, levelY + levelHeight);
        path.lineTo(leftX, levelY);
      }
    }

    path.close();
    canvas.drawPath(path, paint);

    // Templo en la cúspide (pequeño rectángulo superior)
    final templePaint = Paint()
      ..color = pyramidColor.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    final templeWidth = baseWidth * 0.15;
    final templeHeight = baseHeight * 0.08;
    final templeRect = Rect.fromCenter(
      center: Offset(centerX, baseY - levelCount * (baseHeight / levelCount) - templeHeight / 2),
      width: templeWidth,
      height: templeHeight,
    );
    canvas.drawRect(templeRect, templePaint);
  }

  void _drawPyramidOfTheMoon(Canvas canvas, Size size, Paint paint) {
    // Pirámide de la Luna: más pequeña, a la izquierda, perspectiva lejana
    final baseWidth = size.width * 0.28;
    final baseHeight = size.height * 0.22;
    final centerX = size.width * 0.22;
    final baseY = size.height * 0.72;

    // Color ligeramente más claro para perspectiva atmosférica
    final moonPaint = Paint()
      ..color = pyramidColor.withValues(alpha: 0.65)
      ..style = PaintingStyle.fill;

    final path = Path();
    final levelCount = 4;

    for (var level = 0; level < levelCount; level++) {
      final levelProgress = level / levelCount;
      final levelWidth = baseWidth * (1.0 - levelProgress * 0.6);
      final levelHeight = baseHeight / levelCount;
      final levelY = baseY - level * levelHeight;
      final levelCenterX = centerX;

      final leftX = levelCenterX - levelWidth / 2;
      final rightX = levelCenterX + levelWidth / 2;

      if (level == 0) {
        path.moveTo(leftX, levelY + levelHeight);
        path.lineTo(leftX, levelY);
        path.lineTo(rightX, levelY);
        path.lineTo(rightX, levelY + levelHeight);
      } else {
        path.lineTo(rightX, levelY);
        path.lineTo(rightX, levelY + levelHeight);
        path.lineTo(leftX, levelY + levelHeight);
        path.lineTo(leftX, levelY);
      }
    }

    path.close();
    canvas.drawPath(path, moonPaint);

    // Plaza frontal (rectángulo base)
    final plazaPaint = Paint()
      ..color = pyramidColor.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    final plazaRect = Rect.fromLTWH(
      centerX - baseWidth * 0.6,
      baseY,
      baseWidth * 1.2,
      size.height * 0.04,
    );
    canvas.drawRect(plazaRect, plazaPaint);
  }

  void _drawTemploDeLosCodices(Canvas canvas, Size size, Paint paint) {
    // Templo de los Códices: estructura rectangular con escalones, a la izquierda de la Calzada
    // Posición: entre la Pirámide de la Luna y la del Sol, más cerca de la Luna
    final centerX = size.width * 0.35;
    final baseY = size.height * 0.7;
    final baseWidth = size.width * 0.12;
    final baseHeight = size.height * 0.18;

    final path = Path();
    final levelCount = 3;

    for (var level = 0; level < levelCount; level++) {
      final levelProgress = level / levelCount;
      final levelWidth = baseWidth * (1.0 - levelProgress * 0.4);
      final levelHeight = baseHeight / levelCount;
      final levelY = baseY - level * levelHeight;
      final levelCenterX = centerX;

      final leftX = levelCenterX - levelWidth / 2;
      final rightX = levelCenterX + levelWidth / 2;

      if (level == 0) {
        path.moveTo(leftX, levelY + levelHeight);
        path.lineTo(leftX, levelY);
        path.lineTo(rightX, levelY);
        path.lineTo(rightX, levelY + levelHeight);
      } else {
        path.lineTo(rightX, levelY);
        path.lineTo(rightX, levelY + levelHeight);
        path.lineTo(leftX, levelY + levelHeight);
        path.lineTo(leftX, levelY);
      }
    }

    path.close();
    canvas.drawPath(path, paint);

    // Pequeño templo superior
    final templePaint = Paint()
      ..color = pyramidColor.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    final templeWidth = baseWidth * 0.6;
    final templeHeight = baseHeight * 0.15;
    final templeRect = Rect.fromCenter(
      center: Offset(centerX, baseY - levelCount * (baseHeight / levelCount) - templeHeight / 2),
      width: templeWidth,
      height: templeHeight,
    );
    canvas.drawRect(templeRect, templePaint);
  }

  void _drawAvenueOfTheDead(Canvas canvas, Size size) {
    // Calzada de los Muertos: línea punteada conectando ambas pirámides
    final paint = Paint()
      ..color = pyramidColor.withValues(alpha: 0.3)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final sunBaseX = size.width * 0.68;
    final sunBaseY = size.height * 0.68;
    final moonBaseX = size.width * 0.22;
    final moonBaseY = size.height * 0.72;

    final path = Path();
    path.moveTo(moonBaseX, moonBaseY);
    path.lineTo(sunBaseX, sunBaseY);

    // Dibujar como línea discontinua
    const dashWidth = 8.0;
    const dashSpace = 6.0;
    double distance = 0.0;

    for (var t = 0.0; t < 1.0; t += 0.02) {
      final x = moonBaseX + (sunBaseX - moonBaseX) * t;
      final y = moonBaseY + (sunBaseY - moonBaseY) * t;

      if ((distance ~/ (dashWidth + dashSpace)) % 2 == 0) {
        if (t == 0.0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      } else {
        path.moveTo(x, y);
      }
      distance += 0.02 * (size.width * 0.5);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is _PyramidsPainter &&
        (oldDelegate.timePhase != timePhase ||
         oldDelegate.emotionOverride != emotionOverride ||
         oldDelegate.pyramidColor != pyramidColor);
  }
}