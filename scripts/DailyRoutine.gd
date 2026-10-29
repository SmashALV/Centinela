extends Node

const VERSION := "DAILY_v1"
const STAGES := ["morning", "breakfast", "outbound", "arrival", "class", "class_exit", "farewell", "homeward", "dinner", "evening", "bedtime", "sleep", "finished"]
const PLACES := ["bedroom", "living", "street", "school", "classroom", "computer", "tutor"]
const MAPS := {"morning": "bedroom", "breakfast": "living", "outbound": "street", "arrival": "school", "class": "classroom", "farewell": "school", "homeward": "street", "dinner": "living", "evening": "bedroom", "bedtime": "bedroom", "sleep": "bedroom", "finished": "bedroom"}
const PLACES_ES := {"bedroom": "Habitación", "living": "Sala y comedor", "street": "Camino al colegio", "school": "Entrada del colegio", "classroom": "Salón de clase", "computer": "Sala de cómputo", "tutor": "Tutoría"}

var main: Node
var sleep_elapsed := 0.0
var sleep_overlay: Control

static func new_state(day := 0) -> Dictionary:
	return {"version": VERSION, "day": day, "stage": "morning", "place": "bedroom", "scene": "", "step": 0, "chat_seen": false, "matches": [], "messages_checked": false}

static func valid(value: Variant) -> bool:
	if typeof(value) != TYPE_DICTIONARY: return false
	if value.get("version") != VERSION or value.get("stage") not in STAGES or value.get("place") not in PLACES: return false
	if typeof(value.get("day")) not in [TYPE_INT, TYPE_FLOAT] or float(value.day) != float(int(value.day)) or int(value.day) not in range(5): return false
	if typeof(value.get("step")) not in [TYPE_INT, TYPE_FLOAT] or float(value.step) != float(int(value.step)) or int(value.step) not in range(16): return false
	if value.get("scene") not in ["", "wake", "breakfast", "lesson", "goodbye", "dinner", "evening_chat", "match_reply"]: return false
	for key in ["chat_seen", "messages_checked"]:
		if typeof(value.get(key)) != TYPE_BOOL: return false
	if typeof(value.get("matches")) != TYPE_ARRAY or value.matches.size() > 5: return false
	for result in value.matches:
		if result not in ["victoria", "derrota", "empate"]: return false
	return true

func active() -> bool:
	return GameState.flags.has("routine")

func state() -> Dictionary:
	return GameState.flags.get("routine", {})

func initialize(day := 0) -> void:
	GameState.flags.routine = new_state(day)
	if GameState.phone_messages.is_empty(): GameState.phone_messages.append({"speaker": "Mateo", "text": "Nos vemos en la entrada del colegio. Esta noche podemos jugar una corta."})
	# Las guías anteriores no deben sustituir la nueva rutina.
	GameState.flags.erase("d0_guide_active")
	GameState.flags.d0_guide_bedroom_seen = true
	GameState.flags.d0_guide_courtyard_seen = true
	GameState.flags.d0_guide_computer_seen = true

func map_key() -> String:
	return {"bedroom": "bedroom", "living": "living", "street": "street", "school": "school", "classroom": "classroom", "computer": "computer", "tutor": "draft_d3"}.get(str(state().get("place", "bedroom")), "bedroom")

func is_evening() -> bool:
	return state().get("stage") in ["farewell", "homeward", "dinner", "evening", "bedtime", "sleep", "finished"]

func can_use_pc() -> bool:
	return active() and state().get("place") in ["bedroom", "computer"]

func can_play() -> bool:
	if state().get("stage") != "evening" or state().get("place") != "bedroom": return false
	if int(state().day) == 0: return GameState.flags.get("d0_chat_done", false)
	if int(state().day) == 1: return GameState.coral_state.get("actions", []).has("D1_LOBBY_DONE")
	return state().chat_seen

