extends RefCounted
## Día 0: prólogo, guías de controles, observaciones y diálogos del patio y del chat.
## Se movió desde Main.gd sin cambios de comportamiento (paso 8 de la migración modular).

const ConversationUIScript = preload("res://scripts/ConversationUI.gd")

var main: Node

func begin_stage_guide(place: String) -> void:
	if main.save_in_progress: return
	var previous: Dictionary = GameState.snapshot()
	GameState.flags.d0_guide_active = place
	main.save_in_progress = true
	if await SaveManager.save_slot_async():
		main.save_in_progress = false
		render_stage_guide()
	else:
		GameState.restore(previous)
		main.save_in_progress = false
		main._toast("No se pudo guardar la guía")

func render_stage_guide() -> void:
	main.modal_kind = "stage_guide"
	main.ui_kit.begin_conversation_presentation()
	var place: String = str(GameState.flags.get("d0_guide_active", GameState.phase))
	var title: String = {"bedroom": "Antes de salir", "courtyard": "Un momento con tus amigos", "computer": "De vuelta en casa"}.get(place, "")
	var message: String = {
		"bedroom": "Sofi se prepara para ir al colegio. Muévete con WASD, acércate a la alarma y pulsa F. Después recoge la mochila y busca la puerta. La marca dorada indica dónde seguir; puedes mirar otros objetos antes de salir.",
		"courtyard": "Antes de entrar a clase, Sofi se encuentra con sus amigos en el patio. Acércate al grupo y pulsa F para conversar. Al terminar, sus amigos se despedirán y podrás ir hacia la salida.",
		"computer": "Pasaron las clases. Por la tarde, Sofi vuelve a casa, termina sus tareas y enciende la computadora. Sus amigos la esperan en el chat para preparar una partida. Acércate a la PC y pulsa F."
	}.get(place, "")
	main.conversation_ui.show_stage_card(title, message, finish_stage_guide, main.ui_kit.scaled_text_size(18))

func finish_stage_guide() -> bool:
	if main.save_in_progress or main.modal_kind != "stage_guide": return false
	var previous: Dictionary = GameState.snapshot()
	GameState.flags["d0_guide_" + GameState.phase + "_seen"] = true
	GameState.flags.erase("d0_guide_active")
	main.save_in_progress = true
	if await SaveManager.save_slot_async():
		main.save_in_progress = false
		main.ui_kit.close_modal()
		return true
	GameState.restore(previous)
	main.save_in_progress = false
	return false

func transition(next_phase: String, position: Vector2) -> void:
	var old_phase: String = GameState.phase
	var old_position: Vector2 = GameState.player_position
	var old_flags: Dictionary = GameState.flags.duplicate(true)
	if next_phase in ["courtyard", "computer"] and not GameState.flags.get("d0_guide_" + next_phase + "_seen", false): GameState.flags.d0_guide_active = next_phase
	GameState.phase = next_phase
	GameState.player_position = position
	main.world.enabled = false
	if await SaveManager.save_slot_async():
		if not main.is_inside_tree():
			return
		main.router.load_phase()
		AudioManager.play_effect("confirm")
		main.world.enabled = str(GameState.flags.get("d0_guide_active", "")).is_empty()
	else:
		GameState.flags = old_flags
		GameState.phase = old_phase
		GameState.player_position = old_position
		if main.modal_kind == "":
			main.world.enabled = true
		main._toast("Error al guardar. Reintenta la transición.")

func commit_flag(flag: String, message: String) -> void:
	var old_flags := GameState.flags.duplicate(true)
	GameState.flags[flag] = true
	main.world.enabled = false
	if await SaveManager.save_slot_async():
		if not main.is_inside_tree():
			return
		main.hud_view.update()
		AudioManager.play_effect("interact")
		main.world.enabled = true
		main._toast(message)
	else:
		GameState.flags = old_flags
		if main.modal_kind == "":
			main.world.enabled = true
		main._toast("Error al guardar")

