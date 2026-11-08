# Mi Calli - Textos de aviso y privacidad (BORRADOR)

> **Importante:** este es un borrador para que lo apruebes. No es asesoría legal. Antes de publicar, que lo revise alguien con conocimiento en protección de datos en México. Los campos entre `[CORCHETES]` los llenas tú.
>
> Contiene tres partes:
> - **Parte A:** textos cortos dentro de la app (van en `core/constants/legal_texts.dart`).
> - **Parte B:** Aviso de privacidad integral (va en `docs/privacidad.md` y se publica en una URL pública).
> - **Parte C:** datos para el formulario de seguridad de datos de Play Store y notas para el revisor.

---

## PARTE A. Textos dentro de la app

### A1. Bienvenida (`welcomeTitle`, `welcomeBody`)
**Título:** Bienvenido a tu refugio
**Texto:** Aquí puedes desahogarte a tu ritmo, en privado. Quetzalcóatl te acompañará en silencio mientras escribes y cuidas tu pequeño valle. Todo lo que escribes se queda en tu teléfono.

### A2. Mayoría de edad (`ageGateTitle`, `ageGateBody`, `ageGateConfirm`, `ageGateDecline`)
**Título:** Antes de entrar
**Texto:** Esta app es solo para personas mayores de 18 años.
**Botón principal:** Tengo 18 años o más
**Botón secundario:** Soy menor de 18

### A3. Pantalla para menores (`underageTitle`, `underageBody`)
**Título:** Gracias por decirnos
**Texto:** Por ahora este refugio es solo para personas adultas, así que no podemos continuar. Si hoy te sientes mal, no tienes que pasarlo solo o sola: puedes hablar con alguien de confianza o llamar gratis a la Línea de la Vida al 800 911 2000, las 24 horas. Si es una emergencia, marca al 911.
**Botones:** Llamar a la Línea de la Vida · Llamar al 911

### A4. Aviso importante (`disclaimerTitle`, `disclaimerBody`)
**Título:** Un aviso importante
**Texto:** Mi Calli es un espacio de bienestar y autocuidado. No es un servicio médico, psicológico ni de emergencias, y no sustituye la atención de una persona profesional. Si estás en peligro o necesitas ayuda urgente, llama al 911. Si necesitas hablar con alguien, la Línea de la Vida (800 911 2000) atiende gratis las 24 horas.
**Enlace:** Leer aviso de privacidad

### A5. Resumen de privacidad (`privacySummaryTitle`, `privacySummaryBody`)
**Título:** Tu diario es solo tuyo
**Texto:**
- Lo que escribes se guarda cifrado en este teléfono. Nunca lo enviamos a ningún servidor.
- Tu progreso (nivel, racha, plantas) solo se respalda en la nube si tú inicias sesión con Google.
- No usamos publicidad ni compartimos tus datos.
- Puedes exportar tu diario cifrado cuando quieras.
**Botón:** Ver aviso de privacidad completo

### A6. Respaldo en la nube (`cloudConsentTitle`, `cloudConsentBody`)
**Título:** Respaldar mi progreso
**Texto:** Si inicias sesión con Google, guardaremos en la nube únicamente tu progreso numérico: nivel de Quetzalcóatl, días de racha, plantas y reliquias desbloqueadas. **Tu diario no se sube.** Si cambias de teléfono, podrás recuperar este progreso. Puedes pedir que se elimine tu respaldo en cualquier momento.
**Botones:** Continuar con Google · Ahora no

### A7. Contacto de confianza (`contactExplain`)
**Texto:** Puedes guardar a una persona de confianza. Su nombre y teléfono se quedan solo en tu teléfono. Si algún día lo necesitas, la app abrirá WhatsApp con un mensaje listo para que tú decidas si lo envías. Nunca enviamos nada sin que tú lo toques.

### A8. Exportar diario (`exportWarningTitle`, `exportWarningBody`)
**Título:** Exportar mi diario
**Texto:** Se creará un archivo cifrado con tu diario y tu progreso. Elige una contraseña que recuerdes: **no la guardamos y, si la olvidas, no podremos recuperar el archivo.** Guarda el archivo en un lugar seguro; quien tenga el archivo y la contraseña podrá leerlo.

### A9. Importar diario (`importConfirm`)
**Texto:** Vas a agregar al refugio las entradas de este archivo. No se borrarán las que ya tienes ni se duplicarán las repetidas. Necesitarás la contraseña con la que lo exportaste.

### A10. Recordatorio (`reminderExplain`, `reminderNotificationText`)
**Explicación:** Si quieres, te enviamos un recordatorio amable a la hora que elijas. Puedes apagarlo cuando quieras. El permiso de notificaciones solo se pide al activarlo.
**Texto de la notificación:** Tu refugio te espera cuando quieras pasar. 🌿

