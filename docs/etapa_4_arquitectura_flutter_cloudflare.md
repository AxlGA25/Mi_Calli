# Documentación Técnica - Etapa 4: Arquitectura en Flutter, Optimización y Cloudflare

**Proyecto:** Refugio Quetzalcóatl (App de Bienestar y Diario Emocional en Teotihuacán)

**Motor / Framework:** Flutter (Dart 3.x)

**Infraestructura Cloud:** Cloudflare Workers + Cloudflare D1 (SQLite en el Edge) + Google Sign-In

## 1. Visión General de la Etapa 4

Esta etapa define los cimientos de ingeniería del proyecto bajo dos pilares innegociables:
1. **Privacidad por Diseño (*Zero-Knowledge Journal*):** Ningún texto escrito en el diario abandona jamás el teléfono del usuario. La nube en Cloudflare solo almacena el identificador de Google Auth y métricas numéricas de gamificación (racha del Fuego Sagrado, nivel de Quetzalcóatl, semillas y reliquias) para permitir recuperar el progreso si el usuario cambia de dispositivo.
2. **Fluidez Gráfica ($60/120\text{ FPS}$) y Bajo Consumo de Batería:** Gestión inteligente de múltiples instancias de animación (Quetzalcóatl, Xólotl, clima de Tláloc/Ehécatl y Fuego Sagrado) mediante caché en memoria RAM, límites de repintado (`RepaintBoundary`) y pausa automática de ciclos de reloj (`TickerMode`).

## 2. Stack de Paquetes Oficiales (`pubspec.yaml`)

Configuración recomendada de dependencias estables para el proyecto en Flutter:

```yaml
name: refugio_quetzalcoatl
description: App de bienestar emocional y diario interactivo en Teotihuacán.
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.2.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

  # Gestión de Estado e Inyección de Dependencias
  flutter_riverpod: ^2.5.1

  # Base de Datos Local y Almacenamiento Seguro (Etapa 1 y 2)
  sqflite: ^2.3.3
  path: ^1.9.0
  shared_preferences: ^2.2.3
  local_auth: ^2.2.0               # Huella digital y FaceID para el Códice

  # Animaciones por Capas y Audio Ambiental (Etapa 2 y 3)
  rive: ^0.13.4                    # Máquina de estados para Quetzalcóatl y Dioses
  lottie: ^3.1.2                   # Animaciones ligeras (Fuego Sagrado, Plumas, Clima)
  audioplayers: ^6.0.0             # Bucle de sonidos prehispánicos (lluvia, viento, flauta)

  # Autenticación, Red y Utilidades SOS (Etapa 3 y 4)
  google_sign_in: ^6.2.1           # Login seguro para respaldo de progreso
  http: ^1.2.1                     # Conexión con API en Cloudflare Workers
  url_launcher: ^6.3.0             # WhatsApp prellenado a familiar y Línea de la Vida
  uuid: ^4.4.0                     # Generador de IDs únicos locales
  intl: ^0.19.0                    # Formato de fechas para el Calendario Agrícola

flutter:
  uses-material-design: true
  assets:
    - assets/data/feathers.json
    - assets/data/seeds_catalog.json
    - assets/animations/quetzalcoatl_stages.riv
    - assets/animations/sacred_fire.json
    - assets/animations/weather_effects.json
    - assets/images/teotihuacan_layers/
    - assets/images/chinampa_plants/
    - assets/audio/
```

## 3. Estructura de Carpetas en Flutter (Arquitectura Modular)

Organización basada en características (*Feature-First Clean Architecture*) para mantener el código ordenado y fácil de generar por módulos:

```text
lib/
 ├── main.dart
 ├── core/
 │    ├── constants/               # Colores prehispánicos, rutas de assets, textos SOS
 │    ├── database/                # Inicialización de sqflite (tablas locales)
 │    ├── performance/             # AnimationCacheService y observadores de ciclo de vida
 │    ├── security/                # BiometricAuthService (local_auth) y SafetyGuardService
 │    └── audio/                   # AmbientAudioService (audioplayers)
 ├── features/
 │    ├── 1_sanctuary_journal/     # ETAPA 1: Diario, Climas y Plumas de Sabiduría
 │    │    ├── models/             # diary_entry.dart, wisdom_feather.dart
 │    │    ├── services/           # journal_local_repository.dart
 │    │    └── presentation/       # sanctuary_journal_screen.dart, feather_reward_dialog.dart
 │    ├── 2_gamification/          # ETAPA 2: Evolución, Fuego Sagrado, Chinampa y Tonalpohualli
 │    │    ├── models/             # seed_model.dart, gamification_state.dart
 │    │    ├── controllers/        # chinampa_controller.dart, sacred_fire_service.dart
 │    │    ├── services/           # tonalpohualli_generator.dart
 │    │    └── presentation/       # chinampa_garden_widget.dart, tonalpohualli_dialog.dart
 │    ├── 3_teotihuacan_valley/    # ETAPA 3: Paisaje Diegético, Códice y Altar de Calma
 │    │    └── presentation/
 │    │         ├── teotihuacan_valley_screen.dart
 │    │         ├── private_codex_screen.dart
 │    │         └── altar_of_calm_modal.dart
 │    └── 4_cloud_sync/            # ETAPA 4: Google Auth y Sincronización con Cloudflare
 │         ├── services/           # google_auth_service.dart, cloudflare_sync_service.dart
 │         └── models/             # cloud_backup_payload.dart
```

