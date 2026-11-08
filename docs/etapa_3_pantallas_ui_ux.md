# Documentación Técnica - Etapa 3: Pantallas y Flujo de Usuario (UI/UX)

**Proyecto:** Refugio Quetzalcóatl (App de Bienestar y Diario Emocional en Teotihuacán)  
**Motor / Framework:** Flutter (Dart)  
**Paradigma de Diseño:** Interfaz Diegética (*Cozy Zero-UI*) + Accesibilidad Emocional  

---

## 1. Visión General de la Etapa 3

El diseño visual y de experiencia de usuario evita la apariencia de una aplicación clínica o de un formulario tradicional. No existen barras de navegación inferiores (*BottomNavigationBar*) ni menús laterales saturados. Toda la interacción ocurre de forma orgánica tocando elementos vivos dentro de una ilustración multicapa del **Valle de Teotihuacán**.

---

## 2. Mapa de Navegación Diegética ("El Valle de Teotihuacán")

La pantalla principal (`TeotihuacanValleyScreen`) actúa como el centro neurálgico (*Hub*). Cada elemento arquitectónico o natural del paisaje es un área interactiva (*Hitbox*):

| Elemento en el Paisaje | Ubicación en Pantalla | Acción al Tocar (`onTap`) | Pantalla / Modal Destino |
| :--- | :--- | :--- | :--- |
| **Quetzalcóatl** (y Xólotl de noche) | Centro / Altar Principal | Abre el pergamino para seleccionar el clima emocional y escribir. | `SanctuaryJournalScreen` (Etapa 1) |
| **La Chinampa Sagrada** | Parte inferior (Primer plano) | Hace un *zoom* suave hacia las $4$ parcelas para plantar semillas o ver reliquias de dioses. | `ChinampaDetailModal` |
| **Templo de los Códices** | Costado izquierdo de la Calzada | Solicita huella/PIN (`local_auth`) y abre el calendario agrícola de entradas pasadas. | `PrivateCodexScreen` |
| **Brasero del Fuego Sagrado** | Pie de la escalinata central | Muestra los días de racha actuales, el color del fuego y los escudos del *Manto de Xólotl*. | `SacredFireStatusSheet` |
| **Caracol Prehispánico (*Atecocolli*)** | Esquina superior derecha (Flotante discreto) | Abre de inmediato el espacio de regulación emocional y emergencia. | `AltarOfCalmModal` (Respiración + SOS) |
| **Constelación de Venus** *(Solo fines de semana)* | Cielo superior | Despliega la lectura astral de los últimos $7$ días. | `TonalpohualliScrollDialog` |
| **Icono de Flauta de Barro** | Esquina superior izquierda | Activa/silencia el motor de sonidos ambientales prehispánicos. | Acción directa (`AudioService.toggleMute()`) |

---

## 3. Ciclo de Día y Noche en Tiempo Real + Audio Ambiental

Al abrir la aplicación, un controlador verifica la hora local del dispositivo (`DateTime.now().hour`) y adapta la atmósfera de Teotihuacán automáticamente:

| Fase del Día | Rango Horario | Gradiente del Cielo (Hex) | Elementos Dinámicos en Escena | Audio Base (Bucle) |
| :--- | :--- | :--- | :--- | :--- |
| **Amanecer (*Tlahuizcalpan*)** | $06:00 - 08:59$ | `#FF9E80` $\rightarrow$ `#FFD180` | Neblina suave al ras de la Calzada de los Muertos; sol naciendo detrás de la Pirámide del Sol. | Canto de aves del valle y brisa matutina. |
| **Día Solar (*Tonatiuh*)** | $09:00 - 17:59$ | `#48CAE4` $\rightarrow$ `#ADE8F4` | Nubes altas despejadas; mariposas de Xochiquétzal activas en la chinampa. | Viento suave en pastizales y flauta lejana. |
| **Atardecer (*Nepantla*)** | $18:00 - 19:59$ | `#9D4EDD` $\rightarrow$ `#E76F51` | Sombras largas proyectadas por las pirámides; se encienden los primeros braseros. | Viento cálido y fuego crepitando suave. |
| **Noche Estrellada (*Metztli*)** | $20:00 - 05:59$ | `#0F172A` $\rightarrow$ `#1E1B4B` | Cielo estrellado, antorchas encendidas, luciérnagas en el jardín y **Xólotl** durmiendo junto a Quetzalcóatl. | Grillos nocturnos, lechuzas y agua tranquila. |

