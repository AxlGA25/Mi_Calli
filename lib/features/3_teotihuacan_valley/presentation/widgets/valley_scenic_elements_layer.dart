// Layer 3 — Elementos escénicos del Valle (primer plano).
//
// Quetzalcóatl animado con penacho turquesa/jade/grana y orejeras de oro,
// Templo del Códice con bloques y alfardas, Brasero del Fuego Sagrado con
// chispas, Chinampa fértil, vegetación mesoamericana y 5 zonas táctiles.

import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'package:mi_calli/core/audio/ambient_audio_models.dart';
import 'package:mi_calli/core/constants/app_colors.dart';
import 'package:mi_calli/features/1_sanctuary_journal/models/prehispanic_emotion.dart';

/// Clave global para acceder a esta capa en tests.
final GlobalKey valleyScenicElementsLayerKey = GlobalKey(
  debugLabel: 'valleyScenicElementsLayer',
);

/// Claves para los 5 elementos centrales protagonistas (testing).
final GlobalKey valleyAltarQuetzalcoatlKey = GlobalKey(
  debugLabel: 'valley_altar_quetzalcoatl',
);
final GlobalKey valleyXolotlFaunaKey = GlobalKey(
  debugLabel: 'valley_xolotl_fauna',
);
final GlobalKey valleyFuegoSagradoKey = GlobalKey(
  debugLabel: 'valley_fuego_sagrado',
);
final GlobalKey valleyChinampaKey = GlobalKey(debugLabel: 'valley_chinampa');
final GlobalKey valleyVasijaTlalocKey = GlobalKey(
  debugLabel: 'valley_vasija_tlaloc',
);

/// Claves para las 5 zonas táctiles (Tarea 4.3).
const ValueKey<String> touchZoneQuetzalcoatlKey = ValueKey<String>(
  'touch_zone_quetzalcoatl',
);
const ValueKey<String> touchZoneChinampaKey = ValueKey<String>(
  'touch_zone_chinampa',
);
const ValueKey<String> touchZoneSacredFireKey = ValueKey<String>(
  'touch_zone_sacred_fire',
);
const ValueKey<String> touchZoneCodexTempleKey = ValueKey<String>(
  'touch_zone_codex_temple',
);
const ValueKey<String> touchZoneVenusConstellationKey = ValueKey<String>(
  'touch_zone_venus_constellation',
);

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
    this.onOpenSanctuaryJournal,
    this.onOpenChinampa,
    this.onOpenSacredFire,
    this.onOpenCodex,
    this.onOpenVenusReading,
    this.forceVenusAvailable = false,
  });

  final ValleyTimePhase timePhase;
  final PrehispanicEmotion? emotionOverride;
  final bool hasXochiquetzalRelic;
  final bool hasXolotlRelic;
  final bool showXolotl;
  final bool hasTlalocRelic;
  final VoidCallback? onOpenSanctuaryJournal;
  final VoidCallback? onOpenChinampa;
  final VoidCallback? onOpenSacredFire;
  final VoidCallback? onOpenCodex;
  final VoidCallback? onOpenVenusReading;
  final bool forceVenusAvailable;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    final isVenusAvailable =
        forceVenusAvailable ||
        (timePhase == ValleyTimePhase.night && emotionOverride == null);

    return Stack(
      fit: StackFit.expand,
      children: [
        // Fondo de primer plano: vegetación estilizada, neblina, mariposas y luciérnagas
        CustomPaint(
          size: size,
          painter: _ScenicElementsPainter(
            timePhase: timePhase,
            emotionOverride: emotionOverride,
            hasXochiquetzalRelic: hasXochiquetzalRelic,
            hasXolotlRelic: hasXolotlRelic,
            showXolotl: showXolotl,
            hasTlalocRelic: hasTlalocRelic,
          ),
        ),

        // Elementos decorativos opcionales (Xólotl y Vasija de Tláloc)
        if (showXolotl)
          Positioned(
            key: valleyXolotlFaunaKey,
            right: size.width * 0.09,
            bottom: size.height * 0.16,
            child: _XolotlWidget(
              timePhase: timePhase,
              emotionOverride: emotionOverride,
              reduceMotion: reduceMotion,
            ),
          ),

        if (hasTlalocRelic)
          Positioned(
            key: valleyVasijaTlalocKey,
            right: size.width * 0.05,
            bottom: size.height * 0.05,
            child: _VasijaTlalocWidget(
              timePhase: timePhase,
              emotionOverride: emotionOverride,
            ),
          ),

        // ─── 5 ZONAS TÁCTILES PROTAGONISTAS ───

        // 1. Templo del Códice (sobre la terraza izquierda del valle)
        Positioned(
          left: size.width * 0.04,
          top: size.height * 0.44,
          child: _TouchZone(
            key: touchZoneCodexTempleKey,
            label: 'Abrir el Códice Privado de entradas pasadas',
            badgeText: 'Códice',
            badgeIcon: Icons.calendar_month_rounded,
            onTap: onOpenCodex,
            child: _CodexTempleWidget(
              timePhase: timePhase,
              emotionOverride: emotionOverride,
            ),
          ),
        ),

        // 2. Brasero del Fuego Sagrado (centro-derecha de la Calzada)
        Positioned(
          right: size.width * 0.08,
          top: size.height * 0.50,
          child: _TouchZone(
            key: touchZoneSacredFireKey,
            label: 'Ver racha del Fuego Sagrado y evolución de Quetzalcóatl',
            badgeText: 'Fuego',
            badgeIcon: Icons.local_fire_department_rounded,
            accentColor: const Color(0xFFFF9F1C),
            onTap: onOpenSacredFire,
            child: KeyedSubtree(
              key: valleyFuegoSagradoKey,
              child: _FuegoSagradoWidget(
                timePhase: timePhase,
                emotionOverride: emotionOverride,
                reduceMotion: reduceMotion,
              ),
            ),
          ),
        ),

        // 3. Altar de Quetzalcóatl (protagonista central -> Diario)
        Positioned(
          left: (size.width - 144) / 2,
          bottom: size.height * 0.21,
          child: _TouchZone(
            key: touchZoneQuetzalcoatlKey,
            label: 'Escribir en el Santuario del Diario con Quetzalcóatl',
            badgeText: 'Escribir',
            badgeIcon: Icons.edit_note_rounded,
            accentColor: AppColors.turquesa,
            onTap: onOpenSanctuaryJournal,
            child: KeyedSubtree(
              key: valleyAltarQuetzalcoatlKey,
              child: _AltarQuetzalcoatlWidget(
                timePhase: timePhase,
                emotionOverride: emotionOverride,
                reduceMotion: reduceMotion,
              ),
            ),
          ),
        ),

        // 4. La Chinampa Sagrada (flotando sobre el canal inferior izquierdo)
        Positioned(
          left: size.width * 0.04,
          bottom: size.height * 0.035,
          child: _TouchZone(
            key: touchZoneChinampaKey,
            label: 'Abrir la Chinampa Sagrada y tus cultivos',
            badgeText: 'Chinampa',
            badgeIcon: Icons.eco_rounded,
            accentColor: AppColors.jade,
            onTap: onOpenChinampa,
            child: KeyedSubtree(
              key: valleyChinampaKey,
              child: _ChinampaWidget(
                timePhase: timePhase,
                emotionOverride: emotionOverride,
              ),
            ),
          ),
        ),

        // 5. Constelación de Venus (cielo superior derecho, si está disponible)
        if (isVenusAvailable)
          Positioned(
            right: size.width * 0.07,
            top: size.height * 0.14,
            child: _TouchZone(
              key: touchZoneVenusConstellationKey,
              label: 'Abrir lectura semanal del Tonalpohualli',
              badgeText: 'Venus',
              badgeIcon: Icons.auto_awesome_rounded,
              accentColor: AppColors.oro,
              onTap: onOpenVenusReading,
              child: _VenusConstellationWidget(
                timePhase: timePhase,
                emotionOverride: emotionOverride,
                reduceMotion: reduceMotion,
              ),
            ),
          ),
      ],
    );
  }
}

