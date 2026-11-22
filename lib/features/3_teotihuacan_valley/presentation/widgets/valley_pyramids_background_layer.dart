// Layer 1 — Pirámides y paisaje del Valle de Teotihuacán (fondo).
//
// Ilustración vectorial estilo Teotihuacán: montañas, disco solar grabado,
// Pirámide del Sol y de la Luna con bloques escalonados, dobles escalinatas
// con alfardas, templo superior, Calzada de los Muertos y canal de la Chinampa.

import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'package:mi_calli/core/audio/ambient_audio_models.dart';
import 'package:mi_calli/features/1_sanctuary_journal/models/prehispanic_emotion.dart';

/// Clave global para acceder a esta capa en tests.
final GlobalKey valleyPyramidsLayerKey = GlobalKey(
  debugLabel: 'valleyPyramidsLayer',
);

/// Widget que muestra las pirámides y el terreno de fondo del Valle.
class ValleyPyramidsBackgroundLayer extends StatelessWidget {
  const ValleyPyramidsBackgroundLayer({
    super.key,
    required this.timePhase,
    this.emotionOverride,
  });

  final ValleyTimePhase timePhase;
  final PrehispanicEmotion? emotionOverride;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final palette = _ValleyLandscapePalette.resolve(timePhase, emotionOverride);

    return CustomPaint(
      size: size,
      painter: _PyramidsPainter(
        timePhase: timePhase,
        emotionOverride: emotionOverride,
        palette: palette,
      ),
    );
  }
}

class _ValleyLandscapePalette {
  const _ValleyLandscapePalette({
    required this.farMountain,
    required this.midHill,
    required this.stoneLight,
    required this.stoneMid,
    required this.stoneShadow,
    required this.stairRail,
    required this.doorway,
    required this.goldAccent,
    required this.groundTop,
    required this.groundBottom,
    required this.avenue,
    required this.water,
    required this.waterHighlight,
  });

  final Color farMountain;
  final Color midHill;
  final Color stoneLight;
  final Color stoneMid;
  final Color stoneShadow;
  final Color stairRail;
  final Color doorway;
  final Color goldAccent;
  final Color groundTop;
  final Color groundBottom;
  final Color avenue;
  final Color water;
  final Color waterHighlight;

