import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_colors.dart';
import 'core/performance/animation_cache_service.dart';
import 'core/security/biometric_vault_service.dart';
import 'core/settings/app_settings_service.dart';
import 'features/0_onboarding/onboarding_flow.dart';
import 'features/0_onboarding/biometric_lock_screen.dart';
import 'features/0_onboarding/main_app_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider que inicializa AppSettingsService y expone el estado de onboarding.
final onboardingStatusProvider = FutureProvider<({bool onboardingDone, bool adultConfirmed})>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final service = AppSettingsService.createForTesting(prefs);
  return (
    onboardingDone: service.onboardingDone,
    adultConfirmed: service.adultConfirmed,
  );
});

/// Provider para inicializar BiometricVaultService después de AppSettingsService.
final biometricVaultInitProvider = FutureProvider<void>((ref) async {
  await BiometricVaultService.initialize();
  // Iniciar autenticación inicial
  final service = BiometricVaultService.instance;
  await service.authenticateOnStart();
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar caché de animaciones (assets conocidos; lista vacía por ahora,
  // se poblará cuando existan assets reales en Fase 4)
  await AnimationCacheService().initialize([]);

  runApp(const ProviderScope(child: MiCalliApp()));
}

class MiCalliApp extends ConsumerWidget {
  const MiCalliApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Inicializar bóveda biométrica (side effect)
    ref.watch(biometricVaultInitProvider);

    return MaterialApp(
      title: 'Mi Calli',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.jade,
          brightness: Brightness.light,
        ),
        // Configuración global para reducir movimiento
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
            TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      home: const AppEntryPoint(),
    );
  }
}

/// Punto de entrada que decide qué pantalla mostrar según el estado.
class AppEntryPoint extends ConsumerWidget {
  const AppEntryPoint({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingAsync = ref.watch(onboardingStatusProvider);
    final vaultStateAsync = ref.watch(biometricVaultStateProvider);

    return onboardingAsync.when(
      data: (status) {
        final onboardingDone = status.onboardingDone;
        final adultConfirmed = status.adultConfirmed;

        // Si no se completó el onboarding, mostrarlo
        if (!onboardingDone) {
          return OnboardingFlow(onCompleted: () {
            ref.invalidate(onboardingStatusProvider);
          });
        }

        // Onboarding completado: verificar bóveda biométrica
        if (!adultConfirmed) {
          return OnboardingFlow(onCompleted: () {
            ref.invalidate(onboardingStatusProvider);
          });
        }

        // Onboarding OK: mostrar pantalla principal protegida por bóveda
        return ProtectedMainScreen(vaultStateAsync: vaultStateAsync);
      },
      loading: () => const _LoadingScreen(),
      error: (_, __) => const _ErrorScreen(),
    );
  }
}

/// Pantalla principal que maneja el estado de la bóveda biométrica.
class ProtectedMainScreen extends ConsumerWidget {
  final AsyncValue<BiometricVaultState> vaultStateAsync;

  const ProtectedMainScreen({super.key, required this.vaultStateAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vaultState = vaultStateAsync.value ?? BiometricVaultState.locked;

    // Si la bóveda está desbloqueada, mostrar app principal
    if (vaultState == BiometricVaultState.unlocked) {
      return const MainAppScreen();
    }

    // Si está bloqueada, autenticando, o error -> mostrar pantalla de desbloqueo
    return const BiometricLockScreen();
  }
}

/// Pantalla de carga inicial.
class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pergaminoClaro,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
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
            const SizedBox(height: 24),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.jade),
            ),
            const SizedBox(height: 16),
            Text(
              'Cargando Refugio Quetzalcóatl...',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.obsidiana.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pantalla de error.
class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pergaminoClaro,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppColors.rojoGrana),
              const SizedBox(height: 16),
              Text(
                'Error al iniciar la app',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.obsidiana,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Por favor, reinicia la aplicación.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.obsidiana.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}