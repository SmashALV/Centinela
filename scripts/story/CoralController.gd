extends RefCounted
## Control de la historia coral (D1–D4): escenas, elecciones, consejo del tutor, cierre del día y resumen final.
## Se movió desde Main.gd sin cambios de comportamiento (paso 4 de la migración modular).

const ConversationUIScript = preload("res://scripts/ConversationUI.gd")
const CoralFlowScript = preload("res://scripts/narrative/CoralStoryFlow.gd")

var main: Node

func show_d1_interlude() -> bool:
	if main.save_in_progress or GameState.phase != "result":
		return false
	main.save_in_progress = true
	GameState.flags.d1_interlude_active = true
	if await SaveManager.save_slot_async():
		main.save_in_progress = false
		main._show_result()
		return true
	GameState.flags.erase("d1_interlude_active")
	main.save_in_progress = false
	main._toast("No se pudo guardar el avance; reintenta")
	return false

func start_story() -> bool:
	if main.save_in_progress or main.coral_flow.content.is_empty() or GameState.phase != "result":
		return false
	var previous: Dictionary = GameState.snapshot()
	GameState.phase = "coral"
	GameState.coral_state = main.coral_flow.new_state()
	GameState.flags.erase("d1_interlude_active")
	GameState.player_position = Vector2(180, 315)
	return await save(previous)

func world_targets() -> Dictionary:
	var targets := {"camila": Vector2(310, 240), "bruno": Vector2(230, 250),
		"sebas": Vector2(420, 250), "mateo": Vector2(525, 235),
		"tutoria": Vector2(165, 310), "salida": Vector2(385, 345)}
	if int(GameState.coral_state.get("day", 1)) == 1: targets.lobby = Vector2(650, 318)
	if int(GameState.coral_state.get("day", 1)) == 4: targets.pc = Vector2(650, 318)
	return targets

func primary_target() -> String:
	return main.coral_flow.route_target(GameState.coral_state)

func save(previous: Dictionary) -> bool:
	if main.save_in_progress:
		return false
	main.save_in_progress = true
	if await SaveManager.save_slot_async():
		main.save_in_progress = false
		if main.is_inside_tree():
			main._load_phase()
		return true
	GameState.restore(previous)
	main.save_in_progress = false
	main._toast("No se pudo guardar el avance; reintenta")
	return false

func begin_scene(scene_id: String) -> bool:
	if main.save_in_progress or GameState.phase != "coral": return false
	var previous: Dictionary = GameState.snapshot()
	GameState.coral_state.mode = "scene"
	GameState.coral_state.node = scene_id
	GameState.coral_state.step = 0
	return await save(previous)

func interact(target: String) -> void:
	var state: Dictionary = GameState.coral_state
	if state.get("mode") != "explore" or main.save_in_progress: return
	var day: int = int(state.get("day", 1))
	if target in ["camila", "mateo", "sebas", "bruno"]:
		if main.coral_flow.talked_today(state, target):
			main._toast("Ya conversaste con " + target.capitalize() + " hoy. Puedes acercarte a los demás antes de salir.")
		else: begin_scene(main.coral_flow.companion_scene(state, target))
	elif target == "tutoria":
		begin_scene("I_TUTOR")
	elif target == "lobby" and day == 1:
		if state.get("actions", []).has("D1_LOBBY_DONE"):
			main._toast("La partida ya está preparada. Puedes seguir conversando antes de salir.")
		else: begin_scene("D1_GATE")
	elif target == "pc" and day == 4:
		begin_scene("I_LIMIT")
	elif target == "salida":
		if not main.coral_flow.everyone_heard(state):
			main._toast("Todavía puedes conversar con los compañeros que faltan")
		elif day == 1 and not state.get("actions", []).has("D1_LOBBY_DONE"):
			main._toast("Prepara la partida en el lobby antes de salir")
		elif day == 4: finish_day()
		else: next_day()

func next_day() -> bool:
	if main.daily.active(): return false
	if main.save_in_progress or GameState.phase != "coral" or not main.coral_flow.everyone_heard(GameState.coral_state): return false
	if int(GameState.coral_state.day) >= 4: return false
	if int(GameState.coral_state.day) == 1 and not GameState.coral_state.actions.has("D1_LOBBY_DONE"): return false
	var previous: Dictionary = GameState.snapshot()
	GameState.coral_state.day = int(GameState.coral_state.day) + 1
	GameState.coral_state.mode = "intro"
	GameState.coral_state.node = ""
	GameState.coral_state.step = 0
	GameState.coral_state.chapter_scene_done = false
	GameState.player_position = Vector2(180, 315)
	return await save(previous)

