# DOCUMENTO DE CONTEXTO Y HANDOFF TÉCNICO PARA IA — PROYECTO "MI CALLI" (REFUGIO QUETZALCÓATL)

**Estado del Proyecto:** Fase 1 concluida (tareas 1.1 a 1.8 aprobadas). La revisión posterior encontró desviaciones que se corrigen en la **Fase 1B (tareas 1.9 a 1.14)** antes de empezar la Fase 2. Este documento ya está corregido con esas decisiones.  
**Siguiente Paso Inmediato:** Fase 1B, tarea 1.9 (configuración de plataforma). Después, Fase 2.  
**Repositorio Oficial:** `https://github.com/AxlGA25/Mi_Calli`  
**Métricas de Calidad Actuales:**
- `flutter analyze`: **0 issues found**
- `flutter test`: **106/106 tests passing**
- `flutter build apk --debug`: **SUCCESS (`app-debug.apk` generado)**

---

## 1. VISIÓN GENERAL Y REGLAS INQUEBRANTABLES DEL PROYECTO

**Mi Calli (Refugio Quetzalcóatl)** es una aplicación móvil multiplataforma (Flutter) de diario emocional gamificado y bienestar personal ambientada en la cosmogonía prehispánica (Teotihuacán, la Chinampa Sagrada y Quetzalcóatl).

### 1.1 Principios de Ingeniería y Privacidad (Contratos Estrictos)
1. **Zero-Knowledge Journal (Privacidad Local Absoluta):**
   - El texto libre que el usuario escribe en su diario (`diary_entries.content`) **JAMÁS** sale del dispositivo, **JAMÁS** se envía a servidores externos ni a APIs en la nube, y **JAMÁS** se imprime en consola (`print`, `debugPrint`, `log`).
   - La base de datos local está cifrada en reposo mediante **SQLCipher (AES-256)** usando el paquete `sqflite_sqlcipher`.
   - El respaldo opcional en la nube (Fase 5, Cloudflare Workers + D1) únicamente sincroniza metadatos numéricos de gamificación (`quetzal_xp`, `quetzal_level`, `current_streak`, `longest_streak`, `xolotl_shields`, `unlocked_seeds`, `unlocked_relics`, `harvested_count`). El estado de la chinampa **no** se sube a la nube.
2. **Cero IA Generativa Conversacional:**
   - La aplicación **no utiliza LLMs ni chatbots** para responder al usuario ni para "interpretar" sus textos.
   - Toda retroalimentación ("Plumas de Sabiduría" y "Lecturas Astrales") proviene exclusivamente de catálogos JSON estáticos, deterministas y preaprobados en `assets/data/`.
3. **Política de Assets Reales (No Inventar Archivos):**
   - Está estrictamente prohibido referenciar archivos `.riv`, `.json` (Lottie), `.png` o `.mp3` que no existan físicamente en `assets/`.
   - En `pubspec.yaml` únicamente se declaran directorios que existen en el repositorio (actualmente mantenidos con `.gitkeep`).
   - Todo componente visual o sonoro debe degradarse de forma segura a un `fallbackWidget` estático (en `SafeAnimationWrapper`) o ignorar la reproducción si el archivo binario aún no ha sido agregado.
4. **Aislamiento Gráfico y Accesibilidad (60/120 FPS):**
   - Ninguna animación puede ejecutarse fuera de `SafeAnimationWrapper`, el cual impone `RepaintBoundary` y `TickerMode(enabled: isVisible && !effectiveReduceMotion)`.
   - `effectiveReduceMotion` combina la preferencia interna `appSettings.reduceMotion` con `MediaQuery.disableAnimationsOf(context)`.
5. **Interfaz Diegética (Fase 4):**
   - El Valle de Teotihuacán no utiliza barras de navegación inferiores (`BottomNavigationBar`) ni pestañas tradicionales (`TabBar`). La navegación se realiza tocando elementos arquitectónicos del mapa (Pirámide del Sol, Chinampa, Templo de Quetzalcóatl, Observatorio).

---

## 2. CONFIGURACIÓN DEL ENTORNO Y COMPILACIÓN NATIVA

### 2.1 Notas del Entorno Windows del Desarrollador
El proyecto reside en una máquina Windows cuyo nombre de usuario contiene espacios (`C:\Users\Axel GA\...`), pero el repositorio se ubica en `C:\Mi calli\mi_calli`. Debido a un bug en el script de descompresión de `rive_native` con rutas que contienen espacios en PowerShell, las sesiones de terminal deben definir:
```powershell
$env:TEMP="C:\Temp"
$env:TMP="C:\Temp"
$env:PUB_CACHE="C:\PubCache"
```

