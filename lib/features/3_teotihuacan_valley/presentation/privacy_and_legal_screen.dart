// Pantalla de Privacidad y Legal (Tarea 4.6).
//
// Muestra los textos legales aprobados de LegalTexts en secciones
// navegables desde SettingsScreen.

import 'package:flutter/material.dart';
import 'package:mi_calli/core/constants/app_colors.dart';
import 'package:mi_calli/core/constants/legal_texts.dart';

/// Pantalla completa de Aviso y Privacidad.
class PrivacyAndLegalScreen extends StatelessWidget {
  const PrivacyAndLegalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('privacy_and_legal_screen'),
      backgroundColor: AppColors.obsidiana,
      appBar: AppBar(
        backgroundColor: AppColors.obsidiana,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.pergaminoClaro),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Aviso y Privacidad',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.oro,
                fontWeight: FontWeight.bold,
              ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              title: 'Descargo Médico',
              content:
                  'Mi Calli es una herramienta de reflexión personal y bienestar emocional. NO sustituye\n'
                  'atención psicológica, psiquiátrica ni médica profesional. Si estás en crisis,\n'
                  'contacta a la Línea de la Vida (800 911 2000) o al 911.',
              icon: Icons.medical_services_outlined,
            ),
            _buildSection(
              title: 'Solo Mayores de 18 Años',
              content:
                  'Esta app es exclusivamente para personas mayores de 18 años. Al confirmar tu mayoría\n'
                  'de edad, declaras tener 18 años o más.',
              icon: Icons.person_outline,
            ),
            _buildSection(
              title: 'Privacidad Absoluta',
              content:
                  'Tu diario NUNCA sale de tu teléfono. Se guarda cifrado localmente (SQLCipher AES-256).\n'
                  'El respaldo opcional en la nube SOLO sincroniza progreso numérico (XP, racha, nivel),\n'
                  'nunca el texto de tus entradas.',
              icon: Icons.lock_outline,
            ),
            _buildSection(
              title: 'Exportación Cifrada',
              content:
                  'Puedes exportar tu diario a un archivo .calli cifrado con tu contraseña (AES-256-GCM).\n'
                  'La contraseña NO se guarda. Si la olvidas, el archivo no se puede recuperar.',
              icon: Icons.download_outlined,
            ),
            _buildSection(
              title: 'Consentimiento de Datos Sensibles',
              content:
                  LegalTexts.consentBody,
              icon: Icons.verified_user_outlined,
            ),
            _buildSection(
              title: 'Red de Apoyo Dual',
              content:
                  LegalTexts.contactExplain,
              icon: Icons.people_outline,
            ),
            _buildSection(
              title: 'Recordatorio Diario',
              content:
                  LegalTexts.reminderExplain,
              icon: Icons.notifications_outlined,
            ),
            _buildSection(
              title: 'Política de Privacidad Completa (Web)',
              content:
                  'Para consultar la política de privacidad completa requerida por Google Play Store,\n'
                  'visita: ${LegalTexts.urlPoliticaPrivacidad}',
              icon: Icons.language_outlined,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String content,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.jade.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.jade, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.oro,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              color: AppColors.pergaminoClaro,
              height: 1.6,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}