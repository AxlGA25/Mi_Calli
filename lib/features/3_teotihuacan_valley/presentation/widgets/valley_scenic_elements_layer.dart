// Layer 3 — Elementos escénicos del Valle (primer plano).
//
// Dibuja elementos decorativos en primer plano: cactáceas, agaves,
// neblina matutina, mariposas (si hay reliquia de Xochiquétzal),
// fauna de Xólotl (si hay reliquia), luciérnagas nocturnas,
// y 5 elementos centrales protagonistas con ValueKeys para testing:
// - Altar Quetzalcóatl
// - Xólotl
// - Fuego Sagrado
// - Chinampa
// - Vasija Tláloc

import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:mi_calli/core/audio/ambient_audio_models.dart';
import 'package:mi_calli/core/constants/app_colors.dart';
import 'package:mi_calli/features/1_sanctuary_journal/models/prehispanic_emotion.dart';

/// Clave global para acceder a esta capa en tests.
final GlobalKey valleyScenicElementsLayerKey = GlobalKey(debugLabel: 'valleyScenicElementsLayer');

/// Claves para los 5 elementos centrales protagonistas (testing).
final GlobalKey valleyAltarQuetzalcoatlKey = GlobalKey(debugLabel: 'valley_altar_quetzalcoatl');
final GlobalKey valleyXolotlFaunaKey = GlobalKey(debugLabel: 'valley_xolotl_fauna');
final GlobalKey valleyFuegoSagradoKey = GlobalKey(debugLabel: 'valley_fuego_sagrado');
final GlobalKey valleyChinampaKey = GlobalKey(debugLabel: 'valley_chinampa');
final GlobalKey valleyVasijaTlalocKey = GlobalKey(debugLabel: 'valley_vasija_tlaloc');

/// Widget que muestra elementos escénicos del Valle en primer plano.
class ValleyScenicElementsLayer extends StatelessWidget {
  const ValleyScenicElementsLayer({
    super.key,
    required this.timePhase,
    this.emotionOverride,
    this.hasXochiquetzalRelic = false,
    this.hasXolotlRelic = false,
    this.showXolotl = false,
    this.hasTlalocRelic = false,
  });

  /// Fase horaria actual.
  final ValleyTimePhase timePhase;

  /// Clima emocional activo (para neblina, etc.).
  final PrehispanicEmotion? emotionOverride;

  /// Si el usuario tiene la reliquia de Xochiquétzal (mariposas en día).
  final bool hasXochiquetzalRelic;

  /// Si el usuario tiene la reliquia de Xólotl (perros/fauna nocturna).
  final bool hasXolotlRelic;

  /// Si Xólotl debe mostrarse (noche O reliquia).
  final bool showXolotl;

  /// Si el usuario tiene la reliquia de Tláloc (vasija en primer plano).
  final bool hasTlalocRelic;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Stack(
      fit: StackFit.expand,
      children: [
        // Fondo: vegetación, neblina, mariposas, fauna, luciérnagas (CustomPaint)
        CustomPaint(
          size: size,
          painter: _ScenicElementsPainter(
            timePhase: timePhase,
            emotionOverride: emotionOverride,
            hasXochiquetzalRelic: hasXochiquetzalRelic,
            hasXolotlRelic: hasXolotlRelic,
            showXolotl: showXolotl,
            hasTlalocRelic: hasTlalocRelic,
            size: size,
          ),
        ),

        // 5 elementos centrales protagonistas con ValueKeys (para testing y tap en Tarea 4.3)
        // Posicionados en el tercio central de la pantalla

        // 1. Altar Quetzalcóatl - centro-izquierda, zona media
        Positioned(
          key: valleyAltarQuetzalcoatlKey,
          left: size.width * 0.22,
          bottom: size.height * 0.28,
          child: _AltarQuetzalcoatlWidget(
            timePhase: timePhase,
            emotionOverride: emotionOverride,
          ),
        ),

        // 2. Xólotl - centro-derecha, zona baja (solo si showXolotl)
        if (showXolotl)
          Positioned(
            key: valleyXolotlFaunaKey,
            right: size.width * 0.18,
            bottom: size.height * 0.22,
            child: _XolotlWidget(
              timePhase: timePhase,
              emotionOverride: emotionOverride,
            ),
          ),

        // 3. Fuego Sagrado - centro, zona media (siempre visible)
        Positioned(
          key: valleyFuegoSagradoKey,
          left: size.width * 0.42,
          bottom: size.height * 0.35,
          child: _FuegoSagradoWidget(
            timePhase: timePhase,
            emotionOverride: emotionOverride,
          ),
        ),

        // 4. Chinampa - centro-izquierda, zona baja
        Positioned(
          key: valleyChinampaKey,
          left: size.width * 0.08,
          bottom: size.height * 0.12,
          child: _ChinampaWidget(
            timePhase: timePhase,
            emotionOverride: emotionOverride,
          ),
        ),

        // 5. Vasija Tláloc - centro-derecha, zona baja (si tiene reliquia)
        if (hasTlalocRelic)
          Positioned(
            key: valleyVasijaTlalocKey,
            right: size.width * 0.08,
            bottom: size.height * 0.12,
            child: _VasijaTlalocWidget(
              timePhase: timePhase,
              emotionOverride: emotionOverride,
            ),
          ),
      ],
    );
  }
}

/// Painter que dibuja todos los elementos de fondo (vegetación, neblina, etc.).
class _ScenicElementsPainter extends CustomPainter {
  _ScenicElementsPainter({
    required this.timePhase,
    this.emotionOverride,
    required this.hasXochiquetzalRelic,
    required this.hasXolotlRelic,
    required this.showXolotl,
    required this.hasTlalocRelic,
    required this.size,
  });

  final ValleyTimePhase timePhase;
  final PrehispanicEmotion? emotionOverride;
  final bool hasXochiquetzalRelic;
  final bool hasXolotlRelic;
  final bool showXolotl;
  final bool hasTlalocRelic;
  final Size size;

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Neblina matutina (amanecer y emociones nocturnas)
    if (timePhase == ValleyTimePhase.dawn ||
        emotionOverride == PrehispanicEmotion.metztliNoche ||
        emotionOverride == PrehispanicEmotion.mixcoatlTormenta) {
      _drawMorningMist(canvas, size);
    }