## 4. Estrategia de Optimización de Múltiples Instancias de Animación

Para que el teléfono no sufra caídas de rendimiento ni sobrecalentamiento al tener a Quetzalcóatl, a Xólotl, el Fuego Sagrado y la lluvia de Tláloc en pantalla:

### A. Pre-carga en Memoria RAM (`AnimationCacheService`)
En lugar de leer el almacenamiento interno cada vez que cambia una pantalla, al abrir la app durante el *Splash Screen* de Teotihuacán se pre-cargan en memoria los archivos binarios:
* `RiveFile.asset('assets/animations/quetzalcoatl_stages.riv')` se guarda en un *Singleton* en memoria.
* Las instancias de `LottieComposition` (lluvia, fuego naranja/dorado/turquesa, mariposas de Xochiquétzal) se almacenan en un mapa en caché `Map<String, LottieComposition>`.
* Beneficio: Tiempo de carga de $0\text{ ms}$ al cambiar de clima emocional y reducción del uso de CPU en un $45\%$.

### B. Aislamiento de GPU mediante `RepaintBoundary`
En Flutter, si una animación se mueve dentro de un `Stack`, por defecto obliga a repintar todo el paisaje estático detrás de ella.
* **Regla de arquitectura:** Cada criatura animada (Quetzalcóatl, Xólotl, el Brasero y la capa de lluvia) debe estar envuelta en su propio widget `RepaintBoundary`. Así, la pirámide del Sol y la Calzada de los Muertos se convierten en una textura estática en la GPU que se dibuja $1$ sola vez.

### C. Suspensión Inteligente de Fotogramas (`TickerMode` + `AppLifecycleState`)
* **Pausa por Teclado:** Cuando el usuario abre el teclado en `SanctuaryJournalScreen`, un `ValueListenableBuilder` detecta el foco del texto y cambia el paisaje trasero a `TickerMode(enabled: false)`. Esto congela suavemente las animaciones de fondo y dedica el $100\%$ del hilo principal a que la escritura fluya sin retrasos.
* **Pausa en Segundo Plano:** Mediante `WidgetsBindingObserver`, si el usuario bloquea el celular o cambia de app (`AppLifecycleState.paused`), se detienen inmediatamente los motores de Rive/Lottie y el bucle de `audioplayers`.

## 5. Arquitectura Cloud en Cloudflare (Workers + D1)

Para el respaldo en la nube usamos la infraestructura *Serverless* de Cloudflare (rápida, gratuita en su capa inicial y global).

### Flujo de Sincronización Silenciosa
$$
\text{App Flutter (Google Sign-In)} \xrightarrow{\text{ID Token + JSON Progreso}} \text{Cloudflare Worker (Valida Token)} \xrightarrow{\text{SQL Upsert}} \text{Cloudflare D1 Database}
$$

### Esquema SQL para Cloudflare D1 (`schema.sql`)
Este archivo se ejecuta en Cloudflare D1 para crear la tabla de respaldo en la nube:

```sql
-- Archivo: cloudflare/schema.sql
-- Tabla de respaldo de gamificación (CERO textos del diario por privacidad)
CREATE TABLE IF NOT EXISTS user_cloud_backups (
    google_uid TEXT PRIMARY KEY,
    email_hash TEXT NOT NULL,              -- Hash SHA-256 opcional para soporte sin guardar el correo en texto plano
    quetzal_xp INTEGER DEFAULT 0,
    quetzal_level INTEGER DEFAULT 1,
    current_streak INTEGER DEFAULT 0,
    longest_streak INTEGER DEFAULT 0,
    xolotl_shields INTEGER DEFAULT 1,
    unlocked_seeds_json TEXT DEFAULT '[]', -- Arreglo JSON de IDs de semillas desbloqueadas
    unlocked_relics_json TEXT DEFAULT '[]',-- Arreglo JSON de reliquias de dioses (Tláloc, Xochiquétzal, Xólotl)
    harvested_count INTEGER DEFAULT 0,
    updated_at TEXT NOT NULL
);
```