### 2.2 Configuración de Android y Gradle (Tarea 1.1)
- **Archivo `android/app/build.gradle.kts`:**
  - `compileSdk = 36`
  - `minSdk = 24` (Requerido por `sqflite_sqlcipher` y `flutter_secure_storage`)
  - `ndkVersion = "27.0.12077973"`
  - `multiDexEnabled = true`
  - `isCoreLibraryDesugaringEnabled = true` con dependencia `coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")` (Requerido por `flutter_local_notifications`).
- **Archivo `android/settings.gradle.kts`:**
  - Versión de Kotlin actualizada a **`2.2.0`** (Requerido por `share_plus` y plugins modernos).

### 2.3 Dependencias Instaladas en `pubspec.yaml`
| Categoría | Paquetes |
| :--- | :--- |
| **Estado y Utilidades** | `flutter_riverpod: ^3.3.1`, `uuid: ^4.5.3`, `intl: ^0.20.2`, `path: ^1.9.1` |
| **Base de Datos y Seguridad** | `sqflite_sqlcipher: ^3.4.0`, `flutter_secure_storage: ^10.0.0`, `shared_preferences: ^2.5.4`, `local_auth: ^3.0.1`, `cryptography: ^2.9.0` |
| **Gráficos y Audio** | `rive: ^0.14.5`, `lottie: ^3.3.2`, `audioplayers: ^6.6.0` |
| **Red y Sistema** | `google_sign_in: ^7.2.0`, `http: ^1.6.0`, `url_launcher: ^6.3.2`, `flutter_local_notifications: ^21.0.0`, `share_plus: ^12.0.1`, `file_picker: ^10.3.10` |

---

## 3. ESTRUCTURA ACTUAL DEL ÁRBOL DE ARCHIVOS

