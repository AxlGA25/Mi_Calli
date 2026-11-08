# INSTRUCTIONS.md - Reglas de Ingeniería y Convenciones de Código

> **Directiva para IA / Generadores de Código:** Sigue estrictamente estas reglas al escribir código en Dart (Flutter) y TypeScript (Cloudflare Workers). Lee primero `CONTEXT.md`.

## 0. Forma de trabajo (obligatoria)
* Trabaja **una tarea del `ROADMAP.md` a la vez**, en orden. Al terminar, corre `flutter analyze` (y `flutter test` si hay pruebas) y repórtame el resultado antes de seguir.
* **No agregues funciones, pantallas, paquetes ni cambios de diseño que no estén en `CONTEXT.md` o `ROADMAP.md`.** Si crees que algo falta o mejoraría el proyecto, propónlo en una nota corta y espera mi aprobación.
* El nombre de la app es **Mi Calli**.
* Si algo es ambiguo o dos documentos se contradicen, **pregunta**; no inventes. Si hay conflicto, `CONTEXT.md` (sección 6) manda.
* **No inventes assets** (animaciones `.riv`/Lottie, audios, ilustraciones). Usa marcadores simples y que la app no se rompa si falta un asset.
* No instales versiones de paquetes copiadas de la documentación: usa `flutter pub add` y adapta el código a la API actual.
* No subas al repositorio secretos ni identificadores privados (client ID de Google, `database_id` de D1). Usa variables de entorno o archivos ignorados por git.

## 1. Reglas Estrictas de Privacidad y Seguridad
* **PROHIBIDO subir el diario a la nube:** ningún modelo de red, DTO o petición HTTP hacia Cloudflare puede incluir el campo `content` de `diary_entries`.
* **Única excepción de salida del diario:** la exportación manual de `DiaryBackupService`, iniciada por el usuario, cifrada con su contraseña y entregada solo mediante la hoja de compartir del sistema. Nunca automática, nunca por Cloudflare, nunca con la contraseña guardada.
* **Base de datos cifrada:** `diary_entries` y las demás tablas locales viven en SQLite cifrado (`sqflite_sqlcipher`); la llave se genera una vez y se guarda en `flutter_secure_storage`. Nunca escribas el contenido del diario en logs, `print` ni reportes de errores.
* **Sin copias automáticas del diario:** en Android, `android:allowBackup="false"` (o reglas que excluyan la base de datos) para que el sistema no la suba a la nube.
* **PROHIBIDO integrar LLMs conversacionales:** no agregues llamadas a OpenAI, Anthropic, Gemini, Groq ni similares para responder al diario. Usa solo `assets/data/feathers.json` y el generador local `TonalpohualliGenerator`.
* **Filtro SOS antes del cierre:** en `SanctuaryJournalScreen`, ejecuta `SafetyGuardService.containsCrisisKeywords(text)` antes de la animación de cierre.
* **El SOS nunca bloquea ni borra:** el texto se guarda siempre, aunque el filtro dispare el modal; el usuario puede cerrarlo libremente.
* **El apoyo siempre es alcanzable:** ninguna pantalla de bloqueo puede impedir llegar a las llamadas de apoyo (Línea de la Vida y 911). El candado de la app sigue el punto 19 de `CONTEXT.md`.
* **Lista de palabras de riesgo en archivo aparte** (`assets/data/crisis_patterns.json`), fácil de editar y revisar, usada por `SafetyGuardService`. Debe tolerar acentos, mayúsculas y errores comunes de escritura. Usa frases con contexto y una lista de excepciones en lugar de palabras sueltas ambiguas. Las pruebas deben incluir falsos positivos como "cortarme el pelo", "morirme de risa" y "matarme de risa", que **no** deben disparar el aviso.
* **Solo adultos:** el onboarding exige confirmar ser mayor de 18 años. Si no lo confirma, no se continúa ni se guarda ningún dato (ver `CONTEXT.md`, punto 13).
* **Textos legales:** usa solo los de `core/constants/legal_texts.dart`. No redactes avisos legales ni afirmaciones clínicas por tu cuenta, y ningún texto debe prometer tratamiento o curación.
* **Backend (Worker):** al validar el Google ID Token, verifica firma, expiración (`exp`) y que `aud` sea igual al client ID de la app. Si no coincide, responde `401`. El Worker nunca recibe ni guarda texto del diario. `DELETE /api/backup` exige token válido, borra solo la fila del `sub` autenticado, es idempotente y nunca registra el token en logs.
* **Mensajes de apoyo:** usa solo los textos de `core/constants/sos_texts.dart`. No improvises mensajes de crisis.
* **Recordatorios:** solo si el usuario los activó. El texto de la notificación es genérico y cálido; nunca menciona la racha, emociones ni contenido del diario, y nunca presiona ni culpa.