    // 2. Vegetación del primer plano (cactáceas, agaves)
    _drawForegroundVegetation(canvas, size);

    // 3. Mariposas de Xochiquétzal (día, si tiene reliquia)
    if (hasXochiquetzalRelic &&
        (timePhase == ValleyTimePhase.day || timePhase == ValleyTimePhase.dawn) &&
        emotionOverride != PrehispanicEmotion.tlalocLluvia &&
        emotionOverride != PrehispanicEmotion.mixcoatlTormenta) {
      _drawButterflies(canvas, size);
    }

    // 4. Fauna de Xólotl (noche/atardecer, si showXolotl)
    if (showXolotl &&
        (timePhase == ValleyTimePhase.dusk || timePhase == ValleyTimePhase.night)) {
      _drawXolotlFauna(canvas, size);
    }

    // 5. Luciérnagas nocturnas (noche sin tormenta)
    if (timePhase == ValleyTimePhase.night &&
        emotionOverride != PrehispanicEmotion.mixcoatlTormenta &&
        emotionOverride != PrehispanicEmotion.tlalocLluvia) {
      _drawFireflies(canvas, size);
    }
  }

  void _drawMorningMist(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    // Capas de neblina horizontal con gradiente
    const layerCount = 4;
    for (var layer = 0; layer < layerCount; layer++) {
      final yPos = size.height * (0.55 + layer * 0.06);
      final alpha = 0.08 - layer * 0.015;
      final width = size.width * (1.2 - layer * 0.15);
      final xOffset = -size.width * 0.1;

      paint.color = Colors.white.withValues(alpha: alpha);

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(xOffset, yPos, width, size.height * 0.08),
        Radius.circular(size.height * 0.04),
      );
      canvas.drawRRect(rect, paint);
    }
  }

  void _drawForegroundVegetation(Canvas canvas, Size size) {
    final random = math.Random(42); // Seed fijo para consistencia

    // Agaves (izquierda)
    _drawAgaveCluster(canvas, size, Offset(size.width * 0.08, size.height * 0.85), random);

    // Nopales (centro-izquierda)
    _drawNopalCluster(canvas, size, Offset(size.width * 0.35, size.height * 0.82), random);

    // Agaves (derecha)
    _drawAgaveCluster(canvas, size, Offset(size.width * 0.78, size.height * 0.85), random);

    // Magueyes (centro-derecha)
    _drawMagueyCluster(canvas, size, Offset(size.width * 0.55, size.height * 0.83), random);

    // Piedras decorativas base
    _drawStones(canvas, size, random);
  }

  void _drawAgaveCluster(Canvas canvas, Size size, Offset basePos, math.Random random) {
    final paint = Paint()
      ..color = AppColors.jade.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    final leafPaint = Paint()
      ..color = AppColors.jade.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    const plantCount = 3;
    for (var i = 0; i < plantCount; i++) {
      final offsetX = basePos.dx + (i - 1) * size.width * 0.04;
      final offsetY = basePos.dy + random.nextDouble() * 10;
      final height = size.height * (0.12 + random.nextDouble() * 0.04);
      final width = size.width * 0.035;

      // Roseta de hojas (triángulos curvos)
      final path = Path();
      const leafCount = 8;
      for (var leaf = 0; leaf < leafCount; leaf++) {
        final angle = (leaf / leafCount) * 2 * math.pi - math.pi / 2;
        final leafLength = height * (0.6 + random.nextDouble() * 0.3);
        final leafWidth = width * (0.8 + random.nextDouble() * 0.4);

        final tipX = offsetX + math.cos(angle) * leafLength;
        final tipY = offsetY + math.sin(angle) * leafLength;
        final baseLeftX = offsetX + math.cos(angle - 0.3) * leafWidth;
        final baseLeftY = offsetY + math.sin(angle - 0.3) * leafWidth;
        final baseRightX = offsetX + math.cos(angle + 0.3) * leafWidth;
        final baseRightY = offsetY + math.sin(angle + 0.3) * leafWidth;

        if (leaf == 0) {
          path.moveTo(baseLeftX, baseLeftY);
        }
        path.lineTo(tipX, tipY);
        path.lineTo(baseRightX, baseRightY);
      }
      path.close();
      canvas.drawPath(path, leafPaint);

      // Tallo central
      final stemRect = Rect.fromCenter(
        center: Offset(offsetX, offsetY + height * 0.15),
        width: 3,
        height: height * 0.3,
      );
      canvas.drawRect(stemRect, paint);
    }
  }

  void _drawNopalCluster(Canvas canvas, Size size, Offset basePos, math.Random random) {
    final paint = Paint()
      ..color = AppColors.jade.withValues(alpha: 0.65)
      ..style = PaintingStyle.fill;

    const padCount = 4;
    for (var i = 0; i < padCount; i++) {
      final y = basePos.dy - i * size.height * 0.05;
      final x = basePos.dx + (random.nextDouble() - 0.5) * size.width * 0.02;
      final padWidth = size.width * (0.04 + random.nextDouble() * 0.02);
      final padHeight = size.height * (0.025 + random.nextDouble() * 0.01);

      // Pala de nopal (óvalo aplanado)
      final rect = Rect.fromCenter(
        center: Offset(x, y),
        width: padWidth,
        height: padHeight,
      );

      final path = Path()
        ..addOval(rect);
      canvas.drawPath(path, paint);

      // Espinas (pequeños puntos)
      final spinePaint = Paint()
        ..color = AppColors.obsidiana.withValues(alpha: 0.4)
        ..style = PaintingStyle.fill;

      for (var s = 0; s < 3; s++) {
        final spineX = x + (random.nextDouble() - 0.5) * padWidth * 0.6;
        final spineY = y + (random.nextDouble() - 0.5) * padHeight * 0.6;
        canvas.drawCircle(Offset(spineX, spineY), 0.8, spinePaint);
      }
    }
  }

  void _drawMagueyCluster(Canvas canvas, Size size, Offset basePos, math.Random random) {
    // Similar a agave pero más grande y menos hojas
    final paint = Paint()
      ..color = AppColors.jade.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    const plantCount = 2;
    for (var i = 0; i < plantCount; i++) {
      final offsetX = basePos.dx + (i - 0.5) * size.width * 0.06;
      final offsetY = basePos.dy;
      final height = size.height * 0.18;
      final width = size.width * 0.05;

      final path = Path();
      const leafCount = 6;
      for (var leaf = 0; leaf < leafCount; leaf++) {
        final angle = (leaf / leafCount) * 2 * math.pi - math.pi / 2;
        final leafLength = height * 0.7;
        final leafWidth = width * 0.5;

        final tipX = offsetX + math.cos(angle) * leafLength;
        final tipY = offsetY + math.sin(angle) * leafLength;
        final baseLeftX = offsetX + math.cos(angle - 0.4) * leafWidth;
        final baseLeftY = offsetY + math.sin(angle - 0.4) * leafWidth;
        final baseRightX = offsetX + math.cos(angle + 0.4) * leafWidth;
        final baseRightY = offsetY + math.sin(angle + 0.4) * leafWidth;

        if (leaf == 0) path.moveTo(baseLeftX, baseLeftY);
        path.lineTo(tipX, tipY);
        path.lineTo(baseRightX, baseRightY);
      }
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  void _drawStones(Canvas canvas, Size size, math.Random random) {
    final paint = Paint()
      ..color = AppColors.obsidiana.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    const stoneCount = 12;
    for (var i = 0; i < stoneCount; i++) {
      final x = size.width * (0.05 + random.nextDouble() * 0.9);
      final y = size.height * (0.88 + random.nextDouble() * 0.08);
      final radius = size.width * (0.008 + random.nextDouble() * 0.012);

      final path = Path();
      const vertexCount = 6;
      for (var v = 0; v < vertexCount; v++) {
        final angle = (v / vertexCount) * 2 * math.pi;
        final r = radius * (0.7 + random.nextDouble() * 0.3);
        final px = x + math.cos(angle) * r;
        final py = y + math.sin(angle) * r;
        if (v == 0) path.moveTo(px, py);
        path.lineTo(px, py);
      }
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  void _drawButterflies(Canvas canvas, Size size) {
    // Mariposas animadas - posiciones base
    final paint = Paint()
      ..color = AppColors.rosaSuave.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    final wingPaint = Paint()
      ..color = AppColors.oro.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    const butterflyCount = 6;
    for (var i = 0; i < butterflyCount; i++) {
      final random = math.Random(i * 100 + 42);
      final x = size.width * (0.15 + random.nextDouble() * 0.7);
      final y = size.height * (0.15 + random.nextDouble() * 0.4);
      final scale = 0.8 + random.nextDouble() * 0.4;
      final wingSpan = size.width * 0.015 * scale;

      // Ala izquierda
      final leftWing = Path()
        ..moveTo(x, y)
        ..quadraticBezierTo(
          x - wingSpan * 1.2, y - wingSpan * 0.5,
          x - wingSpan * 0.8, y + wingSpan * 0.3,
        )
        ..quadraticBezierTo(x - wingSpan * 0.3, y + wingSpan * 0.1, x, y);
      canvas.drawPath(leftWing, wingPaint);

      // Ala derecha
      final rightWing = Path()
        ..moveTo(x, y)
        ..quadraticBezierTo(
          x + wingSpan * 1.2, y - wingSpan * 0.5,
          x + wingSpan * 0.8, y + wingSpan * 0.3,
        )
        ..quadraticBezierTo(x + wingSpan * 0.3, y + wingSpan * 0.1, x, y);
      canvas.drawPath(rightWing, wingPaint);

      // Cuerpo
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, y),
          width: wingSpan * 0.3,
          height: wingSpan * 0.8,
        ),
        paint,
      );
    }
  }

  void _drawXolotlFauna(Canvas canvas, Size size) {
    // Siluetas de perros/izcuintles (perros xoloitzcuintle) en la lejanía
    final paint = Paint()
      ..color = AppColors.obsidiana.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    const dogCount = 3;
    for (var i = 0; i < dogCount; i++) {
      final random = math.Random(i * 50 + 123);
      final x = size.width * (0.1 + i * 0.3 + random.nextDouble() * 0.1);
      final y = size.height * (0.65 + random.nextDouble() * 0.05);
      final scale = 0.7 + random.nextDouble() * 0.3;

      _drawDogSilhouette(canvas, Offset(x, y), size.width * 0.04 * scale, paint);
    }
  }

  void _drawDogSilhouette(Canvas canvas, Offset pos, double size, Paint paint) {
    final path = Path();
    // Cuerpo alargado
    path.moveTo(pos.dx - size * 0.6, pos.dy);
    path.lineTo(pos.dx + size * 0.6, pos.dy);
    path.lineTo(pos.dx + size * 0.7, pos.dy + size * 0.4);
    path.lineTo(pos.dx + size * 0.3, pos.dy + size * 0.4); // Patas traseras
    path.lineTo(pos.dx + size * 0.3, pos.dy + size * 0.7);
    path.lineTo(pos.dx - size * 0.3, pos.dy + size * 0.7);
    path.lineTo(pos.dx - size * 0.3, pos.dy + size * 0.4); // Patas delanteras
    path.lineTo(pos.dx - size * 0.7, pos.dy + size * 0.4);
    path.close();
    canvas.drawPath(path, paint);

    // Cabeza
    final headPath = Path()
      ..moveTo(pos.dx + size * 0.6, pos.dy)
      ..lineTo(pos.dx + size * 1.0, pos.dy - size * 0.2)
      ..lineTo(pos.dx + size * 1.1, pos.dy + size * 0.1)
      ..lineTo(pos.dx + size * 0.7, pos.dy + size * 0.3)
      ..close();
    canvas.drawPath(headPath, paint);

    // Orejas puntiagudas
    final earPath = Path()
      ..moveTo(pos.dx + size * 0.85, pos.dy - size * 0.15)
      ..lineTo(pos.dx + size * 0.95, pos.dy - size * 0.4)
      ..lineTo(pos.dx + size * 1.0, pos.dy - size * 0.1)
      ..close();
    canvas.drawPath(earPath, paint);
  }

  void _drawFireflies(Canvas canvas, Size size) {
    // Luciérnagas nocturnas - puntos que parpadean
    final random = math.Random(999);

    const fireflyCount = 20;
    for (var i = 0; i < fireflyCount; i++) {
      final x = size.width * (0.1 + random.nextDouble() * 0.8);
      final y = size.height * (0.2 + random.nextDouble() * 0.5);
      final baseAlpha = 0.3 + random.nextDouble() * 0.4;
      final radius = 1.5 + random.nextDouble() * 1.5;

      // Color amarillo verdoso característico
      final color = AppColors.fuegoDorado.withValues(alpha: baseAlpha);

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), radius, paint);

      // Halo de luz
      final haloPaint = Paint()
        ..color = color.withValues(alpha: 0.2)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(Offset(x, y), radius * 3, haloPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is _ScenicElementsPainter &&
        (oldDelegate.timePhase != timePhase ||
         oldDelegate.emotionOverride != emotionOverride ||
         oldDelegate.hasXochiquetzalRelic != hasXochiquetzalRelic ||
         oldDelegate.hasXolotlRelic != hasXolotlRelic ||
         oldDelegate.showXolotl != showXolotl ||
         oldDelegate.hasTlalocRelic != hasTlalocRelic);
  }
}