func advance() -> bool:
	if main.save_in_progress or GameState.phase != "coral": return false
	var state: Dictionary = GameState.coral_state
	var previous: Dictionary = GameState.snapshot()
	if state.mode == "intro":
		var narrator_id: String = "D%d_INTRO_%d" % [int(state.day), int(state.step)]
		if not state.seen_narrator.has(narrator_id): state.seen_narrator.append(narrator_id)
		state.step = int(state.step) + 1
		if int(state.step) >= 2:
			state.mode = "explore"
			state.step = 0
		return await save(previous)
	if state.mode != "scene" and state.mode != "ending": return false
	var scene: Dictionary = main.coral_flow.scene(str(state.node), main.preview_catalog, main.draft_flow, state)
	var lines: Array = scene.get("lines", [])
	if int(state.step) < lines.size() - 1 or (int(state.step) == lines.size() - 1 and not scene.get("choices", []).is_empty()):
		state.step = int(state.step) + 1
		return await save(previous)
	return await finish_scene(previous)

func choose(key: String) -> bool:
	if main.save_in_progress or GameState.phase != "coral" or GameState.coral_state.get("mode") != "scene": return false
	var state: Dictionary = GameState.coral_state
	var scene_id: String = str(state.node)
	var scene: Dictionary = main.coral_flow.scene(scene_id, main.preview_catalog, main.draft_flow, state)
	if int(state.step) != scene.get("lines", []).size(): return false
	var valid := false
	for choice in scene.get("choices", []):
		if choice.get("key") == key: valid = true
	if not valid: return false
	var previous: Dictionary = GameState.snapshot()
	state.choices[scene_id] = key
	if scene_id.begins_with("D2_"):
		var companion: String = scene_id.trim_prefix("D2_")
		state.focus = companion
		state.companion_states[companion] = {"trusted": key == "A", "repair_needed": key == "B"}
		var fact: String = str(CoralFlowScript.D2_FACTS.get(companion, ""))
		if not state.observed.has(fact): state.observed.append(fact)
	elif scene_id.begins_with("D4_") and key == "A" and scene_id.ends_with("2"):
		if not state.actions.has("REPAIR_OFFERED"): state.actions.append("REPAIR_OFFERED")
		var repaired: String = scene_id.substr(3, 1)
		if state.companion_states.has(repaired): state.companion_states[repaired].repair_needed = false
	if scene_id.begins_with("D4_"):
		# El plan acordado guía el objetivo; el final exige realizar la acción.
		var plan: String = "SUPPORT_PLANNED" if key == "A" else "LIMIT_PLANNED" if scene_id.ends_with("1") else ""
		if not plan.is_empty() and not state.actions.has(plan): state.actions.append(plan)
	var kind: String = str(CoralFlowScript.CHOICE_BEHAVIOR.get(scene_id, {}).get(key, ""))
	state.behavior = main.coral_flow.behavior_profile(state).label
	state.mode = "reaction"
	state.step = 0
	var saved: bool = await save(previous)
	if saved and not kind.is_empty():
		main._toast("Respuesta registrada como: " + str(CoralFlowScript.BEHAVIOR_LABELS[kind]).to_lower())
	return saved

