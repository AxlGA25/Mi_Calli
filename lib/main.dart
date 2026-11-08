import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_colors.dart';
import 'core/constants/sos_texts.dart';
import 'core/constants/legal_texts.dart';

void main() {
  runApp(const ProviderScope(child: MiCalliApp()));
}

class MiCalliApp extends StatelessWidget {
  const MiCalliApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mi Calli',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.jade,
          brightness: Brightness.light,
        ),
      ),
      home: const ConstantsDemoScreen(),
    );
  }
}

/// Pantalla de prueba que lee un color y un texto desde las constantes.
class ConstantsDemoScreen extends StatelessWidget {
  const ConstantsDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Calli - Prueba de Constantes'),
        backgroundColor: AppColors.jade,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Demo: Color desde AppColors
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.jade,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.jade.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'Jade\n#2A9D8F',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Demo: Texto desde SosTexts
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.turquesa.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.turquesa),
                ),
                child: Column(
                  children: [
                    Text(
                      'Mensaje SOS (desde SosTexts):',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.obsidiana,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      SosTexts.mensajePersonaConfianza,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.obsidiana.withValues(alpha: 0.8),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Línea de la Vida: ${SosTexts.lineaDeLaVida}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.rojoGrana,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Demo: Texto desde LegalTexts (placeholder)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.oro.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.oro),
                ),
                child: Column(
                  children: [
                    Text(
                      'Aviso legal (desde LegalTexts):',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.obsidiana,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      LegalTexts.avisoPrincipal.split('\n').firstWhere(
                        (line) => line.trim().isNotEmpty,
                        orElse: () => '[AVISO LEGAL]',
                      ),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.obsidiana.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}