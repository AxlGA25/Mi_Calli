// Pantalla bloqueante "Solo Adultos" para menores de 18 años.
//
// No permite avanzar al diario. Muestra números de apoyo.
// Usa textos de LegalTexts (underageTitle, underageBody, underageButtonLineaDeLaVida, underageButtonEmergencias).

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:mi_calli/core/constants/app_colors.dart';
import 'package:mi_calli/core/constants/legal_texts.dart';
import 'package:mi_calli/core/constants/sos_texts.dart';

/// Pantalla bloqueante para menores de 18 años.
class OnboardingMinorBlockScreen extends StatelessWidget {
  const OnboardingMinorBlockScreen({super.key});

  Future<void> _launchPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
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
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icono de bloqueo
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.rojoGrana.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.rojoGrana, width: 3),
                  ),
                  child: const Icon(
                    Icons.lock_outline,
                    size: 60,
                    color: AppColors.rojoGrana,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Título (usa underageTitle)
              Text(
                LegalTexts.underageTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.rojoGrana,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              // Texto informativo (usa underageBody)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.rojoGrana.withValues(alpha: 0.3), width: 1.5),
                ),
                child: Text(
                  LegalTexts.underageBody,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.obsidiana.withValues(alpha: 0.8),
                    height: 1.6,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Botones de emergencia/apoyo (usa underageButtonLineaDeLaVida, underageButtonEmergencias)
              Column(
                children: [
                  // Línea de la Vida
                  OutlinedButton.icon(
                    onPressed: () => _launchPhone(SosTexts.lineaDeLaVida.replaceAll(' ', '')),
                    icon: const Icon(Icons.phone, color: AppColors.jade),
                    label: Text(
                      LegalTexts.underageButtonLineaDeLaVida,
                      style: const TextStyle(color: AppColors.jade, fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.jade, width: 2),
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Emergencias 911
                  OutlinedButton.icon(
                    onPressed: () => _launchPhone('911'),
                    icon: const Icon(Icons.local_hospital, color: AppColors.rojoGrana),
                    label: Text(
                      LegalTexts.underageButtonEmergencias,
                      style: const TextStyle(color: AppColors.rojoGrana, fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.rojoGrana, width: 2),
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Mensaje final
              Text(
                'Cierra la app y busca apoyo.\nEstamos aquí para cuando seas mayor de edad.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.obsidiana.withValues(alpha: 0.6),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}