/// Widget animado para el Altar Quetzalcóatl
class _AltarQuetzalcoatlWidget extends StatefulWidget {
  const _AltarQuetzalcoatlWidget({
    required this.timePhase,
    this.emotionOverride,
  });

  final ValleyTimePhase timePhase;
  final PrehispanicEmotion? emotionOverride;

  @override
  State<_AltarQuetzalcoatlWidget> createState() => _AltarQuetzalcoatlWidgetState();
}

class _AltarQuetzalcoatlWidgetState extends State<_AltarQuetzalcoatlWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);
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
        return CustomPaint(
          size: Size(80, 100),
          painter: _AltarQuetzalcoatlPainter(
            progress: _controller.value,
            timePhase: widget.timePhase,
            emotionOverride: widget.emotionOverride,
          ),
        );
      },
    );
  }
}

class _AltarQuetzalcoatlPainter extends CustomPainter {
  _AltarQuetzalcoatlPainter({
    required this.progress,
    required this.timePhase,
    this.emotionOverride,
  });

  final double progress;
  final ValleyTimePhase timePhase;
  final PrehispanicEmotion? emotionOverride;

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final baseY = size.height;

    // Color base según fase
    Color baseColor;
    switch (timePhase) {
      case ValleyTimePhase.dawn:
        baseColor = const Color(0xFF8B7355);
        break;
      case ValleyTimePhase.day:
        baseColor = const Color(0xFFCD853F);
        break;
      case ValleyTimePhase.dusk:
        baseColor = const Color(0xFF8B4513);
        break;
      case ValleyTimePhase.night:
        baseColor = const Color(0xFF3D3D5C);
        break;
    }

