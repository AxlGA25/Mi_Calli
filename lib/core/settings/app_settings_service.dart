// Servicio de ajustes locales usando shared_preferences.
//
// Maneja las 9 claves exactas definidas en CONTEXT.md sección 5C:
// 1. onboarding_done (bool, default false)
// 2. adult_confirmed (bool, default false)
// 3. audio_enabled (bool, default false)
// 4. reduce_motion (bool, default false)
// 5. reminder_enabled (bool, default false)
// 6. reminder_time (String?, formato 'HH:mm', default null o '20:00')
// 7. last_astral_reading_date (String?, formato 'YYYY-MM-DD', default null)
// 8. trusted_contact_name (String?, default null)
// 9. trusted_contact_phone (String?, default null)

import 'package:shared_preferences/shared_preferences.dart';

/// Claves para los ajustes en shared_preferences.
class _SettingsKeys {
  static const String onboardingDone = 'onboarding_done';
  static const String adultConfirmed = 'adult_confirmed';
  static const String audioEnabled = 'audio_enabled';
  static const String reduceMotion = 'reduce_motion';
  static const String reminderEnabled = 'reminder_enabled';
  static const String reminderTime = 'reminder_time';
  static const String lastAstralReadingDate = 'last_astral_reading_date';
  static const String trustedContactName = 'trusted_contact_name';
  static const String trustedContactPhone = 'trusted_contact_phone';
}

/// Modelo inmutable para el estado de los ajustes.
///
/// Proporciona copyWith para actualizaciones inmutables.
class AppSettingsState {
  const AppSettingsState({
    required this.onboardingDone,
    required this.adultConfirmed,
    required this.audioEnabled,
    required this.reduceMotion,
    required this.reminderEnabled,
    this.reminderTime,
    this.lastAstralReadingDate,
    this.trustedContactName,
    this.trustedContactPhone,
  });

  /// Crea un estado con los valores por defecto.
  const AppSettingsState.defaults()
    : onboardingDone = false,
      adultConfirmed = false,
      audioEnabled = false,
      reduceMotion = false,
      reminderEnabled = false,
      reminderTime = null,
      lastAstralReadingDate = null,
      trustedContactName = null,
      trustedContactPhone = null;

  /// Crea un estado desde SharedPreferences.
  factory AppSettingsState.fromPrefs(SharedPreferences prefs) {
    return AppSettingsState(
      onboardingDone: prefs.getBool(_SettingsKeys.onboardingDone) ?? false,
      adultConfirmed: prefs.getBool(_SettingsKeys.adultConfirmed) ?? false,
      audioEnabled: prefs.getBool(_SettingsKeys.audioEnabled) ?? false,
      reduceMotion: prefs.getBool(_SettingsKeys.reduceMotion) ?? false,
      reminderEnabled: prefs.getBool(_SettingsKeys.reminderEnabled) ?? false,
      reminderTime: prefs.getString(_SettingsKeys.reminderTime),
      lastAstralReadingDate: prefs.getString(_SettingsKeys.lastAstralReadingDate),
      trustedContactName: prefs.getString(_SettingsKeys.trustedContactName),
      trustedContactPhone: prefs.getString(_SettingsKeys.trustedContactPhone),
    );
  }

  final bool onboardingDone;
  final bool adultConfirmed;
  final bool audioEnabled;
  final bool reduceMotion;
  final bool reminderEnabled;
  final String? reminderTime;
  final String? lastAstralReadingDate;
  final String? trustedContactName;
  final String? trustedContactPhone;

  /// Crea una copia con los valores modificados.
  AppSettingsState copyWith({
    bool? onboardingDone,
    bool? adultConfirmed,
    bool? audioEnabled,
    bool? reduceMotion,
    bool? reminderEnabled,
    String? reminderTime,
    String? lastAstralReadingDate,
    String? trustedContactName,
    String? trustedContactPhone,
    // Para permitir limpiar valores opcionales (pasar null explícitamente)
    bool clearReminderTime = false,
    bool clearLastAstralReadingDate = false,
    bool clearTrustedContactName = false,
    bool clearTrustedContactPhone = false,
  }) {
    return AppSettingsState(
      onboardingDone: onboardingDone ?? this.onboardingDone,
      adultConfirmed: adultConfirmed ?? this.adultConfirmed,
      audioEnabled: audioEnabled ?? this.audioEnabled,
      reduceMotion: reduceMotion ?? this.reduceMotion,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderTime: clearReminderTime ? null : (reminderTime ?? this.reminderTime),
      lastAstralReadingDate: clearLastAstralReadingDate ? null : (lastAstralReadingDate ?? this.lastAstralReadingDate),
      trustedContactName: clearTrustedContactName ? null : (trustedContactName ?? this.trustedContactName),
      trustedContactPhone: clearTrustedContactPhone ? null : (trustedContactPhone ?? this.trustedContactPhone),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppSettingsState &&
      other.onboardingDone == onboardingDone &&
      other.adultConfirmed == adultConfirmed &&
      other.audioEnabled == audioEnabled &&
      other.reduceMotion == reduceMotion &&
      other.reminderEnabled == reminderEnabled &&
      other.reminderTime == reminderTime &&
      other.lastAstralReadingDate == lastAstralReadingDate &&
      other.trustedContactName == trustedContactName &&
      other.trustedContactPhone == trustedContactPhone;
  }

  @override
  int get hashCode => Object.hash(
    onboardingDone,
    adultConfirmed,
    audioEnabled,
    reduceMotion,
    reminderEnabled,
    reminderTime,
    lastAstralReadingDate,
    trustedContactName,
    trustedContactPhone,
  );

  @override
  String toString() {
    return 'AppSettingsState('
      'onboardingDone: $onboardingDone, '
      'adultConfirmed: $adultConfirmed, '
      'audioEnabled: $audioEnabled, '
      'reduceMotion: $reduceMotion, '
      'reminderEnabled: $reminderEnabled, '
      'reminderTime: $reminderTime, '
      'lastAstralReadingDate: $lastAstralReadingDate, '
      'trustedContactName: $trustedContactName, '
      'trustedContactPhone: $trustedContactPhone'
    ')';
  }
}

/// Servicio para gestionar los ajustes locales persistentes.
class AppSettingsService {
  AppSettingsService._(this._prefs);