/// Zona táctil accesible con Semantics, área mínima 48x48 px y etiqueta pill.
/// IMPORTANTE: mantiene un único ConstrainedBox descendiente para los tests.
class _TouchZone extends StatelessWidget {
  const _TouchZone({
    super.key,
    required this.label,
    required this.badgeText,
    required this.badgeIcon,
    required this.onTap,
    required this.child,
    this.accentColor,
  });

  final String label;
  final String badgeText;
  final IconData badgeIcon;
  final VoidCallback? onTap;
  final Widget child;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final badgeBorder = accentColor ?? AppColors.fuegoDorado;

    return Semantics(
      button: true,
      label: label,
      hint: onTap != null ? 'Toca para interactuar' : 'No disponible',
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            splashColor: AppColors.jade.withValues(alpha: 0.18),
            highlightColor: AppColors.jade.withValues(alpha: 0.08),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  child,
                  const SizedBox(height: 4),
                  ExcludeSemantics(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1715).withValues(alpha: 0.82),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: badgeBorder.withValues(alpha: 0.78),
                          width: 1.1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.28),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(badgeIcon, size: 13, color: badgeBorder),
                          const SizedBox(width: 4),
                          Text(
                            badgeText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.pergaminoClaro,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Templo de los Códices (bloques cálidos con alfardas y puerta oscura).
class _CodexTempleWidget extends StatelessWidget {
  const _CodexTempleWidget({required this.timePhase, this.emotionOverride});

  final ValleyTimePhase timePhase;
  final PrehispanicEmotion? emotionOverride;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(88, 78),
      painter: _CodexTemplePainter(
        timePhase: timePhase,
        emotionOverride: emotionOverride,
      ),
    );
  }
}

class _CodexTemplePainter extends CustomPainter {
  _CodexTemplePainter({required this.timePhase, this.emotionOverride});

  final ValleyTimePhase timePhase;
  final PrehispanicEmotion? emotionOverride;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final baseY = size.height - 4;

    final isNight = timePhase == ValleyTimePhase.night;
    final stoneLight =
        isNight ? const Color(0xFF565E80) : const Color(0xFFDDB892);
    final stoneMid =
        isNight ? const Color(0xFF3E4566) : const Color(0xFFC2956B);
    final stoneDark =
        isNight ? const Color(0xFF2B304A) : const Color(0xFF946842);

