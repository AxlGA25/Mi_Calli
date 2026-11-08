# Tabla de Diferencias: Catálogos JSON vs Documentos de Especificación

## Resumen Ejecutivo

**✅ Ambos catálogos coinciden exactamente con las especificaciones de Etapa 1 y Etapa 2.** No hay diferencias que corregir.

---

## 1. `feathers.json` (Plumas de Sabiduría) vs **Etapa 1** (`docs/etapa_1_mecanica_diario.md`)

| Campo | Etapa 1 (Espec) | `feathers.json` (Actual) | Estado |
|-------|-----------------|--------------------------|--------|
| **Cantidad de entradas** | 5 | 5 | ✅ Igual |
| **pluma_tlaloc_01** | `emotion_id: tlaloc_lluvia`<br>`name: Pluma de Rocío de Jade`<br>`color: #2A9D8F` | Idéntico | ✅ Match |
| **pluma_tonatiuh_01** | `emotion_id: tonatiuh_sol`<br>`name: Pluma de Rayo Dorado`<br>`color: #E9C46A` | Idéntico | ✅ Match |
| **pluma_ehecatl_01** | `emotion_id: ehecatl_viento`<br>`name: Pluma de Brisa Turquesa`<br>`color: #48CAE4` | Idéntico | ✅ Match |
| **pluma_mixcoatl_01** | `emotion_id: mixcoatl_tormenta`<br>`name: Pluma de Obsidiana y Fuego`<br>`color: #E76F51` | Idéntico | ✅ Match |
| **pluma_metztli_01** | `emotion_id: metztli_noche`<br>`name: Pluma de Luz Estelar`<br>`color: #9D4EDD` | Idéntico | ✅ Match |
| **Mensajes (message)** | 5 frases curadas según emoción | Idénticas palabra por palabra | ✅ Match |
| **Estructura JSON** | Array de objetos con `feather_id`, `emotion_id`, `name`, `color_hex`, `message` | Mismo orden y campos | ✅ Match |

**Conclusión feathers.json:** ✅ **Sin cambios necesarios.** El catálogo está completo y fiel a la especificación de Etapa 1.

---

## 2. `seeds_catalog.json` (Catálogo de Semillas) vs **Etapa 2** (`docs/etapa_2_gamificacion_teotihuacan.md`)

| Campo | Etapa 2 (Espec) | `seeds_catalog.json` (Actual) | Estado |
|-------|-----------------|-------------------------------|--------|
| **Cantidad de entradas** | 7 | 7 | ✅ Igual |

### Comparación detallada por semilla:

| seed_id | name | rarity | waterings_needed | affinity_emotion | description | sprite_stages | Estado |
|---------|------|--------|------------------|------------------|-------------|---------------|--------|
| `seed_cempasuchil` | Cempasúchil (Flor de 20 Pétalos) | comun | 3 | tlaloc_lluvia | Sus pétalos guardan la luz del sol... | 4 etapas | ✅ Match |
| `seed_nopal_tunas` | Nopal con Tunas Rojas | comun | 3 | mixcoatl_tormenta | Símbolo de fortaleza; capaz de dar... | 4 etapas | ✅ Match |
| `seed_maiz_morado` | Maíz Sagrado (Centéotl) | comun | 3 | tonatiuh_sol | El sustento de la vida y la creación... | 4 etapas | ✅ Match |
| `seed_maguey` | Maguey de Mayáhuel | rara | 4 | ehecatl_viento | Sus pencas firmes resisten cualquier... | 4 etapas | ✅ Match |
| `seed_cacao` | Árbol de Cacao Real | sagrada | 4 | tonatiuh_sol | Fruto de los dioses que reconforta... | 4 etapas | ✅ Match |
| `seed_dalia` | Dalia Imperial (Acocoxóchitl) | rara | 3 | tlaloc_lluvia | Flor nacional de tallos huecos que... | 4 etapas | ✅ Match |
| `seed_vainilla` | Orquídea de Vainilla (Xanath) | sagrada | 4 | metztli_noche | Aroma suave que florece en la calma... | 4 etapas | ✅ Match |

### Detalles adicionales verificados:
- **Rarezas:** 3 `comun`, 2 `rara`, 2 `sagrada` ✅
- **Afinidades emocionales:** Cada emoción tiene al menos 1 semilla (tlaloc: 2, tonatiuh: 2, mixcoatl: 1, ehecatl: 1, metztli: 1) ✅
- **Waterings_needed:** 3 para comunes/rara (salvo dalia=3), 4 para sagradas ✅
- **sprite_stages:** Todas tienen 4 archivos (fase 0-3) ✅
- **Orden en JSON:** Coincide con el orden del documento Etapa 2 ✅

**Conclusión seeds_catalog.json:** ✅ **Sin cambios necesarios.** El catálogo está completo y fiel a la especificación de Etapa 2.

---

## 3. Verificación de Documentos en `docs/`

| Archivo | Existe | Notas |
|---------|--------|-------|
| `etapa_1_mecanica_diario.md` | ✅ | Etapa 1 completa |
| `etapa_2_gamificacion_teotihuacan.md` | ✅ | Etapa 2 completa |
| `etapa_3_pantallas_ui_ux.md` | ✅ | **Renombrado** (era `etapa_3_ui_ux_animaciones.md`) |
| `etapa_4_arquitectura_flutter_cloudflare.md` | ✅ | Etapa 4 completa |
| `HANDOFF_FASE_1.md` | ✅ | Documento de entrega Fase 1 |
| `privacidad_y_avisos_borrador.md` | ✅ | Textos legales aprobados (Parte A) |

**Total: 6 archivos ✅** (4 etapas + HANDOFF + privacidad)

---

## Recomendación

**No se requiere ninguna modificación en `feathers.json` ni en `seeds_catalog.json`.** Ambos archivos son fieles reflejos de las especificaciones documentadas en Etapa 1 y Etapa 2 respectivamente.

El renombrado de `etapa_3_ui_ux_animaciones.md` → `etapa_3_pantallas_ui_ux.md` **ya está completado**.

La carpeta `docs/` contiene todos los 6 archivos requeridos.