    // Ajuste por emoción
    if (emotionOverride == PrehispanicEmotion.tonatiuhSol) {
      baseColor = const Color(0xFFFFD700);
    } else if (emotionOverride == PrehispanicEmotion.tlalocLluvia) {
      baseColor = const Color(0xFF48CAE4);
    } else if (emotionOverride == PrehispanicEmotion.mixcoatlTormenta) {
      baseColor = const Color(0xFF4A2C4E);
    }

    // Base del altar (pirámide escalonada pequeña)
    final basePaint = Paint()
      ..color = baseColor.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;

    const levelCount = 3;
    final levelHeight = size.height * 0.2;
    final baseWidth = size.width * 0.7;

    for (var level = 0; level < levelCount; level++) {
      final levelProgress = level / levelCount;
      final levelWidth = baseWidth * (1.0 - levelProgress * 0.5);
      final y = baseY - (level + 1) * levelHeight;

      final path = Path();
      final leftX = centerX - levelWidth / 2;
      final rightX = centerX + levelWidth / 2;

      if (level == 0) {
        path.moveTo(leftX, y + levelHeight);
        path.lineTo(leftX, y);
        path.lineTo(rightX, y);
        path.lineTo(rightX, y + levelHeight);
      } else {
        path.lineTo(rightX, y);
        path.lineTo(rightX, y + levelHeight);
        path.lineTo(leftX, y + levelHeight);
        path.lineTo(leftX, y);
      }
      path.close();
      canvas.drawPath(path, basePaint);
    }

    // Escalera central
    final stairPaint = Paint()
      ..color = baseColor.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    final stairWidth = size.width * 0.12;
    final stairRect = Rect.fromLTWH(
      centerX - stairWidth / 2,
      baseY - levelCount * levelHeight,
      stairWidth,
      levelCount * levelHeight,
    );
    canvas.drawRect(stairRect, stairPaint);

    // Serpiente emplumada en la cúspide (animada)
    final serpentPaint = Paint()
      ..color = AppColors.jade.withValues(alpha: 0.8 + 0.2 * progress)
      ..style = PaintingStyle.fill;

    final serpentPath = Path();
    final serpentX = centerX;
    final serpentY = baseY - levelCount * levelHeight - size.height * 0.15;
    final serpentLength = size.height * 0.25;
    final waveAmplitude = size.width * 0.1 * progress;

    serpentPath.moveTo(serpentX, serpentY);
    for (var i = 0; i <= 6; i++) {
      final t = i / 6.0;
      final x = serpentX + math.sin(t * math.pi * 2 + progress * math.pi * 2) * waveAmplitude;
      final y = serpentY - t * serpentLength;
      serpentPath.lineTo(x, y);
    }

    // Cabeza de la serpiente
    final headPath = Path()
      ..moveTo(serpentX, serpentY - serpentLength)
      ..lineTo(serpentX - size.width * 0.06, serpentY - serpentLength + size.height * 0.05)
      ..lineTo(serpentX + size.width * 0.06, serpentY - serpentLength + size.height * 0.05)
      ..close();