func finish_scene(previous: Dictionary = {}) -> bool:
	if main.save_in_progress or GameState.phase != "coral": return false
	var rollback: Dictionary = previous if not previous.is_empty() else GameState.snapshot()
	var state: Dictionary = GameState.coral_state
	var scene_id: String = str(state.node)
	if main.daily.active() and scene_id in ["D1_GATE", "D1_B_FOLLOW"]:
		for line in main.coral_flow.scene(scene_id, main.preview_catalog, main.draft_flow, state).get("lines", []):
			if line.get("speaker") != "Narrador": GameState.phone_messages.append({"speaker": line.speaker, "text": line.text, "channel": "mateo" if scene_id == "D1_B_FOLLOW" else "group"})
	state.node = ""
	state.step = 0
	state.mode = "explore"
	if scene_id.begins_with("I_D1_"):
		var action_id: String = scene_id.trim_prefix("I_").replace("D1_", "D1_TALK_")
		if not state.actions.has(action_id): state.actions.append(action_id)
	elif scene_id == "I_TUTOR":
		if not state.get("observed", []).is_empty():
			state.adult_support_started = true
			if not state.actions.has("ADULT_SUPPORT_STARTED"): state.actions.append("ADULT_SUPPORT_STARTED")
		elif not state.actions.has("TUTOR_INFO_SEEN"): state.actions.append("TUTOR_INFO_SEEN")
	elif scene_id == "I_LIMIT":
		state.limit_completed = true
		if not state.actions.has("DIGITAL_LIMIT_COMPLETED"): state.actions.append("DIGITAL_LIMIT_COMPLETED")
	elif scene_id == "D1_GATE":
		state.node = "D1_%s_FOLLOW" % str(state.choices.get("D1_GATE", "B"))
		state.mode = "scene"
	elif scene_id.begins_with("D1_") and scene_id.ends_with("_FOLLOW"):
		if scene_id != "D1_B_FOLLOW":
			state.node = "D1_B_FOLLOW"
			state.mode = "scene"
		elif not state.actions.has("D1_LOBBY_DONE"): state.actions.append("D1_LOBBY_DONE")
	elif scene_id.begins_with("D2_"):
		if not state.actions.has("DONE_" + scene_id): state.actions.append("DONE_" + scene_id)
		state.focus = scene_id.trim_prefix("D2_")
		state.node = "N_D2"
		state.mode = "scene"
	elif scene_id == "N_D2":
		var narrator_id: String = "D2_OBSERVED_" + str(state.get("focus", ""))
		if not state.seen_narrator.has(narrator_id): state.seen_narrator.append(narrator_id)
	elif scene_id.begins_with("D3_") or scene_id.begins_with("D4_") or scene_id.begins_with("I_D2_") or scene_id.begins_with("I_D3_") or scene_id.begins_with("I_D4_"):
		if not state.actions.has("DONE_" + scene_id): state.actions.append("DONE_" + scene_id)
		state.chapter_scene_done = int(state.day) == 4 and main.coral_flow.everyone_heard(state)
	elif scene_id.begins_with("F0"):
		state.mode = "summary"
	return await save(rollback)

func finish_day() -> bool:
	if main.daily.active(): return false
	if main.save_in_progress or GameState.phase != "coral" or int(GameState.coral_state.get("day", 0)) != 4 or not GameState.coral_state.get("chapter_scene_done", false): return false
	var previous: Dictionary = GameState.snapshot()
	var state: Dictionary = GameState.coral_state
	state.ending = main.coral_flow.ending_for(state)
	state.node = str(state.ending)
	state.step = 0
	state.mode = "ending"
	return await save(previous)