func objective() -> String:
	if not str(state().get("scene", "")).is_empty(): return "Escucha la conversación"
	match str(state().stage):
		"morning": return "Revisa mensajes y prepara la mochila. Sal por la derecha"
		"breakfast": return "Desayuna en la mesa antes de salir por la derecha"
		"outbound": return "Camina hacia la derecha para llegar al colegio"
		"arrival":
			if state().place == "computer": return "PC disponible. Vuelve por la izquierda"
			if state().place == "tutor": return "Puedes hablar en tutoría. Vuelve por la derecha"
			if int(state().day) == 0: return "Conversa con el grupo y entra a clase por arriba"
			if not main.coral_flow.everyone_heard(GameState.coral_state): return main.coral_flow.objective(GameState.coral_state)
			return "Entra a clase por arriba. Cómputo a la derecha, tutoría a la izquierda"
		"class": return "Acércate al pupitre para comenzar la clase"
		"class_exit": return "Sonó la campana. Sal por abajo para despedirte"
		"farewell": return "Despídete del grupo y sal por abajo"
		"homeward": return "Vuelve a casa caminando hacia la izquierda"
		"dinner": return "Cena en la mesa y ve a tu cuarto por la izquierda"
		"evening": return "Abre Discord en la PC y juega una partida con tus amigos"
		"bedtime": return "Apaga por hoy. Acércate a la cama para dormir"
		"sleep": return "Descansa"
	return "Historia concluida"

func targets() -> Dictionary:
	match str(state().place):
		"bedroom":
			var result := {"pc": Vector2(278, 173), "bed": Vector2(179, 228), "photo": Vector2(494, 140)}
			if state().stage == "morning": result.backpack = Vector2(605, 294)
			return result
		"living": return {"meal": Vector2(370, 230)} if state().stage in ["breakfast", "dinner"] else {}
		"classroom": return {"lesson": Vector2(385, 263)} if state().stage == "class" else {}
		"computer": return {"pc": Vector2(382, 220)}
		"tutor": return {"tutoria": Vector2(380, 250)}
		"school":
			if state().stage == "farewell": return {} if GameState.flags.get("farewell_done", false) else {"friends": Vector2(374, 245)}
			if int(state().day) == 0: return {"friends": Vector2(374, 245)}
			return {"camila": Vector2(300, 242), "bruno": Vector2(210, 255), "sebas": Vector2(420, 255), "mateo": Vector2(535, 240)}
	return {}

func load_view() -> void:
	if GameState.phase == "result":
		if str(state().scene).is_empty():
			state().scene = "match_reply"
			state().step = 0
		_render_scene()
		return
	main.world.configure(map_key(), GameState.player_position)
	main.world.configure_story_targets(targets(), _primary_target())
	main.world.routine_mode = true
	main.world.evening_light = is_evening()
	main.world.edge_routes = edges()
	if state().stage == "farewell" and GameState.flags.get("farewell_done", false): main.world.begin_departures()
	main.world.hide_player = state().stage == "sleep"
	main._update_hud()
	if state().stage == "sleep":
		_render_sleep()
		return
	if not GameState.dialogue_key.is_empty():
		main._resume_saved_dialogue()
	elif int(state().day) == 0 and state().stage == "morning" and not GameState.flags.get("prologue_seen", false):
		main._render_prologue()
	elif int(state().day) == 0 and state().stage == "morning" and not GameState.flags.get("wakeup_seen", false):
		main._show_dialogue("wakeup")
	elif not str(state().scene).is_empty(): _render_scene()
	elif int(state().day) > 0 and GameState.coral_state.get("mode") != "explore": main._render_coral()
	else: main._close_modal()

func _primary_target() -> String:
	match str(state().stage):
		"morning": return "backpack"
		"breakfast", "dinner": return "meal"
		"class": return "lesson"
		"farewell": return "friends"
		"evening": return "pc"
		"bedtime": return "bed"
	if state().place == "school" and int(state().day) > 0: return main.coral_flow.route_target(GameState.coral_state)
	return ""

