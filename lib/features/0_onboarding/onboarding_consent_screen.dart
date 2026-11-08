// Pantalla de Consentimiento de Privacidad del Onboarding.
//
// Se muestra DESPUÉS de confirmar mayoría de edad (+18) y ANTES del contacto de confianza.
// Guarda privacy_consent_accepted = true para permitir avanzar.
// Un menor NUNCA llega a esta pantalla (se bloquea en adultConfirmation).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mi_calli/core/constants/app_colors.dart';
import 'package:mi_calli/core/constants/legal_texts.dart';
import 'package:mi_calli/core/settings/app_settings_provider.dart';

/// Pantalla de consentimiento para guardar entradas cifradas en el teléfono.
class OnboardingConsentScreen extends ConsumerStatefulWidget {
  final VoidCallback onContinue;
  final VoidCallback onDecline;

  const OnboardingConsentScreen({
    super.key,
    required this.onContinue,
    required this.onDecline,
  });

  @override
  ConsumerState<OnboardingConsentScreen> createState() =>
      _OnboardingConsentScreenState();
}

class _OnboardingConsentScreenState extends ConsumerState<OnboardingConsentScreen> {
  bool _accepted = false;

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

              // Icono de privacidad
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.jade.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.jade, width: 2),
                  ),
                  child: const Icon(
                    Icons.privacy_tip_outlined,
                    size: 50,
                    color: AppColors.jade,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Título
              Text(
                LegalTexts.consentTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.obsidiana,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
              ),

              const SizedBox(height: 16),

              // Texto explicativo
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.jade.withValues(alpha: 0.3)),
                ),
                child: Text(
                  LegalTexts.consentBody,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.obsidiana.withValues(alpha: 0.8),
                        height: 1.5,
                      ),
                ),
              ),

              const SizedBox(height: 24),

              // Casilla de aceptación
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _accepted ? AppColors.jade.withValues(alpha: 0.1) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _accepted ? AppColors.jade : AppColors.oro.withValues(alpha: 0.3),
                    width: _accepted ? 2 : 1.5,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _accepted,
                      onChanged: (value) {
                        setState(() => _accepted = value ?? false);
                      },
                      activeColor: AppColors.jade,
                      checkColor: Colors.white,
                      side: BorderSide(
                        color: _accepted ? AppColors.jade : AppColors.obsidiana.withValues(alpha: 0.4),
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          LegalTexts.consentCheck,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.obsidiana,
                                height: 1.4,
                              ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Botón Continuar (habilitado solo si aceptó)
              FilledButton.icon(
                onPressed: _accepted
                    ? () async {
                        await ref
                            .read(appSettingsProvider.notifier)
                            .setPrivacyConsentAccepted(true);
                        widget.onContinue();
                      }
                    : null,
                icon: const Icon(Icons.check_circle_outline, size: 22),
                label: Text(LegalTexts.consentContinue),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.jade,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.obsidiana.withValues(alpha: 0.2),
                  disabledForegroundColor: AppColors.obsidiana.withValues(alpha: 0.4),
                  minimumSize: const Size(double.infinity, 52),
                  textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Botón "Ahora no"
              OutlinedButton.icon(
                onPressed: () {
                  // Mostrar diálogo de confirmación con el texto de consentDeclineBody
                  showDialog<void>(
                    context: context,
                    barrierDismissible: false,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: AppColors.pergaminoClaro,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      title: Text(
                        '¿Seguro?',
                        style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                              color: AppColors.obsidiana,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      content: Text(
                        LegalTexts.consentDeclineBody,
                        style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                              color: AppColors.obsidiana.withValues(alpha: 0.8),
                              height: 1.5,
                            ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: Text(
                            'Volver',
                            style: TextStyle(color: AppColors.jade),
                          ),
                        ),
                        FilledButton(
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            widget.onDecline();
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.rojoGrana,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(LegalTexts.consentDecline),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.hourglass_empty_outlined, size: 22),
                label: Text(LegalTexts.consentDecline),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.oro,
                  side: BorderSide(color: AppColors.oro, width: 2),
                  minimumSize: const Size(double.infinity, 52),
                  textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
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
}