    // Sombra en el suelo
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, baseY + 1),
        width: size.width * 0.88,
        height: 8,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.24),
    );

    // 3 niveles escalonados con sombra de tablero
    final widths = [size.width * 0.84, size.width * 0.68, size.width * 0.54];
    final levelH = size.height * 0.15;

    for (var i = 0; i < 3; i++) {
      final w = widths[i];
      final yTop = baseY - (i + 1) * levelH;
      canvas.drawRect(
        Rect.fromLTWH(cx - w / 2, yTop, w * 0.54, levelH),
        Paint()..color = stoneLight,
      );
      canvas.drawRect(
        Rect.fromLTWH(cx + w * 0.04, yTop, w * 0.46, levelH),
        Paint()..color = stoneMid,
      );
      canvas.drawRect(
        Rect.fromLTWH(cx - w / 2, yTop + levelH - 2, w, 2),
        Paint()..color = stoneDark,
      );
    }

    // Santuario superior con friso
    final shrineW = size.width * 0.44;
    final shrineH = size.height * 0.28;
    final shrineTop = baseY - 3 * levelH - shrineH;

    canvas.drawRect(
      Rect.fromLTWH(cx - shrineW / 2, shrineTop, shrineW, shrineH),
      Paint()..color = stoneLight,
    );
    canvas.drawRect(
      Rect.fromLTWH(cx - shrineW * 0.56, shrineTop - 4, shrineW * 1.12, 5),
      Paint()..color = stoneDark,
    );

    // Puerta oscura del códice + acento dorado
    final doorW = shrineW * 0.36;
    final doorH = shrineH * 0.66;
    canvas.drawRect(
      Rect.fromLTWH(cx - doorW / 2, shrineTop + shrineH - doorH, doorW, doorH),
      Paint()..color = AppColors.obsidiana.withValues(alpha: 0.9),
    );
    canvas.drawCircle(
      Offset(cx, shrineTop + 4),
      2.4,
      Paint()..color = AppColors.oro,
    );

    // Escalinata frontal con alfardas
    final stairPath =
        Path()
          ..moveTo(cx - 11, baseY)
          ..lineTo(cx - 8, baseY - 3 * levelH)
          ..lineTo(cx + 8, baseY - 3 * levelH)
          ..lineTo(cx + 11, baseY)
          ..close();
    canvas.drawPath(stairPath, Paint()..color = stoneDark);

    final railPaint =
        Paint()
          ..color = const Color(
            0xFFEAD0B3,
          ).withValues(alpha: isNight ? 0.5 : 0.9)
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(cx - 11, baseY),
      Offset(cx - 8, baseY - 3 * levelH),
      railPaint,
    );
    canvas.drawLine(
      Offset(cx + 11, baseY),
      Offset(cx + 8, baseY - 3 * levelH),
      railPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is _CodexTemplePainter &&
        (oldDelegate.timePhase != timePhase ||
            oldDelegate.emotionOverride != emotionOverride);
  }
}

/// Constelación de Venus (cielo superior).
class _VenusConstellationWidget extends StatefulWidget {
  const _VenusConstellationWidget({
    required this.timePhase,
    this.emotionOverride,
    this.reduceMotion = false,
  });

  final ValleyTimePhase timePhase;
  final PrehispanicEmotion? emotionOverride;
  final bool reduceMotion;

  @override
  State<_VenusConstellationWidget> createState() =>
      _VenusConstellationWidgetState();
}

class _VenusConstellationWidgetState extends State<_VenusConstellationWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    if (!widget.reduceMotion) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _VenusConstellationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reduceMotion && _controller.isAnimating) {
      _controller.stop();
    } else if (!widget.reduceMotion && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
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
        return CustomPaint(
          size: const Size(64, 64),
          painter: _VenusConstellationPainter(
            progress: widget.reduceMotion ? 0.5 : _controller.value,
          ),
        );
      },
    );
  }
}

class _VenusConstellationPainter extends CustomPainter {
  _VenusConstellationPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    canvas.drawCircle(
      center,
      size.width * (0.34 + 0.05 * progress),
      Paint()
        ..color = AppColors.fuegoDorado.withValues(
          alpha: 0.24 + 0.12 * progress,
        )
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    final rOuter = size.width * (0.32 + 0.03 * progress);
    final rInner = size.width * 0.10;
    final starPath = Path();
    for (var i = 0; i < 8; i++) {
      final angle = -math.pi / 2 + i * (math.pi / 4);
      final r = i.isEven ? rOuter : rInner;
      final pt = Offset(
        center.dx + math.cos(angle) * r,
        center.dy + math.sin(angle) * r,
      );
      if (i == 0) {
        starPath.moveTo(pt.dx, pt.dy);
      } else {
        starPath.lineTo(pt.dx, pt.dy);
      }
    }
    starPath.close();

    canvas.drawPath(starPath, Paint()..color = const Color(0xFFFFF3C4));
    canvas.drawCircle(center, 4.5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is _VenusConstellationPainter &&
        oldDelegate.progress != progress;
  }
}

/// Painter de vegetación mesoamericana y detalles atmosféricos.
class _ScenicElementsPainter extends CustomPainter {
  _ScenicElementsPainter({
    required this.timePhase,
    this.emotionOverride,
    required this.hasXochiquetzalRelic,
    required this.hasXolotlRelic,
    required this.showXolotl,
    required this.hasTlalocRelic,
  });

  final ValleyTimePhase timePhase;
  final PrehispanicEmotion? emotionOverride;
  final bool hasXochiquetzalRelic;
  final bool hasXolotlRelic;
  final bool showXolotl;
  final bool hasTlalocRelic;