func edges() -> Dictionary:
	match str(state().place):
		"bedroom": return {"right": "Sala"} if state().stage == "morning" else {}
		"living": return {"left": "Habitación", "right": "Calle"} if state().stage in ["breakfast", "outbound"] else {"left": "Habitación"}
		"street": return {"left": "Casa", "right": "Colegio"}
		"computer": return {"left": "Entrada"}
		"tutor": return {"right": "Entrada"}
		"classroom": return {"down": "Entrada"}
		"school": return {"down": "Calle"} if state().stage == "farewell" else {"up": "Clase", "right": "Cómputo", "left": "Tutoría", "down": "Calle"}
	return {}

func _commit(previous: Dictionary) -> bool:
	if main.save_in_progress: return false
	main.save_in_progress = true
	main.world.enabled = false
	if not await SaveManager.save_slot_async():
		GameState.restore(previous)
		main.save_in_progress = false
		if main.modal_kind == "pause": main.phase_load_after_pause = true
		else: main._load_phase()
		main._toast("No se pudo guardar el avance. Reintenta")
		return false
	main.save_in_progress = false
	if main.modal_kind == "pause": main.phase_load_after_pause = true
	else: main._load_phase()
	return true

func _phase_for_place() -> void:
	if int(state().day) > 0: GameState.phase = "coral"
	else: GameState.phase = "computer" if state().place == "computer" or state().stage in ["evening", "bedtime", "sleep"] else "bedroom" if state().place in ["bedroom", "living"] else "courtyard"

func go(stage: String, place: String, position: Vector2, scene := "") -> bool:
	if main.save_in_progress: return false
	var previous: Dictionary = GameState.snapshot()
	state().stage = stage
	state().place = place
	state().scene = scene
	state().step = 0
	GameState.ui_modal = ""
	GameState.player_position = position
	_phase_for_place()
	return await _commit(previous)

func boundary(edge: String) -> void:
	if main.modal_kind != "" or main.save_in_progress: return
	if not edges().has(edge): return
	var r: Dictionary = state()
	match str(r.place):
		"bedroom":
			if edge == "right" and r.stage == "morning":
				if not r.messages_checked: main._toast("Puedes revisar tus mensajes con E antes de salir"); return
				if not GameState.flags.get("backpack", false): main._toast("Recoge tu mochila antes de salir"); return
				go("breakfast", "living", Vector2(80, 285))
		"living":
			if edge == "left":
				if r.stage == "dinner": main._toast("Cena antes de subir a tu cuarto"); return
				go("morning" if r.stage in ["breakfast", "outbound"] else "evening", "bedroom", Vector2(670, 275))
			elif edge == "right":
				if r.stage == "breakfast": main._toast("Primero toma tu desayuno en la mesa"); return
				go("outbound", "street", Vector2(85, 285))
		"street":
			if edge == "right":
				if r.stage == "homeward": main._toast("Por hoy terminaron las clases. Tu casa está a la izquierda"); return
				go("arrival", "school", Vector2(385, 340))
			elif edge == "left": go("dinner" if r.stage == "homeward" else "outbound", "living", Vector2(670, 285))
		"school":
			if edge == "down":
				if r.stage != "farewell" or not GameState.flags.get("farewell_done", false): main._toast("Todavía tienes cosas por hacer en el colegio"); return
				go("homeward", "street", Vector2(670, 285))
			elif edge == "up":
				if not _school_ready(): main._toast("Conversa con todos tus amigos antes de entrar a clase"); return
				go("class", "classroom", Vector2(385, 350))
			elif edge == "right": go("arrival", "computer", Vector2(90, 290))
			elif edge == "left": go("arrival", "tutor", Vector2(660, 285))
		"computer", "tutor": go("arrival", "school", Vector2(650, 285) if r.place == "computer" else Vector2(90, 285))
		"classroom":
			if state().stage == "class_exit": go("farewell", "school", Vector2(385, 220))
			else: main._toast("Acércate al pupitre. La clase está por comenzar")

