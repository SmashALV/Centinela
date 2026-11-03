# Propuesta de arquitectura modular · Centinela 2.0

**Objetivo:** que el código sea fácil de entender, probar y ampliar en Godot, **sin cambiar la jugabilidad**. La propuesta reorganiza el código existente en módulos pequeños con funciones sencillas. Cada paso de migración mueve código sin alterar lo que hace y se valida con las pruebas que ya existen.

Fecha: 02-11-2026. Base: `main` en `33afc75`, más el trabajo de telemetría en curso (sin commit).

---

## 1. Diagnóstico del código actual

| Script | Líneas | Funciones | Qué mezcla hoy |
|---|---|---|---|
| `Main.gd` | 2220 | 114 | Menú y ranuras · HUD e inventario · celular, objetivo y pistas · pausa y opciones · diálogo del Día 0 · escritorio, Discord y elección de clase · puente con el MOBA · control de la historia coral (D1–D4) · vista previa y borrador recuperados (código heredado) · fondos de diálogo |
| `World.gd` | 619 | 28 | Movimiento y colisiones · catálogo de mapas y colisiones (constantes) · dibujo de flechas, halos y «Pulsa F» · animación de amigos · decoración heredada del cuarto antiguo |
| `DailyRoutine.gd` | 403 | 27 | Máquina de etapas del día · bordes y objetivos de cada lugar · **textos de las escenas escritos dentro del código** · transición de dormir |
| `ConversationUI.gd` | 651 | 24 | Novela visual · chat de grupo · mensajes directos · panel de consejo · lectura automática |
| `MOBAArena.gd` | 781 | 45 | Arena completa (es una escena aparte y ya está bien aislada) |
| `CoralStoryFlow.gd` | 244 | 17 | Lectura del guion · selección de escenas · pistas · clasificación · reglas de final |

**Problemas concretos:**

1. **`Main.gd` es un «objeto dios».** Para entender cómo se elige un final hay que leer funciones repartidas entre las líneas 1524 y 1801 de un archivo de 2200 líneas.
2. **Contenido mezclado con lógica.** Los textos del desayuno, la clase, la despedida y la cena están en `DailyRoutine._lines()`. Para corregir una frase hay que editar código.
3. **Datos de mapas dentro del código.** Fondos, colisiones y posiciones de objetivos son constantes repartidas entre `World.gd` y `DailyRoutine.gd`. Al cambiar un mapa hay que tocar dos archivos.
4. **Código heredado activo.** Más de 400 líneas de `Main.gd` (vista previa y borrador recuperados) solo sirven para partidas antiguas, pero se leen junto al flujo actual.
5. **Funciones largas.** `_render_coral()`, `_start_slot()` y `_render_preview_story()` superan las 60 líneas cada una.

**Lo que ya está bien y se conserva:**

- Los autoloads (`GameState`, `SaveManager`, `AudioManager`, `SyncManager`, `WebBridge`).
- El guardado transaccional con vuelta atrás si falla.
- El guion coral en JSON.
- `Telemetry.gd`, con funciones estáticas puras.
- El MOBA como escena separada.
- Las 8 suites de pruebas de Godot y las pruebas de guardado web.

---

## 2. Principios

1. **Un script, una responsabilidad.** El nombre del archivo dice qué hace.
2. **Funciones cortas y con un solo propósito**, de unas 25 líneas como máximo, con nombre de verbo: `pick_up_item()`, `ending_for()`, `draw_marker()`.
3. **El contenido va en datos.** Textos, mapas, colisiones y objetivos en JSON o recursos `.tres`. El código decide *cuándo* mostrar algo y los datos dicen *qué*.
4. **Los módulos se comunican con señales.** Ejemplos: `World` emite `interacted(target)` y `boundary_reached(edge)`, y la rutina emite `scene_requested(id)`. Ningún módulo de interfaz modifica `GameState` directamente.
5. **Un único punto para guardar.** Todo cambio de estado pasa por `GameFlow.commit(previous)`, que guarda y, si falla, restaura. Ya existe repetido como `_commit`, `_save_coral` y `_commit_flag`; se unifica.
6. **Las reglas educativas son funciones puras.** La clasificación de respuestas, las reparaciones y el final no tocan la escena, así se prueban sin abrir el juego.

