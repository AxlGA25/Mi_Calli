/// Textos legales para Refugio Quetzalcóatl.
///
/// El texto final será aprobado por el dueño del proyecto.
/// Aquí se definen marcadores de posición claros para cada texto requerido.
class LegalTexts {
  // ─── Aviso principal (no sustituye ayuda profesional, +18) ───
  static const String avisoPrincipal = '''
[AVISO LEGAL - PENDIENTE DE APROBACIÓN]

Esta aplicación (Refugio Quetzalcóatl) es una herramienta de bienestar emocional
y diario íntimo gamificado. **NO es un servicio médico, psicológico ni de
emergencias y NO sustituye la atención profesional.**

Está dirigida **exclusivamente a mayores de 18 años**. Al continuar, confirmas
tener 18 años o más.

Si te sientes en crisis o riesgo inmediato, contacta a servicios de emergencia
o a la Línea de la Vida: 800 911 2000 (México).
''';

  // ─── Confirmación de mayoría de edad ───
  static const String confirmacionMayoriaEdad = '''
[CONFIRMACIÓN +18 - PENDIENTE DE APROBACIÓN]

¿Confirmas que tienes 18 años o más?

Esta app contiene contenido de bienestar emocional y no es adecuada para
menores de edad. Si eres menor de 18 años, por favor busca apoyo con un
adulto de confianza o contacta a la Línea de la Vida: 800 911 2000.
''';

  // ─── Pantalla "Solo adultos" (si no confirma mayoría de edad) ───
  static const String pantallaSoloAdultos = '''
[PANTALLA SOLO ADULTOS - PENDIENTE DE APROBACIÓN]

Esta aplicación es solo para mayores de 18 años.

Si estás pasando por un momento difícil, no estás solo:
• Línea de la Vida (México): 800 911 2000
• Emergencias: 911

Por favor, busca apoyo con un adulto de confianza o con los números arriba.
''';

  // ─── Confirmación de borrado de respaldo en la nube ───
  static const String confirmacionBorradoRespaldo = '''
[CONFIRMACIÓN ELIMINAR RESPALDO - PENDIENTE DE APROBACIÓN]

¿Eliminar tu respaldo en la nube?

Esto borrará tu progreso de gamificación guardado en Cloudflare (nivel de
Quetzalcóatl, racha del Fuego Sagrado, semillas y reliquias desbloqueadas).

**Tus datos locales NO se borran**: tu diario, la Chinampa y el Códice
permanecen intactos en tu teléfono. Tu google_uid se pondrá en NULL y se
cerrará la sesión de Google.

Esta acción no se puede deshacer. Podrás volver a respaldar después como
cuenta nueva si lo deseas.
''';

  // ─── URL de política de privacidad (para Play Store) ───
  static const String urlPoliticaPrivacidad =
      'https://[TU_DOMINIO].com/privacidad'; // TODO: Reemplazar con URL real

  // ─── Texto para formulario de seguridad de datos Play Store ───
  static const String datosRecolectados = '''
[DATOS RECOLECTADOS - PENDIENTE DE APROBACIÓN]

En el dispositivo (local, cifrado):
• Entradas del diario (texto, emoción, fecha) - NUNCA sale del teléfono
• Estado de la Chinampa (plantas, riegos, cosechas)
• Clave de cifrado (flutter_secure_storage)
• Ajustes (shared_preferences)
• Autenticación biométrica (local_auth - solo para abrir Códice)

En la nube (Cloudflare D1, SOLO con login Google):
• google_uid (identificador único de Google)
• Hash SHA-256 del email (opcional, para soporte)
• Progreso numérico: XP, nivel, rachas, escudos, semillas/reliquias desbloqueadas
• NUNCA: contenido del diario, emociones, textos personales

Exportación manual (archivo .refugio):
• Usuario elige contraseña (AES-256-GCM)
• Contiene: 4 tablas locales cifradas
• Se comparte vía share_plus (hoja del sistema)
• NUNCA pasa por servidores
''';

  // ─── Aviso de exportación/importación ───
  static const String avisoExportacion = '''
[AVISO EXPORTACIÓN - PENDIENTE DE APROBACIÓN]

El archivo .refugio se cifra con TU contraseña (AES-256-GCM).
**Si olvidas la contraseña, el archivo NO se puede recuperar.**
La contraseña no se guarda en ningún lado.

El archivo contiene tu diario completo y estado de la Chinampa.
Cómpartelo solo contigo mismo (ej. guardarlo en tu nube personal).
''';

  static const String avisoImportacion = '''
[AVISO IMPORTACIÓN - PENDIENTE DE APROBACIÓN]

Al importar, las entradas se fusionan por ID sin duplicar.
Si la contraseña es incorrecta, la importación falla sin dañar tus datos.
''';
}