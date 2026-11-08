# Documentación Técnica - Etapa 2: Crecimiento, Dioses y el Refugio en Teotihuacán

**Proyecto:** Refugio Quetzalcóatl (App de Bienestar y Diario Emocional en Teotihuacán)

**Motor / Framework:** Flutter (Dart)

**Almacenamiento de Etapa 2:** Híbrido (Progreso en `sqflite` local + Respaldo numérico en la nube vinculado a Google Auth UID)

## 1. Visión General de la Etapa 2

Esta etapa transforma la constancia del usuario en un progreso visual y simbólico dentro del Valle de Teotihuacán. Se descartan por completo los rankings competitivos para evitar ansiedad; en su lugar, toda la gamificación gira en torno al autocuidado: alimentar el Fuego Sagrado, cultivar plantas endémicas de México mediante el riego emocional, presenciar la evolución de Quetzalcóatl y recibir la lectura astral semanal (*Tonalpohualli*).

## 2. Evolución de Quetzalcóatl (Sistema de Niveles)

Quetzalcóatl crece conforme el usuario acumula **Plumas de Sabiduría** (1 desahogo completado $= 1$ pluma $= +10\text{ XP}$).

| Nivel | Nombre de la Etapa | Plumas Requeridas | Apariencia Visual | Ubicación en el Paisaje |
| :--- | :--- | :--- | :--- | :--- |
| **Nivel 1** | *Cóatl de Jade* (Cría) | $0 - 4$ | Pequeña serpiente verde esmeralda con ojos brillantes, sin plumas, saliendo de un cascarón de piedra. | Acostada sobre el altar al pie de la escalinata. |
| **Nivel 2** | *Aprendiz del Viento* | $5 - 14$ | Le brotan pequeñas plumas verdes de quetzal en la cabeza y la punta de la cola. | Se desliza entre las plantas de la Chinampa. |
| **Nivel 3** | *Guardián Emplumado* | $15 - 29$ | Cuerpo cubierto de plumas iridiscentes, collar de caracoles y pectorales de jade. | Levita suavemente sobre la Calzada de los Muertos. |
| **Nivel 4** | *Señor de la Aurora (Tlahuizcalpantecuhtli)* | $30 - 49$ | Gran serpiente emplumada con penacho dorado y estela de polvo estelar turquesa. | Vuela alrededor de la Pirámide de la Luna. |
| **Nivel 5** | *Quetzalcóatl Supremo* | $\ge 50$ | Deidad majestuosa completa, resplandor solar y plumaje real largo que reacciona al clima. | Domina el cielo sobre la Pirámide del Sol y baja al altar cuando el usuario la toca. |

## 3. Sistema de Racha: "El Fuego Sagrado" (Brasero del Templo)

En la base de la pirámide existe un brasero ceremonial (*Cuauhxicalli*). Cada día que el usuario registra al menos una entrada o realiza un ejercicio de respiración en el Altar de Calma, el fuego se aviva.

### Reglas de Negocio del Fuego Sagrado
* **Fuego Cálido ($1 \text{ a } 3$ días):** Llama de color naranja tradicional; otorga $+1$ semilla común al cumplir el día $3$.
* **Fuego Solar ($4 \text{ a } 6$ días):** Llama intensa color oro; otorga $+1$ semilla rara al cumplir el día $6$.
* **Fuego Místico de Quetzalcóatl ($\ge 7$ días):** Llama de color azul turquesa y jade con chispas flotantes; desbloquea semillas sagradas y atrae visitas de otros dioses.
* **Protección Empática ("El Manto de Xólotl"):** Si un usuario olvida entrar un día por estar abrumado, la racha **no se destruye de golpe**. El dios Xólotl cubre las brasas y mantiene la "chispa encendida" hasta por $48\text{ horas}$ (se consume 1 *Amuleto de Obsidiana*, el cual se recarga cada 7 días de racha).

## 4. La Chinampa Sagrada (Ciclo de Cultivo Mexicano)

El jardín al pie de las pirámides cuenta con **4 espacios de cultivo (slots)**. El usuario elige qué semilla plantar y la riega automáticamente cada vez que entrega una ofrenda escrita en su diario.

