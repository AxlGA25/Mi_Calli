# ROADMAP.md - Mi Calli - Plan de Implementación Paso a Paso

> **Instrucción para el Agente de Código:** Ejecuta este plan en orden secuencial, **una tarea a la vez**. Cada tarea tiene un "Listo cuando". Al cumplirlo, corre `flutter analyze`, repórtame el resultado y espera mi visto bueno antes de pasar a la siguiente. Lee antes `CONTEXT.md` e `INSTRUCTIONS.md`.

## Fase 1: Cimientos (COMPLETADA)
- [x] **1.1.** Proyecto Flutter y dependencias con `flutter pub add`.
- [x] **1.2.** Estructura *Feature-First* de `lib/` y carpetas de `assets/` con `.gitkeep`.
- [x] **1.3.** Riverpod, paleta de colores, `sos_texts.dart` y `legal_texts.dart`.
- [x] **1.4.** `feathers.json` (5 plumas) y `seeds_catalog.json` (7 semillas) con sus modelos y `AssetLoaderService`.
- [x] **1.5.** `LocalDatabaseService` con SQLite cifrado y las 4 tablas.
- [x] **1.6.** `AppSettingsService` con sus ajustes y provider de Riverpod.
- [x] **1.7.** `SafeAnimationWrapper` (`RepaintBoundary` + `TickerMode` + reducir movimiento). *Quedó incompleta: ver 1.10.*
- [x] **1.8.** Bóveda biométrica (`BiometricVaultService`) y onboarding de mayoría de edad. *Se ajusta en 1.12 y 1.13. La configuración de plataforma que era de esta tarea pasa a 1.9.*

## Fase 1B: Correcciones de la Fase 1
- [x] **1.9.** Configuración de plataforma: en Android, `allowBackup="false"` y reglas para que el sistema no copie la base de datos, permiso `USE_BIOMETRIC`, `<queries>` para `tel`, `sms` y `https`, y `MainActivity` compatible con `local_auth`. En iOS, `NSFaceIDUsageDescription` y `LSApplicationQueriesSchemes` con `tel`, `sms` y `whatsapp`.
  *Listo cuando:* el manifiesto y el `Info.plist` tienen todo lo anterior, `flutter build apk --debug` pasa, y me dices qué faltaba.
- [x] **1.10.** `AnimationCacheService` (singleton en `core/performance`) que intenta pre-cargar los `.riv` y Lottie conocidos y, si el archivo no existe, devuelve `null` sin errores. Además `SafeAnimationWrapper` debe pausar las animaciones en `AppLifecycleState.paused` e `inactive`.
  *Listo cuando:* pruebas cubren archivo ausente, caché reutilizada y pausa por ciclo de vida.
- [x] **1.11.** En `user_inventory`, `quantity` tiene valor por defecto `1` (no `0`).
  *Listo cuando:* una prueba inserta un elemento sin cantidad y obtiene `1`. Avísame que debo desinstalar la app de prueba para recrear la base.
- [x] **1.12.** Candado de la app según `CONTEXT.md` punto 19: bloquea solo tras más de 30 segundos en segundo plano, nunca por `inactive` ni por el propio aviso de huella, y se puede apagar con el ajuste `app_lock_enabled` (nueva clave en `AppSettingsService`).
  *Listo cuando:* pruebas cubren: volver antes de 30 s no bloquea, volver después sí, `inactive` no bloquea, y con el ajuste apagado nunca bloquea. El botón "Necesito apoyo" de la pantalla de bloqueo se agrega en la 2.2.
- [x] **1.13.** Textos y consentimiento: `legal_texts.dart` usa los textos aprobados de `docs/privacidad_y_avisos_borrador.md` (Parte A) con el nombre Mi Calli; `sos_texts.dart` vuelve al mensaje de `CONTEXT.md` punto 2 con el nombre del contacto; el onboarding agrega el paso de consentimiento (después de confirmar la mayoría de edad) y guarda `privacy_consent_accepted`.
  *Listo cuando:* pruebas cubren: sin consentimiento no se avanza, un menor de edad nunca llega al paso de consentimiento ni se guarda nada, y el mensaje de la persona de confianza cambia con y sin nombre.
- [x] **1.14.** Auditoría de catálogos y documentos: compara `feathers.json` y `seeds_catalog.json` con las Etapas 1 y 2 y **muéstrame una tabla de diferencias antes de cambiar nada**; renombra `docs/etapa_3_ui_ux_animaciones.md` a `docs/etapa_3_pantallas_ui_ux.md`; verifica que `docs/` tenga las 4 etapas, `HANDOFF_FASE_1.md` y `privacidad_y_avisos_borrador.md`.
  *Listo cuando:* la tabla de diferencias está revisada por mí y los cambios aprobados aplicados, con las pruebas pasando.

## Fase 2: Etapa 1 - Diario, Climas Emocionales y Seguridad SOS
- [x] **2.1.** `DiaryEntry`, el enum `PrehispanicEmotion` (con la tabla de `CONTEXT.md` sección 5D) y `DiaryRepository` (guardar, buscar por rango de fechas y contar emociones de los últimos 7 días).
  *Listo cuando:* pruebas cubren guardar, recuperar por fechas y contar emociones.
- [x] **2.2.** `SafetyGuardService` (con `assets/data/crisis_patterns.json`), `SupportContactService` y `SupportNetworkModal` con `url_launcher`. El modal también se abre desde `BiometricLockScreen` sin autenticar.
  *Listo cuando:* pruebas cubren frases de riesgo con y sin acentos y los falsos positivos de `INSTRUCTIONS.md`; el modal abre los dos destinos y funciona desde la pantalla de bloqueo.