---

## 3. Estructura propuesta

```text
scripts/
├── core/                      # Servicios globales (autoloads, sin cambios de nombre)
│   ├── GameState.gd           # Solo datos de la partida + validación del guardado
│   ├── SaveManager.gd         # Ranuras, archivos e IndexedDB
│   ├── AudioManager.gd        # Música y efectos
│   ├── Telemetry.gd           # Hechos de juego (funciones puras)
│   ├── SyncManager.gd         # Cola y envío a Supabase
│   └── WebBridge.gd
│
├── game/
│   ├── Main.gd                # Coordinador corto: crea módulos y conecta señales
│   ├── GameFlow.gd            # commit(previous), cambio de fase y recarga de vista
│   └── PhaseRouter.gd         # Según GameState.phase decide qué módulo muestra la pantalla
│
├── routine/                   # La jornada diaria
│   ├── DailyRoutine.gd        # Máquina de etapas: go(), boundary(), interact(), finish_sleep()
│   ├── RoutineCatalog.gd      # Lee data/routine/places.json y scenes.json
│   └── SleepTransition.gd     # Animación de dormir y amanecer
│
├── story/                     # Historia y reglas educativas
│   ├── CoralStoryFlow.gd      # Acceso al guion coral (JSON)
│   ├── CoralController.gd     # begin_scene, advance, choose, finish_scene, finish_day
│   ├── BehaviorRules.gd       # classify(), profile(), unrepaired_recess(), ending_for()
│   ├── TutorAdvice.gd         # decision_advice(), tutor_tip(), pistas H1/H2
│   └── D0Dialogue.gd          # Diálogos del Día 0 (hoy en Main + NarrativeManager)
│
├── world/                     # Lo que se ve y se recorre
│   ├── World.gd               # Movimiento, colisiones, señales interacted/boundary
│   ├── MapCatalog.gd          # Lee data/maps/*.json: fondo, colisiones, bordes
│   ├── TargetMarkers.gd       # Flecha, halo, «Pulsa F» y etiquetas
│   └── ActorAnimator.gd       # Respiración, saltitos, caminar y despedidas
│
├── ui/                        # Pantallas y paneles
│   ├── MainMenu.gd            # Ranuras: nueva, continuar, rehacer, borrar
│   ├── Hud.gd                 # Objetivo del día + panel de inventario
│   ├── PhoneModal.gd          # Mensajes del celular
│   ├── ObjectiveModal.gd      # Objetivo y pistas
│   ├── PauseMenu.gd           # Pausa, texto, audio y velocidad
│   ├── ConversationUI.gd      # Novela visual, chat y consejo (ya existe)
│   ├── DesktopUI.gd           # Escritorio de la PC (ya existe)
│   └── StageGuide.gd          # Guías de controles del Día 0
│
├── minigame/
│   └── MOBAArena.gd           # Sin cambios
│
└── legacy/
    └── PreviewFlow.gd         # Vista previa y borrador recuperados (partidas antiguas)

data/
├── narrative/coral_story_v0_2.json      # Ya existe
├── routine/
│   ├── places.json            # Lugar → mapa, bordes, objetivos por etapa
│   └── scenes.json            # Textos de despertar, desayuno, clase, despedida y cena por día
└── maps/
    ├── sofi_room.json         # Fondo de día y de noche + colisiones
    ├── tutor_office.json
    └── …
```

### Ejemplo: cómo queda un dato que hoy está en el código

Hoy, en `DailyRoutine.targets()` y `World.ROUTINE_BLOCKS`:

```gdscript
"tutor": return {"tutoria": Vector2(310, 228)}
"tutor_office": [[30, 56, 708, 85], [89, 56, 112, 106], ...]
```

Propuesto, en `data/maps/tutor_office.json`:

```json
{
  "background": "res://assets/world/tutor_office_map.png",
  "blocks": [[30, 56, 708, 85], [89, 56, 112, 106]],
  "edges": {"right": "Entrada"},
  "targets": {"tutoria": [310, 228]}
}
```

`MapCatalog.load_map("tutor_office")` devuelve ese diccionario. **Añadir un lugar nuevo** consiste en crear su JSON y su imagen, sin tocar `World.gd`.