func inspect(target: String) -> void:
	if main.save_in_progress: return
	var flag_name: String = "d0_" + target + "_seen"
	if not GameState.flags.get(flag_name, false):
		var previous: Dictionary = GameState.snapshot()
		GameState.flags[flag_name] = true
		main.save_in_progress = true
		if not await SaveManager.save_slot_async():
			GameState.restore(previous)
			main.save_in_progress = false
			main._toast("No se pudo guardar la observación")
			return
		main.save_in_progress = false
	main.ui_kit.clear_modal()
	main.modal_kind = "observation"
	main.ui_kit.modal_heading("SOFI OBSERVA", "objective")
	var descriptions := {
		"photo": "Sofi mira una foto con Mateo, Camila, Bruno y Sebas. Juegan juntos desde hace tiempo, aunque cada uno necesita su propio espacio y sus propios horarios.",
		"desk": "En su escritorio, Sofi recuerda el acuerdo del grupo: avisar cuando alguien se desconecte, no compartir datos de otra persona y aceptar un no sin insistir.",
		"tutoria": "El cartel de tutoría recuerda que se puede hablar con una persona adulta de confianza aun sin tener todas las respuestas. Pedir apoyo es una opción disponible desde el comienzo."
	}
	main.ui_kit.modal_text(str(descriptions.get(target, "")), 18)
	main.ui_kit.make_button("Volver", main.ui_kit.close_modal)

func render_prologue() -> void:
	main.modal_kind = "prologue"
	main.ui_kit.begin_conversation_presentation()
	main.conversation_ui.show_prologue("\n\n".join(main.PROLOGUE_LINES), advance_prologue, main.ui_kit.scaled_text_size(18))

func advance_prologue() -> void:
	if main.save_in_progress or main.modal_kind != "prologue": return
	main.save_in_progress = true
	var previous: Dictionary = GameState.flags.duplicate(true)
	GameState.flags.erase("prologue_step")
	GameState.flags.prologue_seen = true
	if await SaveManager.save_slot_async():
		main.save_in_progress = false
		if main.is_inside_tree(): show_dialogue("wakeup")
	else:
		GameState.flags = previous
		main.save_in_progress = false
		main._toast("No se pudo guardar el prólogo; reintentando")

func show_dialogue(key: String) -> void:
	if main.save_in_progress:
		return
	var errors: Array[String] = main.dialogue_story.load_story(main.DAY_0_PREVIEW, true)
	if not errors.is_empty() or not main.dialogue_story.start_at(key):
		main._toast("No se pudo abrir la conversación")
		return
	main.save_in_progress = true
	var previous := GameState.snapshot()
	GameState.dialogue_key = key
	GameState.dialogue_position = main.dialogue_story.position
	GameState.dialogue_choice = ""
	GameState.dialogue_history = []
	GameState.ui_modal = ""
	if await SaveManager.save_slot_async():
		main.dialogue_key = key
		main.dialogue_choice = ""
		main.dialogue_visible = 0.0
		if main.is_inside_tree():
			render_dialogue()
	else:
		GameState.restore(previous)
		main._toast("No se pudo guardar el diálogo; reintenta")
	main.save_in_progress = false

func resume_saved_dialogue() -> bool:
	var errors: Array[String] = main.dialogue_story.load_story(main.DAY_0_PREVIEW, true)
	if not errors.is_empty() or GameState.dialogue_position >= main.dialogue_story.data.get("nodes", []).size():
		return false
	main.dialogue_story.position = GameState.dialogue_position
	main.dialogue_key = GameState.dialogue_key
	main.dialogue_choice = GameState.dialogue_choice
	main.dialogue_visible = 0.0
	render_dialogue()
	return true