- [x] **2.3.** `EmotionWeatherSelector`: los 5 climas con la tabla de `CONTEXT.md` 5D, gradientes de fondo con `AppColors` y `SafeAnimationWrapper`.
  *Listo cuando:* al elegir un clima cambia el gradiente y cada clima muestra su emoción correcta.
- [x] **2.4.** `SanctuaryJournalScreen`: pergamino de escritura, botón "Necesito apoyo", `TickerMode` con teclado abierto, filtro SOS antes del cierre (sin bloquear el guardado, marcando `triggered_sos`) y diálogo de la Pluma de Sabiduría.
  *Listo cuando:* se puede escribir, entregar la ofrenda, ver la pluma, y la entrada queda guardada incluso si el SOS aparece.
- [x] **2.5.** `DiaryHistoryScreen` **provisional** (lista de entradas con fecha, clima y pluma). Se elimina al terminar el Códice Privado (4.4).
  *Listo cuando:* muestra las entradas en orden inverso.
- 🏁 **Punto de control 1:** el diario funciona de principio a fin. Reviso contigo antes de seguir.

## Fase 3: Etapa 2 - Gamificación, Fuego Sagrado, Chinampa y Tonalpohualli
- [x] **3.1.** Implementar `SacredFireAndEvolutionService`: 5 niveles de Quetzalcóatl, racha con colores (Naranja, Dorado, Turquesa) y *Manto de Xólotl* con escudos que empiezan en 1, suben $+1$ por cada 7 días de racha y tienen máximo 2, usando la fecha local `YYYY-MM-DD`.
  *Listo cuando:* pruebas cubren racha continua, 1 día perdido con y sin escudo, reinicio compasivo, recarga de escudo y tope de 2.
- [x] **3.2.** Implementar `ChinampaController`: plantar en 4 slots y regar al guardar una entrada ($+1$, o $+2$ por emoción de afinidad), con `waterings_needed` tomado del catálogo.
  *Listo cuando:* pruebas cubren riego normal, riego doble y floración.
- [x] **3.3.** Implementar visitas y reliquias de Tláloc, Xochiquétzal y Xólotl (condiciones de la Etapa 2, guardadas en `user_inventory`).
  *Listo cuando:* pruebas muestran que cada condición desbloquea su reliquia una sola vez.
- [x] **3.4.** Crear `TonalpohualliGenerator` y `TonalpohualliScrollDialog` (astro regente de los últimos 7 días y plantillas modulares) con la regla de disponibilidad de `CONTEXT.md` punto 11.
  *Listo cuando:* pruebas cubren: se habilita en domingo o a los 7 días de la última lectura, sigue disponible hasta abrirse, no se ofrece sin entradas en la semana, y una semana con datos de ejemplo produce una lectura coherente.

## Fase 4: Etapa 3 - Paisaje, Códice Biométrico, Altar de Calma, Ajustes y Accesibilidad
- [x] **4.1.** Implementar `AmbientAudioService` (`audioplayers`): mezcla según clima y hora, inicia silenciado, se detiene al pasar a segundo plano.
  *Listo cuando:* alternar el silencio funciona y no suena nada con la app en segundo plano.
- [x] **4.2.** Construir `TeotihuacanValleyScreen` solo con el ciclo Día/Noche (4 gradientes) y las capas del `Stack`, sin zonas táctiles todavía.
  *Listo cuando:* el cielo cambia según la hora del dispositivo.
- [x] **4.3.** Agregar las zonas táctiles (Quetzalcóatl, Chinampa, Brasero, Templo del Códice) y el HUD de tres botones (audio, Ajustes, Caracol SOS), con `Semantics` en cada uno. Los destinos que aún no existan pueden ser pantallas vacías.
  *Listo cuando:* cada zona navega a su destino, tiene área de toque de al menos $48 \times 48$ px y etiqueta para lectores de pantalla.
- [x] **4.4.** Construir `PrivateCodexScreen` con `local_auth` y la cuadrícula de Calendario Agrícola (detalle en pergamino). Al terminar, elimina el `DiaryHistoryScreen` provisional de la Fase 2.
  *Listo cuando:* sin autenticación no se ve el contenido, y con ella se abre un día con entrada.
- [ ] **4.5.** Construir `AltarOfCalmModal`: respiración $4-4-6$ con vibración háptica y apoyo visual (texto "inhala/sostén/exhala"), 3 ciclos que cuentan para el Fuego Sagrado, y configuración de la Red de Apoyo Dual.
  *Listo cuando:* completar 3 ciclos suma el día de racha y los dos botones de apoyo funcionan.
- [ ] **4.6.** Construir `SettingsScreen` (sonido, reducir movimiento, candado de la app, recordatorio, contacto de confianza, aviso y privacidad, exportar/importar diario) y la pantalla "Aviso y privacidad". La sección de respaldo en la nube se agrega en la 5.3.
  *Listo cuando:* cada ajuste se guarda y se aplica de inmediato, y la pantalla de aviso muestra los textos de `legal_texts.dart`.
- [ ] **4.7.** Implementar `ReminderService` con `flutter_local_notifications`: recordatorio diario opcional a la hora elegida, mensaje genérico, permiso pedido solo al activarlo.
  *Listo cuando:* activarlo pide permiso y programa la notificación, desactivarlo la cancela, y el texto no menciona racha ni contenido.
- [ ] **4.8.** Implementar `DiaryBackupService`: exportar a archivo `.calli` cifrado con contraseña del usuario (4 tablas locales), compartirlo con `share_plus`, e importarlo con `file_picker` fusionando por `id`.
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
