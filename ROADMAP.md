# ROADMAP.md - Plan de Implementación Paso a Paso

> **Instrucción para el Agente de Código:** Ejecuta este plan en orden secuencial, **una tarea a la vez**. Cada tarea tiene un "Listo cuando". Al cumplirlo, corre `flutter analyze`, repórtame el resultado y espera mi visto bueno antes de pasar a la siguiente. Lee antes `CONTEXT.md` e `INSTRUCTIONS.md`.

## Fase 1: Cimientos
- [x] **1.1.** Inicializar el proyecto Flutter y agregar las dependencias con `flutter pub add` (Riverpod, `sqflite_sqlcipher`, `flutter_secure_storage`, `shared_preferences`, `local_auth`, `rive`, `lottie`, `audioplayers`, `google_sign_in`, `http`, `url_launcher`, `uuid`, `intl`, `path`, `flutter_local_notifications`, `cryptography`, `share_plus`, `file_picker`).
  *Listo cuando:* `flutter pub get` y `flutter analyze` pasan sin errores. **✓ Completado**
  *Listo cuando:* `flutter pub get` y `flutter analyze` pasan sin errores.
- [x] **1.2.** Crear la estructura *Feature-First* de `lib/` (Etapa 4 + carpetas adicionales de `CONTEXT.md` sección 4) y las carpetas de `assets/` con un archivo `.gitkeep`. En `pubspec.yaml` declara solo carpetas que existan; los `.riv`, Lottie y audios se declaran cuando haya archivos reales.
  *Listo cuando:* la app compila y muestra una pantalla vacía. **✓ Completado**
- [ ] **1.3.** Configurar Riverpod (`ProviderScope` en `main.dart`) y las constantes: paleta, textos SOS (`sos_texts.dart`, con el mensaje unificado) y `legal_texts.dart` con marcadores de posición para el aviso y la política (el texto final lo apruebo yo).
  *Listo cuando:* un widget de prueba lee un color y un texto desde las constantes.
- [x] **1.4.** Generar `assets/data/feathers.json` (5 plumas) y `assets/data/seeds_catalog.json` (7 semillas) con los datos de las Etapas 1 y 2.
  *Listo cuando:* ambos archivos se cargan y se parsean a modelos sin errores. **✓ Completado**
- [ ] **1.5.** Implementar `LocalDatabaseService` con SQLite cifrado y las 4 tablas de `CONTEXT.md` sección 5A (con `local_id` y `google_uid` nullable). La llave se genera una vez y se guarda en `flutter_secure_storage`.
  *Listo cuando:* hay una prueba que crea la base, inserta y lee una fila de cada tabla, y el archivo de la base no se puede leer como texto plano.
- [ ] **1.6.** Implementar `AppSettingsService` (`shared_preferences`) con las claves de `CONTEXT.md` sección 5C y su provider de Riverpod.
  *Listo cuando:* una prueba guarda y lee cada ajuste y los valores por defecto son los indicados (audio, reducir movimiento y recordatorio apagados).
- [ ] **1.7.** Implementar `AnimationCacheService` y `OptimizedAnimatedLayer` (`RepaintBoundary` + `TickerMode` + `WidgetsBindingObserver`), con reemplazo estático si falta un asset, y que respete `reduce_motion` y `MediaQuery.disableAnimations`.
  *Listo cuando:* la app arranca sin los archivos `.riv`/Lottie sin lanzar excepciones, y al activar "reducir movimiento" las animaciones se detienen.
- [ ] **1.8.** Configuración de plataforma: `allowBackup="false"`, permisos de biometría, `<queries>`, claves de iOS y preparación de notificaciones (sin pedir el permiso todavía), según `INSTRUCTIONS.md` sección 4.
  *Listo cuando:* la app corre en un dispositivo/emulador Android sin advertencias de manifiesto.

## Fase 2: Etapa 1 - Diario, Climas Emocionales, Seguridad SOS y Bienvenida
- [ ] **2.1.** Crear `DiaryEntry`, `WisdomFeather` y el enum `PrehispanicEmotion` (`tlalocLluvia`, `tonatiuhSol`, `ehecatlViento`, `mixcoatlTormenta`, `metztliNoche`), más el repositorio local del diario.
  *Listo cuando:* una prueba guarda una entrada, la recupera por rango de fechas y cuenta emociones de los últimos 7 días.