func _school_ready() -> bool:
	return GameState.flags.get("friends", false) if int(state().day) == 0 else main.coral_flow.everyone_heard(GameState.coral_state)

func interact(target: String) -> void:
	if main.save_in_progress: return
	match target:
		"backpack": main._commit_flag("backpack", "Mochila lista")
		"photo": main._inspect_d0("photo")
		"pc":
			if can_use_pc(): main._show_desktop()
		"meal":
			if state().stage in ["breakfast", "dinner"]: begin_scene("breakfast" if state().stage == "breakfast" else "dinner")
		"lesson":
			if state().stage == "class": begin_scene("lesson")
		"bed":
			if state().stage == "bedtime": go("sleep", "bedroom", Vector2(155, 208))
			else: main._toast("Todavía no es hora de dormir")
		"tutoria":
			if int(state().day) == 0: main._inspect_d0("tutoria")
			else: main._coral_interact(target)
		"friends":
			if state().stage == "farewell": begin_scene("goodbye")
			elif int(state().day) == 0:
				if GameState.flags.get("friends", false): main._toast("El grupo está listo. Entra a clase por arriba")
				else: main._show_dialogue("courtyard")
		_:
			if int(state().day) > 0: main._coral_interact(target)

func begin_scene(key: String) -> bool:
	if main.save_in_progress: return false
	var previous: Dictionary = GameState.snapshot()
	state().scene = key
	state().step = 0
	GameState.ui_modal = ""
	return await _commit(previous)

