import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/constants/app_colors.dart';
import 'core/database/local_database_service.dart';
import 'core/performance/animation_cache_service.dart';
import 'core/security/biometric_vault_service.dart';
import 'core/security/safety_guard_provider.dart';
import 'core/settings/app_settings_service.dart';
import 'core/settings/app_settings_provider.dart';
import 'features/0_onboarding/onboarding_flow.dart';
import 'features/0_onboarding/biometric_lock_screen.dart';
import 'features/1_sanctuary_journal/presentation/sanctuary_journal_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider que inicializa AppSettingsService y expone el estado de onboarding.
/// Usa el servicio inyectado a través de appSettingsServiceProvider.
final onboardingStatusProvider = FutureProvider<({bool onboardingDone, bool adultConfirmed})>((ref) async {
  final service = ref.watch(appSettingsServiceProvider);
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

/// Excepción para errores de inicialización de base de datos.
class DatabaseInitializationException implements Exception {
  final String message;
  const DatabaseInitializationException(this.message);
  @override
  String toString() => 'DatabaseInitializationException: $message';
}

/// Función de arranque (bootstrap) que inicializa todo y devuelve el contenedor
/// ya configurado. Extraída para poder probarse.
///
/// Parámetros opcionales para testing:
/// - [customBiometricVaultInit]: si se proporciona, se usa en lugar de biometricVaultInitProvider
///   para evitar inicializar local_auth real en tests.
/// - [customSafetyGuardInit]: si se proporciona, se usa para inicializar SafetyGuardService.
/// - [customDatabaseInit]: si se proporciona, se usa para inicializar la base de datos local
///   (evita SQLCipher/flutter_secure_storage real en tests).
/// - [preloadProviders]: si false, no precarga onboardingStatusProvider ni biometricVaultInitProvider
///   (útil en tests donde se usa un contenedor hijo que volvería a evaluar los providers).
Future<ProviderContainer> bootstrap({
  Future<void> Function(ProviderContainer)? customBiometricVaultInit,
  Future<void> Function(ProviderContainer)? customSafetyGuardInit,
  Future<void> Function()? customDatabaseInit,
  bool preloadProviders = true,
}) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar datos de locale para formateo de fechas (es_MX)
  await initializeDateFormatting('es_MX', null);

  // 1. Inicializar SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // 2. Crear la única instancia de AppSettingsService
  final settingsService = AppSettingsService.createForTesting(prefs);

  // 3. Inicializar base de datos local cifrada (singleton) - CON MANEJO DE ERRORES
  try {
    if (customDatabaseInit != null) {
      await customDatabaseInit();
    } else {
      await LocalDatabaseService.initializeProduction();
    }
  } catch (e) {
    // Si falla la inicialización de la base de datos, lanzar excepción personalizada
    // para que main() pueda mostrar una pantalla de error amable
    throw DatabaseInitializationException('No se pudo inicializar la base de datos: $e');
  }

  // 4. Inicializar caché de animaciones (assets conocidos; lista vacía por ahora,
  // se poblará cuando existan assets reales en Fase 4)
  await AnimationCacheService().initialize([]);

  // 4.5 Inicializar SafetyGuardService (detector de crisis) antes de runApp.
  // Si falla, el provider usa fallbackPatterns y NO rompe el arranque.
  final safetyContainer = ProviderContainer();
  if (customSafetyGuardInit != null) {
    await customSafetyGuardInit(safetyContainer);
  } else {
    await safetyContainer.read(safetyGuardServiceProvider.future);
  }
  safetyContainer.dispose();

  // 5. Crear el ProviderContainer principal con TODOS los overrides necesarios
  final container = ProviderContainer(
    overrides: [
      appSettingsServiceProvider.overrideWithValue(settingsService),
    ],
  );

  // 6. Precargar providers (opcional, por defecto true para producción)
  if (preloadProviders) {
    // Precargar el estado de onboarding (inicializa el provider)
    await container.read(onboardingStatusProvider.future);

    // Precargar la inicialización de la bóveda biométrica
    if (customBiometricVaultInit != null) {
      await customBiometricVaultInit(container);
    } else {
      await container.read(biometricVaultInitProvider.future);
    }
  }

  return container;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  ProviderContainer? container;
  try {
    container = await bootstrap();
  } on DatabaseInitializationException {
    // Si falla la inicialización de la base de datos, mostrar pantalla de error
    runApp(const _DatabaseErrorApp());
    return;
  } catch (e) {
    // Otros errores inesperados - también mostrar pantalla de error genérica
    runApp(const _DatabaseErrorApp());
    return;
  }

  runApp(UncontrolledProviderScope(container: container, child: const MiCalliApp()));
}

/// App que muestra solo la pantalla de error de base de datos.
class _DatabaseErrorApp extends StatelessWidget {
  const _DatabaseErrorApp();

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
      home: const _DatabaseErrorScreen(),
    );
  }
}

/// Pantalla de error cuando no se puede abrir la base de datos.
class _DatabaseErrorScreen extends StatelessWidget {
  const _DatabaseErrorScreen();

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
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.rojoGrana,
              ),
              const SizedBox(height: 16),
              Text(
                'No pudimos abrir tu diario',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.obsidiana,
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Cierra la app e inténtalo de nuevo.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.obsidiana.withValues(alpha: 0.7),
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  // Reiniciar la app forzando un nuevo bootstrap
                  main();
                },
                icon: const Icon(Icons.refresh, size: 22),
                label: const Text(
                  'Reintentar',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.jade,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
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

        // Onboarding completado pero sin confirmar mayoría de edad
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
/// Después del onboarding (y del candado de la app), muestra directamente SanctuaryJournalScreen.
class ProtectedMainScreen extends ConsumerWidget {
  final AsyncValue<BiometricVaultState> vaultStateAsync;

  const ProtectedMainScreen({super.key, required this.vaultStateAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vaultState = vaultStateAsync.value ?? BiometricVaultState.locked;

    // Si la bóveda está desbloqueada, mostrar el diario directamente (SantuaryJournalScreen)
    if (vaultState == BiometricVaultState.unlocked) {
      return const SanctuaryJournalScreen();
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