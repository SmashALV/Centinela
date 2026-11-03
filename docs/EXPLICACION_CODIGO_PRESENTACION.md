# Cómo funciona el código de Centinela 2.0 · guía para la presentación

Documento de apoyo para explicar el código en una exposición. Cada sección dice **qué hace** una parte, **dónde está** y **qué decir**, con fragmentos reales del proyecto. Versión del código: `main` en `33afc75`, más la telemetría en curso.

**Diagramas de apoyo** (abrir en el navegador):

- Arquitectura modular: `.archify/architecture-centinela-modular-20261103/centinela-arquitectura-modular.html`
- Ramas de la historia hasta cada final: `.archify/workflow-ramas-conversacion-20261102/centinela-ramas-conversacion.html`

---

## 1. La idea en una frase

> Centinela 2.0 es un juego 2D en **Godot 4** con una **rutina diaria** que se repite cinco días. En ella el jugador explora, conversa y decide. Una **máquina de etapas** dice qué toca hacer, un **guion en JSON** dice qué se dice, unas **reglas educativas** convierten las decisiones en un final, y un **guardado transaccional** asegura que no se pierda nada.

## 2. Piezas principales

| Pieza | Archivo | Para qué sirve |
|---|---|---|
| Escena principal | `scenes/Main.tscn` + `scripts/Main.gd` | Coordinador: crea los módulos, recibe la entrada del jugador y enruta las interacciones |
| Módulos | `scripts/ui/`, `scripts/story/`, `scripts/game/`, `scripts/world/`, `scripts/routine/` | Menú, HUD, pausa, historia, reglas, inventario, mapas, indicadores y animación (ver sección 12) |
| Rutina diaria | `scripts/DailyRoutine.gd` | Etapas del día (mañana → colegio → tarde → noche) y lugares |
| Mundo | `scripts/World.gd` | Mapas, movimiento con colisiones, flecha de objetivo y animación de personajes |
| Conversaciones | `scripts/ConversationUI.gd` | Novela visual, chat de grupo, mensajes directos y consejo del tutor |
| Historia coral | `scripts/narrative/CoralStoryFlow.gd` + `data/narrative/coral_story_v0_2.json` | Escenas D1–D4, pistas, clasificación de respuestas y final |
| Estado | `scripts/GameState.gd` (autoload) | Todos los datos de la partida e inventario |
| Guardado | `scripts/SaveManager.gd` (autoload) | Tres ranuras, archivo en escritorio e IndexedDB en web |
| Audio | `scripts/AudioManager.gd` (autoload) | Música por contexto y efectos (campana, puerta, mochila…) |
| Arena 5v5 | `scenes/moba/MOBAArena.tscn` | Minijuego de un minuto |
| Telemetría | `scripts/Telemetry.gd` + `SyncManager.gd` | Hechos de juego anónimos para la investigación (en curso, desactivada por defecto) |

Un **autoload** es un script que Godot carga una sola vez al iniciar y que cualquier otro script puede usar por su nombre, por ejemplo `GameState.phase` o `AudioManager.play_effect("door")`. Se declaran en `project.godot`.

---

## 3. Arranque del juego

1. Godot abre `Main.tscn` (configurado en `project.godot`).
2. `Main._ready()` llama a `_create_modules()`, que crea los módulos (menú, HUD, historia, pausa…). Después crea el mundo (`World`), la rutina (`DailyRoutine`) y las pantallas, y carga el guion coral.
3. Se muestra el **menú de tres ranuras** (`ui/MainMenu.gd`). Al elegir una, `menu.start_slot()` crea una partida nueva o restaura la guardada.
4. `router.load_phase()` (`game/PhaseRouter.gd`) decide qué mostrar según el estado guardado. Con la rutina activa, delega en `DailyRoutine.load_view()`.

**Qué decir:** «Todo parte de una escena principal que crea los sistemas y, al elegir una ranura, recupera exactamente dónde se quedó el jugador».

---

## 4. La rutina diaria: una máquina de etapas

El día es una lista ordenada de etapas (`DailyRoutine.STAGES`):

```text
morning → breakfast → outbound → arrival → class → class_exit → farewell
        → homeward → dinner → evening → bedtime → sleep
```

Cada etapa ocurre en un lugar (habitación, sala, calle, colegio, clase, cómputo o tutoría). El paso de una etapa a otra lo hace siempre la misma función, `go()`:

```gdscript
func go(stage: String, place: String, position: Vector2, scene := "") -> bool:
	if main.save_in_progress: return false
	var previous: Dictionary = GameState.snapshot()
	var from_place: String = str(state().place)
	state().stage = stage
	state().place = place
	...
	var saved: bool = await _commit(previous)
	if saved and from_place != place:
		AudioManager.play_effect("arrival_bell" if place == "school" and stage == "arrival" and from_place == "street" else "door")
	return saved
```

**Qué decir:**
- `go()` primero **toma una foto del estado** (`snapshot`), luego cambia etapa y lugar, y después **guarda**.
- Si el guardado falla, `_commit()` vuelve a la foto anterior. El jugador nunca queda en un estado a medias.
- Al cambiar de lugar suena la puerta, y al llegar al colegio, la campana de entrada.