## 2. Reglas de Rendimiento Gráfico en Flutter (60/120 FPS)
* **`RepaintBoundary` obligatorio:** todo widget con animación continua (`RiveAnimation`, `Lottie`, partículas de clima, Brasero) va en su propio `RepaintBoundary`.
* **Pausa con teclado activo:** cuando el `FocusNode` del diario tenga foco, las animaciones de fondo van en `TickerMode(enabled: false)`.
* **Reducir movimiento:** si `reduce_motion` está activo o `MediaQuery.disableAnimations` es verdadero, las animaciones decorativas se detienen o se sustituyen por una imagen fija. La respiración guiada sigue funcionando, pero con un círculo que cambia de tamaño sin efectos extra.
* **Caché de instancias:** nunca cargues `.riv` o Lottie `.json` desde `build()`. Usa el singleton `AnimationCacheService` inicializado al arranque. Si un asset falta o falla, el servicio devuelve un reemplazo estático sin lanzar excepción.
* **Ciclo de vida:** detén sonidos y animaciones en `AppLifecycleState.paused` o `inactive`.
* **Audio:** el sonido ambiental inicia **silenciado hasta que el usuario lo active** la primera vez.

## 3. Reglas de UI/UX, Diseño Diegético y Accesibilidad
* **Cero `BottomNavigationBar` o `Drawer`:** `TeotihuacanValleyScreen` es un lienzo en `Stack`; se navega tocando elementos del escenario. El HUD superior tiene tres botones discretos: audio (izquierda), Ajustes (centro) y Caracol SOS (derecha).
* **Paleta de colores prehispánica:**
  * Jade Quetzalcóatl: `#2A9D8F`
  * Turquesa Ehécatl: `#48CAE4`
  * Oro Tonatiuh: `#E9C46A`
  * Obsidiana Nocturna: `#0F172A`
  * Rojo Grana / Cempasúchil: `#E76F51`
* **Tono de los textos (español de México):** cálido, empático, poético y respetuoso de la cultura teotihuacana y mexica. Nunca lenguaje clínico frío ni castigos por perder una racha.
* **Zonas táctiles cómodas:** los elementos interactivos del paisaje deben tener al menos $48 \times 48$ px de área de toque.
* **Lectores de pantalla:** cada zona táctil y botón lleva `Semantics` con una etiqueta clara en español (por ejemplo, "Quetzalcóatl, abre tu diario").
* **Texto escalable:** toda pantalla debe soportar escalado de texto hasta el 200 % sin desbordes (usa contenedores desplazables).
* **Contraste y señales:** el texto debe tener contraste suficiente sobre los gradientes. Nunca transmitas información solo con color o solo con vibración; acompáñala de texto o iconos.

## 4. Configuración de plataforma (no la olvides)
* **Android:** permiso `USE_BIOMETRIC`; la `MainActivity` debe extender `FlutterFragmentActivity` para `local_auth`; `<queries>` en `AndroidManifest.xml` para los esquemas `tel`, `sms` y `https` (WhatsApp). Para recordatorios, `POST_NOTIFICATIONS` solicitado **solo cuando el usuario activa el recordatorio**.
* **iOS:** `NSFaceIDUsageDescription` en `Info.plist`; `LSApplicationQueriesSchemes` con `tel`, `sms` y `whatsapp`; el permiso de notificaciones también se pide solo al activar el recordatorio.
* **WhatsApp:** usa `https://wa.me/<telefono>?text=<texto codificado>`; si no se puede abrir, cae a SMS.

## 5. Comandos Útiles del Entorno
* **Flutter - Instalar paquetes:** `flutter pub get`
* **Flutter - Analizar código:** `flutter analyze`
* **Flutter - Ejecutar pruebas:** `flutter test`
* **Cloudflare - Crear tabla local D1:** `npx wrangler d1 execute quetzalcoatl_progress_db --local --file=./cloudflare/schema.sql`
* **Cloudflare - Ejecutar Worker local:** `npx wrangler dev`
* **Cloudflare - Desplegar a producción:** `npx wrangler deploy`
