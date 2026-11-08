# CONTEXT.md - Mi Calli (antes Refugio Quetzalcóatl)

> **Nota para Agentes de IA (Claude Code / Cursor / Copilot / otros):** Este archivo es la fuente de verdad arquitectónica del proyecto. Léelo antes de generar o modificar cualquier archivo en Flutter o Cloudflare. También lee `INSTRUCTIONS.md` (reglas) y `ROADMAP.md` (plan). Para el detalle de cada módulo consulta los archivos de `docs/`:
> - `docs/etapa_1_mecanica_diario.md`
> - `docs/etapa_2_gamificacion_teotihuacan.md`
> - `docs/etapa_3_pantallas_ui_ux.md`
> - `docs/etapa_4_arquitectura_flutter_cloudflare.md`
>
> **Si algo de las etapas contradice la sección 6 de este archivo ("Decisiones de contrato"), gana este archivo.**

## 1. Resumen Ejecutivo del Proyecto
**Mi Calli** (nombre anterior: Refugio Quetzalcóatl) es una aplicación móvil de bienestar emocional y diario íntimo gamificado ambientada en la cosmovisión prehispánica de **Teotihuacán, México**.
El usuario interactúa con **Quetzalcóatl** (la serpiente emplumada) como un compañero silencioso y empático. Al desahogarse escribiendo en su diario, el clima emocional elegido (Lluvia de Tláloc, Sol de Tonatiuh, Viento de Ehécatl, Tormenta de Mixcóatl, Noche de Metztli) nutre la tierra de una **Chinampa Sagrada**, haciendo crecer semillas endémicas mexicanas (cempasúchil, nopal con tunas, maíz, maguey, cacao, dalia, vainilla).

## 2. Filosofía de Seguridad Psicológica y Privacidad (CRÍTICO)
1. **Cero IA Generativa Abierta (No Chatbot):** Quetzalcóatl **nunca** responde con texto generado por un LLM, para evitar alucinaciones o riesgos psicológicos en usuarios con depresión o ansiedad. Toda respuesta consiste en animaciones reconfortantes y **Plumas de Sabiduría** con mensajes preescritos y validados desde un catálogo JSON local (`assets/data/feathers.json`).
2. **Privacidad Absoluta (*Zero-Knowledge Journal*):** Las entradas del diario (`diary_entries`) se guardan **solo en una base SQLite local y cifrada** (`sqflite_sqlcipher`, llave en `flutter_secure_storage`) dentro del teléfono. El Códice Privado exige huella/FaceID/PIN (`local_auth`) para abrirse, y la app completa también se protege al volver de segundo plano (ver punto 19 de la sección 6). **Bajo ninguna circunstancia** el texto del diario se envía a servidores externos ni se incluye en copias de seguridad automáticas del sistema operativo. La **única** salida posible es la exportación manual que el propio usuario inicia y protege con su contraseña (ver sección 6, punto 12).
3. **Red de Apoyo Dual (SOS Local):** Un filtro local en Dart (`SafetyGuardService`) detecta palabras clave de crisis sin conexión a internet y, si hay coincidencia, muestra `SupportNetworkModal` (modal corto y cálido). Desde el botón del Caracol en el Valle, el usuario también puede abrir en cualquier momento el `AltarOfCalmModal` (respiración + los mismos botones de apoyo). Los dos botones de apoyo son: WhatsApp/SMS prellenado a una persona de confianza y llamada a la **Línea de la Vida (`800 911 2000`)**. Para emergencias inmediatas se puede mostrar también el `911`.
4. **El SOS nunca bloquea al usuario:** puede cerrar el modal y continuar; lo que escribió siempre se guarda.
5. **Aviso claro y solo para adultos:** la app no es un servicio médico, psicológico ni de emergencias y no sustituye atención profesional. Es solo para mayores de 18 años (confirmación en el primer arranque). Los textos legales viven en `core/constants/legal_texts.dart`.