### Fases de Crecimiento de cada Planta
$$\text{Fase 0: Semilla} \xrightarrow{+1\text{ Riego}} \text{Fase 1: Brote} \xrightarrow{+1\text{ Riego}} \text{Fase 2: Planta Joven} \xrightarrow{+1\text{ Riego}} \text{Fase 3: Cosecha Florecida}$$

*(Las semillas especiales requieren $4\text{ riegos}$ en total para llegar a la Fase 3).*

### Catálogo Estático de Semillas (`assets/data/seeds_catalog.json`)

```json
[
  {
    "seed_id": "seed_cempasuchil",
    "name": "Cempasúchil (Flor de 20 Pétalos)",
    "rarity": "comun",
    "waterings_needed": 3,
    "affinity_emotion": "tlaloc_lluvia",
    "description": "Sus pétalos guardan la luz del sol para guiar e iluminar los días nublados.",
    "sprite_stages": ["cemp_0.png", "cemp_1.png", "cemp_2.png", "cemp_3_full.png"]
  },
  {
    "seed_id": "seed_nopal_tunas",
    "name": "Nopal con Tunas Rojas",
    "rarity": "comun",
    "waterings_needed": 3,
    "affinity_emotion": "mixcoatl_tormenta",
    "description": "Símbolo de fortaleza; capaz de dar los frutos más dulces incluso en tierras áridas y difíciles.",
    "sprite_stages": ["nopal_0.png", "nopal_1.png", "nopal_2.png", "nopal_3_full.png"]
  },
  {
    "seed_id": "seed_maiz_morado",
    "name": "Maíz Sagrado (Centéotl)",
    "rarity": "comun",
    "waterings_needed": 3,
    "affinity_emotion": "tonatiuh_sol",
    "description": "El sustento de la vida y la creación; crece alto buscando los rayos dorados del valle.",
    "sprite_stages": ["maiz_0.png", "maiz_1.png", "maiz_2.png", "maiz_3_full.png"]
  },
  {
    "seed_id": "seed_maguey",
    "name": "Maguey de Mayáhuel",
    "rarity": "rara",
    "waterings_needed": 4,
    "affinity_emotion": "ehecatl_viento",
    "description": "Sus pencas firmes resisten cualquier vendaval con paciencia y raíces profundas.",
    "sprite_stages": ["maguey_0.png", "maguey_1.png", "maguey_2.png", "maguey_3_full.png"]
  },
  {
    "seed_id": "seed_cacao",
    "name": "Árbol de Cacao Real",
    "rarity": "sagrada",
    "waterings_needed": 4,
    "affinity_emotion": "tonatiuh_sol",
    "description": "Fruto de los dioses que reconforta el corazón cansado y celebra la constancia.",
    "sprite_stages": ["cacao_0.png", "cacao_1.png", "cacao_2.png", "cacao_3_full.png"]
  },
  {
    "seed_id": "seed_dalia",
    "name": "Dalia Imperial (Acocoxóchitl)",
    "rarity": "rara",
    "waterings_needed": 3,
    "affinity_emotion": "tlaloc_lluvia",
    "description": "Flor nacional de tallos huecos que almacenan agua fresca tras la tormenta.",
    "sprite_stages": ["dalia_0.png", "dalia_1.png", "dalia_2.png", "dalia_3_full.png"]
  },
  {
    "seed_id": "seed_vainilla",
    "name": "Orquídea de Vainilla (Xanath)",
    "rarity": "sagrada",
    "waterings_needed": 4,
    "affinity_emotion": "metztli_noche",
    "description": "Aroma suave que florece en la calma y acompaña el descanso profundo.",
    "sprite_stages": ["vainilla_0.png", "vainilla_1.png", "vainilla_2.png", "vainilla_3_full.png"]
  }
]
```
*Nota de bonificación:* Si el usuario riega una planta usando la emoción de afinidad (`affinity_emotion`), el riego vale doble ($+2$).

## 5. Visitas y Reliquias de Otros Dioses

Sin saturar la pantalla, ciertos hitos activan apariciones pacíficas en el escenario y desbloquean reliquias decorativas permanentes para Teotihuacán:

1. **Tláloc (Dios de la Lluvia):**
   * *Condición:* Registrar $3$ entradas con el clima `tlaloc_lluvia`.
   * *Interacción:* Su máscara aparece formada en las nubes sobre la Pirámide de la Luna y deja una **Vasija Ceremonial de Jade** junto a la chinampa.
2. **Xochiquétzal (Diosa de las Flores y el Amor Propio):**
   * *Condición:* Cosechar por completo ($100\%$) tus primeras $3$ plantas en la chinampa.
   * *Interacción:* Rodea el jardín con **Mariposas Monarca animadas** que se quedan revoloteando permanentemente en los días soleados.
3. **Xólotl (El Perro Guía Espiritual y Gemelo de Quetzalcóatl):**
   * *Condición:* Escribir en el diario después de las $21:00\text{ hrs}$ o usar el clima `metztli_noche` $2$ veces.
   * *Interacción:* Un perro xoloitzcuintle místico con grabados luminosos aparece acostado al lado de Quetzalcóatl durante las noches para hacerle compañía.

## 6. El Tonalpohualli (Lectura Astral y Análisis Semanal)

Cada domingo (o al cumplirse 7 días desde el último reporte), se activa en el cielo nocturno de la app el pergamino del **Tonalpohualli** (la cuenta de los días).

### Algoritmo Local de Lectura Astral (Cero IA externa)
El motor calcula el vector de frecuencias emocionales de los últimos 7 días:
$$V = \{n_{\text{lluvia}}, n_{\text{sol}}, n_{\text{viento}}, n_{\text{tormenta}}, n_{\text{noche}}\}$$

1. **Identificación del Astro Regente:** Se determina cuál fue la emoción predominante $\max(V)$ de la semana.
2. **Conteo de Cosechas:** Suma cuántas semillas avanzaron de etapa o florecieron en esos 7 días ($C_{\text{total}}$).
3. **Generación de la Lectura por Plantillas Modulares:**
   * *Apertura (según $\max(V)$):* Ej. Si predominó `tlaloc_lluvia`: *"Los sabios observadores del cielo vieron que las aguas de Tláloc bañaron tu valle esta semana..."*
   * *Cuerpo (según $C_{\text{total}}$):* *"Pero ninguna gota fue en vano: tu honestidad al desahogarte dio vida a $C_{\text{total}}$ brotes en tu chinampa, demostrando que de la melancolía también nacen flores de cempasúchil."*
   * *Augurio de Venus (Cierre motivacional):* *"El lucero de la mañana (Quetzalcóatl) brilla en tu horizonte. Para el nuevo ciclo de 7 días, permite que el viento de Ehécatl limpie tu mente."*

## 7. Esquema de Datos (SQLite + Respaldo en Nube)

### Tablas Locales Adicionales (`sqflite`)

```sql
-- Estado general del jugador, racha y nivel de Quetzalcoatl
CREATE TABLE user_gamification (
    google_uid TEXT PRIMARY KEY,
    quetzal_xp INTEGER DEFAULT 0,
    quetzal_level INTEGER DEFAULT 1,
    current_streak INTEGER DEFAULT 0,
    longest_streak INTEGER DEFAULT 0,
    last_checkin_date TEXT,            -- YYYY-MM-DD
    xolotl_shields INTEGER DEFAULT 1   -- Protectores de racha disponibles
);

-- Estado de las 4 parcelas de la Chinampa
CREATE TABLE chinampa_slots (
    slot_index INTEGER PRIMARY KEY,    -- 0, 1, 2, 3
    seed_id TEXT,                      -- NULL si está vacía
    current_waterings INTEGER DEFAULT 0,
    is_harvested INTEGER DEFAULT 0,    -- 0: creciendo, 1: florecida
    planted_at TEXT
);

-- Inventario de semillas y reliquias desbloqueadas
CREATE TABLE user_inventory (
    item_id TEXT PRIMARY KEY,          -- seed_id o relic_id
    item_type TEXT NOT NULL,           -- 'SEED' o 'RELIC'
    quantity INTEGER DEFAULT 1,
    unlocked_at TEXT NOT NULL
);
```