- [ ] **2.2.** Implementar `SafetyGuardService` (con `assets/data/crisis_patterns.json`), `SupportContactService` y `SupportNetworkModal` con `url_launcher` (WhatsApp/SMS a la persona de confianza y llamada a `800 911 2000`).
  *Listo cuando:* pruebas unitarias cubren frases de riesgo con y sin acentos y frases normales (sin falsos positivos obvios), y el modal abre los dos destinos.
- [ ] **2.3.** Construir `SanctuaryJournalScreen`: selección de clima, gradientes animados, `TextField` tipo pergamino, `TickerMode` con teclado abierto, filtro SOS antes del cierre y diálogo de la Pluma de Sabiduría.
  *Listo cuando:* se puede escribir, entregar la ofrenda, ver la pluma y la entrada queda guardada, incluso si el SOS aparece.
- [ ] **2.4.** Construir `OnboardingFlow`: Bienvenida → confirmación de mayoría de edad → aviso → contacto de confianza (omitible). Incluye la pantalla amable de "solo adultos" con Línea de la Vida y `911`. Hasta que exista el Valle, al terminar lleva a `SanctuaryJournalScreen`.
  *Listo cuando:* la primera vez se ven los pasos y no se repiten; si no confirma ser mayor de 18, ve la pantalla de apoyo y no se guarda ningún dato; el contacto se puede omitir.
- 🏁 **Punto de control 1:** el diario y la bienvenida funcionan de principio a fin. Reviso contigo antes de seguir.

## Fase 3: Etapa 2 - Gamificación, Fuego Sagrado, Chinampa y Tonalpohualli
- [ ] **3.1.** Implementar `SacredFireAndEvolutionService`: 5 niveles de Quetzalcóatl, racha con colores (Naranja, Dorado, Turquesa) y *Manto de Xólotl* con escudos que empiezan en 1, suben $+1$ por cada 7 días de racha y tienen máximo 2, usando la fecha local `YYYY-MM-DD`.
  *Listo cuando:* pruebas cubren racha continua, 1 día perdido con y sin escudo, reinicio compasivo, recarga de escudo y tope de 2.
- [ ] **3.2.** Implementar `ChinampaController`: plantar en 4 slots y regar al guardar una entrada ($+1$, o $+2$ por emoción de afinidad), con `waterings_needed` tomado del catálogo.
  *Listo cuando:* pruebas cubren riego normal, riego doble y floración.
- [ ] **3.3.** Implementar visitas y reliquias de Tláloc, Xochiquétzal y Xólotl (condiciones de la Etapa 2, guardadas en `user_inventory`).
  *Listo cuando:* pruebas muestran que cada condición desbloquea su reliquia una sola vez.
- [ ] **3.4.** Crear `TonalpohualliGenerator` y `TonalpohualliScrollDialog` (astro regente de los últimos 7 días y plantillas modulares) con la regla de disponibilidad de `CONTEXT.md` punto 11.
  *Listo cuando:* pruebas cubren: se habilita en domingo o a los 7 días de la última lectura, sigue disponible hasta abrirse, no se ofrece sin entradas en la semana, y una semana con datos de ejemplo produce una lectura coherente.

## Fase 4: Etapa 3 - Paisaje, Códice Biométrico, Altar de Calma, Ajustes y Accesibilidad
- [ ] **4.1.** Implementar `AmbientAudioService` (`audioplayers`): mezcla según clima y hora, inicia silenciado, se detiene al pasar a segundo plano.
  *Listo cuando:* alternar el silencio funciona y no suena nada con la app en segundo plano.
- [ ] **4.2.** Construir `TeotihuacanValleyScreen` solo con el ciclo Día/Noche (4 gradientes) y las capas del `Stack`, sin zonas táctiles todavía.
  *Listo cuando:* el cielo cambia según la hora del dispositivo.
- [ ] **4.3.** Agregar las zonas táctiles (Quetzalcóatl, Chinampa, Brasero, Templo del Códice) y el HUD de tres botones (audio, Ajustes, Caracol SOS), con `Semantics` en cada uno. Los destinos que aún no existan pueden ser pantallas vacías.
  *Listo cuando:* cada zona navega a su destino, tiene área de toque de al menos $48 \times 48$ px y etiqueta para lectores de pantalla.
- [ ] **4.4.** Construir `PrivateCodexScreen` con `local_auth` y la cuadrícula de Calendario Agrícola (detalle en pergamino).
  *Listo cuando:* sin autenticación no se ve el contenido, y con ella se abre un día con entrada.