```text
mi_calli/
├── CLAUDE.md
├── CONTEXT.md
├── INSTRUCTIONS.md
├── ROADMAP.md
├── docs/
│   ├── etapa_1_mecanica_diario.md
│   ├── etapa_2_gamificacion_teotihuacan.md
│   ├── etapa_3_pantallas_ui_ux.md             # (se renombra en la tarea 1.14)
│   └── etapa_4_arquitectura_flutter_cloudflare.md
├── assets/
│   ├── data/
│   │   ├── feathers.json                  # Catálogo de 5 plumas de sabiduría
│   │   └── seeds_catalog.json             # Catálogo de 7 semillas de la chinampa
│   ├── animations/.gitkeep
│   ├── audio/.gitkeep
│   └── images/
│       ├── chinampa_plants/.gitkeep
│       └── teotihuacan_layers/.gitkeep
├── lib/
│   ├── main.dart                          # ProviderScope + AppEntryPoint + ProtectedMainScreen
│   ├── core/
│   │   ├── audio/                         # (Preparado para Fase 4 - Tarea 4.1)
│   │   ├── backup/                        # (Preparado para Fase 4 - Tarea 4.8: exportar/importar diario)
│   │   ├── constants/
│   │   │   ├── app_colors.dart            # Paleta prehispánica y gradientes
│   │   │   ├── legal_texts.dart           # Avisos legales (+18, no terapia, privacidad)
│   │   │   └── sos_texts.dart             # Textos y teléfonos de emergencia (800 911 2000 / 911)
│   │   ├── database/
│   │   │   ├── asset_loader_service.dart  # Carga y cacheo de feathers.json y seeds_catalog.json
│   │   │   ├── local_database_service.dart# SQLite cifrado (SQLCipher AES-256) y 4 tablas
│   │   │   ├── secure_storage_impl.dart   # Implementación real con flutter_secure_storage
│   │   │   ├── secure_storage_interface.dart # Contrato inyectable de almacenamiento seguro
│   │   │   └── secure_storage_mock.dart   # Mock en memoria para pruebas unitarias
│   │   ├── notifications/                 # (Preparado para Fase 4 - Tarea 4.7: recordatorio)
│   │   ├── performance/
│   │   │   └── safe_animation_wrapper.dart# RepaintBoundary + TickerMode + ReduceMotion + Fallback (falta AnimationCacheService y pausa por ciclo de vida: tarea 1.10)
│   │   ├── security/
│   │   │   ├── biometric_auth_impl.dart   # Implementación con local_auth
│   │   │   ├── biometric_auth_interface.dart # Contrato inyectable de biometría
│   │   │   ├── biometric_auth_mock.dart   # Mock configurable para tests
│   │   │   └── biometric_vault_service.dart # Singleton con WidgetsBindingObserver y Stream de estado
│   │   └── settings/
│   │       ├── app_settings_provider.dart # Riverpod NotifierProvider (AppSettingsNotifier)
│   │       └── app_settings_service.dart  # Servicio sobre shared_preferences (9 claves exactas)
│   └── features/
│       ├── 0_onboarding/
│       │   ├── biometric_lock_screen.dart              # Pantalla de bloqueo/desbloqueo biométrico
│       │   ├── main_app_screen.dart                    # Pantalla principal placeholder post-desbloqueo
│       │   ├── onboarding_adult_confirmation_screen.dart # Filtro obligatorio de mayoría de edad (+18)
│       │   ├── onboarding_flow.dart                    # Máquina de estados de 6 pasos del Onboarding
│       │   ├── onboarding_minor_block_screen.dart      # Pantalla bloqueante para menores de 18 años
│       │   ├── onboarding_preferences_screen.dart      # Configuración inicial de audio y reducir movimiento
│       │   ├── onboarding_trusted_contact_screen.dart  # Registro opcional de persona de confianza
│       │   └── onboarding_welcome_screen.dart          # Bienvenida y descargo de responsabilidad médica
│       ├── 1_sanctuary_journal/
│       │   ├── models/
│       │   │   └── wisdom_feather.dart    # Modelo de Pluma de Sabiduría
│       │   ├── presentation/              # (Se implementará en Fase 2)
│       │   └── services/                  # (Se implementará en Fase 2)
│       ├── 2_gamification/
│       │   ├── controllers/               # (Se implementará en Fase 3)
│       │   ├── models/
│       │   │   └── seed_catalog_item.dart # Modelo de Semilla + SeedRarity + hasAffinityWith()
│       │   ├── presentation/              # (Se implementará en Fase 3)
│       │   └── services/                  # (Se implementará en Fase 3)
│       ├── 3_teotihuacan_valley/
│       │   └── presentation/              # (Se implementará en Fase 4)
│       ├── 4_cloud_sync/
│       │   ├── models/                    # (Se implementará en Fase 5)
│       │   └── services/                  # (Se implementará en Fase 5)
│       └── 5_settings/                    # (Se implementará en Fase 4 - Tarea 4.6; la sección de nube en la 5.3)
└── test/
    ├── app_settings_service_test.dart     # 28 tests
    ├── asset_loader_test.dart             # 11 tests
    ├── local_database_test.dart           # 18 tests (+ validaciones de seguridad)
    ├── onboarding_and_vault_test.dart     # 25 tests
    ├── safe_animation_wrapper_test.dart   # 22 tests
    └── widget_test.dart                   # Tests base de constantes e integración inicial
```

---

## 4. ESPECIFICACIÓN TÉCNICA DETALLADA DE LOS MÓDULOS CONSTRUIDOS EN FASE 1

### 4.1 Constantes del Núcleo (`lib/core/constants/`)
1. **`AppColors` (`app_colors.dart`):**
   - Colores primarios: `jade` (`#2A9D8F`), `turquesa` (`#48CAE4`), `oro` (`#E9C46A`), `obsidiana` (`#0F172A`), `rojoGrana` / `cempasuchil` (`#E76F51`), `violetaMetztli` (`#9D4EDD`), `pergaminoClaro` (`#FDFBF7`), `rosaSuave` (`#F8C8DC`).
   - Incluye gradientes predefinidos para los 5 climas emocionales, ciclo día/noche y colores de evolución del Fuego Sagrado (chispa naranja, fuego jade, fuego turquesa).
2. **`SosTexts` (`sos_texts.dart`):**
   - Mensaje unificado para contacto de confianza (`CONTEXT.md` §6, punto 2). **El código actual usa otro texto; se corrige en la tarea 1.13** a:
     > *"Hola [Nombre], te escribo desde mi refugio porque en este momento no me siento muy bien emocionalmente y me ayudaría mucho platicar o sentir tu compañía. ¿Tienes un momento?"* (sin nombre: "Hola, te escribo...")
   - Números de emergencia oficiales en México:
     - `lineaDeLaVida = '800 911 2000'` (`tel:8009112000`)
     - `emergencias911 = '911'` (`tel:911`)