    canvas.drawPath(serpentPath, serpentPaint);
    canvas.drawPath(headPath, serpentPaint);

    // Ojos de la serpiente (brillantes)
    final eyePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9 + 0.1 * progress)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(serpentX - size.width * 0.03, serpentY - serpentLength + size.height * 0.02),
      size.width * 0.015,
      eyePaint,
    );
    canvas.drawCircle(
      Offset(serpentX + size.width * 0.03, serpentY - serpentLength + size.height * 0.02),
      size.width * 0.015,
      eyePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is _AltarQuetzalcoatlPainter &&
        (oldDelegate.progress != progress ||
         oldDelegate.timePhase != timePhase ||
         oldDelegate.emotionOverride != emotionOverride);
  }
}

/// Widget animado para Xólotl
class _XolotlWidget extends StatefulWidget {
  const _XolotlWidget({
    required this.timePhase,
    this.emotionOverride,
  });

  final ValleyTimePhase timePhase;
  final PrehispanicEmotion? emotionOverride;

  @override
  State<_XolotlWidget> createState() => _XolotlWidgetState();
}

class _XolotlWidgetState extends State<_XolotlWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat();
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
        return CustomPaint(
          size: Size(60, 70),
          painter: _XolotlPainter(
            progress: _controller.value,
            timePhase: widget.timePhase,
            emotionOverride: widget.emotionOverride,
          ),
        );
      },
    );
  }
}

class _XolotlPainter extends CustomPainter {
  _XolotlPainter({
    required this.progress,
    required this.timePhase,
    this.emotionOverride,
  });

  final double progress;
  final ValleyTimePhase timePhase;
  final PrehispanicEmotion? emotionOverride;

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final baseY = size.height;

    // Color según fase/emoción
    Color baseColor;
    switch (timePhase) {
      case ValleyTimePhase.dawn:
      case ValleyTimePhase.day:
        baseColor = const Color(0xFF8B7355);
        break;
      case ValleyTimePhase.dusk:
        baseColor = const Color(0xFF4A2C4E);
        break;
      case ValleyTimePhase.night:
        baseColor = const Color(0xFF1A1A2E);
        break;
    }

    if (emotionOverride == PrehispanicEmotion.metztliNoche) {
      baseColor = const Color(0xFF3D3D5C);
    }

    final paint = Paint()
      ..color = baseColor.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    // Cuerpo del xoloitzcuintle (perro mexicano)
    final bodyPath = Path();
    final bodyLength = size.width * 0.7;
    final bodyHeight = size.height * 0.35;
    final bodyY = baseY - bodyHeight;

    // Animación de respiración/caminata
    final breatheOffset = math.sin(progress * math.pi * 2) * 2.0;

    bodyPath.moveTo(centerX - bodyLength * 0.4, bodyY + breatheOffset);
    bodyPath.lineTo(centerX + bodyLength * 0.4, bodyY + breatheOffset);
    bodyPath.lineTo(centerX + bodyLength * 0.45, bodyY + bodyHeight + breatheOffset);
    bodyPath.lineTo(centerX + bodyLength * 0.2, bodyY + bodyHeight + breatheOffset); // Patas traseras
    bodyPath.lineTo(centerX + bodyLength * 0.2, bodyY + bodyHeight * 1.3 + breatheOffset);
    bodyPath.lineTo(centerX - bodyLength * 0.2, bodyY + bodyHeight * 1.3 + breatheOffset);
    bodyPath.lineTo(centerX - bodyLength * 0.2, bodyY + bodyHeight + breatheOffset); // Patas delanteras
    bodyPath.lineTo(centerX - bodyLength * 0.45, bodyY + bodyHeight + breatheOffset);
    bodyPath.close();
    canvas.drawPath(bodyPath, paint);

    // Cabeza
    final headPath = Path()
      ..moveTo(centerX + bodyLength * 0.4, bodyY + breatheOffset)
      ..lineTo(centerX + bodyLength * 0.8, bodyY - size.height * 0.1 + breatheOffset)
      ..lineTo(centerX + bodyLength * 0.85, bodyY + size.height * 0.05 + breatheOffset)
      ..lineTo(centerX + bodyLength * 0.5, bodyY + bodyHeight * 0.4 + breatheOffset)
      ..close();
    canvas.drawPath(headPath, paint);

    // Orejas puntiagudas (características del xolo)
    final earPath = Path()
      ..moveTo(centerX + bodyLength * 0.6, bodyY - size.height * 0.05 + breatheOffset)
      ..lineTo(centerX + bodyLength * 0.65, bodyY - size.height * 0.25 + breatheOffset)
      ..lineTo(centerX + bodyLength * 0.7, bodyY + size.height * 0.02 + breatheOffset)
      ..close();
    canvas.drawPath(earPath, paint);

    // Cola
    final tailPath = Path()
      ..moveTo(centerX - bodyLength * 0.4, bodyY + bodyHeight * 0.3 + breatheOffset)
      ..quadraticBezierTo(
        centerX - bodyLength * 0.6, bodyY + bodyHeight * 0.1 + breatheOffset,
        centerX - bodyLength * 0.5, bodyY + bodyHeight * 0.5 + breatheOffset,
      )
      ..quadraticBezierTo(
        centerX - bodyLength * 0.4, bodyY + bodyHeight * 0.4 + breatheOffset,
        centerX - bodyLength * 0.4, bodyY + bodyHeight * 0.3 + breatheOffset,
      )
      ..close();
    canvas.drawPath(tailPath, paint);

    // Ojos brillantes (espíritu guardián)
    final eyePaint = Paint()
      ..color = AppColors.fuegoDorado.withValues(alpha: 0.9 + 0.1 * math.sin(progress * math.pi * 4))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(centerX + bodyLength * 0.65, bodyY - size.height * 0.05 + breatheOffset),
      size.width * 0.02,
      eyePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is _XolotlPainter &&
        (oldDelegate.progress != progress ||
         oldDelegate.timePhase != timePhase ||
         oldDelegate.emotionOverride != emotionOverride);
  }
}