  static _ValleyLandscapePalette resolve(
    ValleyTimePhase phase,
    PrehispanicEmotion? emotion,
  ) {
    if (emotion == PrehispanicEmotion.mixcoatlTormenta) {
      return const _ValleyLandscapePalette(
        farMountain: Color(0xFF3A344D),
        midHill: Color(0xFF2D283E),
        stoneLight: Color(0xFF6B5D7A),
        stoneMid: Color(0xFF524661),
        stoneShadow: Color(0xFF382F45),
        stairRail: Color(0xFF7D6E8C),
        doorway: Color(0xFF1D1726),
        goldAccent: Color(0xFFD4A359),
        groundTop: Color(0xFF313936),
        groundBottom: Color(0xFF1F2724),
        avenue: Color(0xFF4C4457),
        water: Color(0xFF233B4D),
        waterHighlight: Color(0xFF4B6E87),
      );
    }

    if (emotion == PrehispanicEmotion.tlalocLluvia) {
      return const _ValleyLandscapePalette(
        farMountain: Color(0xFF4F6F7A),
        midHill: Color(0xFF3D5C66),
        stoneLight: Color(0xFF9E9484),
        stoneMid: Color(0xFF7D7466),
        stoneShadow: Color(0xFF5A544A),
        stairRail: Color(0xFFB5AA98),
        doorway: Color(0xFF292622),
        goldAccent: Color(0xFFE0B86A),
        groundTop: Color(0xFF3D6352),
        groundBottom: Color(0xFF274538),
        avenue: Color(0xFF7B776B),
        water: Color(0xFF2B6E8C),
        waterHighlight: Color(0xFF7EC8E3),
      );
    }

    return switch (phase) {
      ValleyTimePhase.dawn => const _ValleyLandscapePalette(
        farMountain: Color(0xFF7D6B8E),
        midHill: Color(0xFF5D5373),
        stoneLight: Color(0xFFD4A27D),
        stoneMid: Color(0xFFB07D5C),
        stoneShadow: Color(0xFF825846),
        stairRail: Color(0xFFE3B796),
        doorway: Color(0xFF382423),
        goldAccent: Color(0xFFF4C97A),
        groundTop: Color(0xFF5E7358),
        groundBottom: Color(0xFF384D3D),
        avenue: Color(0xFF9E8A78),
        water: Color(0xFF3E6C8A),
        waterHighlight: Color(0xFF9AC5DB),
      ),
      ValleyTimePhase.day => const _ValleyLandscapePalette(
        farMountain: Color(0xFF6B9A94),
        midHill: Color(0xFF4E7D72),
        stoneLight: Color(0xFFDDB892),
        stoneMid: Color(0xFFC2956B),
        stoneShadow: Color(0xFF9C6F47),
        stairRail: Color(0xFFEAD0B3),
        doorway: Color(0xFF4A3123),
        goldAccent: Color(0xFFE9B949),
        groundTop: Color(0xFF6B8E5A),
        groundBottom: Color(0xFF3D5E3C),
        avenue: Color(0xFFD4BE9E),
        water: Color(0xFF2B82A6),
        waterHighlight: Color(0xFF8CD3E8),
      ),
      ValleyTimePhase.dusk => const _ValleyLandscapePalette(
        farMountain: Color(0xFF6B4263),
        midHill: Color(0xFF4F3052),
        stoneLight: Color(0xFFC47D62),
        stoneMid: Color(0xFF9C5B49),
        stoneShadow: Color(0xFF6E3B39),
        stairRail: Color(0xFFD9957A),
        doorway: Color(0xFF2E1A1E),
        goldAccent: Color(0xFFF2B66D),
        groundTop: Color(0xFF4A4B42),
        groundBottom: Color(0xFF2A2E2B),
        avenue: Color(0xFF856558),
        water: Color(0xFF3B436B),
        waterHighlight: Color(0xFFD98B73),
      ),
      ValleyTimePhase.night => const _ValleyLandscapePalette(
        farMountain: Color(0xFF252A48),
        midHill: Color(0xFF1C223B),
        stoneLight: Color(0xFF4F587D),
        stoneMid: Color(0xFF3A4161),
        stoneShadow: Color(0xFF262B45),
        stairRail: Color(0xFF636E96),
        doorway: Color(0xFF131626),
        goldAccent: Color(0xFFE9C46A),
        groundTop: Color(0xFF203330),
        groundBottom: Color(0xFF132120),
        avenue: Color(0xFF343B4F),
        water: Color(0xFF162C46),
        waterHighlight: Color(0xFF4E6F94),
      ),
    };
  }
}

class _PyramidsPainter extends CustomPainter {
  _PyramidsPainter({
    required this.timePhase,
    this.emotionOverride,
    required this.palette,
  });

  final ValleyTimePhase timePhase;
  final PrehispanicEmotion? emotionOverride;
  final _ValleyLandscapePalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final horizonY = size.height * 0.56;

    // 1. Disco solar prehispánico grabado sutilmente en el cielo
    _drawSunStoneHalo(canvas, size);

    // 2. Montañas lejanas (Cerro Gordo y sierra)
    _drawMountains(canvas, size, horizonY);

    // 3. Pirámide de la Luna (izquierda, más lejana)
    _drawTeotihuacanPyramid(
      canvas: canvas,
      centerX: size.width * 0.24,
      baseY: horizonY + size.height * 0.018,
      baseWidth: size.width * 0.36,
      totalHeight: size.height * 0.145,
      levels: 5,
      alpha: 0.90,
      doubleStairs: false,
    );

    // 4. Pirámide del Sol (derecha, protagonista con doble escalinata)
    _drawTeotihuacanPyramid(
      canvas: canvas,
      centerX: size.width * 0.70,
      baseY: horizonY + size.height * 0.032,
      baseWidth: size.width * 0.56,
      totalHeight: size.height * 0.225,
      levels: 7,
      alpha: 1.0,
      doubleStairs: true,
    );

    // 5. Suelo del Valle con degradado cálido/verde
    _drawValleyGround(canvas, size, horizonY);

    // 6. Calzada de los Muertos en perspectiva con losas
    _drawAvenueOfTheDead(canvas, size, horizonY);