3. **`LegalTexts` (`legal_texts.dart`):**
   - Contiene los textos de aviso principal (la app es una herramienta de reflexión personal y **no sustituye atención psicológica, psiquiátrica ni médica profesional**), confirmación de mayoría de edad (+18), pantalla bloqueante para menores, confirmación de borrado de respaldo en la nube y avisos de exportación/importación `.calli`.

---

### 4.2 Catálogos Estáticos y Modelos (`Tarea 1.4`)
1. **`assets/data/feathers.json` y `WisdomFeather` (`lib/features/1_sanctuary_journal/models/wisdom_feather.dart`):**
   - Contiene 5 plumas asociadas a las 5 emociones válidas del sistema:
     - `tlaloc_lluvia` (`pluma_tlaloc_01`, `#2A9D8F`)
     - `tonatiuh_sol` (`pluma_tonatiuh_01`, `#E9C46A`)
     - `ehecatl_viento` (`pluma_ehecatl_01`, `#48CAE4`)
     - `mixcoatl_tormenta` (`pluma_mixcoatl_01`, `#E76F51`)
     - `metztli_noche` (`pluma_metztli_01`, `#9D4EDD`)
   - Campos de `WisdomFeather`: `id`, `emotionId`, `name`, `quote`, `author`, `colorHex`, `description`, más el getter `color`. **Pendiente de auditar en la tarea 1.14:** los mensajes deben ser los de la Etapa 1 y el campo `author` no debe atribuir frases a personas reales.
2. **`assets/data/seeds_catalog.json` y `SeedCatalogItem` (`lib/features/2_gamification/models/seed_catalog_item.dart`):**
   - Contiene 7 semillas divididas en `SeedRarity` (`common`, `rare`, `sacred`):
     - **Comunes (3 riegos):** `seed_cempasuchil` (afinidad `tlaloc_lluvia`), `seed_nopal` (afinidad `mixcoatl_tormenta`), `seed_maiz` (afinidad `tonatiuh_sol`).
     - **Raras:** `seed_maguey` (4 riegos, afinidad `ehecatl_viento`), `seed_dalia` (3 riegos, afinidad `tlaloc_lluvia`).
     - **Sagradas (4 riegos):** `seed_cacao` (afinidad `tonatiuh_sol`), `seed_vainilla` (afinidad `metztli_noche`).
   - Método clave en `SeedCatalogItem`: `bool hasAffinityWith(String emotionId)` -> Devuelve `true` si la emoción del check-in coincide con `affinityEmotion` (otorga **+2 riegos** en lugar de +1).
3. **`AssetLoaderService` (`lib/core/database/asset_loader_service.dart`):**
   - Métodos: `loadFeathers()`, `loadSeedsCatalog()`, `getFeatherByEmotion(String emotionId)`, `getSeedById(String seedId)`, `preloadAll()`, `clearCache()`.

---

### 4.3 Base de Datos Local Cifrada (`LocalDatabaseService` — `Tarea 1.5`)
Ubicación: `lib/core/database/local_database_service.dart`.

- **Mecanismo de Cifrado:**
  - Utiliza `SecureStorageInterface` (con implementación `SecureStorageImpl` en producción y `SecureStorageMock` en tests) bajo la clave `'mi_calli_db_encryption_key_v1'`.
  - Si la llave no existe, genera 32 bytes criptográficamente seguros mediante `Random.secure()`, los codifica en `base64Url` y los persiste en el Keystore/Keychain nativo.
  - Abre la base `mi_calli_encrypted.db` pasando `password: encryptionKey` a `sqflite_sqlcipher`.

- **Esquema SQL Exacto (4 Tablas — `CONTEXT.md` §5A):**

```sql
CREATE TABLE diary_entries (
  id TEXT PRIMARY KEY,
  created_at TEXT NOT NULL,
  emotion_id TEXT NOT NULL,
  content TEXT NOT NULL,
  feather_id TEXT NOT NULL,
  watered_seed_id TEXT,
  triggered_sos INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE user_gamification (
  local_id TEXT PRIMARY KEY,
  google_uid TEXT,
  quetzal_xp INTEGER NOT NULL DEFAULT 0,
  quetzal_level INTEGER NOT NULL DEFAULT 1,
  current_streak INTEGER NOT NULL DEFAULT 0,
  longest_streak INTEGER NOT NULL DEFAULT 0,
  last_checkin_date TEXT,
  xolotl_shields INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE chinampa_slots (
  slot_index INTEGER PRIMARY KEY,
  seed_id TEXT,
  current_waterings INTEGER NOT NULL DEFAULT 0,
  is_harvested INTEGER NOT NULL DEFAULT 0,
  planted_at TEXT
);

CREATE TABLE user_inventory (
  item_id TEXT PRIMARY KEY,
  item_type TEXT NOT NULL,
  quantity INTEGER NOT NULL DEFAULT 0,  -- se corrige a DEFAULT 1 en la tarea 1.11
  unlocked_at TEXT NOT NULL
);
```