  @override
  void paint(Canvas canvas, Size size) {
    if (timePhase == ValleyTimePhase.dawn ||
        emotionOverride == PrehispanicEmotion.metztliNoche ||
        emotionOverride == PrehispanicEmotion.mixcoatlTormenta) {
      _drawSoftMist(canvas, size);
    }

    // Agaves en abanico hacia arriba (esquina inferior derecha)
    _drawAgaveFan(
      canvas,
      Offset(size.width * 0.90, size.height * 0.95),
      scale: 1.0,
    );
    _drawAgaveFan(
      canvas,
      Offset(size.width * 0.77, size.height * 0.97),
      scale: 0.72,
    );

    // Nopal estilizado al borde derecho
    _drawNopal(canvas, Offset(size.width * 0.89, size.height * 0.76));

    // Piedras sutiles en la orilla inferior
    _drawStones(canvas, size);

    if (hasXochiquetzalRelic &&
        (timePhase == ValleyTimePhase.day ||
            timePhase == ValleyTimePhase.dawn) &&
        emotionOverride != PrehispanicEmotion.tlalocLluvia &&
        emotionOverride != PrehispanicEmotion.mixcoatlTormenta) {
      _drawButterflies(canvas, size);
    }

    if (timePhase == ValleyTimePhase.night &&
        emotionOverride != PrehispanicEmotion.mixcoatlTormenta &&
        emotionOverride != PrehispanicEmotion.tlalocLluvia) {
      _drawFireflies(canvas, size);
    }
  }

  void _drawSoftMist(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.08)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawOval(
      Rect.fromLTWH(-40, size.height * 0.54, size.width + 80, 44),
      paint,
    );
  }

  void _drawAgaveFan(Canvas canvas, Offset base, {required double scale}) {
    final isNight = timePhase == ValleyTimePhase.night;
    final backLeaf =
        Paint()
          ..color = (isNight
                  ? const Color(0xFF1F473E)
                  : const Color(0xFF2D6A5B))
              .withValues(alpha: 0.88);
    final frontLeaf =
        Paint()
          ..color = (isNight
                  ? const Color(0xFF2B5E52)
                  : const Color(0xFF479C7F))
              .withValues(alpha: 0.94);

    const angles = [-2.55, -2.20, -1.85, -1.57, -1.29, -0.94, -0.59];
    const lengths = [32.0, 44.0, 54.0, 60.0, 54.0, 44.0, 32.0];

    for (var i = 0; i < angles.length; i++) {
      final angle = angles[i];
      final len = lengths[i] * scale;
      final tip = Offset(
        base.dx + math.cos(angle) * len,
        base.dy + math.sin(angle) * len,
      );
      final perp = angle + math.pi / 2;
      final halfW = 6.2 * scale;
      final leftBase = Offset(
        base.dx + math.cos(perp) * halfW,
        base.dy + math.sin(perp) * halfW,
      );
      final rightBase = Offset(
        base.dx - math.cos(perp) * halfW,
        base.dy - math.sin(perp) * halfW,
      );

      final leaf =
          Path()
            ..moveTo(leftBase.dx, leftBase.dy)
            ..quadraticBezierTo(
              (leftBase.dx + tip.dx) / 2,
              (leftBase.dy + tip.dy) / 2 - 4 * scale,
              tip.dx,
              tip.dy,
            )
            ..quadraticBezierTo(
              (rightBase.dx + tip.dx) / 2,
              (rightBase.dy + tip.dy) / 2 - 4 * scale,
              rightBase.dx,
              rightBase.dy,
            )
            ..close();

      canvas.drawPath(leaf, i.isEven ? backLeaf : frontLeaf);
    }
  }