/// Widget animado para Fuego Sagrado
class _FuegoSagradoWidget extends StatefulWidget {
  const _FuegoSagradoWidget({
    required this.timePhase,
    this.emotionOverride,
  });

  final ValleyTimePhase timePhase;
  final PrehispanicEmotion? emotionOverride;

  @override
  State<_FuegoSagradoWidget> createState() => _FuegoSagradoWidgetState();
}

class _FuegoSagradoWidgetState extends State<_FuegoSagradoWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat();
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
        return CustomPaint(
          size: Size(50, 80),
          painter: _FuegoSagradoPainter(
            progress: _controller.value,
            timePhase: widget.timePhase,
            emotionOverride: widget.emotionOverride,
          ),
        );
      },
    );
  }
}

class _FuegoSagradoPainter extends CustomPainter {
  _FuegoSagradoPainter({
    required this.progress,
    required this.timePhase,
    this.emotionOverride,
  });

  final double progress;
  final ValleyTimePhase timePhase;
  final PrehispanicEmotion? emotionOverride;

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final baseY = size.height;

    // Base de piedras del fuego
    final stonePaint = Paint()
      ..color = AppColors.obsidiana.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    const stoneCount = 6;
    final random = math.Random(42);
    for (var i = 0; i < stoneCount; i++) {
      final angle = (i / stoneCount) * 2 * math.pi;
      final radius = size.width * 0.25;
      final x = centerX + math.cos(angle) * radius;
      final y = baseY - size.height * 0.1 + math.sin(angle) * radius * 0.3;
      final stoneRadius = size.width * (0.04 + random.nextDouble() * 0.02);

      final stonePath = Path();
      const vertexCount = 5;
      for (var v = 0; v < vertexCount; v++) {
        final vAngle = (v / vertexCount) * 2 * math.pi + random.nextDouble() * 0.3;
        final r = stoneRadius * (0.7 + random.nextDouble() * 0.3);
        final px = x + math.cos(vAngle) * r;
        final py = y + math.sin(vAngle) * r;
        if (v == 0) stonePath.moveTo(px, py);
        stonePath.lineTo(px, py);
      }
      stonePath.close();
      canvas.drawPath(stonePath, stonePaint);
    }

    // Llamas animadas
    const flameCount = 5;
    for (var i = 0; i < flameCount; i++) {
      _drawFlame(canvas, size, centerX, baseY, i, flameCount, progress);
    }
  }

  void _drawFlame(Canvas canvas, Size size, double centerX, double baseY, int index, int total, double progress) {
    final random = math.Random(index * 100 + 42);
    final offsetX = (random.nextDouble() - 0.5) * size.width * 0.3;
    final baseHeight = size.height * 0.6;
    final flameHeight = baseHeight * (0.6 + random.nextDouble() * 0.4);
    final flameWidth = size.width * (0.08 + random.nextDouble() * 0.06);

    // Animación de parpadeo
    final flicker = math.sin(progress * math.pi * 4 + index * 1.5) * 0.15 + 0.85;
    final animatedHeight = flameHeight * flicker;
    final animatedWidth = flameWidth * flicker;

    // Gradiente de llama
    final gradient = LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: [
        AppColors.fuegoDorado.withValues(alpha: 0.9),
        const Color(0xFFFF8C00).withValues(alpha: 0.8),
        const Color(0xFFFF4500).withValues(alpha: 0.6),
        Colors.white.withValues(alpha: 0.3 * flicker),
      ],
      stops: const [0.0, 0.4, 0.7, 1.0],
    );

    final flamePaint = Paint()
      ..shader = gradient.createShader(
        Rect.fromLTWH(
          centerX + offsetX - animatedWidth / 2,
          baseY - size.height * 0.1 - animatedHeight,
          animatedWidth,
          animatedHeight,
        ),
      )
      ..style = PaintingStyle.fill;

    final flamePath = Path();
    flamePath.moveTo(centerX + offsetX, baseY - size.height * 0.1);

    // Lado izquierdo con ondas
    for (var t = 0.0; t <= 1.0; t += 0.1) {
      final wave = math.sin(t * math.pi * 2 + progress * math.pi * 4 + index) * animatedWidth * 0.3;
      final y = baseY - size.height * 0.1 - t * animatedHeight;
      final x = centerX + offsetX - animatedWidth / 2 + wave;
      flamePath.lineTo(x, y);
    }

    // Punta
    flamePath.lineTo(centerX + offsetX, baseY - size.height * 0.1 - animatedHeight);

    // Lado derecho con ondas
    for (var t = 1.0; t >= 0.0; t -= 0.1) {
      final wave = math.sin(t * math.pi * 2 + progress * math.pi * 4 + index + 1) * animatedWidth * 0.3;
      final y = baseY - size.height * 0.1 - t * animatedHeight;
      final x = centerX + offsetX + animatedWidth / 2 + wave;
      flamePath.lineTo(x, y);
    }

    flamePath.close();
    canvas.drawPath(flamePath, flamePaint);

    // Brillo/resplandor alrededor
    final glowPaint = Paint()
      ..color = AppColors.fuegoDorado.withValues(alpha: 0.15 * flicker)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawCircle(
      Offset(centerX + offsetX, baseY - size.height * 0.1 - animatedHeight * 0.5),
      animatedWidth * 1.5,
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is _FuegoSagradoPainter &&
        (oldDelegate.progress != progress ||
         oldDelegate.timePhase != timePhase ||
         oldDelegate.emotionOverride != emotionOverride);
  }
}

/// Widget para Chinampa (estático con detalles)
class _ChinampaWidget extends StatelessWidget {
  const _ChinampaWidget({
    required this.timePhase,
    this.emotionOverride,
  });

  final ValleyTimePhase timePhase;
  final PrehispanicEmotion? emotionOverride;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(100, 60),
      painter: _ChinampaPainter(
        timePhase: timePhase,
        emotionOverride: emotionOverride,
      ),
    );
  }
}