func _lines() -> Array:
	var day: int = int(state().day)
	match str(state().scene):
		"wake": return [{"speaker": "Narrador", "text": ["", "La alarma vuelve a sonar. Sofi se levanta pensando en la partida de ayer y en lo que sus amigos tendrán para contar.", "Sofi se despereza. Antes de salir, quiere ver si alguien dejó un mensaje durante la noche.", "Es una nueva mañana. Sofi recuerda las conversaciones de ayer y decide acercarse a sus amigos sin apurarlos.", "Sofi abre las cortinas. Hoy quiere escuchar a sus amigos y dar un paso concreto junto a ellos."][day]}]
		"breakfast": return [{"speaker": "Narrador", "text": "Sofi toma su desayuno en la sala. Por la ventana entra la luz de la mañana. Ya tiene la mochila lista para salir."}, {"speaker": "Sofi", "text": ["A ver si hoy llego antes que Mateo.", "Luego les pregunto cómo estuvo la noche. Primero, al colegio.", "Les voy a preguntar cómo están, sin insistir si no quieren contarme.", "Si alguien quiere hablar, puedo hacerle un espacio en el recreo.", "No tengo que resolverlo todo yo sola. Podemos buscar compañía."][day]}]
		"lesson":
			return [{"speaker": "Narrador", "text": "Sofi deja la mochila junto a su pupitre. El profesor comienza la clase y el grupo baja la voz."}, {"speaker": "Mateo", "text": ["¿Anotaste la tarea? Esta vez prometo no dejarla para el último minuto.", "Después te cuento cómo me fue jugando. Ahorita mejor copiamos esto.", "Me distraje un poco. ¿Me prestas tus apuntes cuando terminemos?", "Gracias por escucharme ayer. Luego seguimos hablando con calma.", "Al salir quiero conversar un momento. Me ayuda saber que estás cerca."][day]}, {"speaker": "Camila", "text": "Yo tengo los apuntes. Los revisamos juntos cuando termine la explicación."}, {"speaker": "Narrador", "text": "Entre ejercicios y comentarios en voz baja, la mañana pasa. Suena la campana y todos empiezan a guardar sus cosas."}]
		"goodbye": return [{"speaker": "Bruno", "text": ["¡Nos vemos al rato! Dejen la tarea lista antes de jugar.", "Ya saben, entramos cuando cada uno pueda. Nadie tiene que quedarse esperando.", "Voy a estar conectado más tarde. Si no quieren jugar, igual podemos conversar.", "Hoy puedo acompañarlos un rato. Me avisan si necesitan algo.", "Nos escribimos al llegar a casa. Lo que acordamos hoy sigue en pie."][day]}, {"speaker": "Sebas", "text": "Yo me voy por aquí. Gracias por hacerme un lugar hoy."}, {"speaker": "Camila", "text": "Lleguen con cuidado. Nos hablamos luego."}, {"speaker": "Mateo", "text": "Chau, Sofi. Después reviso el grupo."}, {"speaker": "Narrador", "text": "Los amigos toman caminos distintos. El cielo se vuelve naranja mientras Sofi emprende el regreso a casa."}]
		"dinner": return [{"speaker": "Narrador", "text": "De vuelta en casa, Sofi deja sus cosas y se sienta a cenar. Tiene un momento tranquilo para recordar lo que pasó en el colegio."}, {"speaker": "Sofi", "text": ["Ahora sí, voy a ver si ya se conectaron.", "Voy a revisar el grupo. Mateo dijo que tenía a alguien para presentarnos.", "Quiero saber cómo siguen todos después de lo que hablamos.", "Puedo compartir una partida sin dejar pendiente lo que nos preocupa.", "Voy a revisar nuestros mensajes y respetar lo que cada uno decidió contar."][day]}]
		"evening_chat": return [{"speaker": "Camila", "text": ["", "", "Ya llegué. Gracias por escucharme hoy, Sofi.", "¿Cómo están? Si quieren conversar antes de jugar, aquí estoy.", "Ya estoy en casa. Podemos seguir con el plan que acordamos hoy."][day]}, {"speaker": "Bruno", "text": "Podemos jugar una corta. Si alguien quiere parar, lo dice y listo."}, {"speaker": "Mateo", "text": "Gracias. Me gusta poder entrar sin sentir que debo quedarme toda la noche."}, {"speaker": "Sofi", "text": "Una partida y a descansar. Mañana seguimos hablando."}]
		"match_reply": return [{"speaker": "Camila", "text": main.draft_flow.camila_reaction(GameState.moba_result, GameState.moba_class)}, {"speaker": "Sofi", "text": "Gracias por jugar. Por hoy voy a apagar y descansar. Nos hablamos mañana."}]
	return []

func _render_scene() -> void:
	var lines: Array = _lines()
	if lines.is_empty(): return
	main.modal_kind = "routine"
	main._begin_conversation_presentation()
	var index: int = mini(int(state().step), lines.size() - 1)
	var line: Dictionary = lines[index]
	if state().scene in ["evening_chat", "match_reply"]:
		main.conversation_ui.show_chat("los-chicos", lines.slice(0, index + 1), [], advance_scene, "", Callable(), main._scaled_text_size(18))
	else:
		var speaker: String = str(line.speaker)
		main.conversation_ui.show_scene(main._conversation_background(), "Día %d" % int(state().day), speaker, str(line.text), [], advance_scene, "", speaker if speaker != "Narrador" else "Sofi", "Sofi" if speaker not in ["Sofi", "Narrador"] else "", false, main._scaled_text_size(18))

func advance_scene() -> bool:
	if main.save_in_progress: return false
	var previous: Dictionary = GameState.snapshot()
	state().step = int(state().step) + 1
	if int(state().step) < _lines().size(): return await _commit(previous)
	var finished: String = str(state().scene)
	state().scene = ""
	state().step = 0
	match finished:
		"breakfast": state().stage = "outbound"
		"lesson":
			AudioManager.play_effect("school_bell")
			state().stage = "class_exit"
			GameState.flags.farewell_done = false
		"goodbye": GameState.flags.farewell_done = true
		"dinner": state().stage = "evening"
		"evening_chat":
			state().chat_seen = true
			GameState.phone_messages.append_array(_lines_for_chat())
		"match_reply":
			state().matches.append(GameState.moba_result)
			state().stage = "bedtime"
			state().place = "bedroom"
			GameState.player_position = Vector2(355, 275)
	_phase_for_place()
	return await _commit(previous)