  void _drawNopal(Canvas canvas, Offset base) {
    final isNight = timePhase == ValleyTimePhase.night;
    final padPaint =
        Paint()
          ..color = isNight ? const Color(0xFF224D3A) : const Color(0xFF3E7C52);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(base.dx, base.dy - 12),
        width: 16,
        height: 22,
      ),
      padPaint,
    );
    canvas.save();
    canvas.translate(base.dx - 11, base.dy - 26);
    canvas.rotate(-0.35);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 13, height: 18),
      padPaint,
    );
    canvas.restore();
    canvas.save();
    canvas.translate(base.dx + 11, base.dy - 24);
    canvas.rotate(0.35);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 12, height: 16),
      padPaint,
    );
    canvas.restore();
    // Tunas rojizas sutiles
    canvas.drawCircle(
      Offset(base.dx - 13, base.dy - 36),
      2.6,
      Paint()..color = AppColors.rojoGrana,
    );
  }

  void _drawStones(Canvas canvas, Size size) {
    final stonePaint =
        Paint()..color = AppColors.obsidiana.withValues(alpha: 0.22);
    final spots = [
      Offset(size.width * 0.56, size.height * 0.92),
      Offset(size.width * 0.61, size.height * 0.94),
      Offset(size.width * 0.68, size.height * 0.90),
    ];
    for (var i = 0; i < spots.length; i++) {
      canvas.drawOval(
        Rect.fromCenter(center: spots[i], width: 12.0 - i * 2, height: 6.0),
        stonePaint,
      );
    }
  }

  void _drawButterflies(Canvas canvas, Size size) {
    final wingPaint =
        Paint()..color = AppColors.fuegoDorado.withValues(alpha: 0.88);
    final spots = [
      Offset(size.width * 0.22, size.height * 0.30),
      Offset(size.width * 0.74, size.height * 0.28),
      Offset(size.width * 0.52, size.height * 0.38),
    ];
    for (final p in spots) {
      canvas.drawOval(
        Rect.fromCenter(center: p.translate(-4, -1), width: 8, height: 5),
        wingPaint,
      );
      canvas.drawOval(
        Rect.fromCenter(center: p.translate(4, -1), width: 8, height: 5),
        wingPaint,
      );
    }
  }

  void _drawFireflies(Canvas canvas, Size size) {
    final random = math.Random(999);
    for (var i = 0; i < 16; i++) {
      final pos = Offset(
        size.width * (0.1 + random.nextDouble() * 0.8),
        size.height * (0.35 + random.nextDouble() * 0.5),
      );
      canvas.drawCircle(
        pos,
        4.5,
        Paint()
          ..color = AppColors.fuegoDorado.withValues(alpha: 0.22)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawCircle(
        pos,
        1.6,
        Paint()..color = const Color(0xFFFFF3B0).withValues(alpha: 0.85),
      );
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

/// Altar central con Quetzalcóatl animado (tocado turquesa/jade, plumas rojas,
/// orejeras de oro y flotación suave).
class _AltarQuetzalcoatlWidget extends StatefulWidget {
  const _AltarQuetzalcoatlWidget({
    required this.timePhase,
    this.emotionOverride,
    this.reduceMotion = false,
  });

  final ValleyTimePhase timePhase;
  final PrehispanicEmotion? emotionOverride;
  final bool reduceMotion;

  @override
  State<_AltarQuetzalcoatlWidget> createState() =>
      _AltarQuetzalcoatlWidgetState();
}

class _AltarQuetzalcoatlWidgetState extends State<_AltarQuetzalcoatlWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 3600),
      vsync: this,
    );
    if (!widget.reduceMotion) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _AltarQuetzalcoatlWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reduceMotion && _controller.isAnimating) {
      _controller.stop();
    } else if (!widget.reduceMotion && !_controller.isAnimating) {
      _controller.repeat();
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
        return CustomPaint(
          size: const Size(132, 128),
          painter: _AltarQuetzalcoatlPainter(
            progress: widget.reduceMotion ? 0.25 : _controller.value,
            timePhase: widget.timePhase,
          ),
        );
      },
    );
  }
}

class _AltarQuetzalcoatlPainter extends CustomPainter {
  _AltarQuetzalcoatlPainter({required this.progress, required this.timePhase});

  final double progress;
  final ValleyTimePhase timePhase;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final baseY = size.height - 6;
    final isNight = timePhase == ValleyTimePhase.night;
    final wave = math.sin(progress * math.pi * 2);
    final pulse = 0.5 + 0.5 * wave;

    final stoneLight =
        isNight ? const Color(0xFF5A6382) : const Color(0xFFDDB892);
    final stoneMid =
        isNight ? const Color(0xFF424A68) : const Color(0xFFC2956B);
    final stoneDark =
        isNight ? const Color(0xFF2D334D) : const Color(0xFF946842);

