// Provider y Notifier de Riverpod para AppSettingsService.
//
// Permite a la UI escuchar cambios en tiempo real (especialmente
// audio_enabled y reduce_motion) mediante AppSettingsState inmutable.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_settings_service.dart';

/// Provider del servicio de ajustes (para inyección en el Notifier).
final appSettingsServiceProvider = Provider<AppSettingsService>((ref) {
  throw UnimplementedError(
    'appSettingsServiceProvider debe ser sobrescrito en main.dart con '
    'ProviderScope(overrides: [appSettingsServiceProvider.overrideWithValue(service)])',
  );
});

/// Notifier que expone AppSettingsState y notifica cambios.
class AppSettingsNotifier extends Notifier<AppSettingsState> {
  late final AppSettingsService _service;

  @override
  AppSettingsState build() {
    _service = ref.read(appSettingsServiceProvider);
    return _service.currentState;
  }

  /// Actualiza el estado notificando a los listeners.
  void _updateState(AppSettingsState newState) {
    state = newState;
  }

  // ─── Métodos para modificar ajustes ───

  /// Marca el onboarding como completado.
  Future<void> setOnboardingDone(bool value) async {
    await _service.setOnboardingDone(value);
    _updateState(state.copyWith(onboardingDone: value));
  }

  /// Marca la confirmación de mayoría de edad.
  Future<void> setAdultConfirmed(bool value) async {
    await _service.setAdultConfirmed(value);
    _updateState(state.copyWith(adultConfirmed: value));
  }

  /// Activa/desactiva el audio ambiental.
  Future<void> setAudioEnabled(bool value) async {
    await _service.setAudioEnabled(value);
    _updateState(state.copyWith(audioEnabled: value));
  }

  /// Activa/desactiva reducir movimiento.
  Future<void> setReduceMotion(bool value) async {
    await _service.setReduceMotion(value);
    _updateState(state.copyWith(reduceMotion: value));
  }

  /// Activa/desactiva el recordatorio diario.
  Future<void> setReminderEnabled(bool value) async {
    await _service.setReminderEnabled(value);
    _updateState(state.copyWith(reminderEnabled: value));
  }

  /// Establece la hora del recordatorio (formato 'HH:mm').
  Future<void> setReminderTime(String? time) async {
    await _service.setReminderTime(time);
    if (time != null) {
      _updateState(state.copyWith(reminderTime: time));
    } else {
      _updateState(state.copyWith(clearReminderTime: true));
    }
  }

  /// Establece la fecha de la última lectura astral (formato 'YYYY-MM-DD').
  Future<void> setLastAstralReadingDate(String? date) async {
    await _service.setLastAstralReadingDate(date);
    if (date != null) {
      _updateState(state.copyWith(lastAstralReadingDate: date));
    } else {
      _updateState(state.copyWith(clearLastAstralReadingDate: true));
    }
  }

  /// Establece el nombre del contacto de confianza.
  Future<void> setTrustedContactName(String? name) async {
    await _service.setTrustedContactName(name);
    if (name != null) {
      _updateState(state.copyWith(trustedContactName: name));
    } else {
      _updateState(state.copyWith(clearTrustedContactName: true));
    }
  }

  /// Establece el teléfono del contacto de confianza.
  Future<void> setTrustedContactPhone(String? phone) async {
    await _service.setTrustedContactPhone(phone);
    if (phone != null) {
      _updateState(state.copyWith(trustedContactPhone: phone));
    } else {
      _updateState(state.copyWith(clearTrustedContactPhone: true));
    }
  }
}

/// Provider del estado de ajustes (AppSettingsState inmutable).
///
/// La UI puede escuchar cambios con:
///   final settings = ref.watch(appSettingsProvider);
///   final audioEnabled = ref.watch(appSettingsProvider.select((s) => s.audioEnabled));
final appSettingsProvider = NotifierProvider<AppSettingsNotifier, AppSettingsState>(
  AppSettingsNotifier.new,
);