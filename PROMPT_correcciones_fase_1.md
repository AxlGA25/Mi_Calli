# PROMPT PARA EL AGENTE - Correcciones de la Fase 1 (tareas 1.9 a 1.14)

> Copia y pega todo lo que está debajo de la línea en tu herramienta. Antes, copia a tu proyecto los archivos nuevos: `CLAUDE.md`, `CONTEXT.md`, `INSTRUCTIONS.md` y `ROADMAP.md` van en la raíz; `HANDOFF_FASE_1.md` y `privacidad_y_avisos_borrador.md` (el archivo `privacidad_y_avisos.md` renombrado) van en `docs/`.

---

Hola. El proyecto se llama **Mi Calli**. La Fase 1 (tareas 1.1 a 1.8) está terminada, pero una revisión encontró desviaciones respecto a la documentación. Antes de empezar la Fase 2 hay que corregirlas.

**Paso 0. Vuelve a leer, completos y en este orden:** `CLAUDE.md`, `CONTEXT.md`, `INSTRUCTIONS.md`, `ROADMAP.md` y `docs/HANDOFF_FASE_1.md`. Esos archivos acaban de actualizarse. Si recuerdas algo distinto, manda lo que dicen ahora. Recuerda las variables de entorno de Windows de `CLAUDE.md`.

**Forma de trabajo para esta ronda.** Son 6 tareas pequeñas (1.9 a 1.14 del `ROADMAP.md`). Haz una a la vez, en orden. Esta vez puedes encadenarlas sin esperar mi aprobación entre una y otra, con estas condiciones:
- Después de cada tarea corre `flutter analyze` y `flutter test`.
- Si algo falla, **detente**, muéstrame el error completo y no cambies el plan.
- Si todo pasa, escribe un resumen de máximo 5 líneas (qué cambiaste, archivos tocados, resultado de analyze y test) y sigue con la siguiente.
- No marques `[x]` en `ROADMAP.md`; eso lo hago yo.
- No agregues nada que no esté descrito aquí. Si algo es ambiguo, pregúntame. No inventes assets.

## Tarea 1.9 - Configuración de plataforma
1. Revisa `android/app/src/main/AndroidManifest.xml` y corrige lo que falte:
   - `android:allowBackup="false"` y reglas que impidan que el sistema copie la base de datos o el almacenamiento seguro (por ejemplo, `android:dataExtractionRules` y `android:fullBackupContent`).
   - Permiso `USE_BIOMETRIC`.
   - `<queries>` para los esquemas `tel`, `sms` y `https`.
2. Revisa que `MainActivity` sea compatible con la versión instalada de `local_auth` (normalmente debe extender `FlutterFragmentActivity`). Si la versión instalada ya no lo requiere, dime por qué.
3. En iOS (`ios/Runner/Info.plist`): `NSFaceIDUsageDescription` con un texto amable en español, y `LSApplicationQueriesSchemes` con `tel`, `sms` y `whatsapp`.
4. No agregues permisos de notificaciones todavía (eso es de la tarea 4.7).
5. Corre `flutter build apk --debug`.

**Listo cuando:** el manifiesto y el `Info.plist` tienen todo lo anterior, el APK compila, y me dices exactamente qué faltaba.

## Tarea 1.10 - `AnimationCacheService` y pausa por ciclo de vida
1. Crea el singleton `AnimationCacheService` en `lib/core/performance/`. Debe intentar pre-cargar los `.riv` y Lottie conocidos y, **si un archivo no existe o falla, devolver `null` sin lanzar error y sin imprimir contenido sensible**. No agregues ni inventes ningún asset.
2. Haz que `SafeAnimationWrapper` use esa caché y que pause las animaciones (`TickerMode` desactivado) cuando la app pase a `AppLifecycleState.paused` o `inactive`, usando `WidgetsBindingObserver`. Debe seguir respetando `reduceMotion` y `MediaQuery.disableAnimationsOf`.
3. Pruebas: archivo ausente, caché reutilizada y pausa por ciclo de vida.

**Listo cuando:** `flutter analyze` y `flutter test` pasan con las pruebas nuevas.

## Tarea 1.11 - `user_inventory.quantity`
Cambia el valor por defecto de `quantity` a `1` en `LocalDatabaseService` y actualiza las pruebas. Como todavía no hay usuarios, basta con cambiar `onCreate`. Prueba que insertar un elemento sin cantidad produce `1`. **Avísame que debo desinstalar la app de mis dispositivos de prueba** para recrear la base.