    // 1. Sombra suave en la Calzada
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, baseY + 1),
        width: size.width * 0.86,
        height: 10,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.28),
    );

    // 2. Pedestal escalonado teotihuacano con escalinata central
    final b1W = size.width * 0.82;
    final b2W = size.width * 0.62;
    const h1 = 15.0;
    const h2 = 13.0;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - b1W / 2, baseY - h1, b1W, h1),
        const Radius.circular(3),
      ),
      Paint()..color = stoneMid,
    );
    canvas.drawRect(
      Rect.fromLTWH(cx - b1W / 2, baseY - h1, b1W * 0.52, h1),
      Paint()..color = stoneLight,
    );
    canvas.drawRect(
      Rect.fromLTWH(cx - b1W / 2, baseY - 2.5, b1W, 2.5),
      Paint()..color = stoneDark,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - b2W / 2, baseY - h1 - h2, b2W, h2),
        const Radius.circular(3),
      ),
      Paint()..color = stoneMid,
    );
    canvas.drawRect(
      Rect.fromLTWH(cx - b2W / 2, baseY - h1 - h2, b2W * 0.52, h2),
      Paint()..color = stoneLight,
    );

    // Mini escalinata con alfardas doradas en el altar
    canvas.drawRect(
      Rect.fromLTWH(cx - 10, baseY - h1 - h2, 20, h1 + h2),
      Paint()..color = stoneDark,
    );
    canvas.drawLine(
      Offset(cx - 10, baseY),
      Offset(cx - 10, baseY - h1 - h2),
      Paint()
        ..color = AppColors.oro.withValues(alpha: 0.8)
        ..strokeWidth = 2,
    );
    canvas.drawLine(
      Offset(cx + 10, baseY),
      Offset(cx + 10, baseY - h1 - h2),
      Paint()
        ..color = AppColors.oro.withValues(alpha: 0.8)
        ..strokeWidth = 2,
    );

    // 3. Quetzalcóatl flotando sobre el altar
    final center = Offset(cx, baseY - h1 - h2 - 42 + wave * 3.5);

    // Resplandor turquesa y dorado
    canvas.drawCircle(
      center,
      38 + pulse * 4,
      Paint()
        ..color = const Color(0xFF00B4D8).withValues(alpha: 0.18 + 0.08 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    // Disco solar sutil girando detrás de Quetzalcóatl
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(progress * math.pi * 0.5);
    canvas.drawCircle(
      Offset.zero,
      30,
      Paint()
        ..color = AppColors.oro.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
    for (var i = 0; i < 8; i++) {
      final a = i * (math.pi / 4);
      canvas.drawCircle(
        Offset(math.cos(a) * 30, math.sin(a) * 30),
        2.0,
        Paint()..color = AppColors.fuegoDorado,
      );
    }
    canvas.restore();

    // 4. Penacho de plumas vibrantes (turquesa, jade y puntas rojo grana)
    final featherAngles = [-2.55, -2.25, -1.92, -1.57, -1.22, -0.89, -0.59];
    final featherLens = [34.0, 40.0, 44.0, 46.0, 44.0, 40.0, 34.0];

    for (var i = 0; i < featherAngles.length; i++) {
      final sway = math.sin(progress * math.pi * 2 + i * 0.6) * 0.05;
      final a = featherAngles[i] + sway;
      final len = featherLens[i];
      final tip = Offset(
        center.dx + math.cos(a) * len,
        center.dy + math.sin(a) * len,
      );
      final mid = Offset(
        center.dx + math.cos(a) * (len * 0.65),
        center.dy + math.sin(a) * (len * 0.65),
      );
      final perp = a + math.pi / 2;

      final featherColor =
          i == 3
              ? const Color(0xFF00C2B8)
              : (i.isEven ? const Color(0xFF1B998B) : const Color(0xFF00A896));

      final featherPath =
          Path()
            ..moveTo(center.dx, center.dy)
            ..quadraticBezierTo(
              mid.dx + math.cos(perp) * 6.5,
              mid.dy + math.sin(perp) * 6.5,
              tip.dx,
              tip.dy,
            )
            ..quadraticBezierTo(
              mid.dx - math.cos(perp) * 6.5,
              mid.dy - math.sin(perp) * 6.5,
              center.dx,
              center.dy,
            )
            ..close();
      canvas.drawPath(featherPath, Paint()..color = featherColor);

      // Punta decorativa roja o dorada en las plumas
      canvas.drawCircle(
        Offset(
          center.dx + math.cos(a) * (len - 5),
          center.dy + math.sin(a) * (len - 5),
        ),
        3.0,
        Paint()..color = i.isOdd ? AppColors.rojoGrana : AppColors.oro,
      );
    }

    // 5. Collar / cuerpo de serpiente emplumada bajo la cabeza
    final collarRect = Rect.fromCenter(
      center: Offset(center.dx, center.dy + 19),
      width: 38,
      height: 14,
    );
    canvas.drawOval(collarRect, Paint()..color = const Color(0xFF0F6B5B));
    for (var i = -2; i <= 2; i++) {
      canvas.drawCircle(
        Offset(center.dx + i * 7.5, center.dy + 22),
        2.6,
        Paint()..color = AppColors.oro,
      );
    }

    // 6. Orejeras de oro y jade (como la máscara de la referencia)
    for (final dir in [-1.0, 1.0]) {
      final earCenter = Offset(center.dx + dir * 23, center.dy + 5);
      canvas.drawCircle(earCenter, 6.2, Paint()..color = AppColors.oro);
      canvas.drawCircle(
        earCenter,
        3.2,
        Paint()..color = const Color(0xFF00C2B8),
      );
      // Colgante de pluma bajo la orejera
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: earCenter.translate(0, 9),
            width: 4.5,
            height: 8,
          ),
          const Radius.circular(2),
        ),
        Paint()..color = const Color(0xFF00A896),
      );
    }

    // 7. Cabeza de Quetzalcóatl (estilo glifo teotihuacano amigable)
    final headRect = Rect.fromCenter(
      center: Offset(center.dx, center.dy + 1),
      width: 40,
      height: 34,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(headRect, const Radius.circular(14)),
      Paint()..color = const Color(0xFF178577),
    );
    // Frente / máscara de jade claro
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(center.dx, center.dy - 4),
          width: 34,
          height: 16,
        ),
        const Radius.circular(9),
      ),
      Paint()..color = const Color(0xFF28B5A2),
    );

    // Diadema dorada en la frente
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(center.dx, center.dy - 11),
          width: 28,
          height: 5,
        ),
        const Radius.circular(2.5),
      ),
      Paint()..color = AppColors.oro,
    );
    canvas.drawCircle(
      Offset(center.dx, center.dy - 11),
      3.0,
      Paint()..color = AppColors.rojoGrana,
    );

    // Ojos expresivos con cejas doradas
    for (final dir in [-1.0, 1.0]) {
      final eyeCenter = Offset(center.dx + dir * 8.5, center.dy - 1);
      // Aro dorado
      canvas.drawCircle(
        eyeCenter,
        4.8,
        Paint()..color = const Color(0xFFFFF3C4),
      );
      // Pupila obsidiana
      canvas.drawCircle(eyeCenter, 2.5, Paint()..color = AppColors.obsidiana);
      // Brillo vivo en el ojo
      canvas.drawCircle(
        eyeCenter.translate(0.9, -0.9),
        1.0,
        Paint()..color = Colors.white,
      );
    }

    // Hocico / sonrisa cálida prehispánica
    final snoutRect = Rect.fromCenter(
      center: Offset(center.dx, center.dy + 9),
      width: 22,
      height: 9,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(snoutRect, const Radius.circular(4.5)),
      Paint()..color = const Color(0xFF0E5E52),
    );
    // Colmillitos suaves blancos (toque de serpiente emplumada)
    canvas.drawCircle(
      Offset(center.dx - 5, center.dy + 9),
      1.6,
      Paint()..color = AppColors.pergaminoClaro,
    );
    canvas.drawCircle(
      Offset(center.dx + 5, center.dy + 9),
      1.6,
      Paint()..color = AppColors.pergaminoClaro,
    );

    // 8. Chispas doradas flotando alrededor de Quetzalcóatl
    final sparkPaint =
        Paint()
          ..color = AppColors.fuegoDorado.withValues(alpha: 0.75 * pulse + 0.2);
    canvas.drawCircle(
      Offset(center.dx - 34, center.dy - 18 - pulse * 6),
      2.2,
      sparkPaint,
    );
    canvas.drawCircle(
      Offset(center.dx + 35, center.dy - 12 - (1 - pulse) * 6),
      2.0,
      sparkPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is _AltarQuetzalcoatlPainter &&
        (oldDelegate.progress != progress ||
            oldDelegate.timePhase != timePhase);
  }
}