## 3. Stack Tecnológico
* **Frontend Móvil:** Flutter (Dart 3.x), gestión de estado con `flutter_riverpod`.
* **Persistencia Local:** `sqflite_sqlcipher` (diario y estado de la Chinampa, cifrado), `flutter_secure_storage` (llave de la base), `shared_preferences` (contacto SOS y ajustes), `local_auth` (biometría).
* **Motor Gráfico y Audio:** `rive` (Quetzalcóatl evolucionable y dioses), `lottie` (climas y Fuego Sagrado), `audioplayers` (audio ambiental en bucle).
* **Recordatorios, exportación y archivos:** `flutter_local_notifications` (recordatorio opcional), `cryptography` (cifrado del archivo exportado), `share_plus` y `file_picker` (guardar e importar el archivo).
* **Backend Serverless (solo respaldo de progreso numérico):** Cloudflare Workers (TypeScript) + Cloudflare D1 + `google_sign_in`.
* **Versiones:** no copies versiones fijas de paquetes desde las etapas; usa `flutter pub add <paquete>` y adapta el código a la API de la versión instalada.

## 4. Mapa de las 4 Etapas Documentadas
* **Etapa 1:** Selección de los 5 climas prehispánicos, escritura optimizada en el pergamino, filtro SOS local y entrega de Plumas de Sabiduría.
* **Etapa 2:** Evolución de Quetzalcóatl (5 niveles), racha del **Fuego Sagrado** con protección empática (*El Manto de Xólotl*), cultivo en la Chinampa (4 slots) y lectura astral semanal (**El Tonalpohualli**). Sin rankings competitivos.
* **Etapa 3:** Interfaz diegética en el Valle de Teotihuacán (navegación tocando el paisaje, cero barras de navegación), ciclo Día/Noche en tiempo real, Códice Privado con calendario agrícola y Altar de Calma (respiración $4-4-6$ con Ehécatl).
* **Etapa 4:** Estructura de carpetas *Feature-First*, pre-carga de animaciones en RAM (`AnimationCacheService`), aislamiento con `RepaintBoundary` y API de respaldo en Cloudflare D1.

Funciones añadidas después de las etapas (aprobadas): onboarding y mayoría de edad, pantalla de Ajustes, recordatorio opcional, exportación/importación cifrada del diario, accesibilidad y textos legales. Su detalle está en la sección 6.

### Carpetas adicionales a las de la Etapa 4
```text
lib/
 ├── core/
 │    ├── settings/        # AppSettingsService (shared_preferences)
 │    ├── notifications/   # ReminderService
 │    └── backup/          # DiaryBackupService (exportar/importar cifrado)
 └── features/
      ├── 0_onboarding/    # OnboardingFlow, pantalla de solo adultos
      └── 5_settings/      # SettingsScreen, pantalla de aviso y privacidad
```

## 5. Contratos de Datos Principales

### A. Tablas Locales en Dispositivo (`sqflite_sqlcipher`)
* `diary_entries`: `id`, `created_at`, `emotion_id`, `content` (SECRETO LOCAL), `feather_id`, `watered_seed_id`, `triggered_sos`.
* `user_gamification`: `local_id` (PK, valor fijo `'local'`), `google_uid` (**nullable**, se llena al iniciar sesión), `quetzal_xp`, `quetzal_level`, `current_streak`, `longest_streak`, `last_checkin_date`, `xolotl_shields`.
* `chinampa_slots`: `slot_index` ($0-3$), `seed_id`, `current_waterings`, `is_harvested`, `planted_at`.
* `user_inventory`: `item_id`, `item_type` (`SEED` | `RELIC`), `quantity`, `unlocked_at`.

### B. Tabla Remota en Cloudflare D1 (`user_cloud_backups`)
Sincroniza únicamente: `google_uid`, `email_hash`, `quetzal_xp`, `quetzal_level`, `current_streak`, `longest_streak`, `xolotl_shields`, `unlocked_seeds_json`, `unlocked_relics_json`, `harvested_count`, `updated_at`.