  final SharedPreferences _prefs;

  /// Crea una instancia del servicio.
  static Future<AppSettingsService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettingsService._(prefs);
  }

  /// Crea una instancia para testing con SharedPreferences mockeado.
  static AppSettingsService createForTesting(SharedPreferences prefs) {
    return AppSettingsService._(prefs);
  }

  /// Obtiene el estado actual de todos los ajustes.
  AppSettingsState get currentState => AppSettingsState.fromPrefs(_prefs);

  /// Guarda el estado completo (para inicialización o migración).
  Future<void> saveState(AppSettingsState state) async {
    await _prefs.setBool(_SettingsKeys.onboardingDone, state.onboardingDone);
    await _prefs.setBool(_SettingsKeys.adultConfirmed, state.adultConfirmed);
    await _prefs.setBool(_SettingsKeys.audioEnabled, state.audioEnabled);
    await _prefs.setBool(_SettingsKeys.reduceMotion, state.reduceMotion);
    await _prefs.setBool(_SettingsKeys.reminderEnabled, state.reminderEnabled);

    if (state.reminderTime != null) {
      await _prefs.setString(_SettingsKeys.reminderTime, state.reminderTime!);
    } else {
      await _prefs.remove(_SettingsKeys.reminderTime);
    }

    if (state.lastAstralReadingDate != null) {
      await _prefs.setString(_SettingsKeys.lastAstralReadingDate, state.lastAstralReadingDate!);
    } else {
      await _prefs.remove(_SettingsKeys.lastAstralReadingDate);
    }

    if (state.trustedContactName != null) {
      await _prefs.setString(_SettingsKeys.trustedContactName, state.trustedContactName!);
    } else {
      await _prefs.remove(_SettingsKeys.trustedContactName);
    }

    if (state.trustedContactPhone != null) {
      await _prefs.setString(_SettingsKeys.trustedContactPhone, state.trustedContactPhone!);
    } else {
      await _prefs.remove(_SettingsKeys.trustedContactPhone);
    }
  }

  // ─── Setters individuales ───

  /// Marca el onboarding como completado.
  Future<void> setOnboardingDone(bool value) async {
    await _prefs.setBool(_SettingsKeys.onboardingDone, value);
  }

  /// Marca la confirmación de mayoría de edad.
  Future<void> setAdultConfirmed(bool value) async {
    await _prefs.setBool(_SettingsKeys.adultConfirmed, value);
  }

  /// Activa/desactiva el audio ambiental.
  Future<void> setAudioEnabled(bool value) async {
    await _prefs.setBool(_SettingsKeys.audioEnabled, value);
  }

  /// Activa/desactiva reducir movimiento.
  Future<void> setReduceMotion(bool value) async {
    await _prefs.setBool(_SettingsKeys.reduceMotion, value);
  }

  /// Activa/desactiva el recordatorio diario.
  Future<void> setReminderEnabled(bool value) async {
    await _prefs.setBool(_SettingsKeys.reminderEnabled, value);
  }

  /// Establece la hora del recordatorio (formato 'HH:mm').
  Future<void> setReminderTime(String? time) async {
    if (time != null) {
      await _prefs.setString(_SettingsKeys.reminderTime, time);
    } else {
      await _prefs.remove(_SettingsKeys.reminderTime);
    }
  }

  /// Establece la fecha de la última lectura astral (formato 'YYYY-MM-DD').
  Future<void> setLastAstralReadingDate(String? date) async {
    if (date != null) {
      await _prefs.setString(_SettingsKeys.lastAstralReadingDate, date);
    } else {
      await _prefs.remove(_SettingsKeys.lastAstralReadingDate);
    }
  }

  /// Establece el nombre del contacto de confianza.
  Future<void> setTrustedContactName(String? name) async {
    if (name != null) {
      await _prefs.setString(_SettingsKeys.trustedContactName, name);
    } else {
      await _prefs.remove(_SettingsKeys.trustedContactName);
    }
  }

  /// Establece el teléfono del contacto de confianza.
  Future<void> setTrustedContactPhone(String? phone) async {
    if (phone != null) {
      await _prefs.setString(_SettingsKeys.trustedContactPhone, phone);
    } else {
      await _prefs.remove(_SettingsKeys.trustedContactPhone);
    }
  }

  // ─── Getters individuales ───

  bool get onboardingDone => _prefs.getBool(_SettingsKeys.onboardingDone) ?? false;
  bool get adultConfirmed => _prefs.getBool(_SettingsKeys.adultConfirmed) ?? false;
  bool get audioEnabled => _prefs.getBool(_SettingsKeys.audioEnabled) ?? false;
  bool get reduceMotion => _prefs.getBool(_SettingsKeys.reduceMotion) ?? false;
  bool get reminderEnabled => _prefs.getBool(_SettingsKeys.reminderEnabled) ?? false;
  String? get reminderTime => _prefs.getString(_SettingsKeys.reminderTime);
  String? get lastAstralReadingDate => _prefs.getString(_SettingsKeys.lastAstralReadingDate);
  String? get trustedContactName => _prefs.getString(_SettingsKeys.trustedContactName);
  String? get trustedContactPhone => _prefs.getString(_SettingsKeys.trustedContactPhone);
}