/// Brasero del Fuego Sagrado con llama viva y chispas.
class _FuegoSagradoWidget extends StatefulWidget {
  const _FuegoSagradoWidget({
    required this.timePhase,
    this.emotionOverride,
    this.reduceMotion = false,
  });

  final ValleyTimePhase timePhase;
  final PrehispanicEmotion? emotionOverride;
  final bool reduceMotion;

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
      duration: const Duration(milliseconds: 1300),
      vsync: this,
    );
    if (!widget.reduceMotion) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _FuegoSagradoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reduceMotion && _controller.isAnimating) {
      _controller.stop();
    } else if (!widget.reduceMotion && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
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
        return CustomPaint(
          size: const Size(74, 84),
          painter: _FuegoSagradoPainter(
            progress: widget.reduceMotion ? 0.5 : _controller.value,
          ),
        );
      },
    );
  }
}

class _FuegoSagradoPainter extends CustomPainter {
  _FuegoSagradoPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final baseY = size.height - 4;
    final bowlTop = baseY - 26;

    // Sombra base
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, baseY), width: 46, height: 8),
      Paint()..color = Colors.black.withValues(alpha: 0.25),
    );

    // Resplandor cálido
    canvas.drawCircle(
      Offset(cx, bowlTop - 18),
      24 + progress * 4,
      Paint()
        ..color = const Color(
          0xFFFF8C00,
        ).withValues(alpha: 0.26 + 0.1 * progress)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    // Llama exterior
    final sway = math.sin(progress * math.pi * 2) * 2.5;
    final outerH = 38.0 + progress * 5.0;
    final outerFlame =
        Path()
          ..moveTo(cx + sway, bowlTop - outerH)
          ..cubicTo(
            cx + 20,
            bowlTop - outerH * 0.45,
            cx + 18,
            bowlTop - 2,
            cx,
            bowlTop + 1,
          )
          ..cubicTo(
            cx - 18,
            bowlTop - 2,
            cx - 20,
            bowlTop - outerH * 0.45,
            cx + sway,
            bowlTop - outerH,
          )
          ..close();
    canvas.drawPath(outerFlame, Paint()..color = const Color(0xFFE76F51));

    // Llama intermedia dorada
    final innerH = 26.0 + (1 - progress) * 4.0;
    final innerFlame =
        Path()
          ..moveTo(cx - sway * 0.5, bowlTop - innerH)
          ..cubicTo(
            cx + 12,
            bowlTop - innerH * 0.45,
            cx + 11,
            bowlTop - 1,
            cx,
            bowlTop,
          )
          ..cubicTo(
            cx - 11,
            bowlTop - 1,
            cx - 12,
            bowlTop - innerH * 0.45,
            cx - sway * 0.5,
            bowlTop - innerH,
          )
          ..close();
    canvas.drawPath(innerFlame, Paint()..color = const Color(0xFFFFD166));

    // Núcleo luminoso
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, bowlTop - 7), width: 8, height: 12),
      Paint()..color = const Color(0xFFFFF8E1),
    );

    // Chispas ascendentes
    final sparkPaint =
        Paint()..color = const Color(0xFFFFE082).withValues(alpha: 0.85);
    canvas.drawCircle(
      Offset(cx - 10, bowlTop - 30 - progress * 8),
      1.7,
      sparkPaint,
    );
    canvas.drawCircle(
      Offset(cx + 11, bowlTop - 34 - (1 - progress) * 7),
      1.5,
      sparkPaint,
    );

    // Brasero teotihuacano con banda de oro
    final brazierPath =
        Path()
          ..moveTo(cx - 18, baseY)
          ..lineTo(cx - 12, baseY - 12)
          ..lineTo(cx - 24, bowlTop)
          ..lineTo(cx + 24, bowlTop)
          ..lineTo(cx + 12, baseY - 12)
          ..lineTo(cx + 18, baseY)
          ..close();
    canvas.drawPath(brazierPath, Paint()..color = const Color(0xFF4F4640));

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, bowlTop), width: 50, height: 6),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFF6B5E55),
    );
    canvas.drawLine(
      Offset(cx - 12, bowlTop + 9),
      Offset(cx + 12, bowlTop + 9),
      Paint()
        ..color = AppColors.oro.withValues(alpha: 0.85)
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is _FuegoSagradoPainter &&
        oldDelegate.progress != progress;
  }
}