Los **bordes del mapa** funcionan como puertas. `boundary(edge)` decide a dónde lleva cada borde y bloquea el paso si falta algo, por ejemplo: «Recoge tu mochila antes de salir».

---

## 5. El mundo: mapas, movimiento e indicadores

`World.gd` es un `Node2D` que:

- **Dibuja el fondo del lugar** y crea **cuerpos de colisión** (`StaticBody2D`) a partir de rectángulos guardados en `data/maps/maps.json`, que lee `MapCatalog.gd`. El cuarto de Sofi tiene un mapa de día y otro de noche con las mismas colisiones.
- **Mueve a Sofi** con `CharacterBody2D.move_and_slide()`, que la detiene contra los muebles.
- **Detecta el objetivo cercano** y, al pulsar **F**, emite la señal `interacted(target)`. Al llegar a un borde emite `boundary_reached(edge)`.
- **Dibuja los indicadores:** la flecha amarilla que rebota (`_draw_objective_marker`), el halo pulsante (`_draw_target_glow`) y el aviso «Pulsa F» (`_draw_press_prompt`).
- **Anima a los personajes:** respiración, saltito ocasional y cambio de postura (`_draw_character`). Además, caminan hacia su nuevo lugar (`_update_actor_walks`) y se despiden caminando (`begin_departures`).

**Qué decir:** «El mundo no decide la historia: solo avisa con señales que el jugador interactuó o llegó a un borde, y la rutina responde».

---

## 6. El inventario de la mochila

```gdscript
# scripts/game/Inventory.gd
func pick_up(item: String, flag: String, message: String) -> void:
	if GameState.has_item(item):
		main._toast("Ya llevas la " + item + " en tu inventario")
		return
	var previous: Dictionary = GameState.snapshot()
	GameState.add_item(item)
	...
	if await SaveManager.save_slot_async():
		main.world.objects.erase(flag)          # desaparece del cuarto
		...
		AudioManager.play_effect("pickup")
```

**Qué decir:** «El objeto pasa a `GameState.flags.inventory`, desaparece del mapa y no se puede recoger dos veces. El guardado valida que el inventario solo contenga objetos conocidos».

---

## 7. La historia y las decisiones

El guion está en **`coral_story_v0_2.json`**: escenas, líneas, opciones y reacciones. `CoralStoryFlow.companion_scene()` elige qué escena toca con cada amigo según el día y las respuestas anteriores:

- **Día 1:** presentación de los cuatro amigos y, por la noche, el lobby con el nuevo jugador Kairo (decisión `D1_GATE`, con opciones A, B y C).
- **Día 2, el recreo:** tres decisiones clave con Camila (`D2_A`), Mateo (`D2_B`) y Sebas (`D2_C`). La opción **A** escucha y respeta; la **B** minimiza o expone.
- **Día 3:** cada amigo continúa según cómo se le respondió. Por ejemplo, `D3_A1` si se respetó a Camila o `D3_A2` si hay que reparar.
- **Día 4:** el plan final con cada uno (apoyo adulto, límite digital o reparación).

En cualquier día, la **tutoría** permite pedir apoyo adulto, y el día 4 la **PC** permite revisar bloqueo y privacidad.

**Consejo del tutor:** en cada decisión hay un botón que muestra una orientación (`decision_advice()`) **sin elegir por el jugador**.

---

## 8. Reglas educativas: clasificación y final

Cada respuesta se clasifica como *protectora*, *protectora con límite* o *de riesgo* (`CHOICE_BEHAVIOR` en `scripts/story/BehaviorRules.gd`). Al final se muestra el perfil completo, decisión por decisión. El final sale de **lo que el jugador hizo**:

```gdscript
# scripts/story/BehaviorRules.gd
static func ending_for(state: Dictionary) -> String:
	# Pedir apoyo adulto nunca se bloquea por respuestas anteriores.
	if state.get("adult_support_started", false): return "F01"
	# Un límite solo sostiene al grupo si la confianza del recreo no quedó rota.
	if state.get("limit_completed", false) and unrepaired_recess(state) < 2: return "F02"
	return "F03"
```

```gdscript
static func unrepaired_recess(state: Dictionary) -> int:
	# Respuestas de riesgo en el recreo (D2) que no se repararon en D4.
	...
		if choices.get("D2_" + companion, "") == "B" and choices.get("D4_%s2" % companion, "") != "A": total += 1
```

**Qué decir:**
- **F01 · Apoyo iniciado:** Sofi y sus amigos hablaron con el tutor. Siempre es posible, aunque antes se hayan cometido errores.
- **F02 · Un límite y un paso pendiente:** revisaron bloqueo y privacidad, y el grupo mantuvo la confianza.
- **F03 · Seguimos aquí:** quedan pasos pendientes. También se llega aquí si en el recreo hubo dos o más respuestas de riesgo que nunca se repararon.
- Son **funciones puras**: reciben el estado y devuelven un resultado. Por eso se prueban automáticamente.