### Ejemplo: funciones sencillas en lugar de una función larga

Hoy, `_coral_choose()` (35 líneas) guarda la elección, actualiza confianza, hechos observados, reparación, planes y clasificación, guarda la partida y muestra un aviso. Propuesto:

```gdscript
# story/CoralController.gd
func choose(key: String) -> bool:
	if not _can_choose(key): return false
	var previous := GameState.snapshot()
	_record_choice(key)
	_update_companion(key)
	_record_plan(key)
	GameState.coral_state.behavior = BehaviorRules.profile(GameState.coral_state).label
	return await flow.commit(previous)
```

Cada función auxiliar hace una sola cosa y se puede probar por separado.

---

## 4. Mapa de responsabilidades (de dónde sale cada módulo)

| Módulo nuevo | Funciones que se mueven (hoy en…) |
|---|---|
| `MainMenu.gd` | `_show_menu`, `_refresh_web_menu`, `_confirm_slot_action`, `_apply_slot_action`, `_start_slot` (Main) |
| `Hud.gd` | `_update_hud`, `_objective_text`, `_build_inventory_panel`, `_refresh_inventory`, `_toast` (Main) |
| `PhoneModal.gd`, `ObjectiveModal.gd` | `_show_phone`, `_render_phone`, `_show_objective`, `_render_objective`, `_coral_request_hint`, `_advance_hint`, `_set_d0_hint` (Main) |
| `PauseMenu.gd` | `_show_pause`, `_render_pause`, `_cycle_text_size`, `_cycle_audio`, `_cycle_dialogue_speed`, `_resume_pause`, `_return_to_menu` (Main) |
| `D0Dialogue.gd` | `_show_dialogue`, `_render_dialogue`, `_advance_dialogue`, `_choose_dialogue`, `_complete_dialogue`, `_render_prologue` (Main) |
| `CoralController.gd` | `_coral_begin_scene`, `_coral_interact`, `_coral_advance`, `_coral_choose`, `_coral_finish_scene`, `_coral_finish_day`, `_render_coral`, `_render_coral_summary`, `_show_tutor_advice` (Main) |
| `BehaviorRules.gd` | `behavior_profile`, `unrepaired_recess`, `ending_for` y la tabla `CHOICE_BEHAVIOR` (CoralStoryFlow) |
| `TutorAdvice.gd` | `decision_advice`, `tutor_tip`, `educational_hint`, `navigation_hint` (CoralStoryFlow) |
| `Inventory` (dentro de `GameFlow`) | `_pick_up_item` (Main), `has_item`/`add_item`/`remove_item` (GameState) |
| `RoutineCatalog.gd` + JSON | `_lines`, `targets`, `edges`, `map_key`, `objective` (DailyRoutine) |
| `SleepTransition.gd` | `_render_sleep`, `_process`, `finish_sleep` (DailyRoutine) |
| `MapCatalog.gd` + JSON | `ROUTINE_BACKGROUNDS`, `ROUTINE_BLOCKS`, `DAY0_*`, `DRAFT_*`, `_configure_layers` (World) |
| `TargetMarkers.gd` | `_draw_objective_marker`, `_draw_target_glow`, `_draw_press_prompt`, `_draw_story_target`, `_draw_object` (World) |
| `ActorAnimator.gd` | `_idle_facing`, `_walk_facing`, `_update_actor_walks`, `begin_departures`, `_update_departures` (World) |
| `PreviewFlow.gd` (legacy) | `_start_playable_draft`, `_render_preview*`, `_commit_preview`, `_finish_draft`, `_scene_parts` y afines (≈ 400 líneas de Main) |

**Resultado esperado:** `Main.gd` pasa de 2220 a unas 200 líneas: crear los módulos, conectar señales y delegar en `PhaseRouter`. Ningún script nuevo supera unas 300 líneas.

---

## 5. Cómo escala