class _ChinampaPainter extends CustomPainter {
  _ChinampaPainter({
    required this.timePhase,
    this.emotionOverride,
  });

  final ValleyTimePhase timePhase;
  final PrehispanicEmotion? emotionOverride;

  @override
  void paint(Canvas canvas, Size size) {
    final baseY = size.height;

    // Color base según fase
    Color waterColor;
    Color landColor;
    switch (timePhase) {
      case ValleyTimePhase.dawn:
        waterColor = const Color(0xFF4A5D8A);
        landColor = const Color(0xFF6B5B3D);
        break;
      case ValleyTimePhase.day:
        waterColor = const Color(0xFF2E86AB);
        landColor = const Color(0xFF8B7355);
        break;
      case ValleyTimePhase.dusk:
        waterColor = const Color(0xFF3D2C5E);
        landColor = const Color(0xFF5D4E37);
        break;
      case ValleyTimePhase.night:
        waterColor = const Color(0xFF1A1A3E);
        landColor = const Color(0xFF2D2D2D);
        break;
    }

    if (emotionOverride == PrehispanicEmotion.tlalocLluvia) {
      waterColor = const Color(0xFF48CAE4);
    } else if (emotionOverride == PrehispanicEmotion.mixcoatlTormenta) {
      waterColor = const Color(0xFF2C2C3E);
    }

    // Agua alrededor de la chinampa
    final waterPaint = Paint()
      ..color = waterColor.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    final waterRect = Rect.fromLTWH(0, baseY - size.height * 0.3, size.width, size.height * 0.3);
    canvas.drawRect(waterRect, waterPaint);

    // Olas en el agua
    final wavePaint = Paint()
      ..color = waterColor.withValues(alpha: 0.3)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < 3; i++) {
      final y = baseY - size.height * 0.3 + i * size.height * 0.08;
      final path = Path();
      path.moveTo(0, y);
      for (var x = 0.0; x <= size.width; x += 5.0) {
        final waveY = y + math.sin(x * 0.1) * 3;
        path.lineTo(x, waveY);
      }
      canvas.drawPath(path, wavePaint);
    }

    // Tierra de la chinampa (rectángulo elevado)
    final landPaint = Paint()
      ..color = landColor.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;

    final landRect = Rect.fromLTWH(
      size.width * 0.1,
      baseY - size.height * 0.7,
      size.width * 0.8,
      size.height * 0.5,
    );
    canvas.drawRect(landRect, landPaint);

    // Bordes de la chinampa (estacas de madera)
    final stakePaint = Paint()
      ..color = AppColors.obsidiana.withValues(alpha: 0.5)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    const stakeCount = 8;
    for (var i = 0; i < stakeCount; i++) {
      final x = size.width * 0.1 + i * size.width * 0.8 / (stakeCount - 1);
      canvas.drawLine(
        Offset(x, baseY - size.height * 0.3),
        Offset(x, baseY - size.height * 0.7),
        stakePaint,
      );
    }

    // Cultivos en la chinampa (hileras)
    final cropPaint = Paint()
      ..color = AppColors.jade.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    const rowCount = 3;
    for (var row = 0; row < rowCount; row++) {
      final y = baseY - size.height * 0.65 + row * size.height * 0.12;
      for (var i = 0; i < 5; i++) {
        final x = size.width * 0.18 + i * size.width * 0.12;
        final plantRadius = size.width * 0.025;

        canvas.drawCircle(Offset(x, y), plantRadius, cropPaint);
      }
    }

    // Ahuejotes (árboles de sauces) en los bordes

    // Izquierda
    _drawAhuejote(canvas, Offset(size.width * 0.12, baseY - size.height * 0.7), size);
    // Derecha
    _drawAhuejote(canvas, Offset(size.width * 0.88, baseY - size.height * 0.7), size);
  }

  void _drawAhuejote(Canvas canvas, Offset base, Size size) {
    final trunkPaint = Paint()
      ..color = AppColors.obsidiana.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    // Tronco
    final trunkRect = Rect.fromCenter(
      center: Offset(base.dx, base.dy - size.height * 0.15),
      width: size.width * 0.03,
      height: size.height * 0.25,
    );
    canvas.drawRect(trunkRect, trunkPaint);

    // Copa (redondeada)
    final foliagePaint = Paint()
      ..color = AppColors.jade.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(base.dx, base.dy - size.height * 0.3),
      size.width * 0.08,
      foliagePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is _ChinampaPainter &&
        (oldDelegate.timePhase != timePhase ||
         oldDelegate.emotionOverride != emotionOverride);
  }
}

/// Widget para Vasija Tláloc (estático con detalles)
class _VasijaTlalocWidget extends StatelessWidget {
  const _VasijaTlalocWidget({
    required this.timePhase,
    this.emotionOverride,
  });

  final ValleyTimePhase timePhase;
  final PrehispanicEmotion? emotionOverride;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(50, 70),
      painter: _VasijaTlalocPainter(
        timePhase: timePhase,
        emotionOverride: emotionOverride,
      ),
    );
  }
}

class _VasijaTlalocPainter extends CustomPainter {
  _VasijaTlalocPainter({
    required this.timePhase,
    this.emotionOverride,
  });

  final ValleyTimePhase timePhase;
  final PrehispanicEmotion? emotionOverride;

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final baseY = size.height;

    // Color de la vasija (cerámica/arcilla)
    Color vaseColor;
    switch (timePhase) {
      case ValleyTimePhase.dawn:
        vaseColor = const Color(0xFFC48A5C);
        break;
      case ValleyTimePhase.day:
        vaseColor = const Color(0xFFD2915C);
        break;
      case ValleyTimePhase.dusk:
        vaseColor = const Color(0xFFB87D4A);
        break;
      case ValleyTimePhase.night:
        vaseColor = const Color(0xFF8B6B4A);
        break;
    }

    if (emotionOverride == PrehispanicEmotion.tlalocLluvia) {
      vaseColor = const Color(0xFF48CAE4);
    }

    final vasePaint = Paint()
      ..color = vaseColor.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;

