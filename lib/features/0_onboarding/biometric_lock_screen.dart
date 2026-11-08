// Pantalla de bloqueo biométrico.
//
// Se muestra cuando la bóveda está bloqueada y pide autenticación.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mi_calli/core/constants/app_colors.dart';
import 'package:mi_calli/core/security/biometric_auth_interface.dart';
import 'package:mi_calli/core/security/biometric_vault_service.dart';
import 'package:mi_calli/core/security/support_network_modal.dart';

/// Pantalla que pide autenticación biométrica/PIN para desbloquear.
class BiometricLockScreen extends ConsumerStatefulWidget {
  final String? customReason;

  const BiometricLockScreen({
    super.key,
    this.customReason,
  });

  @override
  ConsumerState<BiometricLockScreen> createState() => _BiometricLockScreenState();
}

class _BiometricLockScreenState extends ConsumerState<BiometricLockScreen> {
  bool _isAuthenticating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _attemptUnlock();
  }

  Future<void> _attemptUnlock() async {
    if (_isAuthenticating) return;

    setState(() {
      _isAuthenticating = true;
      _errorMessage = null;
    });

    final service = ref.read(biometricVaultServiceProvider);
    final result = await service.requestUnlock(
      localizedReason: widget.customReason ??
          'Autentícate para acceder a tu diario y Chinampa',
    );

    if (!mounted) return;

    setState(() {
      _isAuthenticating = false;
    });

    if (result != BiometricAuthResult.success) {
      setState(() {
        switch (result) {
          case BiometricAuthResult.cancelled:
            _errorMessage = 'Autenticación cancelada. Intenta de nuevo.';
            break;
          case BiometricAuthResult.failed:
            _errorMessage = 'Autenticación fallida. Intenta de nuevo.';
            break;
          case BiometricAuthResult.notAvailable:
            _errorMessage = 'Tu dispositivo no tiene biometría ni PIN configurado.\nVe a Ajustes del dispositivo para configurarlo.';
            break;
          case BiometricAuthResult.error:
            _errorMessage = 'Error inesperado. Intenta de nuevo.';
            break;
          default:
            _errorMessage = 'No se pudo desbloquear. Intenta de nuevo.';
        }
      });
    }
    // Si success, el stateStream del servicio cambiará a unlocked y la UI principal reaccionará
  }

  @override
  Widget build(BuildContext context) {
    final vaultStateAsync = ref.watch(biometricVaultStateProvider);

    // Si ya está desbloqueado, no mostrar esta pantalla (la UI principal lo manejará)
    if (vaultStateAsync.value == BiometricVaultState.unlocked) {
      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: AppColors.pergaminoClaro,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icono de candado
              Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: _isAuthenticating
                        ? AppColors.oro.withValues(alpha: 0.1)
                        : AppColors.jade.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _isAuthenticating ? AppColors.oro : AppColors.jade,
                      width: 3,
                    ),
                  ),
                  child: _isAuthenticating
                      ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.oro),
                          strokeWidth: 3,
                        )
                      : Icon(
                          Icons.lock_outline,
                          size: 60,
                          color: AppColors.jade,
                        ),
                ),
              ),

              const SizedBox(height: 32),

              // Título
              Text(
                _isAuthenticating ? 'Autenticando...' : 'Refugio Quetzalcóatl',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: _isAuthenticating ? AppColors.oro : AppColors.obsidiana,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                _isAuthenticating
                    ? 'Verificando tu identidad...'
                    : 'Tu diario está protegido',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.obsidiana.withValues(alpha: 0.7),
                ),
              ),

              const SizedBox(height: 32),

              // Mensaje de error si hay
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.rojoGrana.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.rojoGrana.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.rojoGrana,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _attemptUnlock,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.rojoGrana,
                          side: BorderSide(color: AppColors.rojoGrana),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Botón desbloquear (si no está autenticando)
              if (!_isAuthenticating && _errorMessage == null) ...[
                FilledButton.icon(
                  onPressed: _attemptUnlock,
                  icon: const Icon(Icons.fingerprint, size: 24),
                  label: const Text('Desbloquear con Biometría / PIN'),
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

                Text(
                  'Usa tu huella, rostro o PIN/patrón del dispositivo',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.obsidiana.withValues(alpha: 0.5),
                  ),
                ),

                const SizedBox(height: 24),

                // Botón "Necesito apoyo" - abre modal de red de apoyo SIN autenticación
                OutlinedButton.icon(
                  onPressed: () => SupportNetworkModal.show(context),
                  icon: const Icon(Icons.favorite_outline, size: 22),
                  label: const Text('Necesito apoyo'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.oro,
                    side: BorderSide(color: AppColors.oro, width: 2),
                    minimumSize: const Size(double.infinity, 56),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Accede a tu red de apoyo sin desbloquear la app',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.obsidiana.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}