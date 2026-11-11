// Pantalla de Confirmación de Mayoría de Edad (+18) del Onboarding.
//
// Si el usuario indica que es menor de 18, muestra la pantalla "Solo Adultos".
// Usa textos de LegalTexts (ageGateTitle, ageGateBody, ageGateConfirm, ageGateDecline).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mi_calli/core/constants/app_colors.dart';
import 'package:mi_calli/core/constants/legal_texts.dart';
import 'package:mi_calli/core/settings/app_settings_provider.dart';

/// Pantalla de confirmación de mayoría de edad.
class OnboardingAdultConfirmationScreen extends ConsumerWidget {
  final VoidCallback onConfirmAdult;
  final VoidCallback onNotAdult;

  const OnboardingAdultConfirmationScreen({
    super.key,
    required this.onConfirmAdult,
    required this.onNotAdult,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.pergaminoClaro,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),

              // Icono de advertencia
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.rojoGrana.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.rojoGrana, width: 2),
                  ),
                  child: const Icon(
                    Icons.shield_outlined,
                    size: 40,
                    color: AppColors.rojoGrana,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Título (usa ageGateTitle)
              Text(
                LegalTexts.ageGateTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.obsidiana,
                      fontWeight: FontWeight.bold,
                    ),
              ),

              const SizedBox(height: 16),

              // Texto de confirmación (usa ageGateBody)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.oro.withValues(alpha: 0.3)),
                ),
                child: Text(
                  LegalTexts.ageGateBody,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.obsidiana.withValues(alpha: 0.8),
                        height: 1.5,
                      ),
                ),
              ),

              const SizedBox(height: 24),

              // Botones Sí/No
              Column(
                children: [
                  // Botón "Sí, tengo 18+" (usa ageGateConfirm)
                  FilledButton.icon(
                    onPressed: () async {
                      try {
                        await ref.read(appSettingsProvider.notifier).setAdultConfirmed(true);
                        if (context.mounted) onConfirmAdult();
                      } catch (_) {
                        if (context.mounted) {
                          _showErrorSnackBar(context);
                        }
                      }
                    },
                    icon: const Icon(Icons.check_circle_outline, size: 22),
                    label: Text(LegalTexts.ageGateConfirm),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.jade,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 52),
                      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Botón "No, soy menor de 18" (usa ageGateDecline)
                  OutlinedButton.icon(
                    onPressed: onNotAdult,
                    icon: const Icon(Icons.cancel_outlined, size: 22),
                    label: Text(LegalTexts.ageGateDecline),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.rojoGrana,
                      side: BorderSide(color: AppColors.rojoGrana, width: 2),
                      minimumSize: const Size(double.infinity, 52),
                      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
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