func _lines_for_chat() -> Array:
	var previous_scene: String = str(state().scene)
	state().scene = "evening_chat"
	var lines: Array = _lines()
	state().scene = previous_scene
	return lines

func _render_sleep() -> void:
	main.modal_kind = "sleep"
	main._begin_conversation_presentation()
	sleep_elapsed = 0.0
	sleep_overlay = Control.new()
	sleep_overlay.name = "SleepTransition"
	main.conversation_ui.add_child(sleep_overlay)
	main.conversation_ui.visible = true
	var shade := ColorRect.new()
	shade.name = "Shade"
	shade.size = Vector2(768, 448)
	shade.color = Color(0.06, 0.03, 0.12, 0)
	sleep_overlay.add_child(shade)
	var face := TextureRect.new()
	face.name = "SleepingSofi"
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.texture = load("res://assets/world/props/sofi_sleep.tres")
	face.position = Vector2(81, 115)
	face.size = Vector2(102, 110)
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_SCALE
	face.size = Vector2(102, 110)
	sleep_overlay.add_child(face)
	face.size = Vector2(102, 110)
	sleep_overlay.move_child(shade, sleep_overlay.get_child_count() - 1)
	var caption := Label.new()
	caption.name = "Caption"
	caption.position = Vector2(200, 265)
	caption.size = Vector2(368, 80)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.add_theme_font_size_override("font_size", 26)
	sleep_overlay.add_child(caption)

func _process(delta: float) -> void:
	if not active() or state().stage != "sleep" or main.modal_kind != "sleep" or main.save_in_progress or not is_instance_valid(sleep_overlay): return
	sleep_elapsed += delta
	sleep_overlay.get_node("SleepingSofi").scale.y = 1.0 + sin(sleep_elapsed * 2.1) * 0.012
	var shade: ColorRect = sleep_overlay.get_node("Shade")
	shade.color = Color("1b102b", clampf(sleep_elapsed / 1.5, 0, 0.97)) if sleep_elapsed < 3.0 else Color("f2cadb", clampf(1.0 - (sleep_elapsed - 3.0) / 1.5, 0, 0.97))
	sleep_overlay.get_node("Caption").text = "Sofi descansa…" if sleep_elapsed < 3.0 else "Amanece"
	if sleep_elapsed >= 4.5: finish_sleep()

func finish_sleep() -> bool:
	if main.save_in_progress or state().stage != "sleep": return false
	var previous: Dictionary = GameState.snapshot()
	var day: int = int(state().day)
	if day == 4:
		state().stage = "finished"
		GameState.phase = "coral"
		GameState.coral_state.chapter_scene_done = true
		GameState.coral_state.ending = main.coral_flow.ending_for(GameState.coral_state)
		GameState.coral_state.node = GameState.coral_state.ending
		GameState.coral_state.step = 0
		GameState.coral_state.mode = "ending"
	else:
		var matches: Array = state().matches.duplicate()
		GameState.flags.routine = new_state(day + 1)
		state().matches = matches
		state().scene = "wake"
		GameState.flags.backpack = false
		GameState.flags.farewell_done = false
		GameState.phone_messages.append({"speaker": "Camila", "text": "Buen día, Sofi. Nos vemos en el colegio. Podemos hablar cuando llegues."})
		GameState.coral_state = main.coral_flow.new_state() if day == 0 else GameState.coral_state
		GameState.coral_state.day = day + 1
		GameState.coral_state.mode = "explore"
		GameState.coral_state.node = ""
		GameState.coral_state.step = 0
		GameState.coral_state.chapter_scene_done = false
		GameState.player_position = Vector2(205, 245)
		_phase_for_place()
	return await _commit(previous)
