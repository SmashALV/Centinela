# Mejoras del juego serio · v0.41 (30-10-2026)

Fuente: checklist elaborado a partir del audio de retroalimentación y el requerimiento adicional sobre la mochila y el inventario.

## Checklist

| # | Mejora | Prioridad | Estado | Dónde |
|---|---|---|---|---|
| 1 | Inventario de la mochila | Alta | Hecho | `GameState.gd` (`has_item`, `add_item`, `valid_inventory`), `Main._pick_up_item`, `DailyRoutine.targets()` |
| 2 | Indicadores de interacción más visibles | Media | Hecho | `World._draw_objective_marker`, `_draw_target_glow`, `_draw_press_prompt` |
| 3 | Ritmo de escenas y diálogos | Media | Hecho | `DailyRoutine._lines()`, `ConversationUI.reading_seconds()` |
| 4 | Tutor visual y consejos | Alta | Hecho | `World._draw_story_target`, `ConversationUI.show_advice`, `CoralStoryFlow.decision_advice/tutor_tip` |
| 5 | Consecuencias de las decisiones | Alta | Hecho y probado | `CoralStoryFlow.behavior_profile/unrepaired_recess/ending_for`, `Main._coral_choose` |
| 6 | Animaciones idle de los NPC | Media | Hecho | `World._draw_character`, `_idle_facing` |
| 7 | Desplazamiento visible de los personajes | Media | Hecho | `World._update_actor_walks`, `DailyRoutine.targets()`, `begin_departures` |
| 8 | Campana y efectos de sonido | Media | Hecho | `scripts/generate_audio.py`, `AudioManager.EFFECTS`, `DailyRoutine` |

## Detalle

**Mochila e inventario.** Al pulsar F sobre la mochila, `Main._pick_up_item` añade `"mochila"` a `GameState.flags.inventory`, marca `backpack`, guarda y retira la mochila del mapa. Si se vuelve a intentar, solo aparece «Ya llevas la mochila en tu inventario». Un panel en la esquina inferior derecha del HUD muestra el inventario. Al amanecer la mochila vuelve al cuarto. El guardado valida el inventario en escritorio (`GameState.restore`) y en Web (`web/centinela_storage.js`).

**Indicadores.** La flecha del objetivo es ahora una flecha amarilla grande con contorno que rebota sobre el objetivo, acompañada de un halo pulsante. Al acercarse aparece «Pulsa F». A la hora de dormir, toda la cama se resalta con un marco animado.

**Ritmo.** Se ampliaron las escenas cortas: despertar (línea de Sofi), desayuno (cierre del narrador), clase (intervención del profesor por día y respuesta de Sofi) y cena (conversación familiar). La lectura automática dura más: mínimo 5 s y un ritmo más pausado por palabra. El avance con clic dentro del recuadro y con Enter se mantiene; ahora una indicación lo recuerda en pantalla. Se conservó que un clic fuera del recuadro no avance, decisión verificada por `DialogueChatTests`.

**Tutor.** Nuevo personaje: el profesor tutor. Su ilustración de novela visual (`assets/vn/tutor_v2.png`) es arte entregado por el equipo. La hoja de mapa en cuatro vistas y el avatar se derivan de ella con `scripts/generate_tutor_assets.py`. El mismo docente dicta la clase (`Profesor`). El tutor espera junto a la puerta de tutoría y aparece cuando habla. Cada decisión incluye el botón «¿No sabes qué responder? Pide un consejo al tutor (no elige por ti)». El consejo orienta sin seleccionar una opción y queda registrado como acción `ADVICE_<decisión>`. En tutoría, el tutor añade además un consejo del día.

**Consecuencias.** Cada respuesta se clasifica como protectora, protectora con límite o de riesgo (`CHOICE_BEHAVIOR`). La etiqueta global (Protectora, En aprendizaje o De riesgo) se guarda en `coral_state.behavior` tras cada elección y se resume al final, decisión por decisión. Las respuestas del recreo influyen ahora en el desenlace: si quedan dos o más respuestas de riesgo de D2 sin reparar en D4, completar el bloqueo y la privacidad ya no basta para F02 y el final es F03. Pedir apoyo en tutoría siempre conduce a F01. Las elecciones de D4 fijan un plan (`SUPPORT_PLANNED` o `LIMIT_PLANNED`) que actualiza el objetivo, y una reparación en D4 marca al compañero como reparado. La clasificación es descriptiva y no constituye un puntaje educativo aprobado.

**NPC.** Los amigos respiran, dan un saltito ocasional, cambian de postura cada pocos segundos y miran a Sofi cuando se acerca. Después de conversar, cada compañero camina a otro punto del patio. En la despedida se alejan caminando con balanceo de pasos.

**Sonido.** Al llegar al colegio suena un timbre eléctrico nuevo (`arrival_bell.wav`). El fin de clase conserva el timbre original (`school_bell.wav`), que ahora suena justo cuando el narrador lo menciona, ya no después de terminar la escena. Nuevos efectos: recoger objeto, puerta al cambiar de lugar, notificación de mensajes y transición al dormir; además, sonido de interacción en la rutina. Se regeneran con `python scripts/generate_audio.py`.

## Verificación

Con Godot 4.7.2 en modo headless pasaron `RunTests`, `DailyRoutineTests`, `CoralRoutesTests`, `StoryRoutesTests`, `MobaReturnTests`, `TeacherFeedbackTests`, `DialogueChatTests` y `AutoPresentationTests`; también `npm run test:web-storage`, `tests/verify_recovered_script.py` y `generate_audio.py --check`.

- `DailyRoutineTests` comprueba que la mochila pasa al inventario, desaparece y no se duplica.
- `CoralRoutesTests` añade un cuarto recorrido: recreo con respuestas de riesgo sin reparar más bloqueo da F03. Con reparación en D4 sigue dando F02. También comprueba la clasificación y el panel de consejo.

Se revisaron capturas del juego para la mochila, el inventario, el patio, la tutoría, el consejo y la cama. No se probó con jugadores ni se cronometró la duración.

## Diagramas

Generados con Archify 3.2.0 (comprobaciones automáticas validate, deliver, check y browser-check superadas):

- Arquitectura: `.archify/architecture-centinela-mejoras-20261030-234434/centinela-arquitectura-v041.html`
- Flujograma de juego: `.archify/workflow-jugabilidad-centinela-20261030-234434/centinela-flujo-jugabilidad.html`