    // 7. Canal de agua de la Chinampa (inferior izquierda)
    _drawChinampaCanal(canvas, size);
  }

  /// Anillo solar grabado estilo Piedra del Sol detrás del astro.
  void _drawSunStoneHalo(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.50, size.height * 0.22);
    final ringPaint =
        Paint()
          ..color = palette.goldAccent.withValues(alpha: 0.14)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4;

    canvas.drawCircle(center, 66, ringPaint);
    canvas.drawCircle(center, 82, ringPaint..strokeWidth = 1.0);

    // 12 rayos geométricos discretos estilo glifo solar
    final rayPaint =
        Paint()
          ..color = palette.goldAccent.withValues(alpha: 0.16)
          ..style = PaintingStyle.fill;

    for (var i = 0; i < 12; i++) {
      final angle = i * (math.pi * 2 / 12);
      final tip = Offset(
        center.dx + math.cos(angle) * 94,
        center.dy + math.sin(angle) * 94,
      );
      final p1 = Offset(
        center.dx + math.cos(angle - 0.08) * 82,
        center.dy + math.sin(angle - 0.08) * 82,
      );
      final p2 = Offset(
        center.dx + math.cos(angle + 0.08) * 82,
        center.dy + math.sin(angle + 0.08) * 82,
      );
      final ray =
          Path()
            ..moveTo(p1.dx, p1.dy)
            ..lineTo(tip.dx, tip.dy)
            ..lineTo(p2.dx, p2.dy)
            ..close();
      canvas.drawPath(ray, rayPaint);
    }
  }

  void _drawMountains(Canvas canvas, Size size, double horizonY) {
    final farPath =
        Path()
          ..moveTo(0, horizonY + 10)
          ..quadraticBezierTo(
            size.width * 0.18,
            horizonY - size.height * 0.11,
            size.width * 0.38,
            horizonY - size.height * 0.05,
          )
          ..quadraticBezierTo(
            size.width * 0.58,
            horizonY - size.height * 0.13,
            size.width * 0.82,
            horizonY - size.height * 0.07,
          )
          ..quadraticBezierTo(
            size.width * 0.92,
            horizonY - size.height * 0.09,
            size.width,
            horizonY - size.height * 0.03,
          )
          ..lineTo(size.width, horizonY + 20)
          ..lineTo(0, horizonY + 20)
          ..close();

    canvas.drawPath(
      farPath,
      Paint()..color = palette.farMountain.withValues(alpha: 0.72),
    );

    final midPath =
        Path()
          ..moveTo(0, horizonY + 12)
          ..quadraticBezierTo(
            size.width * 0.28,
            horizonY - size.height * 0.045,
            size.width * 0.55,
            horizonY - size.height * 0.015,
          )
          ..quadraticBezierTo(
            size.width * 0.78,
            horizonY - size.height * 0.055,
            size.width,
            horizonY - size.height * 0.01,
          )
          ..lineTo(size.width, horizonY + 24)
          ..lineTo(0, horizonY + 24)
          ..close();

    canvas.drawPath(
      midPath,
      Paint()..color = palette.midHill.withValues(alpha: 0.85),
    );
  }

  /// Dibuja una pirámide teotihuacana con bloques de piedra escalonados,
  /// sombras por nivel, alfardas (barandales de escalinata) y templo superior.
  void _drawTeotihuacanPyramid({
    required Canvas canvas,
    required double centerX,
    required double baseY,
    required double baseWidth,
    required double totalHeight,
    required int levels,
    required double alpha,
    required bool doubleStairs,
  }) {
    final lightPaint =
        Paint()..color = palette.stoneLight.withValues(alpha: alpha);
    final midPaint = Paint()..color = palette.stoneMid.withValues(alpha: alpha);
    final shadowPaint =
        Paint()..color = palette.stoneShadow.withValues(alpha: alpha);
    final mortarPaint =
        Paint()
          ..color = palette.stoneShadow.withValues(alpha: 0.32 * alpha)
          ..strokeWidth = 1.0;

    final levelH = totalHeight / levels;

    // 1. Cuerpos escalonados con sombra de tablero y líneas de sillares
    for (var i = 0; i < levels; i++) {
      final t = i / levels;
      final w = baseWidth * (1.0 - t * 0.62);
      final left = centerX - w / 2;
      final yTop = baseY - (i + 1) * levelH;

      // Bloque base iluminado a la izquierda y tono medio a la derecha
      canvas.drawRect(
        Rect.fromLTWH(left, yTop, w * 0.54, levelH + 0.5),
        lightPaint,
      );
      canvas.drawRect(
        Rect.fromLTWH(left + w * 0.54, yTop, w * 0.46, levelH + 0.5),
        midPaint,
      );

      // Cornisa superior clara del nivel
      canvas.drawRect(
        Rect.fromLTWH(left, yTop, w, 2.2),
        Paint()..color = palette.stairRail.withValues(alpha: 0.55 * alpha),
      );

      // Sombra inferior del nivel (efecto talud-tablero)
      canvas.drawRect(
        Rect.fromLTWH(left, yTop + levelH - 2.6, w, 2.6),
        shadowPaint,
      );

      // Uniones verticales sutiles de bloques de piedra
      final blockCount = (w / 18).floor().clamp(3, 12);
      final blockW = w / blockCount;
      for (var b = 1; b < blockCount; b++) {
        final bx = left + b * blockW + (i.isEven ? 0 : blockW * 0.35);
        if (bx < left + w - 4) {
          canvas.drawLine(
            Offset(bx, yTop + 2),
            Offset(bx, yTop + levelH - 2),
            mortarPaint,
          );
        }
      }
    }

    // 2. Templo superior plano con molduras y puerta oscura
    final summitY = baseY - totalHeight;
    final topW = baseWidth * 0.36;
    final templeH = levelH * 1.45;
    final templeLeft = centerX - topW / 2;

    canvas.drawRect(
      Rect.fromLTWH(templeLeft, summitY - templeH, topW, templeH),
      midPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(templeLeft, summitY - templeH, topW * 0.52, templeH),
      lightPaint,
    );
    // Friso/cornisa superior del templo
    canvas.drawRect(
      Rect.fromLTWH(templeLeft - 3, summitY - templeH - 3, topW + 6, 5),
      shadowPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(templeLeft - 2, summitY - templeH + 4, topW + 4, 2),
      Paint()..color = palette.stairRail.withValues(alpha: 0.65 * alpha),
    );

    // Puerta oscura del templo
    final doorW = topW * 0.28;
    final doorH = templeH * 0.62;
    canvas.drawRect(
      Rect.fromLTWH(centerX - doorW / 2, summitY - doorH, doorW, doorH),
      Paint()..color = palette.doorway.withValues(alpha: alpha),
    );

    // 3. Escalinatas con alfardas (doble para Pirámide del Sol, sencilla para la Luna)
    if (doubleStairs) {
      _drawStairwayWithAlfardas(
        canvas: canvas,
        topCenterX: centerX - topW * 0.24,
        bottomCenterX: centerX - baseWidth * 0.20,
        topY: summitY,
        bottomY: baseY,
        topW: baseWidth * 0.055,
        bottomW: baseWidth * 0.095,
        steps: levels * 2,
        alpha: alpha,
      );
      _drawStairwayWithAlfardas(
        canvas: canvas,
        topCenterX: centerX + topW * 0.24,
        bottomCenterX: centerX + baseWidth * 0.20,
        topY: summitY,
        bottomY: baseY,
        topW: baseWidth * 0.055,
        bottomW: baseWidth * 0.095,
        steps: levels * 2,
        alpha: alpha,
      );
    } else {
      _drawStairwayWithAlfardas(
        canvas: canvas,
        topCenterX: centerX,
        bottomCenterX: centerX,
        topY: summitY,
        bottomY: baseY,
        topW: baseWidth * 0.11,
        bottomW: baseWidth * 0.18,
        steps: levels * 2,
        alpha: alpha,
      );
    }
  }

  void _drawStairwayWithAlfardas({
    required Canvas canvas,
    required double topCenterX,
    required double bottomCenterX,
    required double topY,
    required double bottomY,
    required double topW,
    required double bottomW,
    required int steps,
    required double alpha,
  }) {
    final railW = 3.2;
    // Cuerpo central de escalones
    final stairPath =
        Path()
          ..moveTo(bottomCenterX - bottomW / 2, bottomY)
          ..lineTo(topCenterX - topW / 2, topY)
          ..lineTo(topCenterX + topW / 2, topY)
          ..lineTo(bottomCenterX + bottomW / 2, bottomY)
          ..close();

    canvas.drawPath(
      stairPath,
      Paint()..color = palette.stoneShadow.withValues(alpha: 0.92 * alpha),
    );

    // Peldaños horizontales
    final stepPaint =
        Paint()
          ..color = palette.stoneLight.withValues(alpha: 0.55 * alpha)
          ..strokeWidth = 1.2;

    for (var s = 1; s < steps; s++) {
      final t = s / steps;
      final cx = bottomCenterX + (topCenterX - bottomCenterX) * t;
      final y = bottomY + (topY - bottomY) * t;
      final halfW = (bottomW + (topW - bottomW) * t) / 2;
      canvas.drawLine(Offset(cx - halfW, y), Offset(cx + halfW, y), stepPaint);
    }

    // Alfardas (barandales laterales claros)
    final railPaint =
        Paint()
          ..color = palette.stairRail.withValues(alpha: 0.95 * alpha)
          ..strokeWidth = railW
          ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(bottomCenterX - bottomW / 2, bottomY),
      Offset(topCenterX - topW / 2, topY),
      railPaint,
    );
    canvas.drawLine(
      Offset(bottomCenterX + bottomW / 2, bottomY),
      Offset(topCenterX + topW / 2, topY),
      railPaint,
    );
  }

  void _drawValleyGround(Canvas canvas, Size size, double horizonY) {
    final groundRect = Rect.fromLTWH(
      0,
      horizonY,
      size.width,
      size.height - horizonY,
    );
    final groundPaint =
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [palette.groundTop, palette.groundBottom],
          ).createShader(groundRect);

    final groundPath =
        Path()
          ..moveTo(0, horizonY + size.height * 0.012)
          ..quadraticBezierTo(
            size.width * 0.5,
            horizonY - size.height * 0.008,
            size.width,
            horizonY + size.height * 0.018,
          )
          ..lineTo(size.width, size.height)
          ..lineTo(0, size.height)
          ..close();

    canvas.drawPath(groundPath, groundPaint);
  }

  void _drawAvenueOfTheDead(Canvas canvas, Size size, double horizonY) {
    final avenuePath =
        Path()
          ..moveTo(size.width * 0.44, horizonY + size.height * 0.004)
          ..lineTo(size.width * 0.56, horizonY + size.height * 0.004)
          ..lineTo(size.width * 0.74, size.height)
          ..lineTo(size.width * 0.26, size.height)
          ..close();

    final avenuePaint =
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              palette.avenue.withValues(alpha: 0.55),
              palette.avenue.withValues(alpha: 0.22),
            ],
          ).createShader(
            Rect.fromLTWH(0, horizonY, size.width, size.height - horizonY),
          );

    canvas.drawPath(avenuePath, avenuePaint);

    // Losas horizontales en perspectiva sobre la Calzada
    final slabPaint =
        Paint()
          ..color = palette.stoneShadow.withValues(alpha: 0.16)
          ..strokeWidth = 1.1;
    for (var i = 1; i <= 7; i++) {
      final t = math.pow(i / 8, 1.5).toDouble();
      final y = horizonY + (size.height - horizonY) * t;
      final leftX = size.width * (0.44 - 0.18 * t);
      final rightX = size.width * (0.56 + 0.18 * t);
      canvas.drawLine(Offset(leftX, y), Offset(rightX, y), slabPaint);
    }

    // Guarniciones laterales de piedra
    final borderPaint =
        Paint()
          ..color = palette.stairRail.withValues(alpha: 0.42)
          ..strokeWidth = 2.0;
    canvas.drawLine(
      Offset(size.width * 0.44, horizonY + size.height * 0.004),
      Offset(size.width * 0.26, size.height),
      borderPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.56, horizonY + size.height * 0.004),
      Offset(size.width * 0.74, size.height),
      borderPaint,
    );
  }

  void _drawChinampaCanal(Canvas canvas, Size size) {
    final canalPath =
        Path()
          ..moveTo(0, size.height * 0.76)
          ..quadraticBezierTo(
            size.width * 0.27,
            size.height * 0.72,
            size.width * 0.50,
            size.height * 0.80,
          )
          ..quadraticBezierTo(
            size.width * 0.58,
            size.height * 0.86,
            size.width * 0.44,
            size.height * 0.94,
          )
          ..quadraticBezierTo(
            size.width * 0.22,
            size.height * 0.99,
            0,
            size.height * 0.96,
          )
          ..close();

    canvas.drawPath(
      canalPath,
      Paint()..color = palette.water.withValues(alpha: 0.82),
    );

    final ripplePaint =
        Paint()
          ..color = palette.waterHighlight.withValues(alpha: 0.40)
          ..strokeWidth = 1.6
          ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(size.width * 0.06, size.height * 0.81),
      Offset(size.width * 0.22, size.height * 0.81),
      ripplePaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.15, size.height * 0.91),
      Offset(size.width * 0.35, size.height * 0.91),
      ripplePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is _PyramidsPainter &&
        (oldDelegate.timePhase != timePhase ||
            oldDelegate.emotionOverride != emotionOverride);
  }
}
