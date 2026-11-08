# Documentación Técnica - Etapa 1: Mecánica Principal y el Diario
**Proyecto:** Refugio Quetzalcóatl (App de Bienestar y Diario Emocional en Teotihuacán)  
**Motor / Framework:** Flutter (Dart)  
**Almacenamiento de Etapa 1:** 100% Local (`sqflite` + Encriptación local)  

---

## 1. Visión General de la Etapa 1
Esta etapa define el núcleo interactivo de la aplicación: el proceso mediante el cual el usuario registra su estado emocional, escribe su desahogo en un entorno privado y recibe una respuesta visual/simbólica (Cosecha y Pluma de Sabiduría) sin utilizar IA generativa abierta, garantizando seguridad psicológica y privacidad absoluta.

---

## 2. Flujo de Usuario (Core Loop del Desahogo)

1. **Entrada al Altar de Escritura:** El usuario toca a Quetzalcóatl en el Valle de Teotihuacán.
2. **Selección del Clima Emocional:** Antes de mostrar el teclado, el usuario selecciona uno de los 5 estados emocionales representados por deidades y climas prehispánicos.
3. **Transición Ambiental:** El fondo (cielo de Teotihuacán) y el audio ambiental cambian en tiempo real según la selección.
4. **Escritura del Desahogo:** El usuario escribe libremente en el pergamino/códice. (En segundo plano, los controladores de animación pesada se pausan con `TickerMode` para optimizar el teclado).
5. **Verificación de Seguridad (Filtro Local SOS):** Al presionar "Entregar Ofrenda", un validador local revisa si el texto contiene palabras clave de crisis.
   * *Si detecta alerta:* Despliega suavemente el modal de la **Red de Apoyo Dual** antes de continuar.
   * *Si es seguro:* Continúa al paso 6.
6. **Transformación y Riego (El Ciclo de la Tierra):** El texto se guarda en la base de datos local (`sqflite`). El clima seleccionado "nutre" la tierra: la semilla activa en la chinampa recibe +1 punto de riego.
7. **Ofrenda de Cierre (Pluma de Sabiduría):** Quetzalcóatl realiza una animación de agradecimiento y entrega una pluma coleccionable con una frase predefinida acorde a la emoción registrada.

---

## 3. Matriz de Climas Emocionales y Deidades

Cada emoción está vinculada a un fenómeno natural en Teotihuacán, una paleta de colores y un efecto de riego específico:

| ID (`emotion_id`) | Emoción / Estado | Deidad / Clima Prehispánico | Efecto Visual en Teotihuacán | Audio Ambiental |
| :--- | :--- | :--- | :--- | :--- |
| `tlaloc_lluvia` | Tristeza / Melancolía | **Lluvia de Tláloc** | Cielo gris azulado, lluvia suave cayendo sobre las pirámides. | Lluvia constante y trueno lejano suave. |
| `tonatiuh_sol` | Alegría / Calma / Gratitud | **Sol de Tonatiuh** | Cielo despejado, rayos cálidos dorados sobre la Pirámide del Sol. | Viento suave, aves del valle y flauta de barro. |
| `ehecatl_viento` | Ansiedad / Estrés / Abrumo | **Viento de Ehécatl** | Nubes rápidas, hojas y pétalos volando por la Calzada de los Muertos. | Brisa de viento envolvente y hojas secas. |
| `mixcoatl_tormenta` | Enojo / Frustración | **Tormenta de Mixcóatl** | Cielo rojizo/púrpura de atardecer intenso, nubes densas. | Fuego crepitando en los braseros y viento fuerte. |
| `metztli_noche` | Cansancio / Agotamiento | **Noche de Metztli** | Cielo nocturno estrellado, niebla baja al pie del templo y luciérnagas. | Grillos nocturnos y agua corriendo en calma. |

---

## 4. Esquema de Datos Local (SQLite) para Etapa 1

El contenido del diario **nunca** se envía a servidores externos. Se almacena localmente en el dispositivo del usuario.

### Tabla: `diary_entries` (Entradas del Códice)
```sql
CREATE TABLE diary_entries (
    id TEXT PRIMARY KEY,               -- UUID v4 generado localmente
    created_at TEXT NOT NULL,          -- Fecha y hora en formato ISO-8601
    emotion_id TEXT NOT NULL,          -- FK: tlaloc_lluvia, tonatiuh_sol, etc.
    content TEXT NOT NULL,             -- Texto íntimo del usuario
    feather_id TEXT NOT NULL,          -- ID de la pluma entregada en esa sesión
    watered_seed_id TEXT,              -- ID de la planta que recibió el riego
    triggered_sos INTEGER DEFAULT 0    -- Booleano (0 o 1) para control interno local
);
```