### C. Ajustes locales (`shared_preferences`, vía `AppSettingsService`)
`onboarding_done`, `adult_confirmed`, `audio_enabled` (por defecto `false`), `reduce_motion` (por defecto `false`), `reminder_enabled` (por defecto `false`), `reminder_time`, `last_astral_reading_date`, `trusted_contact_name`, `trusted_contact_phone`, `app_lock_enabled` (por defecto `true`), `privacy_consent_accepted` (por defecto `false`).

### D. Climas emocionales (fuente de verdad)
| `emotion_id` | Emoción | Deidad / clima |
| :--- | :--- | :--- |
| `tlaloc_lluvia` | Tristeza, melancolía | Lluvia de Tláloc |
| `tonatiuh_sol` | Alegría, calma, gratitud | Sol de Tonatiuh |
| `ehecatl_viento` | Ansiedad, estrés, abrumo | Viento de Ehécatl |
| `mixcoatl_tormenta` | Enojo, frustración | Tormenta de Mixcóatl |
| `metztli_noche` | Cansancio, agotamiento | Noche de Metztli |

## 6. Decisiones de contrato (prevalecen sobre las etapas)
Estas decisiones resuelven contradicciones entre las etapas y definen las funciones aprobadas:

1. **La app funciona sin cuenta de Google.** Por eso `user_gamification` usa `local_id` como llave y `google_uid` es opcional. El login solo activa el respaldo.
2. **Un solo mensaje SOS para la persona de confianza**, definido como constante en `core/constants/sos_texts.dart`:
   *"Hola [Nombre], te escribo desde mi refugio porque en este momento no me siento muy bien emocionalmente y me ayudaría mucho platicar o sentir tu compañía. ¿Tienes un momento?"*
   Si no hay contacto configurado, el botón 1 lleva a configurarlo y el botón 2 (Línea de la Vida) siempre funciona.
