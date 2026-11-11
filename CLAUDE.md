# CLAUDE.md - Mi Calli

Antes de hacer cualquier cosa, lee en este orden:
1. `CONTEXT.md` (qué es el proyecto y las decisiones de contrato)
2. `INSTRUCTIONS.md` (reglas obligatorias)
3. `ROADMAP.md` (plan por tareas)
4. `docs/HANDOFF_FASE_1.md` (qué existe ya construido en el proyecto)

Los detalles de cada etapa están en `docs/`. Lee **solo** la etapa que corresponda a la tarea en curso, no todas a la vez. Si algo de `docs/` contradice la sección 6 de `CONTEXT.md`, gana `CONTEXT.md`.

## Reglas rápidas
- Trabaja **una tarea del ROADMAP a la vez**, en orden.
- Al terminar, corre `flutter analyze` y `flutter test`, dime el resultado y **espera mi visto bueno** antes de seguir (salvo que yo te pida explícitamente encadenar tareas).
- No marques `[x]` en `ROADMAP.md` hasta que yo lo confirme.
- No agregues funciones, paquetes ni cambios que no estén en el plan. Si tienes una idea, proponla y espera mi respuesta.
- No inventes assets (animaciones, audios, ilustraciones).
- El texto del diario nunca sale del teléfono, nunca se sube a la nube, nunca se imprime en consola y nunca se manda a un modelo de IA.
- No pegues llaves, tokens ni identificadores privados en archivos del proyecto.
- Si algo es ambiguo o dos documentos se contradicen, pregúntame.

## Entorno de Windows (importante)
La ruta del usuario de Windows tiene espacios y eso rompe la descompresión de `rive_native`. En cada terminal nueva, antes de compilar, ejecuta:
```powershell
$env:TEMP="C:\Temp"
$env:TMP="C:\Temp"
$env:PUB_CACHE="C:\PubCache"
```
Si tu shell es bash (por ejemplo, cuando corres comandos desde esta herramienta), la sintaxis de PowerShell falla. Usa:
export TEMP="C:/Temp" TMP="C:/Temp" PUB_CACHE="C:/PubCache"

Para `flutter test` normalmente no hace falta definir estas variables. No las antepongas a cada comando.

## Fuente de verdad
- El código real manda. Si algún documento (HANDOFF, etapas, etc.) contradice el código, dime la diferencia y corrige el documento, no el código, salvo que yo diga lo contrario.
- Los documentos sobre el estado del código (HANDOFF) solo los genera o actualiza esta herramienta leyendo el disco. Si otra IA los redacta, se marcan como "sin verificar".

## Límites de seguridad
- No hagas `git commit`, `git push` ni `git reset`, y no borres archivos fuera de este proyecto. Los commits los hago yo.
- No ejecutes comandos que instalen cosas globales ni toques archivos fuera de `C:\Mi calli\mi_calli`.