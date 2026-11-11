// Pantalla de configuración de Contacto de Confianza (opcional) en el Onboarding.
//
// Permite al usuario configurar nombre y teléfono de su contacto de confianza.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mi_calli/core/constants/app_colors.dart';
import 'package:mi_calli/core/constants/legal_texts.dart';
import 'package:mi_calli/core/settings/app_settings_provider.dart';

/// Pantalla opcional para configurar contacto de confianza.
class OnboardingTrustedContactScreen extends ConsumerStatefulWidget {
  final VoidCallback onContinue;
  final VoidCallback onSkip;

  const OnboardingTrustedContactScreen({
    super.key,
    required this.onContinue,
    required this.onSkip,
  });

  @override
  ConsumerState<OnboardingTrustedContactScreen> createState() =>
      _OnboardingTrustedContactScreenState();
}

class _OnboardingTrustedContactScreenState
    extends ConsumerState<OnboardingTrustedContactScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveAndContinue() async {
    if (!_formKey.currentState!.validate()) return;

    final contextRef = context; // Capture context before async gaps
    try {
      await ref.read(appSettingsProvider.notifier).setTrustedContactName(_nameController.text.trim());
      await ref.read(appSettingsProvider.notifier).setTrustedContactPhone(_phoneController.text.trim());
      if (contextRef.mounted) widget.onContinue();
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
                    color: AppColors.turquesa.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.turquesa, width: 2),
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    size: 50,
                    color: AppColors.turquesa,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Título
              Text(
                'Contacto de Confianza\n(opcional)',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.obsidiana,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
              ),

              const SizedBox(height: 16),

              // Descripción (usa LegalTexts.contactExplain)
              Text(
                LegalTexts.contactExplain,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.obsidiana.withValues(alpha: 0.7),
                      height: 1.5,
                    ),
              ),

              const SizedBox(height: 32),

              // Formulario
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Campo nombre
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Nombre',
                        hintText: 'Ej. María, Juan, Mamá...',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value != null && value.trim().isNotEmpty && value.trim().length < 2) {
                          return 'El nombre debe tener al menos 2 caracteres';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Campo teléfono
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Teléfono',
                        hintText: 'Ej. 5551234567',
                        prefixIcon: const Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value != null && value.trim().isNotEmpty) {
                          final digits = value.replaceAll(RegExp(r'\D'), '');
                          if (digits.length < 10) {
                            return 'Ingresa un teléfono válido (mín. 10 dígitos)';
                          }
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Botones
              Column(
                children: [
                  // Botón Continuar (guarda si hay datos)
                  FilledButton.icon(
                    onPressed: _saveAndContinue,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Guardar y Continuar'),
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

                  const SizedBox(height: 12),

                  // Botón Saltar
                  TextButton.icon(
                    onPressed: widget.onSkip,
                    icon: const Icon(Icons.skip_next_outlined),
                    label: const Text('Saltar este paso'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.obsidiana.withValues(alpha: 0.6),
                      minimumSize: const Size(double.infinity, 48),
                      textStyle: const TextStyle(fontSize: 16),
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