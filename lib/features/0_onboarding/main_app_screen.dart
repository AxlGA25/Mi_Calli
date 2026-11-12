// Pantalla principal protegida (después de onboarding + bóveda biométrica).
//
// Aquí irá la navegación principal de la app (Valle, Diario, Códice, etc.).
// Renderiza directamente TeotihuacanValleyScreen (Tarea 4.3).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mi_calli/core/constants/app_colors.dart';
import 'package:mi_calli/core/security/biometric_vault_service.dart';
import 'package:mi_calli/core/settings/app_settings_provider.dart';
import 'package:mi_calli/features/3_teotihuacan_valley/presentation/teotihuacan_valley_screen.dart';

/// Pantalla principal de la app (protegida por bóveda biométrica).
class MainAppScreen extends ConsumerWidget {
  const MainAppScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vaultStateAsync = ref.watch(biometricVaultStateProvider);
    final vaultState = vaultStateAsync.value ?? BiometricVaultState.locked;
    ref.watch(appSettingsProvider); // Watch to trigger rebuild on settings change

    return Scaffold(
      backgroundColor: AppColors.pergaminoClaro,
      appBar: AppBar(
        title: const Text('Mi Calli'),
        backgroundColor: AppColors.jade,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Indicador de estado de la bóveda
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: vaultState == BiometricVaultState.unlocked
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      vaultState == BiometricVaultState.unlocked
                          ? Icons.lock_open
                          : Icons.lock,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      vaultState == BiometricVaultState.unlocked ? 'Desbloqueado' : 'Bloqueado',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: vaultState == BiometricVaultState.unlocked
            ? const TeotihuacanValleyScreen()
            : const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.jade),
                ),
              ),
      ),
    );
  }
}