*Nota:* Cuando el usuario selecciona manualmente una emoción para escribir en su diario (ej. *Lluvia de Tláloc*), el clima emocional se superpone temporalmente sobre el ciclo horario.

---

## 4. El Códice Privado (Biometría + Calendario Agrícola)

Para garantizar que nadie ajeno pueda leer los desahogos si toma el teléfono desbloqueado:

1. **Barrera Biométrica (`local_auth`):**
   * Al tocar el Templo de los Códices, se invoca `LocalAuthentication().authenticate()`.
   * Soporta Huella Digital, FaceID o el PIN/Patrón nativo del sistema operativo.
2. **Vista de Calendario Agrícola (No listas de texto aburridas):**
   * Se muestra una cuadrícula mensual estilo piedra calendárica.
   * Cada día registrado muestra dos indicadores visuales en miniatura:
     * **Fondo de la celda:** El icono del clima que predominó ese día (gota de Tláloc, sol de Tonatiuh, espiral de Ehécatl, etc.).
     * **Centro de la celda:** El brote o flor que creció gracias a ese desahogo (ej. una flor de cempasúchil o una tuna).
3. **Detalle de Memoria:**
   * Al tocar un día específico del calendario, se abre el pergamino con el texto íntimo que escribió el usuario, la hora exacta y la **Pluma de Sabiduría** que Quetzalcóatl le regaló en esa ocasión.

---

## 5. El "Altar de Calma" (Respiración de Ehécatl + Red de Apoyo Dual)

Diseñado para momentos de alta ansiedad o crisis donde el usuario necesita contención inmediata en menos de $2$ toques.

### A. Respiración Guiada con Ehécatl (Dios del Viento)
Un ejercicio interactivo visual y háptico (vibración suave del teléfono) con el ritmo fisiológico $4 - 4 - 6$:
* **Inhalar ($4\text{ s}$):** Las plumas de Quetzalcóatl y un círculo de jade se expanden suavemente.
* **Sostener ($4\text{ s}$):** El círculo brilla con luz turquesa estática.
* **Exhalar ($6\text{ s}$):** Las plumas descienden lentamente liberando partículas de viento.
* *Recompensa compasiva:* Completar $3$ ciclos de respiración también cuenta para mantener encendido el **Fuego Sagrado** si el usuario no tiene ánimos de escribir ese día.

### B. Red de Apoyo Dual (SOS Empático)
Consta de configuración previa de un contacto seguro en `SharedPreferences` (`trusted_contact_name`, `trusted_contact_phone`) y dos botones de acción directa:

1. **Opción 1: "Pedir compañía a mi persona de confianza" (Familiar / Amigo)**
   * Usa `url_launcher` para abrir WhatsApp (o SMS como respaldo) directamente en el chat del contacto elegido con el siguiente mensaje prellenado para evitar que el usuario tenga que pensar qué escribir:
   * > *"Hola [Nombre], te escribo desde mi app de refugio porque en este momento no me siento muy bien emocionalmente y me ayudaría mucho platicar o sentir tu compañía. ¿Tienes un momento?"*
2. **Opción 2: "Hablar con un especialista (Línea de la Vida México)"**
   * Para usuarios que no tienen un familiar disponible o prefieren ayuda profesional anónima las $24\text{ horas}$.
   * Ejecuta `launchUrl(Uri.parse('tel:8009112000'))`.

---

## 6. Arquitectura de Capas Visuales en Flutter (`Stack` Optimizado)

Para lograr que el paisaje de Teotihuacán se vea vivo a $60/120\text{ FPS}$ sin consumir batería excesiva, la pantalla principal se estructura en $5$ capas aisladas:

$$
\text{Layer 0 (Cielo)} \prec \text{Layer 1 (Pirámides)} \prec \text{Layer 2 (Clima)} \prec \text{Layer 3 (Quetzalcóatl y Chinampa)} \prec \text{Layer 4 (HUD Discreto)}
$$

```text
Stack (TeotihuacanValleyScreen)
 ├── 0. AnimatedContainer (Gradiente Cielo Día/Noche/Clima)
 ├── 1. Static Background ( Pirámide del Sol, Luna y Calzada - PNG/SVG cacheado )
 ├── 2. RepaintBoundary -> WeatherParticlesWidget (Lluvia de Tláloc / Estrellas / Viento)
 ├── 3. Interactive Elements Layer:
 │    ├── Positioned (Templo del Códice - GestureDetector)
 │    ├── Positioned (Brasero Fuego Sagrado - Rive/Lottie ligero)
 │    ├── Positioned (Quetzalcóatl + Xólotl - RepaintBoundary + Rive State Machine)
 │    └── Positioned (Chinampa Sagrada - 4 Slots interactivos)
 └── 4. SafeArea HUD Superior:
      ├── Botón Audio Ambiental (Izquierda)
      └── Botón Altar de Calma / Caracol SOS (Derecha)
```

