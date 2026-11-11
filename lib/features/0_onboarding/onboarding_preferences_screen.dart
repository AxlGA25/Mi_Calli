// Pantalla de preferencias iniciales (opcional) en el Onboarding.
//
// Permite configurar audio_enabled y reduce_motion (ambos apagados por defecto).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mi_calli/core/constants/app_colors.dart';
import 'package:mi_calli/core/settings/app_settings_provider.dart';

/// Pantalla opcional para configurar preferencias iniciales.
class OnboardingPreferencesScreen extends ConsumerStatefulWidget {
  final VoidCallback onComplete;

  const OnboardingPreferencesScreen({
    super.key,
    required this.onComplete,
  });

  @override
  ConsumerState<OnboardingPreferencesScreen> createState() =>
      _OnboardingPreferencesScreenState();
}

class _OnboardingPreferencesScreenState
    extends ConsumerState<OnboardingPreferencesScreen> {
  bool _audioEnabled = false;
  bool _reduceMotion = false;

  Future<void> _completeOnboarding() async {
    final contextRef = context; // Capture context before async gaps
    try {
      await ref.read(appSettingsProvider.notifier).setAudioEnabled(_audioEnabled);
      await ref.read(appSettingsProvider.notifier).setReduceMotion(_reduceMotion);
      // Marcar onboarding como completado
      await ref.read(appSettingsProvider.notifier).setOnboardingDone(true);
      if (contextRef.mounted) widget.onComplete();
    } catch (_) {
      if (contextRef.mounted) _showErrorSnackBar(contextRef);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pergaminoClaro,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),

              // Icono
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.oro.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.oro, width: 2),
                  ),
                  child: const Icon(
                    Icons.tune_outlined,
                    size: 50,
                    color: AppColors.oro,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Título
              Text(
                'Preferencias Iniciales\n(opcional)',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.obsidiana,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
              ),

              const SizedBox(height: 16),

              // Descripción
              Text(
                'Puedes ajustar esto ahora o después\nen la pantalla de Ajustes.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.obsidiana.withValues(alpha: 0.7),
                      height: 1.5,
                    ),
              ),

              const SizedBox(height: 40),

              // Opciones de preferencias
              Column(
                children: [
                  // Audio ambiental
                  _PreferenceTile(
                    icon: Icons.volume_up_outlined,
                    title: 'Audio Ambiental',
                    subtitle: 'Sonidos de naturaleza según clima y hora.\nInicia silenciado; se detiene en segundo plano.',
                    value: _audioEnabled,
                    onChanged: (value) {
                      setState(() => _audioEnabled = value);
                    },
                    iconColor: AppColors.jade,
                  ),

                  const SizedBox(height: 16),

                  // Reducir movimiento
                  _PreferenceTile(
                    icon: Icons.accessibility_new_outlined,
                    title: 'Reducir Movimiento',
                    subtitle: 'Desactiva animaciones y transiciones.\nRespeta también la configuración del sistema.',
                    value: _reduceMotion,
                    onChanged: (value) {
                      setState(() => _reduceMotion = value);
                    },
                    iconColor: AppColors.turquesa,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Botón Finalizar
              FilledButton.icon(
                onPressed: _completeOnboarding,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Finalizar y Entrar'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.jade,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'No pudimos guardar tu elección. Inténtalo de nuevo.',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.rojoGrana.withValues(alpha: 0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

/// Widget auxiliar para una preferencia con switch.
class _PreferenceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color iconColor;

  const _PreferenceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: iconColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.obsidiana.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.obsidiana,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.obsidiana.withValues(alpha: 0.6),
                          height: 1.4,
                        ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: iconColor,
              activeTrackColor: iconColor.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }
}