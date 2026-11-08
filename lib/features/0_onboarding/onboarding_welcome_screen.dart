// Pantalla de Bienvenida y Aviso Legal del Onboarding.
//
// Muestra el aviso principal (no sustituye ayuda profesional, +18 años).
// Usa textos de LegalTexts (welcomeTitle, welcomeBody, avisoPrincipal legacy).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mi_calli/core/constants/app_colors.dart';
import 'package:mi_calli/core/constants/legal_texts.dart';

/// Pantalla de bienvenida con aviso legal.
class OnboardingWelcomeScreen extends ConsumerWidget {
  final VoidCallback onContinue;

  const OnboardingWelcomeScreen({
    super.key,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.pergaminoClaro,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),

              // Icono/Logo
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
                    Icons.psychology_alt,
                    size: 50,
                    color: AppColors.jade,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Título (usa welcomeTitle)
              Text(
                LegalTexts.welcomeTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.obsidiana,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),

              const SizedBox(height: 16),

              // Subtítulo (usa welcomeBody)
              Text(
                LegalTexts.welcomeBody,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.obsidiana.withValues(alpha: 0.7),
                ),
              ),

              const SizedBox(height: 40),

              // Aviso Legal (A4 - con scroll si es largo)
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.oro.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.oro, width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.gavel,
                              color: AppColors.oro,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                LegalTexts.disclaimerTitle,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: AppColors.obsidiana,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          LegalTexts.disclaimerBody,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.obsidiana.withValues(alpha: 0.8),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Botón continuar
              FilledButton.icon(
                onPressed: onContinue,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Continuar'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.jade,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
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
}