### A12. Consentimiento (`consentTitle`, `consentBody`, `consentCheck`, `consentDeclineBody`)
**Título:** Tu consentimiento
**Texto:** Lo que escribes en Mi Calli puede hablar de cómo te sientes, y eso es información delicada. Para guardarlo en este teléfono, cifrado y solo para ti, necesitamos tu permiso. No lo enviamos a ningún servidor.
**Casilla:** Entiendo y acepto que Mi Calli guarde mis entradas cifradas en este teléfono.
**Botones:** Continuar · Ahora no
**Si elige "Ahora no":** Sin tu permiso no podemos guardar tus entradas, así que por ahora no podemos continuar. Cuando quieras, aquí estaremos.

### A11. Eliminar mi respaldo (`deleteBackupTitle`, `deleteBackupBody`)
**Título:** Eliminar mi respaldo
**Texto:** Se borrará de la nube el progreso que respaldaste con tu cuenta de Google. Tu diario y tu progreso en este teléfono no se tocan. Después podrás volver a respaldar si quieres. Esta acción no se puede deshacer.
**Botones:** Eliminar respaldo · Cancelar

---

## PARTE B. Aviso de Privacidad Integral (para publicar en una URL)

**Mi Calli - Aviso de Privacidad**
Última actualización: `[FECHA]`

### 1. Quién es el responsable
El responsable del tratamiento de tus datos personales es `[NOMBRE COMPLETO DE LA PERSONA O RAZÓN SOCIAL]`, con domicilio en `[DOMICILIO]` y correo de contacto `[CORREO DE CONTACTO]` (en adelante, "el Responsable").

### 2. Qué es esta aplicación
Mi Calli es una aplicación de bienestar y diario personal. No es un servicio médico, psicológico, de diagnóstico ni de emergencias, y no sustituye la atención de profesionales de la salud. Es solo para personas mayores de 18 años.

### 3. Qué datos tratamos y dónde se quedan

**3.1. Datos que se quedan únicamente en tu teléfono (el Responsable no los recibe ni puede leerlos):**
- El texto de tus entradas del diario y la emoción que elegiste en cada una, con su fecha y hora. *Estos datos pueden revelar tu estado de ánimo o de salud emocional, por lo que se consideran datos personales sensibles.*
- Tu progreso en el juego (nivel, racha, plantas, reliquias).
- El nombre y teléfono de la persona de confianza que decidas guardar (datos de un tercero que tú proporcionas).
- Tus ajustes (sonido, reducción de movimiento, recordatorio).
- Una marca interna que indica si el aviso de apoyo se mostró en alguna entrada. No sale del teléfono.

El diario se guarda en una base de datos cifrada en tu teléfono. La app no lo incluye en copias de seguridad automáticas del sistema.

**3.2. Datos que se envían a la nube solo si tú decides iniciar sesión con Google (respaldo opcional):**
- Identificador de tu cuenta de Google y una versión cifrada irreversible (hash) de tu correo.
- Tu progreso numérico: nivel y experiencia de Quetzalcóatl, días de racha actual y más larga, escudos de protección, semillas y reliquias desbloqueadas, número de plantas cosechadas y fecha de la última actualización.

**Nunca se envía a la nube el texto de tu diario, las emociones que registras, tu contacto de confianza ni tus ajustes.**

Para este respaldo usamos servicios de terceros: Google (inicio de sesión) y Cloudflare (almacenamiento del respaldo). Estos proveedores tratan los datos por cuenta del Responsable y bajo sus propias políticas de privacidad.

**3.3. Datos que no recopilamos:** no usamos publicidad, no incluimos analíticas ni rastreadores de terceros, no accedemos a tu ubicación, contactos ni fotos, y no vendemos ni compartimos tus datos.

### 4. Para qué usamos los datos (finalidades)

**Finalidades necesarias para que la app funcione:**
- Guardar tu diario y mostrarte tu calendario de entradas en tu teléfono.
- Calcular tu progreso, tu racha y tu lectura semanal en tu teléfono.
- Mostrarte, cuando detecte ciertas palabras de riesgo, opciones de apoyo (como la Línea de la Vida). Esta revisión se hace **solo en tu teléfono**, sin conexión, y su resultado no se envía a nadie.
- Si inicias sesión: guardar y restaurar tu progreso numérico en la nube.

**Finalidades que requieren tu consentimiento:**
- Tratar el contenido de tus entradas (dato sensible) para guardarlo y analizarlo localmente en tu teléfono. Lo pedimos al abrir la app por primera vez.
- Respaldar tu progreso en la nube (solo si inicias sesión).
- Enviarte un recordatorio local si lo activas.