/// La Chinampa Sagrada (parcela flotante con cultivos, cempasúchil y ahuejotes).
class _ChinampaWidget extends StatelessWidget {
  const _ChinampaWidget({required this.timePhase, this.emotionOverride});

  final ValleyTimePhase timePhase;
  final PrehispanicEmotion? emotionOverride;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(132, 78),
      painter: _ChinampaPainter(timePhase: timePhase),
    );
  }
}

class _ChinampaPainter extends CustomPainter {
  _ChinampaPainter({required this.timePhase});

  final ValleyTimePhase timePhase;

  @override
  void paint(Canvas canvas, Size size) {
    final isNight = timePhase == ValleyTimePhase.night;
    final soilTop = isNight ? const Color(0xFF473A2C) : const Color(0xFF8C6239);
    final woodSide =
        isNight ? const Color(0xFF33261B) : const Color(0xFF634328);
    final grass = isNight ? const Color(0xFF2B6148) : const Color(0xFF52B788);
    const flower = Color(0xFFFFB703);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(8, size.height - 16, size.width - 16, 12),
        const Radius.circular(6),
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.22),
    );

    final wallRect = Rect.fromLTWH(10, size.height - 28, size.width - 20, 16);
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        wallRect,
        bottomLeft: const Radius.circular(6),
        bottomRight: const Radius.circular(6),
      ),
      Paint()..color = woodSide,
    );

    final stakePaint =
        Paint()
          ..color = Colors.black.withValues(alpha: 0.25)
          ..strokeWidth = 1.4;
    for (var x = wallRect.left + 10; x < wallRect.right; x += 11) {
      canvas.drawLine(
        Offset(x, wallRect.top),
        Offset(x, wallRect.bottom),
        stakePaint,
      );
    }

    final topRect = Rect.fromLTWH(8, size.height - 46, size.width - 16, 22);
    canvas.drawRRect(
      RRect.fromRectAndRadius(topRect, const Radius.circular(7)),
      Paint()..color = soilTop,
    );

    for (var i = 0; i < 4; i++) {
      final px = topRect.left + 21 + i * 24;
      final py = topRect.center.dy;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(px, py), width: 16, height: 10),
        Paint()..color = grass,
      );
      if (i == 1 || i == 2) {
        canvas.drawCircle(Offset(px, py - 2), 3.4, Paint()..color = flower);
      }
    }

    _drawAhuejote(canvas, Offset(topRect.left + 8, topRect.top + 4), isNight);
    _drawAhuejote(canvas, Offset(topRect.right - 8, topRect.top + 4), isNight);
  }

  void _drawAhuejote(Canvas canvas, Offset base, bool isNight) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(base.dx - 2.2, base.dy - 14, 4.4, 15),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFF5C4033),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(base.dx, base.dy - 21),
        width: 16,
        height: 22,
      ),
      Paint()
        ..color = isNight ? const Color(0xFF23523C) : const Color(0xFF40916C),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is _ChinampaPainter &&
        oldDelegate.timePhase != timePhase;
  }
}

/// Xólotl estilizado (visible de noche o con reliquia).
class _XolotlWidget extends StatelessWidget {
  const _XolotlWidget({
    required this.timePhase,
    this.emotionOverride,
    this.reduceMotion = false,
  });

  final ValleyTimePhase timePhase;
  final PrehispanicEmotion? emotionOverride;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size(52, 48), painter: _XolotlPainter());
  }
}

class _XolotlPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bodyPaint = Paint()..color = const Color(0xFF2B2D42);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(12, 22, 22, 20),
        const Radius.circular(8),
      ),
      bodyPaint,
    );
    canvas.drawCircle(const Offset(28, 16), 9, bodyPaint);
    final leftEar =
        Path()
          ..moveTo(22, 11)
          ..lineTo(20, 2)
          ..lineTo(26, 8)
          ..close();
    final rightEar =
        Path()
          ..moveTo(30, 8)
          ..lineTo(35, 2)
          ..lineTo(35, 11)
          ..close();
    canvas.drawPath(leftEar, bodyPaint);
    canvas.drawPath(rightEar, bodyPaint);
    canvas.drawCircle(
      const Offset(31, 15),
      1.8,
      Paint()..color = AppColors.fuegoDorado,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Vasija de Tláloc (visible si tiene la reliquia de Tláloc).
class _VasijaTlalocWidget extends StatelessWidget {
  const _VasijaTlalocWidget({required this.timePhase, this.emotionOverride});

  final ValleyTimePhase timePhase;
  final PrehispanicEmotion? emotionOverride;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(44, 52),
      painter: _VasijaTlalocPainter(),
    );
  }
}

class _VasijaTlalocPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final clay = Paint()..color = const Color(0xFFC87D55);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, 32), width: 30, height: 28),
      clay,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, 15), width: 18, height: 10),
        const Radius.circular(3),
      ),
      clay,
    );
    final ring =
        Paint()
          ..color = AppColors.turquesa
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
    canvas.drawCircle(Offset(cx - 5, 29), 3.5, ring);
    canvas.drawCircle(Offset(cx + 5, 29), 3.5, ring);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