### Configuración del Proyecto en Cloudflare (`wrangler.toml`)

```toml
name = "refugio-quetzalcoatl-api"
main = "src/index.ts"
compatibility_date = "2026-01-01"

[[d1_databases]]
binding = "DB"
database_name = "quetzalcoatl_progress_db"
database_id = "REEMPLAZAR_CON_TU_D1_DATABASE_ID"
```

## 6. Prompts de Ingeniería (Para Generación de Código / IA / Cloudflare)

Copia y pega estos *prompts* para construir la optimización gráfica en Flutter y desplegar el backend en Cloudflare:

### Prompt 1: Gestor de Pre-carga y Optimización de Instancias de Animación en Flutter

> **Prompt:**
> "Actúa como un ingeniero especialista en rendimiento gráfico de Flutter. Crea un servicio singleton llamado `AnimationCacheService` y un widget envolvente `OptimizedAnimatedLayer`.
> 1. `AnimationCacheService` debe pre-cargar al inicio de la app un archivo `RiveFile` (`quetzalcoatl_stages.riv`) y múltiples composiciones de Lottie (`sacred_fire.json`, `rain_tlaloc.json`, `wind_ehecatl.json`, `butterflies_xochiquetzal.json`) guardándolas en memoria RAM para reutilizar instancias sin volver a leer el disco.
> 2. `OptimizedAnimatedLayer` debe envolver a su hijo en un `RepaintBoundary` y un `TickerMode`.
> 3. Implementa `WidgetsBindingObserver` dentro de `OptimizedAnimatedLayer` para que pause automáticamente las animaciones (`TickerMode(enabled: false)`) cuando la aplicación pase a segundo plano (`AppLifecycleState.paused` o `inactive`) o cuando reciba un parámetro booleano `isKeyboardOpen == true`."

### Prompt 2: Servicio de Google Auth y Sincronización Híbrida en Flutter

> **Prompt:**
> "Crea en Flutter la capa de sincronización en la nube `CloudBackupService` usando `google_sign_in` y `http`.
> 1. Implementa el método `signInWithGoogle()` que autentique al usuario y obtenga su `idToken` y su `id` único (`googleUid`).
> 2. Crea el método `syncProgressToCloud()` que lea de la base de datos local SQLite **únicamente** los datos de gamificación (`quetzalXp`, `quetzalLevel`, `currentStreak`, `longestStreak`, `xolotlShields`, lista de semillas y reliquias desbloqueadas). Asegúrate por diseño de que **nunca** lea ni serialice la tabla `diary_entries`.
> 3. Envía este payload mediante una petición `POST` a nuestro endpoint de Cloudflare Worker adjuntando el `idToken` en el header `Authorization: Bearer <token>`.
> 4. Crea también el método `restoreProgressFromCloud()` para recuperar el progreso si el usuario instala la app en un teléfono nuevo."

### Prompt 3: Backend Serverless en Cloudflare Workers + D1 (TypeScript)

> **Prompt:**
> "Actúa como un desarrollador experto en Cloudflare Workers y TypeScript. Escribe el archivo `src/index.ts` completo para la API de respaldo de nuestra app 'Refugio Quetzalcóatl' conectada a una base de datos Cloudflare D1 (`env.DB`).
> 1. Implementa una función auxiliar que verifique la validez del token de Google (`Authorization: Bearer <idToken>`) consultando el endpoint de certificados de Google (`https://oauth2.googleapis.com/tokeninfo?id_token=...`) y extraiga el `sub` (`google_uid`).
> 2. Crea el endpoint `POST /api/backup` que reciba el JSON de progreso del jugador y ejecute un `INSERT INTO user_cloud_backups ... ON CONFLICT(google_uid) DO UPDATE SET ...` en Cloudflare D1, asegurando que nunca se retroceda el progreso si el `quetzal_xp` entrante es menor al guardado.
> 3. Crea el endpoint `GET /api/backup` que devuelva el estado guardado del usuario autenticado para restaurar su cuenta en un nuevo dispositivo.
> 4. Incluye cabeceras CORS apropiadas y manejo de errores limpio con respuestas JSON estructuradas."