No usamos tus datos para mercadotecnia, perfilamiento ni decisiones automatizadas sobre ti.

### 5. Persona de confianza
El nombre y teléfono que guardas permanecen en tu teléfono. La app solo abre WhatsApp o mensajes con un texto prellenado; **tú decides si lo envías**. Te recomendamos avisar a esa persona que la registraste.

### 6. Tus derechos
Tienes derecho a acceder, rectificar, cancelar u oponerte al tratamiento de tus datos personales (derechos ARCO), así como a revocar tu consentimiento. Dentro de la app puedes:
- Ver, exportar y borrar tu diario desde tu propio teléfono (el diario solo existe ahí).
- Desactivar el recordatorio y el respaldo en cualquier momento.
- Eliminar tu respaldo en la nube desde Ajustes, con el botón "Eliminar mi respaldo".

Para solicitar el acceso a tu respaldo, para eliminarlo si ya no tienes la app o, en general, para ejercer cualquier derecho, escribe a `[CORREO DE CONTACTO]` indicando tu nombre y el correo de tu cuenta de Google. Responderemos en un plazo máximo de `[PLAZO, por ejemplo 20 días hábiles]`. Si consideras que tus derechos no fueron atendidos, puedes acudir a la autoridad competente en materia de protección de datos personales en posesión de particulares (actualmente, la Secretaría Anticorrupción y Buen Gobierno).

### 7. Conservación
- El diario permanece en tu teléfono hasta que lo borres o desinstales la app.
- El respaldo en la nube se conserva hasta que pidas su eliminación o dejes de usar la app por `[PLAZO, por ejemplo 24 meses]`.

### 8. Seguridad
Cifrado del diario en el teléfono, llave guardada en el almacenamiento seguro del sistema, acceso biométrico o PIN para abrir el Códice, comunicaciones cifradas con la nube y validación de tu sesión de Google en cada respaldo. Ningún sistema es infalible, pero el diseño evita que el Responsable tenga acceso a lo que escribes.

### 9. Archivo exportado
Si exportas tu diario, el archivo queda bajo tu control y lo cifras con una contraseña que solo tú conoces. El Responsable no recibe ese archivo ni la contraseña.

### 10. Menores de edad
La app es solo para personas mayores de 18 años y no recopilamos intencionalmente datos de menores. Si detectamos que un menor creó un respaldo, lo eliminaremos.

### 11. Cambios a este aviso
Si cambia este aviso, publicaremos la nueva versión en `[URL PÚBLICA]` y te lo mostraremos en la app. Si el cambio implica usar tus datos para una finalidad nueva, te pediremos de nuevo tu consentimiento.

### 12. Ayuda inmediata
Si estás en peligro, llama al 911. Para hablar con alguien: Línea de la Vida, 800 911 2000, gratis, las 24 horas.

---

## PARTE C. Notas para el formulario de Play Store y para el revisor

### C1. Datos para el formulario "Seguridad de los datos" (verifícalo contra el formulario vigente al publicar)
| Dato | ¿Sale del teléfono? | Cuándo | Finalidad | Opcional | Cifrado en tránsito |
| :--- | :--- | :--- | :--- | :--- | :--- |
| Identificador de usuario (UID de Google) | Sí | Solo con inicio de sesión | Funcionalidad de la app / respaldo | Sí | Sí |
| Correo (solo como hash) | Sí | Solo con inicio de sesión | Administración de la cuenta | Sí | Sí |
| Progreso del juego (números) | Sí | Solo con inicio de sesión | Funcionalidad de la app | Sí | Sí |
| Texto del diario, emociones, contacto de confianza | **No** | Nunca | - | - | - |

Según la guía de Google, los datos que solo se procesan en el dispositivo y no salen de él no cuentan como "recopilados". Confírmalo en el formulario al publicar. La app no usa publicidad ni analíticas.

### C2. Cosas que debe revisar quien dé el visto bueno legal
1. Que el aviso cumpla los requisitos vigentes de la Ley Federal de Protección de Datos Personales en Posesión de los Particulares (en vigor desde el 21 de marzo de 2025) y no mencione al INAI, que desapareció.
2. Si, al estar el diario solo en el teléfono, el Responsable realmente "trata" esos datos o no; el borrador lo declara con transparencia de todos modos.
3. La forma de pedir el consentimiento expreso para datos sensibles en el primer arranque.
4. El mecanismo de eliminación del respaldo (botón "Eliminar mi respaldo" en Ajustes y solicitud por correo).
5. Que lo escrito sobre Google y Cloudflare coincida con sus condiciones vigentes.
6. Que el aviso refleje cualquier cambio que se haga a la app (por ejemplo, si algún día se agregan analíticas).