---

## 9. Guardado transaccional

`SaveManager.save_slot_async()` guarda la foto completa del estado:

- **En escritorio:** archivo JSON en `user://`, con copia de respaldo `.bak`.
- **En web:** IndexedDB a través de `WebBridge`, con bloqueo por pestaña. La telemetría pendiente viaja **en la misma transacción** que la partida.

```gdscript
var response: Dictionary = await WebBridge.request("save_snapshot" if facts.is_empty() else "save_event_atomic", payload)
if not response.get("success", false):
	_handle_web_error(response)
	return false
```

**Qué decir:** «Cada acción importante guarda al instante. Si algo falla, el juego vuelve al estado anterior y avisa. Al recargar, la partida sigue en la misma línea del diálogo».

`GameState.restore()` valida cada campo antes de aceptar un guardado: etapa, día, elecciones, inventario y posición. Un archivo dañado no rompe el juego.

---

## 10. Audio, MOBA y telemetría

- **Audio:** `AudioManager.enter_context("explore" | "arena")` cambia la música, y `play_effect(nombre)` reproduce efectos. Los sonidos se generan con `scripts/generate_audio.py`.
- **MOBA:** escena aparte. Al terminar guarda el resultado (victoria, derrota o empate) y vuelve a la rutina: Camila reacciona y Sofi se va a dormir.
- **Telemetría:** `Telemetry.gd` compara el estado anterior con el nuevo y deriva hechos (`day_start`, `story_choice`, `story_action`, `hint_request`…) sin texto libre ni datos personales. Está **desactivada** (`web/backend_config.json → enabled: false`) hasta desplegar el backend.

---

## 11. Calidad: pruebas automáticas

Ocho suites de Godot se ejecutan sin abrir ventana (`--headless`):

| Suite | Qué comprueba |
|---|---|
| `RunTests` | Recorrido técnico, guardado, ranuras, MOBA y vista previa |
| `DailyRoutineTests` | Los 5 días completos para cada final (F01, F02, F03), inventario y bordes |
| `CoralRoutesTests` | Cuatro recorridos de la historia, finales, clasificación y consejo del tutor |
| `StoryRoutesTests`, `MobaReturnTests` | Rutas de la historia y regreso desde la arena |
| `TeacherFeedbackTests`, `DialogueChatTests`, `AutoPresentationTests` | Guías, lectura con clic, pausa, chats y presentación |

**Qué decir:** «Antes de cada cambio ejecutamos todas las pruebas. Por ejemplo, la regla del recreo se verificó con un recorrido que toma todas las respuestas de riesgo y termina en F03».

---

## 12. Arquitectura modular

El código se reorganizó en 8 pasos sin cambiar la jugabilidad ([detalle](ARQUITECTURA_MODULAR_PROPUESTA.md)). `Main.gd` pasó de 2220 a 402 líneas y ahora solo coordina:

| Carpeta | Módulos |
|---|---|
| `ui/` | `UiKit` (piezas comunes), `MainMenu`, `Hud`, `PauseMenu`, `PhoneModal`, `ObjectiveModal`, `ComputerScreens` |
| `story/` | `CoralController` (D1–D4), `Day0Flow`, `BehaviorRules` (clasificación y final), `TutorAdvice` |
| `game/` | `PhaseRouter` (qué pantalla mostrar), `Inventory` |
| `world/` | `MapCatalog`, `TargetMarkers` (flecha y halo), `ActorAnimator` |
| `routine/` | `RoutineCatalog` |
| `data/` | `routine/scenes.json` (textos de la rutina), `maps/maps.json` (mapas y colisiones), `narrative/` (guiones) |

**Qué decir:** «Cada archivo hace una sola cosa. Para corregir una frase se edita un JSON; para añadir un lugar se agrega su mapa al catálogo; la regla del final está en una función de seis líneas. En cada paso de la reorganización comprobamos que el juego siguiera igual: mismas pruebas, mismos textos, mismas colisiones y capturas idénticas píxel a píxel».

---

## Guion breve para exponer el código (unos 4 minutos)

1. **(30 s)** «El juego está hecho en Godot 4. Una escena principal crea los sistemas y recupera la partida de cualquiera de tres ranuras».
2. **(45 s)** «El día es una máquina de etapas. Cada cambio pasa por `go()`, que toma una foto del estado, guarda y, si falla, vuelve atrás».
3. **(45 s)** «El mundo mueve a Sofi con colisiones reales, marca el objetivo con una flecha y avisa con señales cuando el jugador interactúa».
4. **(60 s)** «La historia está en un JSON. En el recreo del día 2 hay tres decisiones clave. Cada respuesta se clasifica, y el final se decide con una función pura: apoyo adulto, límite o pasos pendientes».
5. **(30 s)** «El guardado es transaccional y la telemetría anónima viaja en la misma transacción».
6. **(30 s)** «Ocho suites de pruebas verifican los tres finales antes de cada cambio. El código está organizado en módulos pequeños y los contenidos en JSON, así que crecer es añadir datos y no reescribir».