---

## 7. Prompts de Ingeniería (Para Generación de Código / IA)

Copia y pega estos *prompts* para generar las pantallas y componentes de la Etapa 3 en Flutter:

### Prompt 1: Pantalla Principal Interactiva "El Valle de Teotihuacán" y Ciclo Día/Noche
> **Prompt:**  
> "Actúa como un desarrollador experto en UI/UX con Flutter. Crea la pantalla principal `TeotihuacanValleyScreen` usando un enfoque de interfaz diegética (sin `BottomNavigationBar`).
> 1. Implementa un método que detecte la hora actual (`DateTime.now().hour`) y configure automáticamente 4 estados atmosféricos: Amanecer ($6-8$), Día ($9-17$), Atardecer ($18-19$) y Noche ($20-5$), cambiando los colores del cielo con un `AnimatedContainer`.
> 2. Construye un `Stack` optimizado donde el fondo sean las pirámides de Teotihuacán, y coloca áreas interactivas (`Positioned` + `GestureDetector`) para:
>    - Tocar a Quetzalcóatl en el centro (navega al diario).
>    - Tocar el Brasero del Fuego Sagrado (muestra modal de racha).
>    - Tocar la Chinampa en la parte inferior (abre selector de semillas).
>    - Tocar el Templo de los Códices a la izquierda (abre el historial protegido).
> 3. Envuelve a Quetzalcóatl y a las partículas del clima en widgets `RepaintBoundary` independientes para garantizar máximo rendimiento gráfico. Si es de noche ($20:00$ a $05:59$), muestra también al compañero Xólotl descansando junto a Quetzalcóatl."

### Prompt 2: El Códice Privado con Huella Digital (`local_auth`) y Calendario Agrícola
> **Prompt:**  
> "Crea en Flutter el módulo del historial íntimo llamado `PrivateCodexScreen`.
> 1. Antes de renderizar el contenido, ejecuta un servicio de autenticación biométrica con el paquete `local_auth` (`authenticate(localizedReason: 'Usa tu huella para abrir tu Códice Sagrado')`). Si falla o se cancela, regresa a la pantalla principal.
> 2. Una vez autenticado, muestra una vista mensual tipo 'Calendario Agrícola Prehispánico' usando un `GridView.builder`.
> 3. Cada celda del día que tenga un registro en SQLite debe mostrar el icono del clima emocional de ese día (Tláloc, Tonatiuh, Ehécatl, Mixcóatl, Metztli) y el brote de la planta regada.
> 4. Al tocar un día con registro, abre un diálogo estilizado como pergamino antiguo mostrando el texto completo del desahogo y la 'Pluma de Sabiduría' obtenida en esa fecha."

### Prompt 3: Modal del "Altar de Calma" (Respiración de Ehécatl $4-4-6$ y Red de Apoyo Dual)
> **Prompt:**  
> "Desarrolla en Flutter el widget `AltarOfCalmModal` que se abre desde el botón de emergencia emocional en la esquina superior derecha. Debe tener dos pestañas o secciones claras:
> 1. **Respiración de Ehécatl:** Una animación fluida controlada por un `AnimationController` que guíe al usuario en el ciclo $4\text{ segundos}$ inhalar (círculo color jade se expande), $4\text{ segundos}$ mantener, y $6\text{ segundos}$ exhalar (se contrae suavemente), incluyendo vibración ligera con `HapticFeedback.lightImpact()` en cada cambio de fase. Al completar 3 ciclos, llama a la función para mantener vivo el Fuego Sagrado del día.
> 2. **Red de Apoyo Dual (SOS):**
>    - Permite guardar o editar el nombre y teléfono de un familiar/amigo de confianza en `SharedPreferences`.
>    - Botón 1 ('Pedir compañía a mi contacto de confianza'): usa `url_launcher` para abrir WhatsApp con el teléfono guardado y el texto codificado: *'Hola, te escribo desde mi refugio porque en este momento no me siento bien y me ayudaría mucho tu compañía. ¿Podemos hablar?'*.
>    - Botón 2 ('Línea de la Vida - Ayuda Profesional 24/7'): usa `url_launcher` para disparar la llamada telefónica directa al `tel:8009112000`."