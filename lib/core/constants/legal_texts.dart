/// Textos legales para Mi Calli.
///
/// Textos aprobados de docs/privacidad_y_avisos_borrador.md (Parte A).
class LegalTexts {
  // ─── A1. Bienvenida ───
  static const String welcomeTitle = 'Bienvenido a tu refugio';
  static const String welcomeBody =
      'Aquí puedes desahogarte a tu ritmo, en privado. Quetzalcóatl te '
      'acompañará en silencio mientras escribes y cuidas tu pequeño valle. '
      'Todo lo que escribes se queda en tu teléfono.';

  // ─── A2. Mayoría de edad ───
  static const String ageGateTitle = 'Antes de entrar';
  static const String ageGateBody =
      'Esta app es solo para personas mayores de 18 años.';
  static const String ageGateConfirm = 'Tengo 18 años o más';
  static const String ageGateDecline = 'Soy menor de 18';

  // ─── A3. Pantalla para menores ───
  static const String underageTitle = 'Gracias por decirnos';
  static const String underageBody =
      'Por ahora este refugio es solo para personas adultas, así que no '
      'podemos continuar. Si hoy te sientes mal, no tienes que pasarlo solo o '
      'sola: puedes hablar con alguien de confianza o llamar gratis a la '
      'Línea de la Vida al 800 911 2000, las 24 horas. Si es una emergencia, '
      'marca al 911.';
  static const String underageButtonLineaDeLaVida = 'Llamar a la Línea de la Vida';
  static const String underageButtonEmergencias = 'Llamar al 911';

  // ─── A4. Aviso importante ───
  static const String disclaimerTitle = 'Un aviso importante';
  static const String disclaimerBody =
      'Mi Calli es un espacio de bienestar y autocuidado. No es un servicio '
      'médico, psicológico ni de emergencias, y no sustituye la atención de '
      'una persona profesional. Si estás en peligro o necesitas ayuda urgente, '
      'llama al 911. Si necesitas hablar con alguien, la Línea de la Vida '
      '(800 911 2000) atiende gratis las 24 horas.';
  static const String disclaimerPrivacyLink = 'Leer aviso de privacidad';

  // ─── A5. Resumen de privacidad ───
  static const String privacySummaryTitle = 'Tu diario es solo tuyo';
  static const String privacySummaryBody =
      '• Lo que escribes se guarda cifrado en este teléfono. Nunca lo '
      'enviamos a ningún servidor.\n'
      '• Tu progreso (nivel, racha, plantas) solo se respalda en la nube si '
      'tú inicias sesión con Google.\n'
      '• No usamos publicidad ni compartimos tus datos.\n'
      '• Puedes exportar tu diario cifrado cuando quieras.';
  static const String privacySummaryButton = 'Ver aviso de privacidad completo';

  // ─── A6. Respaldo en la nube ───
  static const String cloudConsentTitle = 'Respaldar mi progreso';
  static const String cloudConsentBody =
      'Si inicias sesión con Google, guardaremos en la nube únicamente tu '
      'progreso numérico: nivel de Quetzalcóatl, días de racha, plantas y '
      'reliquias desbloqueadas. Tu diario no se sube. Si cambias de teléfono, '
      'podrás recuperar este progreso. Puedes pedir que se elimine tu respaldo '
      'en cualquier momento.';
  static const String cloudConsentContinue = 'Continuar con Google';
  static const String cloudConsentLater = 'Ahora no';

  // ─── A7. Contacto de confianza ───
  static const String contactExplain =
      'Puedes guardar a una persona de confianza. Su nombre y teléfono se '
      'quedan solo en tu teléfono. Si algún día lo necesitas, la app abrirá '
      'WhatsApp con un mensaje listo para que tú decidas si lo envías. Nunca '
      'enviamos nada sin que tú lo toques.';

  // ─── A8. Exportar diario ───
  static const String exportWarningTitle = 'Exportar mi diario';
  static const String exportWarningBody =
      'Se creará un archivo cifrado con tu diario y tu progreso. Elige una '
      'contraseña que recuerdes: no la guardamos y, si la olvidas, no '
      'podremos recuperar el archivo. Guarda el archivo en un lugar seguro; '
      'quien tenga el archivo y la contraseña podrá leerlo.';
  static const String exportSuccess = 'Diario exportado correctamente. Guarda el archivo en un lugar seguro.';
  static const String exportError = 'No se pudo exportar el diario. Inténtalo de nuevo.';

  // ─── A9. Importar diario ───
  static const String importWarningTitle = 'Importar mi diario';
  static const String importWarningBody =
      'Vas a agregar al refugio las entradas de este archivo. No se borrarán '
      'las que ya tienes ni se duplicarán las repetidas. Necesitarás la '
      'contraseña con la que lo exportaste.';
  static const String importConfirm =
      'Vas a agregar al refugio las entradas de este archivo. No se borrarán '
      'las que ya tienes ni se duplicarán las repetidas. Necesitarás la '
      'contraseña con la que lo exportaste.';
  static const String importError = 'No se pudo importar el archivo. Verifica la contraseña e inténtalo de nuevo.';

  // ─── A10. Recordatorio ───
  static const String reminderExplain =
      'Si quieres, te enviamos un recordatorio amable a la hora que elijas. '
      'Puedes apagarlo cuando quieras. El permiso de notificaciones solo se '
      'pide al activarlo.';
  static const String reminderNotificationText =
      'Tu refugio te espera cuando quieras pasar. 🌿';

  // ─── A12. Consentimiento (guardar entradas cifradas en el teléfono) ───
  static const String consentTitle = 'Tu consentimiento';
  static const String consentBody =
      'Lo que escribes en Mi Calli puede hablar de cómo te sientes, y eso es '
      'información delicada. Para guardarlo en este teléfono, cifrado y solo '
      'para ti, necesitamos tu permiso. No lo enviamos a ningún servidor.';
  static const String consentCheck =
      'Entiendo y acepto que Mi Calli guarde mis entradas cifradas en este teléfono.';
  static const String consentContinue = 'Continuar';
  static const String consentDecline = 'Ahora no';
  static const String consentDeclineBody =
      'Sin tu permiso no podemos guardar tus entradas, así que por ahora no '
      'podemos continuar. Cuando quieras, aquí estaremos.';

  // ─── A11. Eliminar mi respaldo ───
  static const String deleteBackupTitle = 'Eliminar mi respaldo';
  static const String deleteBackupBody =
      'Se borrará de la nube el progreso que respaldaste con tu cuenta de '
      'Google. Tu diario y tu progreso en este teléfono no se tocan. Después '
      'podrás volver a respaldar si quieres. Esta acción no se puede deshacer.';
  static const String deleteBackupConfirm = 'Eliminar respaldo';
  static const String deleteBackupCancel = 'Cancelar';

  // ─── URL de política de privacidad (para Play Store) ───
  static const String urlPoliticaPrivacidad =
      'https://[TU_DOMINIO].com/privacidad'; // TODO: Reemplazar con URL real
}