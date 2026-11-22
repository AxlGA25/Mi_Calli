// HUD Superior del Valle (Layer 4) con microinteracciones y AnimatedSwitcher.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mi_calli/core/audio/ambient_audio_service.dart';
import 'package:mi_calli/core/constants/app_colors.dart';
import 'package:mi_calli/core/widgets/mi_calli_animations.dart';
import 'package:mi_calli/features/3_teotihuacan_valley/presentation/settings_screen.dart';
import 'package:mi_calli/features/3_teotihuacan_valley/presentation/widgets/altar_of_calm_modal.dart';

/// Capa del HUD superior con 3 botones flotantes con microinteracciones.
class ValleyTopHudLayer extends ConsumerWidget {
  const ValleyTopHudLayer({
    super.key,
    this.onOpenSettings,
    this.onOpenSanctuaryJournal,
    this.onOpenCodex,
  });

  final VoidCallback? onOpenSettings;
  final VoidCallback? onOpenSanctuaryJournal;
  final VoidCallback? onOpenCodex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMuted = ref.watch(ambientAudioIsMutedProvider);

    return IgnorePointer(
      ignoring: false,
      child: Stack(
        children: [
          // Botón 1: Audio Ambiental con AnimatedSwitcher
          Positioned(
            top: 16,
            left: 16,
            child: _HudButton(
              key: const ValueKey('valley_hud_audio_button'),
              semanticsLabel:
                  isMuted
                      ? 'Activar sonido ambiental'
                      : 'Silenciar sonido ambiental',
              onTap: () {
                HapticFeedback.selectionClick();
                ref.read(ambientAudioProvider.notifier).toggleMute();
              },
              backgroundColor: const Color(0xFF0E1720).withValues(alpha: 0.86),
              borderColor:
                  isMuted
                      ? AppColors.pergaminoClaro.withValues(alpha: 0.35)
                      : const Color(0xFF00D2B8).withValues(alpha: 0.85),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder:
                    (child, anim) => ScaleTransition(
                      scale: anim,
                      child: FadeTransition(opacity: anim, child: child),
                    ),
                child: Icon(
                  isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                  key: ValueKey<bool>(isMuted),
                  color:
                      isMuted
                          ? AppColors.pergaminoClaro.withValues(alpha: 0.7)
                          : const Color(0xFF7BF1E0),
                  size: 24,
                ),
              ),
            ),
          ),

          // Botón 2: Ajustes con transición suave MiCalliPageRoute
          Positioned(
            top: 16,
            right: 80,
            child: _HudButton(
              key: const ValueKey('valley_hud_settings_button'),
              semanticsLabel: 'Abrir ajustes y accesibilidad',
              onTap: () {
                HapticFeedback.selectionClick();
                if (onOpenSettings != null) {
                  onOpenSettings!();
                } else {
                  Navigator.of(context).push(
                    MiCalliPageRoute<void>(
                      builder: (_) => const SettingsScreen(),
                    ),
                  );
                }
              },
              backgroundColor: const Color(0xFF0E1720).withValues(alpha: 0.86),
              borderColor: AppColors.oro.withValues(alpha: 0.75),
              child: const Icon(
                Icons.settings_rounded,
                color: AppColors.pergaminoClaro,
                size: 24,
              ),
            ),
          ),

          // Botón 3: Altar de Calma / SOS (rojo grana vibrante con halo sutil)
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
              backgroundColor: const Color(0xFFD63E38),
              borderColor: const Color(0xFFFFD166),
              glowColor: const Color(0xFFE63946).withValues(alpha: 0.45),
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

class _HudButton extends StatelessWidget {
  const _HudButton({
    super.key,
    required this.semanticsLabel,
    required this.onTap,
    required this.backgroundColor,
    required this.borderColor,
    required this.child,
    this.glowColor,
  });

  final String semanticsLabel;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color borderColor;
  final Widget child;
  final Color? glowColor;

  @override
  Widget build(BuildContext context) {
    return BouncyTap(
      scaleDown: 0.90,
      child: Semantics(
        button: true,
        label: semanticsLabel,
        child: ExcludeSemantics(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(16),
                splashColor: borderColor.withValues(alpha: 0.28),
                highlightColor: borderColor.withValues(alpha: 0.14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor, width: 1.6),
                    boxShadow: [
                      BoxShadow(
                        color:
                            glowColor ??
                            AppColors.obsidiana.withValues(alpha: 0.38),
                        blurRadius: 14,
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
      ),
    );
  }
}