- **Semilla de Datos Iniciales (`onCreate`):**
  - Inserta automáticamente la fila única en `user_gamification` con `local_id = 'local'`, `quetzal_xp = 0`, `quetzal_level = 1`, `current_streak = 0`, `longest_streak = 0`, `xolotl_shields = 1`.
  - Inserta automáticamente los 4 slots vacíos en `chinampa_slots` con `slot_index` `0`, `1`, `2` y `3`.

---

### 4.4 Ajustes y Preferencias Locales (`AppSettingsService` — `Tarea 1.6`)
Ubicación: `lib/core/settings/app_settings_service.dart` y `app_settings_provider.dart`.

- **Modelo Inmutable `AppSettingsState`** con las 9 claves exactas de `CONTEXT.md` §5C:
  1. `onboardingDone` (`'onboarding_done'`, `bool`, default: `false`)
  2. `adultConfirmed` (`'adult_confirmed'`, `bool`, default: `false`)
  3. `audioEnabled` (`'audio_enabled'`, `bool`, default: `false`)
  4. `reduceMotion` (`'reduce_motion'`, `bool`, default: `false`)
  5. `reminderEnabled` (`'reminder_enabled'`, `bool`, default: `false`)
  6. `reminderTime` (`'reminder_time'`, `String?`, formato `'HH:mm'`, default: `'20:00'`)
  7. `lastAstralReadingDate` (`'last_astral_reading_date'`, `String?`, formato `'YYYY-MM-DD'`, default: `null`)
  8. `trustedContactName` (`'trusted_contact_name'`, `String?`, default: `null`)
  9. `trustedContactPhone` (`'trusted_contact_phone'`, `String?`, default: `null`)
- **Providers expuestos:**
  - `appSettingsServiceProvider`: `Provider<AppSettingsService>` (permite `overrideWithValue` en tests usando `AppSettingsService.createForTesting(prefs)`).
  - `appSettingsProvider`: `NotifierProvider<AppSettingsNotifier, AppSettingsState>` con métodos asíncronos reactivos para actualizar cada propiedad y notificar a la UI inmediatamente.

---

### 4.5 Aislamiento Gráfico (`SafeAnimationWrapper` — `Tarea 1.7`)
Ubicación: `lib/core/performance/safe_animation_wrapper.dart`.

- Es un `ConsumerWidget` que escucha `appSettingsProvider.select((s) => s.reduceMotion)` y `MediaQuery.disableAnimationsOf(context)`.
- Envuelve toda salida en `RepaintBoundary` -> `TickerMode(enabled: isVisible && !effectiveReduceMotion)`.
- Constructores disponibles:
  - `SafeAnimationWrapper(...)`: Constructor general con `fallbackWidget` obligatorio, `child` opcional, `assetPath` opcional, `isVisible` y `fallbackBehavior`.
  - `SafeAnimationWrapper.rive(...)` y `SafeAnimationWrapper.lottie(...)`: Constructores con `childBuilder` que verifican la existencia del asset y el estado de `reduceMotion` antes de instanciar la animación.

---

### 4.6 Bóveda Biométrica y Onboarding +18 (`Tarea 1.8`)
Ubicación: `lib/core/security/` y `lib/features/0_onboarding/`.

1. **`BiometricVaultService` (`lib/core/security/biometric_vault_service.dart`):**
   - Implementa `WidgetsBindingObserver`. Cuando el ciclo de vida de la app pasa a `paused`, `inactive`, `detached` o `hidden`, emite `BiometricVaultState.locked` en su `stateStream`.
   - Al volver a `resumed`, solicita autenticación mediante `BiometricAuthInterface` (`local_auth` con `stickyAuth: true` y `biometricOnly: false` para permitir PIN/patrón del sistema como respaldo).
   - Si el dispositivo no cuenta con hardware biométrico ni bloqueo configurado (`BiometricAuthResult.notAvailable`), permite el paso seguro sin bloquear ni crashear la app.
   - Para pruebas de integración cuenta con `BiometricVaultService.setInstanceForTesting(vaultService)`.