### Payload JSON de Respaldo en la Nube (Cloudflare D1 / KV o Firebase)
Solo se sincroniza este objeto ligero asociado al `google_uid` (jamás incluye el texto del diario):

```json
{
  "google_uid": "usr_987654321",
  "last_sync": "2026-11-07T23:55:00Z",
  "quetzal_xp": 180,
  "quetzal_level": 3,
  "current_streak": 8,
  "unlocked_relics": ["relic_vasija_tlaloc", "relic_xolotl_companion"],
  "harvested_plants_count": 5
}
```

## 8. Prompts de Ingeniería (Para Generación de Código / IA / Cloudflare)

Copia y pega estos *prompts* para construir los módulos de la Etapa 2:

### Prompt 1: Motor de Racha "Fuego Sagrado" y Evolución de Quetzalcóatl
> **Prompt:**
> "Actúa como un desarrollador experto en Flutter. Necesito implementar el servicio de gamificación `SacredFireAndEvolutionService` para la Etapa 2 de nuestra app en Teotihuacán.
> 1. Crea la lógica para calcular el nivel de Quetzalcóatl (del Nivel 1 al 5) basado en la experiencia acumulada (`quetzalXp`, donde cada pluma suma $+10\text{ XP}$).
> 2. Implementa el método `updateDailyStreak(DateTime now)` que evalúa la fecha del último registro (`lastCheckinDate`):
>    - Si fue ayer, incrementa `currentStreak` en $+1$.
>    - Si fue hace 2 días y el usuario tiene `xolotlShields > 0`, consume $1$ escudo ('El Manto de Xólotl'), mantiene la racha intacta y devuelve un estado `StreakStatus.savedByXolotl`.
>    - Si pasaron más días sin escudo, reinicia la racha a $1$ con un mensaje compasivo.
> 3. Agrega un getter que devuelva el color e intensidad del Fuego Sagrado según los días de racha ($1-3$ Naranja, $4-6$ Dorado, $\ge 7$ Turquesa Místico)."

### Prompt 2: Gestor de la Chinampa Sagrada y Ciclo de Riego
> **Prompt:**
> "Crea un controlador de estado en Flutter (usando `ChangeNotifier` o `Riverpod`) llamado `ChinampaController` junto con su widget visual `ChinampaGardenWidget`.
> 1. Debe manejar 4 espacios de cultivo (`ChinampaSlot`).
> 2. Incluye el método `plantSeed(int slotIndex, String seedId)` y el método `waterActivePlants(EmotionType currentEmotion)`.
> 3. Cuando `waterActivePlants` se ejecuta tras escribir en el diario, todas las semillas plantadas que aún no han florecido suman $+1$ a `currentWaterings` (o $+2$ si `currentEmotion` coincide con la `affinityEmotion` de la semilla).
> 4. Si `currentWaterings >= wateringsNeeded`, marca la planta como florecida (`isHarvested = true`) y dispara una notificación para revisar si aparece la diosa Xochiquétzal."

### Prompt 3: Generador Local del "Tonalpohualli" (Lectura Semanal) y Worker de Respaldo en Cloudflare
> **Prompt:**
> "Necesito dos componentes para cerrar la Etapa 2 de mi aplicación:
> 1. **En Dart (Flutter):** Una clase `TonalpohualliGenerator` que reciba la lista de entradas locales de los últimos 7 días, cuente qué emoción (`tlalocLluvia`, `tonatiuhSol`, `ehecatlViento`, `mixcoatlTormenta`, `metztliNoche`) se repitió más y cuántas plantas fueron regadas, y devuelva un objeto `WeeklyAstralReading` con un título místico prehispánico y un párrafo de retroalimentación empática armado mediante plantillas locales.
> 2. **En TypeScript (Cloudflare Worker + D1):** Un endpoint ligero `POST /api/sync-progress` que valide un token de Google Auth y guarde/actualice en una tabla de Cloudflare D1 únicamente los datos no sensibles del usuario (`google_uid`, `quetzal_xp`, `quetzal_level`, `current_streak`, `unlocked_relics`)."