    // Cuerpo de la vasija (forma bulbosa)
    final vasePath = Path();
    final neckWidth = size.width * 0.18;
    final neckHeight = size.height * 0.15;
    final bodyWidth = size.width * 0.5;
    final bodyHeight = size.height * 0.55;
    final baseWidth = size.width * 0.25;
    final baseHeight = size.height * 0.1;

    // Cuello
    vasePath.moveTo(centerX - neckWidth / 2, baseY - baseHeight - bodyHeight - neckHeight);
    vasePath.lineTo(centerX + neckWidth / 2, baseY - baseHeight - bodyHeight - neckHeight);
    vasePath.lineTo(centerX + neckWidth / 2, baseY - baseHeight - bodyHeight);
    vasePath.lineTo(centerX - neckWidth / 2, baseY - baseHeight - bodyHeight);
    vasePath.close();
    canvas.drawPath(vasePath, vasePaint);

    // Cuerpo principal
    final bodyPath = Path();
    bodyPath.moveTo(centerX - neckWidth / 2, baseY - baseHeight - bodyHeight);
    bodyPath.quadraticBezierTo(
      centerX - bodyWidth / 2, baseY - baseHeight - bodyHeight * 0.3,
      centerX - bodyWidth / 2, baseY - baseHeight - bodyHeight * 0.6,
    );
    bodyPath.quadraticBezierTo(
      centerX - bodyWidth / 2, baseY - baseHeight,
      centerX, baseY - baseHeight,
    );
    bodyPath.quadraticBezierTo(
      centerX + bodyWidth / 2, baseY - baseHeight,
      centerX + bodyWidth / 2, baseY - baseHeight - bodyHeight * 0.6,
    );
    bodyPath.quadraticBezierTo(
      centerX + bodyWidth / 2, baseY - baseHeight - bodyHeight * 0.3,
      centerX + neckWidth / 2, baseY - baseHeight - bodyHeight,
    );
    bodyPath.close();
    canvas.drawPath(bodyPath, vasePaint);

    // Base
    final basePath = Path();
    basePath.moveTo(centerX - baseWidth / 2, baseY - baseHeight);
    basePath.lineTo(centerX + baseWidth / 2, baseY - baseHeight);
    basePath.lineTo(centerX + baseWidth * 0.4, baseY);
    basePath.lineTo(centerX - baseWidth * 0.4, baseY);
    basePath.close();
    canvas.drawPath(basePath, vasePaint);

    // Asas (dos lados)
    final handlePaint = Paint()
      ..color = vaseColor.withValues(alpha: 0.7)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Asa izquierda
    final leftHandle = Path()
      ..moveTo(centerX - neckWidth / 2, baseY - baseHeight - bodyHeight - neckHeight * 0.3)
      ..quadraticBezierTo(
        centerX - bodyWidth * 0.4, baseY - baseHeight - bodyHeight * 0.5,
        centerX - bodyWidth * 0.3, baseY - baseHeight - bodyHeight * 0.2,
      );
    canvas.drawPath(leftHandle, handlePaint);

    // Asa derecha
    final rightHandle = Path()
      ..moveTo(centerX + neckWidth / 2, baseY - baseHeight - bodyHeight - neckHeight * 0.3)
      ..quadraticBezierTo(
        centerX + bodyWidth * 0.4, baseY - baseHeight - bodyHeight * 0.5,
        centerX + bodyWidth * 0.3, baseY - baseHeight - bodyHeight * 0.2,
      );
    canvas.drawPath(rightHandle, handlePaint);

    // Decoración: glifos de Tláloc (ojos y colmillos)
    final glyphPaint = Paint()
      ..color = AppColors.obsidiana.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    // Ojos de Tláloc (círculos concéntricos)
    final eyeY = baseY - baseHeight - bodyHeight * 0.3;
    const eyeRadius = 4.0;

    // Ojo izquierdo
    canvas.drawCircle(Offset(centerX - size.width * 0.12, eyeY), eyeRadius, glyphPaint);
    canvas.drawCircle(Offset(centerX - size.width * 0.12, eyeY), eyeRadius * 0.5, Paint()..color = vaseColor..style = PaintingStyle.fill);

    // Ojo derecho
    canvas.drawCircle(Offset(centerX + size.width * 0.12, eyeY), eyeRadius, glyphPaint);
    canvas.drawCircle(Offset(centerX + size.width * 0.12, eyeY), eyeRadius * 0.5, Paint()..color = vaseColor..style = PaintingStyle.fill);

    // Colmillos
    final fangPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    // Colmillo izquierdo
    final leftFang = Path()
      ..moveTo(centerX - size.width * 0.12, eyeY + eyeRadius)
      ..lineTo(centerX - size.width * 0.15, eyeY + eyeRadius * 2)
      ..lineTo(centerX - size.width * 0.09, eyeY + eyeRadius * 2)
      ..close();
    canvas.drawPath(leftFang, fangPaint);

    // Colmillo derecho
    final rightFang = Path()
      ..moveTo(centerX + size.width * 0.12, eyeY + eyeRadius)
      ..lineTo(centerX + size.width * 0.15, eyeY + eyeRadius * 2)
      ..lineTo(centerX + size.width * 0.09, eyeY + eyeRadius * 2)
      ..close();
    canvas.drawPath(rightFang, fangPaint);

    // Agua saliendo de la vasija (si emoción Tláloc)
    if (emotionOverride == PrehispanicEmotion.tlalocLluvia) {
      final waterPaint = Paint()
        ..color = AppColors.turquesa.withValues(alpha: 0.6)
        ..style = PaintingStyle.fill;

      // Chorrito de agua desde el cuello
      for (var i = 0; i < 5; i++) {
        final dropX = centerX + (i - 2) * size.width * 0.03;
        final dropY = baseY - baseHeight - bodyHeight - neckHeight - i * size.height * 0.04;
        final dropRadius = size.width * 0.015;
        canvas.drawCircle(Offset(dropX, dropY), dropRadius, waterPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is _VasijaTlalocPainter &&
        (oldDelegate.timePhase != timePhase ||
         oldDelegate.emotionOverride != emotionOverride);
  }
}