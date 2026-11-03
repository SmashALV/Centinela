# Documentación de Centinela 2.0

Cada carpeta agrupa un tipo de documento. Si buscas por dónde empezar: [presentación](#presentacion) para exponer el juego, [diseño](#diseno) para entender qué es y [arquitectura](#arquitectura) para entender el código.

| Carpeta | Qué contiene |
|---|---|
| [presentacion/](presentacion/) | Guiones de exposición y grabación, explicación del código, reporte técnico y guía en Word |
| [diseno/](diseno/) | Documento de diseño (GDD), plan de trabajo y registro de decisiones |
| [guias/](guias/) | Guías para estudiantes, investigadores y recuperación de partidas |
| [historia/](historia/) | Guiones, propuestas narrativas, rúbricas, auditorías de fuentes y textos recuperados |
| [arquitectura/](arquitectura/) | Arquitectura modular, telemetría y revisión del código frente al guion |
| [implementacion/](implementacion/) | Notas de cada funcionalidad implementada (rutina, chat, presentación automática, MOBA…) |
| [arte/](arte/) | Inventario de assets y prompts para generar sprites, retratos y fondos |
| [calidad/](calidad/) | Estado de las fases, pruebas, requisitos no funcionales, operación y build de Windows |
| [diagramas/](diagramas/) | Diagramas en PNG/SVG y los scripts de Python que los generan |

<a id="presentacion"></a>
## presentacion/

- [GUION_EXPOSICION_JUGABILIDAD_2026-10-30.md](presentacion/GUION_EXPOSICION_JUGABILIDAD_2026-10-30.md): guion para exponer la jugabilidad.
- [EXPLICACION_CODIGO_PRESENTACION.md](presentacion/EXPLICACION_CODIGO_PRESENTACION.md): cómo explicar el código y los módulos.
- [GUION_GRABACION_RUTA_INICIAL.md](presentacion/GUION_GRABACION_RUTA_INICIAL.md): guion de grabación de la ruta inicial.
- `Guia_exposicion_Centinela_2_0_v0_20.docx`, `Reporte_tecnico_Centinela_2_0.docx`, `Textos_para_completar_articulo.docx`.

<a id="diseno"></a>
## diseno/

- [GDD_CENTINELA_2_0.md](diseno/GDD_CENTINELA_2_0.md): documento de diseño del juego.
- [PLAN_CODEX_CENTINELA_2_0.md](diseno/PLAN_CODEX_CENTINELA_2_0.md): plan por fases.
- [DECISION_REGISTER.md](diseno/DECISION_REGISTER.md): decisiones tomadas y por qué.

## guias/

- [STUDENT_GUIDE.md](guias/STUDENT_GUIDE.md), [RESEARCHER_GUIDE.md](guias/RESEARCHER_GUIDE.md), [RECOVERY.md](guias/RECOVERY.md).

## historia/

- Guion jugable: [PLAYABLE_DRAFT.md](historia/PLAYABLE_DRAFT.md), [GUION_EDITORIAL_CANDIDATO_v2.md](historia/GUION_EDITORIAL_CANDIDATO_v2.md) (generado por `scripts/build_candidate_script.py`) y su versión [v1](historia/GUION_EDITORIAL_CANDIDATO_v1.md).
- Historia coral: [CORAL_STORY_IMPLEMENTATION_2026-10-29.md](historia/CORAL_STORY_IMPLEMENTATION_2026-10-29.md), [SHARED_DAY_STORY_2026-10-29.md](historia/SHARED_DAY_STORY_2026-10-29.md), [PROPUESTA_HISTORIA_CORAL_15_20_MIN_v1.md](historia/PROPUESTA_HISTORIA_CORAL_15_20_MIN_v1.md).
- Día 0 y continuidad: [DAY0_PROLOGUE_2026-10-28.md](historia/DAY0_PROLOGUE_2026-10-28.md), [D0_D1_CONTINUITY_2026-10-28.md](historia/D0_D1_CONTINUITY_2026-10-28.md).
- Ramas y pistas: [GUION_RAMIFICADO_DECISIONES_TEMPRANAS_v2.md](historia/GUION_RAMIFICADO_DECISIONES_TEMPRANAS_v2.md), [ACCIONES_NARRADOR_PISTAS_POR_DIA_v3.md](historia/ACCIONES_NARRADOR_PISTAS_POR_DIA_v3.md) (+ `NARRADOR_ACCIONES_PISTAS_v3.json`).
- Rúbricas: `rubric_candidate_v1.json`, `rubric_candidate_v2.json`.
- Fuentes: [P5_SOURCE_GAPS.md](historia/P5_SOURCE_GAPS.md), [P5_ZIP_AUDIT_2026-10-28.md](historia/P5_ZIP_AUDIT_2026-10-28.md) y [recovered/](historia/recovered/) (guion literal recuperado y mapa de IDs).

<a id="arquitectura"></a>
## arquitectura/

- [ARQUITECTURA_MODULAR_PROPUESTA.md](arquitectura/ARQUITECTURA_MODULAR_PROPUESTA.md): módulos del código y avance de la migración.
- [TELEMETRIA_SUPABASE.md](arquitectura/TELEMETRIA_SUPABASE.md): eventos, guardado y sincronización.
- [REVISION_CODIGO_VS_GUION_2026_10_29.md](arquitectura/REVISION_CODIGO_VS_GUION_2026_10_29.md) (+ `revision_coral_2026_10_29.log`).

## implementacion/

- [MEJORAS_JUEGO_SERIO_2026-10-30.md](implementacion/MEJORAS_JUEGO_SERIO_2026-10-30.md): mochila, flecha, tutor, consecuencias y sonidos.
- [DAILY_ROUTINE_2026-10-29.md](implementacion/DAILY_ROUTINE_2026-10-29.md), [DIALOGUE_CHAT_2026-10-29.md](implementacion/DIALOGUE_CHAT_2026-10-29.md), [AUTOMATIC_PRESENTATION_2026-10-29.md](implementacion/AUTOMATIC_PRESENTATION_2026-10-29.md), [TEACHER_FEEDBACK_IMPLEMENTATION_2026-10-29.md](implementacion/TEACHER_FEEDBACK_IMPLEMENTATION_2026-10-29.md), [VN_PRESENTATION_2026-10-28.md](implementacion/VN_PRESENTATION_2026-10-28.md), [SLOT_MANAGEMENT_2026-10-28.md](implementacion/SLOT_MANAGEMENT_2026-10-28.md), [P2_MOBA_60S_2026-10-28.md](implementacion/P2_MOBA_60S_2026-10-28.md).

## arte/

- [ASSETS.md](arte/ASSETS.md): inventario y licencias.
- Prompts: [PROMPTS_ASSETS_RECORRIDO_v0_42.md](arte/PROMPTS_ASSETS_RECORRIDO_v0_42.md), [PROMPTS_CUARTO_SOFI_v0_42.md](arte/PROMPTS_CUARTO_SOFI_v0_42.md), [PROMPTS_TUTOR_Y_RECURSOS_v0_41.md](arte/PROMPTS_TUTOR_Y_RECURSOS_v0_41.md), [PORTRAIT_PROMPTS.md](arte/PORTRAIT_PROMPTS.md), [WORLD_ASSET_PROMPTS.md](arte/WORLD_ASSET_PROMPTS.md), `ROUTINE_ASSET_PROMPTS_2026-10-29.json`.
- Notas de assets: [SPRITE_ASSETS_2026-10-28.md](arte/SPRITE_ASSETS_2026-10-28.md), [DAY0_MAP_ASSETS_2026-10-28.md](arte/DAY0_MAP_ASSETS_2026-10-28.md), [MOBA_MAP_ASSET_2026-10-28.md](arte/MOBA_MAP_ASSET_2026-10-28.md), [CAMILA_V2](arte/CAMILA_V2_ASSETS_2026-10-29.md), [CAMILA_V3](arte/CAMILA_V3_ASSETS_2026-10-29.md).

## calidad/

- [TEST_MATRIX.md](calidad/TEST_MATRIX.md): qué cubre cada suite de pruebas.
- [WINDOWS_VALIDATION_BUILD_2026-10-29.md](calidad/WINDOWS_VALIDATION_BUILD_2026-10-29.md): exportación y validación en Windows.
- Estado por fases: [P0_P1](calidad/P0_P1_CLOSURE_2026-10-28.md), [P4](calidad/P4_STATUS.md), [P6](calidad/P6_STATUS.md), [P7](calidad/P7_QA_2026-10-27.md), [P8](calidad/P8_OPERATIONS.md), [NFR](calidad/NFR_CLOSEOUT_2026-10-28.md).

## diagramas/

Cada `generate_*.py` escribe su PNG/SVG en esta misma carpeta; `generate_story_flow_with_hints_v3.py` lee y actualiza además los archivos de pistas en `historia/`. Ejecuta los scripts desde cualquier carpeta: usan su propia ubicación.