func render() -> void:
	var state: Dictionary = GameState.coral_state
	var mode: String = str(state.get("mode", "explore"))
	if mode == "explore":
		main._close_modal()
		return
	if mode == "summary":
		render_summary()
		return
	main.modal_kind = "coral"
	main._begin_conversation_presentation()
	if mode == "intro":
		var intro: Array = main.coral_flow.content.get("day_intros", {}).get(str(state.day), [])
		if int(state.step) >= intro.size(): return
		main.conversation_ui.show_scene(main._conversation_background(), "Día %d" % state.day, "Narrador", str(intro[int(state.step)]), [], advance, "Continuar", "Sofi", "", false, main._scaled_text_size(18))
		return
	var scene_id: String = str(state.get("node", ""))
	var scene: Dictionary = main.coral_flow.scene(scene_id, main.preview_catalog, main.draft_flow, state)
	var lines: Array = scene.get("lines", [])
	var selected: String = str(state.get("choices", {}).get(scene_id, ""))
	var current: Dictionary = {}
	var options: Array = []
	var next_action: Callable = advance
	if mode == "reaction":
		current = main.coral_flow.content.get("reactions", {}).get(scene_id, {}).get(selected, {})
		next_action = finish_scene
	elif int(state.step) < lines.size():
		current = lines[int(state.step)]
	elif not scene.get("choices", []).is_empty():
		for choice in scene.choices:
			var key: String = str(choice.get("key", ""))
			options.append({"label": str(choice.get("text", "")), "action": func(): choose(key)})
		options.append({"label": "¿No sabes qué responder? Pide un consejo al tutor (no elige por ti)", "action": func(): show_tutor_advice(scene_id)})
	else:
		return
	var presentation: String = str(scene.get("presentation", "vn"))
	if presentation in ["group", "dm"] and str(current.get("speaker", "")) == "Narrador" and options.is_empty():
		main.conversation_ui.show_scene(main._conversation_background(), "Día %d · %s" % [int(scene.get("day", state.day)), str(scene.get("title", "Historia"))], "Narrador", str(current.get("text", "")), [], next_action, "Continuar", "Sofi", "", false, main._scaled_text_size(18))
		return
	if presentation in ["group", "dm"]:
		var messages: Array = lines.slice(0, mini(int(state.step) + 1, lines.size())) if mode != "reaction" else lines.duplicate(true)
		var system_note: String = ""
		if mode == "reaction":
			var choice_text: String = ""
			for choice in scene.get("choices", []):
				if choice.get("key") == selected: choice_text = str(choice.get("text", ""))
			messages.append({"speaker": "Sofi", "text": choice_text})
			messages.append(current)
		for message in messages.duplicate():
			if str(message.get("speaker", "")) == "Narrador":
				system_note = str(message.get("text", ""))
				messages.erase(message)
		if presentation == "group":
			main.conversation_ui.show_chat("lobby-de-juego", messages, options, next_action, "Continuar", Callable(), main._scaled_text_size(15), system_note)
		else:
			main.conversation_ui.show_direct_chat("Mateo", messages, options, next_action, "Continuar", main._scaled_text_size(15), system_note)
		return
	var speaker: String = str(current.get("speaker", "Narrador"))
	var actor: String = str(scene.get("actor", ""))
	if actor.is_empty() and scene_id.begins_with("I_D1_"): actor = scene_id.trim_prefix("I_D1_").capitalize()
	var sprite: String = main._scene_sprite_key(speaker, scene_id, selected)
	if "(mensaje)" in speaker and not actor.is_empty(): sprite = main._scene_sprite_key(actor, scene_id, selected)
	if not ConversationUIScript.SPRITES.has(sprite): sprite = speaker if ConversationUIScript.SPRITES.has(speaker) else actor
	var partner: String = "Sofi" if speaker != "Sofi" and actor != "Sofi" else actor
	if speaker == "Narrador": sprite = "Sofi"
	var background: String = main._conversation_background()
	main.conversation_ui.show_scene(background, "Día %d · %s" % [int(scene.get("day", state.day)), str(scene.get("title", "Historia"))], speaker, str(current.get("text", "")), options, next_action, "Continuar", sprite, partner, "(mensaje)" in speaker, main._scaled_text_size(18))

func render_summary() -> void:
	main.modal_kind = "coral"
	main._clear_modal()
	main._modal_heading("HISTORIA CONCLUIDA", "result")
	var body: VBoxContainer = main._preview_content()
	var ending: String = str(GameState.coral_state.get("ending", "F03"))
	var description: String = {"F01": "Se inició una conversación de apoyo con una persona adulta.", "F02": "Se ajustó la privacidad o el contacto con permiso.", "F03": "Hay pasos de protección pendientes; aún se puede pedir ayuda."}.get(ending, "")
	main._preview_text(body, description, 20)
	main._preview_text(body, "Sofi pudo escuchar a todo el grupo. Sus respuestas cambiaron la confianza de cada compañero y las acciones que concretaron juntos.", 16)
	var profile: Dictionary = main.coral_flow.behavior_profile(GameState.coral_state)
	main._preview_text(body, "Clasificación del comportamiento: %s (%d protectoras, %d con límite, %d de riesgo)" % [profile.label, profile.counts.protectora, profile.counts.limite, profile.counts.riesgo], 17)
	for detail in profile.details:
		main._preview_text(body, "· %s: %s" % [detail.name, detail.label], 14)
	if int(profile.unrepaired_recess) >= 2 and ending == "F03" and GameState.coral_state.get("limit_completed", false):
		main._preview_text(body, "Las respuestas del recreo sin reparar impidieron que el límite acordado sostuviera al grupo.", 15)
	main._preview_button(body, "Volver al menú", main._return_to_menu)

func show_tutor_advice(scene_id: String) -> void:
	var state: Dictionary = GameState.coral_state
	var action_id: String = "ADVICE_" + scene_id
	if not state.get("actions", []).has(action_id) and state.get("actions", []).size() < 100: state.actions.append(action_id)
	main.conversation_ui.show_advice("Tutor", main.coral_flow.decision_advice(scene_id))