- [ ] **4.5.** Construir `AltarOfCalmModal`: respiración $4-4-6$ con vibración háptica y apoyo visual (texto "inhala/sostén/exhala"), 3 ciclos que cuentan para el Fuego Sagrado, y configuración de la Red de Apoyo Dual.
  *Listo cuando:* completar 3 ciclos suma el día de racha y los dos botones de apoyo funcionan.
- [ ] **4.6.** Construir `SettingsScreen` (sonido, reducir movimiento, recordatorio, contacto de confianza, aviso y privacidad, exportar/importar diario) y la pantalla "Aviso y privacidad". La sección de respaldo en la nube se agrega en la 5.3.
  *Listo cuando:* cada ajuste se guarda y se aplica de inmediato, y la pantalla de aviso muestra los textos de `legal_texts.dart`.
- [ ] **4.7.** Implementar `ReminderService` con `flutter_local_notifications`: recordatorio diario opcional a la hora elegida, mensaje genérico, permiso pedido solo al activarlo.
  *Listo cuando:* activarlo pide permiso y programa la notificación, desactivarlo la cancela, y el texto no menciona racha ni contenido.
- [ ] **4.8.** Implementar `DiaryBackupService`: exportar a archivo `.refugio` cifrado con contraseña del usuario (4 tablas locales), compartirlo con `share_plus`, e importarlo con `file_picker` fusionando por `id`.
  *Listo cuando:* una prueba exporta, importa en una base vacía y recupera las mismas entradas; con contraseña incorrecta la importación falla sin dañar datos; el archivo no contiene texto legible.
- [ ] **4.9.** Pasada de accesibilidad: revisar `Semantics`, escalado de texto al 200 %, contraste y modo "reducir movimiento" en todas las pantallas.
  *Listo cuando:* ninguna pantalla se desborda a 200 % de texto y cada elemento interactivo se anuncia correctamente con el lector de pantalla.
- 🏁 **Punto de control 2:** la app completa funciona sin nube. Reviso contigo antes de seguir.

## Fase 5: Etapa 4 - Autenticación con Google y Respaldo en Cloudflare D1
- [ ] **5.1.** Crear `cloudflare/` con `wrangler.toml`, `schema.sql` y `src/index.ts`: validación del Google ID Token (firma, `exp` y `aud`) y endpoints `POST /api/backup`, `GET /api/backup` y `DELETE /api/backup` (este último borra solo la fila del usuario autenticado). El `POST` nunca baja el progreso.
  *Listo cuando:* con `npx wrangler dev` un token inválido da `401`, uno válido guarda y devuelve el progreso, y `DELETE` borra solo su fila (repetirlo no da error).
- [ ] **5.2.** Implementar `CloudBackupService` (`google_sign_in` + `http`) que respalda y restaura **solo** el progreso numérico, y permite eliminar el respaldo (`deleteCloudBackup()`).
  *Listo cuando:* una prueba confirma que el payload nunca contiene `content` ni lee `diary_entries`, y que `deleteCloudBackup()` no toca la base local.
- [ ] **5.3.** Agregar a `SettingsScreen` la sección "Respaldo en la nube": iniciar y cerrar sesión con Google, restaurar progreso y el botón **"Eliminar mi respaldo"**. Antes de borrar, muestra una confirmación con el texto de `legal_texts.dart`. Al eliminar, la app conserva todos sus datos locales, pone `google_uid` en `NULL` y cierra la sesión.
  *Listo cuando:* eliminar borra el respaldo en la nube, la app local sigue intacta, y se puede volver a respaldar después como cuenta nueva.
- [ ] **5.4.** Pruebas de flujo completo y revisión de rendimiento a 60 FPS en un dispositivo real.
  *Listo cuando:* el flujo diario → riego → pluma → racha → respaldo → eliminación funciona sin tirones al escribir.

## Fase 6: Preparación para publicar
- [ ] **6.1.** Preparar los datos para la política de privacidad pública (qué se guarda en el teléfono, qué va a la nube, qué nunca sale) y para el formulario de seguridad de datos de Play Store. El texto final lo redacto y apruebo yo. Incluye cómo se solicita la eliminación de datos por la web o por correo (verifica el requisito vigente de Play Store).
  *Listo cuando:* hay un documento `docs/privacidad.md` con la lista exacta de datos y su destino, revisado por mí.
- [ ] **6.2.** Verificar que la clasificación de edad y las declaraciones de la tienda coincidan con "solo mayores de 18 años" y con el aviso de la app.
  *Listo cuando:* la lista de verificación de publicación está completa y sin contradicciones con `CONTEXT.md`.