3. **Dos modales distintos, un solo servicio de apoyo:** `SupportNetworkModal` (lo dispara el filtro) y `AltarOfCalmModal` (lo abre el Caracol). Ambos usan `SupportContactService` (contacto en `shared_preferences`) y los mismos textos.
4. **Riego de la Chinampa:** cada entrada guardada suma $+1$ riego a cada planta viva, o $+2$ si la emoción de la entrada coincide con su `affinity_emotion`. El número de riegos para florecer lo define **`waterings_needed` de `seeds_catalog.json`** (no el texto de la Etapa 2).
5. **Endpoints del Worker:** `POST /api/backup`, `GET /api/backup` y `DELETE /api/backup` (la Etapa 4 reemplaza al `/api/sync-progress` mencionado en la Etapa 2).
6. **Payload de respaldo:** el definido en la tabla `user_cloud_backups` (sección 5B), no el JSON de ejemplo de la Etapa 2.
7. **Fechas de racha:** se calculan con la fecha local del dispositivo en formato `YYYY-MM-DD`.
8. **El respaldo en la nube nunca baja el progreso:** si el `quetzal_xp` entrante es menor al guardado, el Worker conserva el mayor.
9. **Recuperación al cambiar de teléfono:** el respaldo en la nube restaura solo progreso numérico. El diario y el estado de la Chinampa solo se recuperan con la exportación manual del punto 12.
10. **Amuleto de Obsidiana (escudo de Xólotl):** el usuario empieza con 1, gana $+1$ por cada 7 días de racha cumplidos y el máximo es **2**.
11. **Lectura del Tonalpohualli (Constelación de Venus):** se habilita cada **domingo** o cuando pasan **7 días o más desde la última lectura abierta**, y **permanece disponible hasta que el usuario la abra** (no desaparece si no entra ese día). Se guarda `last_astral_reading_date`. Si no hubo entradas en esos 7 días, no se ofrece lectura. Esto reemplaza el "solo fines de semana" de la Etapa 3.
12. **Exportación e importación del diario (`DiaryBackupService`):** el usuario puede exportar un archivo `.calli` con las 4 tablas locales, cifrado con una **contraseña que él elige** (AES-256-GCM con la llave derivada mediante un KDF robusto como PBKDF2 con muchas iteraciones o Argon2). El archivo lo guarda o comparte el propio usuario mediante la hoja de compartir del sistema; **nunca pasa por Cloudflare ni se hace de forma automática**. La contraseña no se guarda en ningún lado y se advierte claramente que, si se olvida, el archivo no se puede recuperar. Al importar, se fusionan las entradas por `id` sin duplicar.
13. **Onboarding (solo la primera vez, `onboarding_done`):** Bienvenida con aviso (no es servicio médico ni de emergencias) → confirmación de mayoría de edad → consentimiento de privacidad para datos sensibles (`privacy_consent_accepted`) → contacto de confianza (**omitible**) → preferencias (audio y reducir movimiento, ambos apagados) → Valle. El consentimiento se pide **después** de confirmar la mayoría de edad para no guardar nada de menores. Si el usuario **no** confirma ser mayor de edad, ve una pantalla amable que explica que la app es solo para adultos y muestra la Línea de la Vida (`800 911 2000`) y el `911`; no se crea ningún dato ni se continúa.
14. **Ajustes (`SettingsScreen`):** se abre con un **tercer botón discreto en el HUD superior** (centro, icono de piedra tallada). No requiere biometría. Contiene: sonido, reducir movimiento, candado de la app, recordatorio, contacto de confianza, respaldo en la nube (iniciar o cerrar sesión, restaurar y eliminar mi respaldo), aviso y privacidad, y exportar/importar diario.
15. **Recordatorio opcional (`ReminderService`):** apagado por defecto; el usuario elige la hora; usa un mensaje cálido y genérico que **nunca** menciona la racha, emociones ni contenido del diario, ni presiona. El permiso de notificaciones se pide solo cuando el usuario lo activa.
16. **Accesibilidad:** modo "reducir movimiento" (interruptor propio, y también se respeta el ajuste del sistema), textos escalables hasta el 200 % sin desbordes, `Semantics` en cada zona táctil y botón, contraste suficiente, y ninguna información transmitida solo por vibración o solo por color.
17. **Textos legales:** viven en `core/constants/legal_texts.dart` y los aprueba el dueño del proyecto. El agente no redacta avisos legales por su cuenta. La política de privacidad completa se hospeda en una URL pública (necesaria para publicar en Play Store).
18. **Eliminar mi respaldo:** el botón en Ajustes llama a `DELETE /api/backup`, que borra solo la fila del usuario autenticado (token validado). La app pide confirmación, conserva todos sus datos locales, pone `google_uid` en `NULL` y cierra la sesión. Quien ya no tiene la app puede pedir la eliminación por correo, como indica el aviso de privacidad.
19. **Candado de la app (`BiometricVaultService`):** la app pide huella/PIN del sistema al volver de segundo plano **solo si pasaron más de 30 segundos** fuera de ella. Nunca se bloquea por estados breves del sistema (`inactive`, avisos, el propio mensaje de huella). Si el dispositivo no tiene bloqueo configurado, la app no se bloquea. La pantalla de bloqueo tiene un botón **"Necesito apoyo"** que abre `SupportNetworkModal` **sin pedir autenticación** (solo opciones de apoyo, nunca datos del diario). En Ajustes hay un interruptor `app_lock_enabled`. El Códice Privado siempre exige su propia autenticación, aunque el candado esté apagado.
20. **Nombres de clases del módulo SOS:** `SafetyGuardService` (lista en `assets/data/crisis_patterns.json`), `SupportContactService` y `SupportNetworkModal`. No se usan los nombres `CrisisKeywordDetector` ni `SosSupportModal`.
21. **Catálogos como fuente de verdad:** `assets/data/feathers.json` y `assets/data/seeds_catalog.json` mandan sobre los textos, ids, colores, riegos y afinidades. Los mensajes de las plumas son los de la Etapa 1 y no atribuyen frases a personas reales.
22. **Nombre de la app:** **Mi Calli**. Archivo de exportación `.calli`, base de datos `mi_calli_encrypted.db`.
