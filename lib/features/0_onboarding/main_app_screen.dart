// Pantalla principal protegida (después de onboarding + bóveda biométrica).
//
// Aquí irá la navegación principal de la app (Valle, Diario, Códice, etc.).
// Por ahora es un placeholder que muestra que el flujo funciona.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mi_calli/core/constants/app_colors.dart';
import 'package:mi_calli/core/security/biometric_vault_service.dart';
import 'package:mi_calli/core/settings/app_settings_provider.dart';
import 'package:mi_calli/core/settings/app_settings_service.dart';

/// Pantalla principal de la app (protegida por bóveda biométrica).
class MainAppScreen extends ConsumerWidget {
  const MainAppScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vaultStateAsync = ref.watch(biometricVaultStateProvider);
    final vaultState = vaultStateAsync.value ?? BiometricVaultState.locked;
    final settings = ref.watch(appSettingsProvider);

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
            ? _buildMainContent(context, ref, settings)
            : const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.jade),
                ),
              ),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, WidgetRef ref, AppSettingsState settings) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),

          // Bienvenida
          Text(
            'Bienvenido a tu Refugio',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppColors.obsidiana,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Tu diario íntimo y espacio de bienestar\nestán listos y protegidos.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.obsidiana.withValues(alpha: 0.7),
            ),
          ),

          const SizedBox(height: 32),

          // Tarjetas de navegación principal (placeholder)
          _NavCard(
            icon: Icons.menu_book_outlined,
            title: 'Diario & Santuario',
            subtitle: 'Escribe tu entrada diaria, elige tu clima emocional',
            color: AppColors.jade,
            onTap: () {},
          ),

          const SizedBox(height: 16),

          _NavCard(
            icon: Icons.landscape_outlined,
            title: 'Valle de Teotihuacán',
            subtitle: 'Ciclo día/noche, Chinampa, Fuego Sagrado',
            color: AppColors.turquesa,
            onTap: () {},
          ),

          const SizedBox(height: 16),

          _NavCard(
            icon: Icons.auto_stories_outlined,
            title: 'Códice & Tonalpohualli',
            subtitle: 'Lecturas astrales semanales, calendario agrícola',
            color: AppColors.oro,
            onTap: () {},
          ),

          const SizedBox(height: 16),

          _NavCard(
            icon: Icons.spa_outlined,
            title: 'Altar de la Calma',
            subtitle: 'Respiración 4-4-6, apoyo háptico, red de apoyo',
            color: AppColors.rosaSuave,
            onTap: () {},
          ),

          const SizedBox(height: 32),

          // Estado de ajustes actuales
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.oro.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estado Actual',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.obsidiana,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _StatusRow(
                  label: 'Audio Ambiental',
                  value: settings.audioEnabled ? 'Activado' : 'Desactivado',
                  icon: Icons.volume_up,
                ),
                const SizedBox(height: 12),
                _StatusRow(
                  label: 'Reducir Movimiento',
                  value: settings.reduceMotion ? 'Activado' : 'Desactivado',
                  icon: Icons.accessibility_new,
                ),
                const SizedBox(height: 12),
                _StatusRow(
                  label: 'Contacto de Confianza',
                  value: settings.trustedContactName != null
                      ? '${settings.trustedContactName} (${settings.trustedContactPhone})'
                      : 'No configurado',
                  icon: Icons.person,
                ),
                const SizedBox(height: 12),
                _StatusRow(
                  label: 'Recordatorio Diario',
                  value: settings.reminderEnabled ? 'Activado' : 'Desactivado',
                  icon: Icons.notifications,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Botón para bloquear manualmente (para testing)
          OutlinedButton.icon(
            onPressed: () {
              ref.read(biometricVaultServiceProvider).lock();
            },
            icon: const Icon(Icons.lock_outline),
            label: const Text('Bloquear App (Test)'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.obsidiana.withValues(alpha: 0.7),
              side: BorderSide(color: AppColors.obsidiana.withValues(alpha: 0.3)),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta de navegación auxiliar.
class _NavCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _NavCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
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
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.obsidiana.withValues(alpha: 0.4)),
          ],
        ),
      ),
    );
  }
}

/// Fila de estado auxiliar.
class _StatusRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatusRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.obsidiana.withValues(alpha: 0.5)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.obsidiana.withValues(alpha: 0.8),
            ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.obsidiana,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}