func render_dialogue(preserve_reveal: bool = false) -> void:
	if main.modal_kind == "pause":
		main.modal_before_pause = "dialogue"
		return
	main.modal_kind = "dialogue"
	var node: Dictionary = main.dialogue_story.current_node()
	if not preserve_reveal:
		main.dialogue_visible = 0.0
	var reaction: Dictionary = main.D0_CHAT_REACTIONS.get(main.dialogue_choice, {}) if main.dialogue_key == "group_chat" and node.get("speaker") == "Sofi" else {}
	var message: String = str(reaction.get("text", node.get("text", "")))
	var speaker: String = str(reaction.get("speaker", node.get("speaker", "")))
	main.dialogue_visible = float(message.length())
	var revealing: bool = false
	var choices: Array = node.get("choices", [])
	var options: Array = []
	if not revealing:
		for i in choices.size():
			var choice_id: String = str(choices[i].choice_id)
			options.append({"label": "%d · %s" % [i + 1, choices[i].text], "action": func(): request_dialogue_choice(choice_id)})
	var next_action: Callable = reveal_dialogue if revealing else advance_dialogue if node.get("next", null) != null else complete_dialogue
	var next_label: String = "Mostrar" if revealing else "Continuar"
	main.ui_kit.begin_conversation_presentation()
	if main.dialogue_key == "group_chat":
		var messages: Array = []
		for position in GameState.dialogue_history:
			var past: Dictionary = main.dialogue_story.data.nodes[int(position)]
			if not str(past.get("text", "")).is_empty():
				messages.append({"speaker": past.speaker, "text": past.text})
		if not reaction.is_empty():
			messages.append({"speaker": node.speaker, "text": node.text})
		if not message.is_empty():
			messages.append({"speaker": speaker, "text": message})
		main.dialogue_text_label = main.conversation_ui.show_chat("los-chicos", messages, options, next_action, next_label, render_dialogue_history, main.ui_kit.scaled_text_size(16))
		if message.is_empty():
			main.dialogue_text_label = null
	else:
		var partner: String = "Sofi" if main.dialogue_key == "courtyard" and speaker != "Sofi" else "Mateo" if main.dialogue_key == "courtyard" else ""
		main.dialogue_text_label = main.conversation_ui.show_scene("bedroom" if main.dialogue_key == "wakeup" else "courtyard", "Día 0 · " + ("Habitación" if main.dialogue_key == "wakeup" else "Patio"), speaker, message, options, next_action, next_label, speaker, partner, false, main.ui_kit.scaled_text_size(18), "", render_dialogue_history)
	if is_instance_valid(main.dialogue_text_label):
		main.dialogue_visible = float(main.dialogue_text_label.text.length())
		main.dialogue_text_label.visible_characters = main.dialogue_text_label.text.length()

func reveal_dialogue() -> void:
	main.dialogue_visible = float(main.dialogue_text_label.text.length()) if is_instance_valid(main.dialogue_text_label) else 0.0
	render_dialogue(true)

func render_dialogue_history() -> void:
	main.modal_kind = "dialogue_history"
	main.ui_kit.clear_modal()
	main.ui_kit.modal_heading("HISTORIAL · conversación actual", "history", 20)
	var body: VBoxContainer = main.ui_kit.content_box()
	var positions: Array = GameState.dialogue_history.duplicate()
	if positions.is_empty():
		main.ui_kit.add_text(body, "Todavía no hay líneas anteriores en esta conversación.", 16)
	for position in positions:
		if int(position) < 0 or int(position) >= main.dialogue_story.data.get("nodes", []).size():
			continue
		var line: Dictionary = main.dialogue_story.data.nodes[int(position)]
		if str(line.get("text", "")).is_empty():
			continue
		main.ui_kit.add_text(body, "%s\n%s" % [line.get("speaker", ""), ConversationUIScript.dialogue_text(str(line.get("text", "")))], 17)
	main.ui_kit.add_button(body, "Volver al diálogo", func(): render_dialogue(true)).grab_focus()

