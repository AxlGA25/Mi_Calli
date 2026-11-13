// HUD Superior Minimalista del Valle (Layer 4 — Tarea 4.3).
//
// Tres botones semitransparentes flotantes:
// - Esquina superior izquierda: Audio Ambiental
// - Esquina superior derecha (izquierda): Ajustes / Accesibilidad
// - Esquina superior derecha (derecha): Caracol SOS (rojo grana)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mi_calli/core/audio/ambient_audio_service.dart';
import 'package:mi_calli/core/constants/app_colors.dart';
import 'package:mi_calli/features/3_teotihuacan_valley/presentation/widgets/altar_of_calm_modal.dart';
import 'package:mi_calli/features/3_teotihuacan_valley/presentation/settings_screen.dart';

/// Capa del HUD superior con 3 botones flotantes.
class ValleyTopHudLayer extends ConsumerWidget {
  const ValleyTopHudLayer({
    super.key,
    this.onOpenSettings,
    this.onOpenSanctuaryJournal,
    this.onOpenCodex,
  });

  /// Callback para abrir ajustes (inyectado desde TeotihuacanValleyScreen).
  /// Si es null, navega directamente a SettingsScreen.
  final VoidCallback? onOpenSettings;

  /// Callback para abrir el Santuario del Diario (Quetzalcóatl).
  final VoidCallback? onOpenSanctuaryJournal;

  /// Callback para abrir el Códice/Historial (Templo de los Códices).
  final VoidCallback? onOpenCodex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMuted = ref.watch(ambientAudioIsMutedProvider);

    return IgnorePointer(
      // El IgnorePointer permite que los botones reciban taps pero no bloquee el resto
      ignoring: false,
      child: Stack(
        children: [
          // Botón 1: Audio Ambiental (Esquina Superior Izquierda)
          Positioned(
            top: 16,
            left: 16,
            child: _HudButton(
              key: const ValueKey('valley_hud_audio_button'),
              semanticsLabel: isMuted ? 'Activar sonido ambiental' : 'Silenciar sonido ambiental',
              onTap: () {
                HapticFeedback.selectionClick();
                ref.read(ambientAudioProvider.notifier).toggleMute();
              },
              backgroundColor: AppColors.obsidiana.withValues(alpha: 0.7),
              borderColor: AppColors.jade.withValues(alpha: 0.5),
              child: Icon(
                isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                color: AppColors.pergaminoClaro,
                size: 24,
              ),
            ),
          ),

          // Botón 2: Ajustes / Accesibilidad (Esquina Superior Derecha - Izquierda)
          Positioned(
            top: 16,
            right: 80, // 48 + 16 + 16 = 80 desde la derecha (espacio para botón SOS)
            child: _HudButton(
              key: const ValueKey('valley_hud_settings_button'),
              semanticsLabel: 'Abrir ajustes y accesibilidad',
              onTap: () {
                HapticFeedback.selectionClick();
                if (onOpenSettings != null) {
                  onOpenSettings!();
                } else {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
                  );
                }
              },
              backgroundColor: AppColors.obsidiana.withValues(alpha: 0.7),
              borderColor: AppColors.jade.withValues(alpha: 0.5),
              child: const Icon(
                Icons.settings_rounded,
                color: AppColors.pergaminoClaro,
                size: 24,
              ),
            ),
          ),

          // Botón 3: Caracol SOS (Esquina Superior Derecha - Derecha, color terracota)
          Positioned(
            top: 16,
            right: 16,
            child: _HudButton(
              key: const ValueKey('valley_hud_sos_button'),
              semanticsLabel: 'Altar de Calma: respiración y red de apoyo',
              onTap: () {
                HapticFeedback.mediumImpact();
                AltarOfCalmModal.show(context);
              },
              backgroundColor: AppColors.rojoGrana.withValues(alpha: 0.85),
              borderColor: AppColors.oro.withValues(alpha: 0.5),
              child: const Icon(
                Icons.favorite_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Botón del HUD con área táctil mínima 48x48, Semantics y estilo consistente.
class _HudButton extends StatelessWidget {
  const _HudButton({
    super.key,
    required this.semanticsLabel,
    required this.onTap,
    required this.backgroundColor,
    required this.borderColor,
    required this.child,
  });

  final String semanticsLabel;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color borderColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: ExcludeSemantics(
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(14),
              splashColor: borderColor.withValues(alpha: 0.2),
              highlightColor: borderColor.withValues(alpha: 0.1),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.obsidiana.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}