## Tarea 1.12 - Candado de la app
Sigue `CONTEXT.md`, sección 6, punto 19:
1. Agrega la clave `app_lock_enabled` (bool, por defecto `true`, clave exacta `'app_lock_enabled'`) a `AppSettingsService`, `AppSettingsState` y su provider, con pruebas.
2. En `BiometricVaultService`:
   - La app solo se bloquea al volver a `resumed` **si pasaron más de 30 segundos** desde que salió de primer plano. Define el valor como constante (`Duration(seconds: 30)`).
   - **Nunca** se bloquea por `inactive` solo, ni por los eventos de ciclo de vida que provoca el propio aviso de huella (ignora eventos mientras hay una autenticación en curso).
   - Si `app_lock_enabled` es `false`, nunca bloquea.
   - Si el dispositivo no tiene bloqueo configurado, deja pasar (como ya hace) y documéntalo en un comentario.
3. No agregues todavía el botón "Necesito apoyo" en la pantalla de bloqueo; eso se hace en la tarea 2.2.
4. Pruebas: volver antes de 30 s no bloquea; después de 30 s sí; `inactive` no bloquea; con el ajuste apagado nunca bloquea.

**Listo cuando:** las pruebas anteriores pasan. Dime también que debo probarlo en un teléfono real (por si el aviso de huella provoca un bucle de bloqueo).

## Tarea 1.13 - Textos, mensaje SOS y consentimiento
1. **`legal_texts.dart`:** reemplaza los textos por los aprobados en `docs/privacidad_y_avisos_borrador.md`, **Parte A** (A1 a A12), con el nombre **Mi Calli**. No inventes textos legales. Si algún texto de la Parte A no tiene uso todavía, déjalo como constante.
2. **`sos_texts.dart`:** el mensaje para la persona de confianza debe ser el de `CONTEXT.md`, sección 6, punto 2. Ofrece una función que reciba el nombre del contacto: con nombre dice "Hola [Nombre], te escribo desde mi refugio porque..."; sin nombre dice "Hola, te escribo desde mi refugio porque...". No debe mencionar el nombre de la app.
3. **Onboarding:** agrega el paso `privacyConsent` **después** de confirmar la mayoría de edad (y antes del contacto de confianza). Muestra el texto A12, una casilla y el botón "Continuar". Guarda `privacy_consent_accepted` (bool, por defecto `false`, clave exacta `'privacy_consent_accepted'`) en `AppSettingsService` con su provider. Si elige "Ahora no", muestra el mensaje de A12 y no avanza.
4. Un menor de edad nunca debe llegar a ese paso ni quedar con nada guardado.
5. Pruebas: sin consentimiento no se avanza; el menor no llega al consentimiento ni guarda datos; el mensaje cambia con y sin nombre.

**Listo cuando:** pruebas, `flutter analyze` y `flutter test` pasan.

## Tarea 1.14 - Auditoría de catálogos y nombres de documentos
1. Compara `assets/data/feathers.json` con la Etapa 1 y `assets/data/seeds_catalog.json` con la Etapa 2 (carpeta `docs/`). **Muéstrame una tabla de diferencias y no cambies nada todavía.** Revisa en particular: los mensajes de las plumas (deben ser los de la Etapa 1), el campo `author` (no debe atribuir frases a personas reales; explica de dónde salió), colores, `waterings_needed` y `affinity_emotion` de cada semilla, y los ids (los del JSON mandan, `CONTEXT.md` punto 21).
2. Espera mi respuesta sobre las diferencias antes de aplicar cambios en esos JSON y en sus modelos.
3. Renombra `docs/etapa_3_ui_ux_animaciones.md` a `docs/etapa_3_pantallas_ui_ux.md` y confirma que su contenido es la Etapa 3 de pantallas y flujo de UI/UX.
4. Verifica que `docs/` contenga: las 4 etapas con los nombres de `CONTEXT.md`, `HANDOFF_FASE_1.md` y `privacidad_y_avisos_borrador.md`.

**Listo cuando:** la tabla está revisada por mí, los cambios aprobados aplicados y las pruebas pasan.

## Reporte final
Al terminar las 6 tareas, dame un reporte con: lista de archivos creados y modificados, resultado de `flutter analyze` y `flutter test` (número de pruebas), cualquier cosa que debo decidir o probar a mano, y la confirmación de que **no empezaste la Fase 2**.