func request_dialogue_choice(choice_id: String) -> bool:
	if main.save_in_progress or main.modal_kind != "dialogue":
		return false
	for choice in main.dialogue_story.current_node().get("choices", []):
		if str(choice.get("choice_id", "")) == choice_id:
			return await choose_dialogue(choice_id)
	return false

func advance_dialogue() -> void:
	if main.save_in_progress:
		return
	var previous_position: int = main.dialogue_story.position
	var previous_history: Array = GameState.dialogue_history.duplicate()
	if not main.dialogue_story.advance():
		return
	main.save_in_progress = true
	GameState.dialogue_position = main.dialogue_story.position
	GameState.dialogue_history.append(previous_position)
	if await SaveManager.save_slot_async():
		if main.is_inside_tree():
			AudioManager.play_effect("confirm")
			render_dialogue()
	else:
		main.dialogue_story.position = previous_position
		GameState.dialogue_position = previous_position
		GameState.dialogue_history = previous_history
		main._toast("No se pudo guardar el avance; reintenta")
	main.save_in_progress = false

func choose_dialogue(choice_id: String) -> bool:
	if main.save_in_progress:
		return false
	var previous_position: int = main.dialogue_story.position
	var previous_history: Array = GameState.dialogue_history.duplicate()
	if not main.dialogue_story.advance(choice_id):
		return false
	main.save_in_progress = true
	GameState.dialogue_position = main.dialogue_story.position
	GameState.dialogue_choice = choice_id
	GameState.dialogue_history.append(previous_position)
	if await SaveManager.save_slot_async():
		main.dialogue_choice = choice_id
		if main.is_inside_tree():
			AudioManager.play_effect("confirm")
			render_dialogue()
		main.save_in_progress = false
		return true
	else:
		main.dialogue_story.position = previous_position
		GameState.dialogue_position = previous_position
		GameState.dialogue_choice = main.dialogue_choice
		GameState.dialogue_history = previous_history
		main._toast("No se pudo guardar la opción; reintenta")
	main.save_in_progress = false
	return false

func complete_dialogue() -> void:
	if main.save_in_progress:
		return
	main.save_in_progress = true
	var previous := GameState.snapshot()
	match main.dialogue_key:
		"wakeup":
			GameState.flags.wakeup_seen = true
			if not GameState.flags.get("d0_guide_bedroom_seen", false): GameState.flags.d0_guide_active = "bedroom"
		"courtyard": GameState.flags.friends = true
		"group_chat":
			if main.dialogue_choice.is_empty():
				main.save_in_progress = false
				return
			GameState.flags.d0_chat_done = true
			GameState.flags.d0_chat_choice = main.dialogue_choice
			GameState.phone_messages = []
			for i in range(14, 19):
				var node: Dictionary = main.dialogue_story.data.nodes[i]
				GameState.phone_messages.append({"speaker": node.speaker, "text": node.text})
			var answer: Dictionary = main.dialogue_story.current_node()
			GameState.phone_messages.append({"speaker": answer.speaker, "text": answer.text})
			var reply: Dictionary = main.D0_CHAT_REACTIONS.get(main.dialogue_choice, {})
			if not reply.is_empty():
				GameState.phone_messages.append({"speaker": reply.speaker, "text": reply.text})
	GameState.dialogue_key = ""
	GameState.dialogue_position = 0
	GameState.dialogue_choice = ""
	GameState.dialogue_history = []
	if not await SaveManager.save_slot_async():
		main.save_in_progress = false
		GameState.restore(previous)
		main._toast("No se pudo guardar el diálogo; reintenta")
		return
	main.save_in_progress = false
	main.hud_view.update()
	var finished_key: String = main.dialogue_key
	main.dialogue_key = ""
	if main.modal_kind == "pause":
		if finished_key == "group_chat": main.computer.show_desktop()
		else: main.phase_load_after_pause = true
		return
	if finished_key == "group_chat":
		main.computer.show_desktop()
	else:
		main.ui_kit.close_modal()
		main.router.load_phase()