| Si quieres… | Hoy | Con la propuesta |
|---|---|---|
| Corregir una frase de la cena | Editar `DailyRoutine._lines()` | Editar `data/routine/scenes.json` |
| Añadir un lugar (por ejemplo, biblioteca) | Tocar `World.gd`, `DailyRoutine.gd` y `Main.gd` | Crear `data/maps/library.json` + imagen y añadir el borde en `places.json` |
| Añadir un objeto al inventario | Constantes en `GameState` + lógica en `Main` | Añadirlo a la lista de ítems y a los objetivos del lugar en JSON |
| Añadir una decisión nueva | Escena en JSON + ramas en `Main._coral_choose` | Escena en JSON + una fila en `BehaviorRules` |
| Cambiar la regla de un final | Buscar en `CoralStoryFlow` y `Main` | Solo `BehaviorRules.ending_for()` |
| Cambiar el aspecto de la flecha | Buscar en `World._draw*` | Solo `TargetMarkers.gd` |

---

## 6. Plan de migración sin romper nada

Cada paso es un commit independiente. Se aplican cuatro reglas:

- **No se cambian** las claves de `GameState` ni el formato del guardado, así siguen abriendo las partidas existentes.
- Durante la transición, `Main` conserva **funciones puente** con el nombre antiguo (`_coral_choose` llama a `coral.choose`), porque las pruebas las usan.
- **Al terminar cada paso** se ejecutan las 8 suites de Godot, `npm run test:web-storage` y una captura del recorrido.
- **No se toca** la telemetría en curso hasta que esté integrada.

| Paso | Qué se mueve | Riesgo | Validación extra |
|---|---|---|---|
| 1 | Código heredado de vista previa → `legacy/PreviewFlow.gd` | Bajo | `RunTests` (cubre la vista previa) |
| 2 | Pausa, celular, objetivo y menú → `ui/` | Bajo | `DialogueChatTests`, `AutoPresentationTests` |
| 3 | `BehaviorRules` y `TutorAdvice` (funciones puras) | Bajo | `CoralRoutesTests` (los 4 recorridos y finales) |
| 4 | `CoralController` | Medio | `CoralRoutesTests`, `DailyRoutineTests`, `StoryRoutesTests` |
| 5 | Textos de la rutina → `data/routine/scenes.json` | Bajo | `DailyRoutineTests` + comparación de textos antes y después |
| 6 | Mapas → `MapCatalog` + JSON | Medio | Capturas con colisiones superpuestas, como en la revisión de mapas |
| 7 | `TargetMarkers` y `ActorAnimator` | Bajo | Capturas del patio, el cuarto y la tutoría |
| 8 | `Main` queda como coordinador + `PhaseRouter` | Medio | Todas las suites + recorrido D0→D4 completo |

**Estimación:** de 8 a 12 horas de trabajo repartidas en los 8 pasos. Se puede detener después de cualquier paso con el juego funcionando.

---

## 7. Avance de la migración

| Paso | Estado | Resultado |
|---|---|---|
| 1 · Código heredado → `scripts/legacy/PreviewFlow.gd` | ✅ Hecho (02-11-2026) | 19 funciones fuera de `Main`. Las pruebas usan `main.legacy.*` |
| 2 · Pausa, celular y objetivo → `scripts/ui/` | ✅ Hecho (02-11-2026) | `PauseMenu.gd`, `PhoneModal.gd`, `ObjectiveModal.gd`. `Main` usa `pause_menu`, `phone_modal` y `objective_modal` |
| 3 · Reglas y consejos → `scripts/story/` | ✅ Hecho (02-11-2026) | `BehaviorRules.gd` y `TutorAdvice.gd` como funciones puras. `CoralStoryFlow` conserva puentes de una línea |
| 4 · `CoralController` | Pendiente | |
| 5 · Textos de la rutina → JSON | Pendiente | |
| 6 · Mapas → `MapCatalog` + JSON | Pendiente | |
| 7 · `TargetMarkers` y `ActorAnimator` | Pendiente | |
| 8 · `Main` como coordinador | Pendiente | |

`Main.gd` bajó de 2221 a 1633 líneas. En cada paso pasaron las 8 suites de Godot con los mismos resultados que antes del cambio (488, 1449, 1, 24, 33, 5, 5 y 12 comprobaciones). La jugabilidad y el formato del guardado no cambiaron.

## 7. Diagramas

- Arquitectura actual: `.archify/architecture-centinela-v043-20261102/centinela-arquitectura-v043.html`
- Ramas de conversación hasta cada final: `.archify/workflow-ramas-conversacion-20261102/centinela-ramas-conversacion.html`