### Catálogo Estático: `wisdom_feathers` (Plumas de Sabiduría)
Archivo JSON local (`assets/data/feathers.json`) con mensajes curados y seguros:
```json
[
  {
    "feather_id": "pluma_tlaloc_01",
    "emotion_id": "tlaloc_lluvia",
    "name": "Pluma de Rocío de Jade",
    "color_hex": "#2A9D8F",
    "message": "Incluso la tierra más sagrada necesita de la lluvia para volver a florecer. Tus lágrimas hoy son el agua que dará vida mañana."
  },
  {
    "feather_id": "pluma_tonatiuh_01",
    "emotion_id": "tonatiuh_sol",
    "name": "Pluma de Rayo Dorado",
    "color_hex": "#E9C46A",
    "message": "El calor de tus pensamientos ilumina el valle. Guarda esta claridad en tu corazón para los días de niebla."
  },
  {
    "feather_id": "pluma_ehecatl_01",
    "emotion_id": "ehecatl_viento",
    "name": "Pluma de Brisa Turquesa",
    "color_hex": "#48CAE4",
    "message": "El viento mueve las ramas, pero las raíces del ahuehuete permanecen firmes. Respira; esta ráfaga también pasará."
  },
  {
    "feather_id": "pluma_mixcoatl_01",
    "emotion_id": "mixcoatl_tormenta",
    "name": "Pluma de Obsidiana y Fuego",
    "color_hex": "#E76F51",
    "message": "Soltar el fuego interno evita que te queme por dentro. Has entregado tu carga al templo; ahora puedes descansar."
  },
  {
    "feather_id": "pluma_metztli_01",
    "emotion_id": "metztli_noche",
    "name": "Pluma de Luz Estelar",
    "color_hex": "#9D4EDD",
    "message": "Hasta el mismo Sol descansa bajo la tierra cada noche. Permítete pausar sin culpa; las estrellas cuidan tu sueño."
  }
]
```

---

## 5. Filtro Local de Seguridad (Detector de Crisis Cero-IA)

Para proteger al usuario sin violar su privacidad ni depender de conexión a internet:
* Se ejecuta una función síncrona en Dart (`SafetyFilterService.checkContent(String text)`).
* Normaliza el texto (minúsculas, sin acentos) y verifica coincidencias con una lista local de expresiones regulares de riesgo (autolesión, ideación suicida, desesperanza extrema).
* Si devuelve `true`, antes de mostrar la animación de la pluma, invoca un `ModalBottomSheet` cálido con dos acciones directas mediante `url_launcher`:
  1. **Contactar a mi Red de Confianza:** Abre WhatsApp/SMS con el contacto preconfigurado y el mensaje: *"Hola, en este momento no me siento bien y necesito compañía, ¿podemos hablar?"*.
  2. **Línea de la Vida (México):** Abre el marcador telefónico al `800 911 2000`.

---

## 6. Prompts de Ingeniería (Para Generación de Código / IA / Cloudflare)

Puedes copiar y pegar estos *prompts* directamente en tu asistente de programación (Cursor, Copilot, Claude, ChatGPT o Workers AI) para generar los módulos exactos de esta Etapa 1:

### Prompt 1: Generación de Modelos y Base de Datos Local en Flutter
> **Prompt:**  
> "Actúa como un arquitecto senior de Flutter. Necesito crear la capa de persistencia local para la Etapa 1 de una app de diario emocional ambientada en Teotihuacán.  
> 1. Utiliza el paquete `sqflite` y `path`.  
> 2. Crea el modelo `DiaryEntry` con los campos: `id` (String), `createdAt` (DateTime), `emotionId` (Enum: `tlalocLluvia`, `tonatiuhSol`, `ehecatlViento`, `mixcoatlTormenta`, `metztliNoche`), `content` (String), `featherId` (String), `wateredSeedId` (String?), y `triggeredSos` (bool).  
> 3. Crea un singleton `LocalDatabaseService` con métodos CRUD para guardar una entrada, obtener entradas por rango de fechas (para el calendario agrícola) y contar cuántas veces se ha usado cada emoción en los últimos 7 días.  
> Escribe código limpio, con tipado fuerte y manejo de excepciones."

### Prompt 2: Generación de la Pantalla de Desahogo y Clima Dinámico
> **Prompt:**  
> "Crea un widget de pantalla completa en Flutter llamado `SanctuaryJournalScreen`.  
> 1. La pantalla debe permitir al usuario seleccionar uno de los 5 climas emocionales (`tlalocLluvia`, `tonatiuhSol`, `ehecatlViento`, `mixcoatlTormenta`, `metztliNoche`) mediante botones circulares con iconos y colores prehispánicos.  
> 2. Al cambiar la emoción, el fondo de la pantalla debe transicionar suavemente usando un `AnimatedContainer` con gradientes que representen el cielo de Teotihuacán para esa emoción.  
> 3. Incluye un `TextField` multilínea estilizado como un pergamino/códice antiguo pero minimalista y cómodo para leer.  
> 4. Cuando el `FocusNode` del `TextField` esté activo (teclado abierto), envuelve las animaciones de fondo en un `TickerMode(enabled: false)` para garantizar 60 FPS sin lag al escribir.  
> 5. Al presionar el botón 'Entregar Ofrenda a Quetzalcóatl', ejecuta la validación de seguridad y luego muestra un diálogo animado entregando la 'Pluma de Sabiduría' correspondiente."

### Prompt 3: Servicio de Seguridad y Filtro de Palabras Clave (SOS)
> **Prompt:**  
> "Escribe una clase en Dart llamada `SafetyGuardService` para una aplicación de salud emocional en México.  
> 1. Debe incluir un método estático `bool containsCrisisKeywords(String input)` que normalice el texto (quitando tildes y pasándolo a minúsculas) y evalúe de forma local si existen frases o palabras asociadas con autolesión o crisis severa.  
> 2. Crea también el widget `SupportNetworkModal` que se muestra cuando el método devuelve `true`. Este modal debe tener un diseño empático, cálido y no alarmista, ofreciendo dos botones usando el paquete `url_launcher`:  
>    - Botón 1: 'Escribir a mi persona de confianza' (abre un enlace `https://wa.me/$phone?text=...` con un mensaje prellenado pidiendo compañía).  
>    - Botón 2: 'Llamar a la Línea de la Vida (800 911 2000)' (abre `tel:8009112000`)."