2. **Flujo de Onboarding (`lib/features/0_onboarding/onboarding_flow.dart`):**
   - Máquina de estados controlada por `OnboardingFlowController`:
     - `welcome` -> Muestra `OnboardingWelcomeScreen` con `LegalTexts.avisoPrincipal`.
     - `adultConfirmation` -> Muestra `OnboardingAdultConfirmationScreen`.
       - Si responde **NO (<18 años)**: Transiciona a `minorBlocked` (`OnboardingMinorBlockScreen`), muestra teléfonos de ayuda y **NO** marca `adult_confirmed` ni `onboarding_done`.
       - Si responde **SÍ (+18 años)**: Guarda `adult_confirmed = true` y avanza a `trustedContact`.
     - `trustedContact` -> Muestra `OnboardingTrustedContactScreen` (permite guardar nombre/teléfono o saltar paso).
     - `preferences` -> Muestra `OnboardingPreferencesScreen` (switches para `audio_enabled` y `reduce_motion`, ambos en `false` por defecto).
     - `completed` -> Guarda `onboarding_done = true`, invalida `onboardingStatusProvider` y navega hacia `ProtectedMainScreen`.

---

## 5. HOJA DE RUTA PENDIENTE

La fuente de verdad es `ROADMAP.md`. Resumen:

### 5.1 Fase 1B: correcciones (tareas 1.9 a 1.14)
- **1.9** Configuración de plataforma Android/iOS (`allowBackup="false"`, `USE_BIOMETRIC`, `<queries>`, `FlutterFragmentActivity`, claves de iOS).
- **1.10** `AnimationCacheService` y pausa de animaciones por ciclo de vida.
- **1.11** `user_inventory.quantity` con valor por defecto 1.
- **1.12** Candado de la app: bloquea solo tras más de 30 s en segundo plano, nunca por `inactive`, con interruptor `app_lock_enabled`.
- **1.13** Textos legales aprobados, mensaje de la persona de confianza y paso de consentimiento en el onboarding (`privacy_consent_accepted`).
- **1.14** Auditoría de catálogos (tabla de diferencias antes de cambiar nada) y renombre de `docs/etapa_3_...`.

### 5.2 Fase 2: Santuario, Diario y Red de Apoyo (SOS)
- **2.1** `DiaryEntry`, `PrehispanicEmotion` y `DiaryRepository` (guardar, buscar por fechas, contar emociones de 7 días).
- **2.2** `SafetyGuardService` (lista en `assets/data/crisis_patterns.json`, con frases con contexto, excepciones y pruebas de falsos positivos como "cortarme el pelo" o "morirme de risa"), `SupportContactService` y `SupportNetworkModal`. También se abre desde la pantalla de bloqueo sin autenticar.
- **2.3** `EmotionWeatherSelector` con los 5 climas. **Fuente de verdad (`CONTEXT.md` §5D):**
  1. `tlaloc_lluvia`: tristeza, melancolía
  2. `tonatiuh_sol`: alegría, calma, gratitud
  3. `ehecatl_viento`: ansiedad, estrés, abrumo
  4. `mixcoatl_tormenta`: enojo, frustración
  5. `metztli_noche`: cansancio, agotamiento
- **2.4** `SanctuaryJournalScreen`: pergamino, botón "Necesito apoyo", `TickerMode` con teclado, filtro SOS (sin bloquear el guardado, marcando `triggered_sos`), entrega de la Pluma de Sabiduría.
- **2.5** `DiaryHistoryScreen` **provisional**; se elimina al terminar el Códice Privado (4.4).

### 5.3 Decisiones ya tomadas por el dueño del proyecto
- El nombre de la app es **Mi Calli**; exportación `.calli`.
- Clases del SOS: `SafetyGuardService`, `SupportContactService`, `SupportNetworkModal`.
- Mensaje de la persona de confianza: el de `CONTEXT.md` punto 2.
- Candado de la app: según `CONTEXT.md` punto 19.

---

## 6. PROTOCOLO DE TRABAJO PARA EL AGENTE IA
1. **Avanzar tarea por tarea** siguiendo el orden numérico de `ROADMAP.md`.
2. **Al concluir cada tarea**, ejecutar obligatoriamente:
   - `flutter analyze` (debe arrojar `No issues found!`)
   - `flutter test` (todos los tests existentes + los nuevos de la tarea deben pasar)
3. **No marcar `[x]` en `ROADMAP.md`** hasta que el usuario revise el resumen de la tarea y dé su confirmación explícita.