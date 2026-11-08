/// Textos de apoyo SOS (Red de Apoyo Dual) para Refugio Quetzalcóatl.
///
/// CONTEXT.md punto 2: Un solo mensaje SOS para la persona de confianza.
/// Si no hay contacto configurado, el botón 1 lleva a configurarlo y el botón 2
/// (Línea de la Vida) siempre funciona.
class SosTexts {
  // Mensaje unificado para la persona de confianza (CONTEXT.md punto 2)
  static const String mensajePersonaConfianza =
      'Hola [Nombre], te escribo desde mi refugio porque en este momento '
      'no me siento muy bien emocionalmente y me ayudaría mucho platicar '
      'o sentir tu compañía. ¿Tienes un momento?';

  // Números de emergencia
  static const String lineaDeLaVida = '800 911 2000';
  static const String emergencias911 = '911';

  // Textos para botones del modal de apoyo
  static const String botonContactoConfianza = 'Contactar a mi persona de confianza';
  static const String botonLineaDeLaVida = 'Llamar a Línea de la Vida ($lineaDeLaVida)';
  static const String botonEmergencias = 'Llamar al $emergencias911';

  // Textos para cuando no hay contacto configurado
  static const String sinContactoConfigurado =
      'No tienes una persona de confianza configurada aún.';
  static const String botonConfigurarContacto = 'Configurar contacto de confianza';

  // Títulos y descripciones de los modales
  static const String tituloSupportNetworkModal = 'Aquí hay manos que te sostienen';
  static const String subtituloSupportNetworkModal =
      'No tienes que pasar por esto solo. Elige a quién recurrir:';

  static const String tituloAltarOfCalmModal = 'Altar de la Calma';
  static const String subtituloAltarOfCalmModal =
      'Respira con Ehécatl. El viento te acompaña.';

  // Textos de confirmación
  static const String confirmacionLlamada =
      'Se abrirá el marcador con el número $lineaDeLaVida. ¿Continuar?';
  static const String confirmacionEmergencias =
      'Se abrirá el marcador con el número $emergencias911. ¿Continuar?';
}