// Servicio para gestionar el contacto de confianza (Red de Apoyo Dual).
//
// Lee el nombre y teléfono guardados en shared_preferences vía AppSettingsService.

import 'package:mi_calli/core/settings/app_settings_service.dart';

/// Servicio para acceder al contacto de confianza configurado por el usuario.
class SupportContactService {
  SupportContactService._(this._settings);

  final AppSettingsService _settings;

  /// Crea una instancia del servicio.
  static Future<SupportContactService> create() async {
    final settings = await AppSettingsService.create();
    return SupportContactService._(settings);
  }

  /// Crea una instancia para testing.
  static SupportContactService createForTesting(AppSettingsService settings) {
    return SupportContactService._(settings);
  }

  /// Nombre del contacto de confianza (null si no configurado).
  String? get trustedContactName => _settings.trustedContactName;

  /// Teléfono del contacto de confianza (null si no configurado).
  String? get trustedContactPhone => _settings.trustedContactPhone;

  /// Indica si hay un contacto de confianza configurado (nombre y teléfono).
  bool get hasContact => trustedContactName != null && trustedContactPhone != null;

  /// Nombre a mostrar (nombre o "mi persona de confianza" si no hay nombre).
  String get displayName => trustedContactName ?? 'mi persona de confianza';

  /// Teléfono formateado para URL (solo dígitos).
  String? get phoneDigits {
    final phone = trustedContactPhone;
    if (phone == null) return null;
    return phone.replaceAll(RegExp(r'[^\d]'), '');
  }
}