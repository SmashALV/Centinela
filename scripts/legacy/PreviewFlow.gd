extends RefCounted
## Flujo heredado de vista previa y borrador recuperados (D1–D4 de una sola ruta).
## Solo lo usan partidas guardadas antes de la rutina diaria y la historia coral.
## Se movió desde Main.gd sin cambios de comportamiento (paso 1 de la migración modular).

const DraftFlowScript = preload("res://scripts/narrative/PlayableDraftFlow.gd")
const PreviewCatalogScript = preload("res://scripts/narrative/RecoveredPreviewCatalog.gd")
const ConversationUIScript = preload("res://scripts/ConversationUI.gd")

var main: Node

func start_playable_draft() -> bool:
	if main.save_in_progress or main.draft_flow.content.is_empty() or main.preview_catalog.scenes.is_empty():
		return false
	var previous := GameState.snapshot()
	GameState.flags.draft_mode = true
	GameState.flags.draft_completed = false
	GameState.flags.draft_ending = ""
	GameState.flags.erase("d1_interlude_active")
	GameState.preview_choices.clear()
	if await commit_preview("D1_02_A", 0, "", false, true):
		return true
	GameState.restore(previous)
	return false

func render_day_intro() -> void:
	var scene_id: String = GameState.preview_scene
	var introduction: Array = main.draft_flow.day_introduction(scene_id)
	var step: int = int(GameState.flags.get("draft_intro_step", 0))
	if step < 0 or step >= introduction.size():
		push_error("Presentación diaria inválida: " + scene_id)
		return
	main.modal_kind = "day_intro"
	main.ui_kit.begin_conversation_presentation()
	var scene: Dictionary = main.preview_catalog.get_scene(scene_id)
	var title: String = "Día %d · %s" % [int(scene.get("day", 1)), scene_title(scene)]
	var background: String = main.router.conversation_background()
	main.conversation_ui.show_scene(background, title, "Narrador", str(introduction[step]), [], advance_day_intro,
		"Continuar", "Sofi", "", false, main.ui_kit.scaled_text_size(18))

func advance_day_intro() -> bool:
	if main.save_in_progress or GameState.phase != "preview" or not GameState.flags.get("draft_mode", false) or not GameState.flags.get("draft_exploring", false) or not GameState.flags.has("draft_intro_step"):
		return false
	var previous: Dictionary = GameState.snapshot()
	var next_step: int = int(GameState.flags.draft_intro_step) + 1
	if next_step < main.draft_flow.day_introduction(GameState.preview_scene).size():
		GameState.flags.draft_intro_step = next_step
	else:
		GameState.flags.erase("draft_intro_step")
	main.save_in_progress = true
	if await SaveManager.save_slot_async():
		main.save_in_progress = false
		main.router.load_phase()
		return true
	GameState.restore(previous)
	main.save_in_progress = false
	main._toast("No se pudo guardar la presentación del día")
	return false

func commit_preview(next_scene: String, next_step: int, choice_key: String = "", mark_reviewed: bool = false, explore: bool = false) -> bool:
	if main.save_in_progress or main.preview_catalog.scenes.is_empty():
		return false
	main.save_in_progress = true
	var previous := GameState.snapshot()
	GameState.phase = "preview"
	GameState.ui_modal = ""
	GameState.preview_scene = next_scene
	GameState.preview_step = next_step
	if GameState.flags.get("draft_mode", false):
		GameState.flags.draft_exploring = explore
		if explore:
			GameState.player_position = Vector2(180, 315)
			GameState.hint_level = 0
			GameState.flags.draft_intro_step = 0
		else:
			GameState.flags.erase("draft_intro_step")
	if not choice_key.is_empty():
		GameState.preview_choices[next_scene] = choice_key
	if mark_reviewed:
		GameState.flags.preview_reviewed = true
	if await SaveManager.save_slot_async():
		main.save_in_progress = false
		if main.is_inside_tree():
			main.router.load_phase()
		return true
	else:
		GameState.restore(previous)
		main.save_in_progress = false
		main._toast("No se pudo guardar el avance; reintenta")
	return false

func preview_line(parent: VBoxContainer, line: Dictionary) -> void:
	var speaker: String = str(line.get("speaker", ""))
	if "(mensaje)" in speaker:
		var card := PanelContainer.new()
		card.custom_minimum_size.x = 545
		var style := StyleBoxFlat.new()
		style.bg_color = Color("263550")
		style.border_color = Color("d5a4ca")
		style.set_border_width_all(1)
		style.set_content_margin_all(10)
		card.add_theme_stylebox_override("panel", style)
		parent.add_child(card)
		var message_box := VBoxContainer.new()
		card.add_child(message_box)
		main.ui_kit.add_text(message_box, "CHAT MOSTRADO POR MATEO" if GameState.preview_scene == "D2_03_A" else "MENSAJE RECUPERADO", 13, 515)
		main.ui_kit.add_text(message_box, speaker, 16, 515)
		main.ui_kit.add_text(message_box, "«" + ConversationUIScript.dialogue_text(str(line.get("text", ""))) + "»", 18, 515)
	else:
		main.ui_kit.add_text(parent, speaker, 18)
		main.ui_kit.add_text(parent, "«" + ConversationUIScript.dialogue_text(str(line.get("text", ""))) + "»", 19)

func scene_title(scene: Dictionary) -> String:
	var title: String = str(scene.get("title", "Historia"))
	if title.begins_with("F0") and " · " in title:
		return title.get_slice(" · ", 1).capitalize()
	return title

func scene_portrait_path(speaker: String, scene_id: String, choice: String = "") -> String:
	if speaker == "Kairo":
		return "res://assets/vn/kairo_v4.png"
	if speaker == "Sofi" and scene_id in ["D3_01_A", "D4_01_A", "D4_02_A", "D4_03_A", "F03"]:
		return main.EMOTION_PORTRAITS["Sofi_concerned"]
	if speaker == "Mateo":
		if choice == "A" and scene_id in ["D3_01_A", "D4_01_A", "D4_02_A", "D4_03_A", "F01_A", "F01_B"]:
			return main.EMOTION_PORTRAITS["Mateo_relieved"]
		if scene_id in ["D4_01_A", "F03"]:
			return main.EMOTION_PORTRAITS["Mateo_alarmed"]
		if scene_id in ["D2_03_A", "D3_01_A", "D4_02_A", "D4_03_A", "F02"]:
			return main.EMOTION_PORTRAITS["Mateo_worried"]
	return str(main.PORTRAITS.get(speaker, ""))

func scene_parts(scene_id: String, draft_mode: bool) -> Dictionary:
	var scene: Dictionary = main.preview_catalog.get_scene(scene_id)
	var lines: Array = scene.get("lines", []).duplicate(true)
	var after_choice: Array = scene.get("after_choice", []).duplicate(true)
	var later_chat: Array = scene.get("later_chat", []).duplicate(true)
	if draft_mode:
		if scene_id == "D3_01_A":
			var opening: Dictionary = main.draft_flow.d3_opening(GameState.preview_choices)
			if not opening.is_empty():
				lines.insert(2, opening)
		elif scene_id == "F03":
			later_chat.append_array(main.draft_flow.ending_tail(scene_id))
		elif DraftFlowScript.ENDING_IDS.has(scene_id):
			lines.append_array(main.draft_flow.ending_tail(scene_id))
		after_choice.append_array(main.draft_flow.extra_after_choice(scene_id))
	return {"lines": lines, "after_choice": after_choice, "later_chat": later_chat, "choices": scene.get("choices", [])}

func preview_next_action(scene_id: String) -> Callable:
	if GameState.flags.get("draft_mode", false):
		var next_id: String = main.draft_flow.next_main(scene_id)
		if scene_id == "D4_03_A":
			next_id = main.draft_flow.ending_for(str(GameState.preview_choices.get(scene_id, "")), GameState.preview_choices)
		elif scene_id == "F01_A":
			next_id = "F01_B"
		if not next_id.is_empty():
			var next_explore: bool = DraftFlowScript.EXPLORATION_IDS.has(next_id) and scene_id not in ["D4_01_A", "D4_02_A"]
			return func(): commit_preview(next_id, 0, "", false, next_explore)
		return finish_draft
	var independent_next: String = main.preview_catalog.next_main(scene_id) if PreviewCatalogScript.MAIN_ORDER.has(scene_id) else ""
	if not independent_next.is_empty():
		return func(): commit_preview(independent_next, 0)
	if PreviewCatalogScript.MAIN_ORDER.has(scene_id):
		return func(): commit_preview("ENDINGS_INDEX", 0)
	return finish_preview

func render_preview_story(scene_id: String, draft_mode: bool) -> void:
	var scene: Dictionary = main.preview_catalog.get_scene(scene_id)
	if scene.is_empty():
		main.ui_kit.modal_heading("ESCENA", "dialogue")
		main.ui_kit.modal_text("Esta escena no está disponible.")
		return
	var step: int = GameState.preview_step
	var parts: Dictionary = scene_parts(scene_id, draft_mode)
	var lines: Array = parts.lines
	var choices: Array = parts.choices
	var after_choice: Array = parts.after_choice
	var later_chat: Array = parts.later_chat
	var selected: String = str(GameState.preview_choices.get(scene_id, ""))
	var current: Dictionary = {}
	var options: Array = []
	var next_action: Callable = Callable()
	var next_label := "Continuar"
	var terminal := false
	if step < lines.size():
		current = lines[step]
		next_action = func(): commit_preview(scene_id, step + 1)
	elif not choices.is_empty():
		if step == lines.size():
			for i in choices.size():
				var key: String = str(choices[i].key)
				options.append({"label": "%d · %s" % [i + 1, choices[i].text], "action": func(): request_preview_choice(scene_id, key)})
		elif draft_mode and step == lines.size() + 1:
			current = {"speaker": "Mateo", "text": main.draft_flow.choice_reaction(scene_id, selected)}
			next_action = func(): commit_preview(scene_id, step + 2)
		elif step == lines.size() + (2 if draft_mode else 1):
			current = {"speaker": "Mateo", "text": main.draft_flow.choice_reaction(scene_id, selected)}
			next_action = func(): commit_preview(scene_id, step + 1)
		elif step < lines.size() + 2 + after_choice.size() + (1 if draft_mode else 0):
			current = after_choice[step - lines.size() - 2 - (1 if draft_mode else 0)]
			next_action = func(): commit_preview(scene_id, step + 1)
	elif not later_chat.is_empty():
		if step == lines.size():
			current = {"speaker": "Narrador", "text": "Mateo recibe nuevos mensajes."}
		else:
			var later_index: int = step - lines.size() - 1
			if later_index < later_chat.size():
				current = later_chat[later_index]
		if not current.is_empty():
			next_action = func(): commit_preview(scene_id, step + 1)
	var terminal_step: int = draft_terminal_step(scene_id) if draft_mode else main.preview_catalog.terminal_step(scene_id)
	if not current.is_empty() and options.is_empty() and step == terminal_step - 1:
		next_action = preview_next_action(scene_id)
	if current.is_empty() and options.is_empty():
		terminal = true
		current = {"speaker": "Narrador", "text": "La conversación continúa."}
		next_action = preview_next_action(scene_id)
		next_label = "Continuar"
	var additional: Callable = render_unplaced_preview if terminal and not draft_mode and scene.has("unplaced_lines") else Callable()
	var day_label: String = "Final" if scene.get("day") == null else "Día " + str(int(scene.day))
	var title: String = day_label + " · " + scene_title(scene)
	var note: String = main.draft_flow.connector(scene_id) if draft_mode and step == 0 and scene_id != "D1_02_A" else ""
	if draft_mode and step == 0 and scene_id == "F01_A":
		note = main.draft_flow.f01_context(str(GameState.preview_choices.get("D4_03_A", "")))
	main.ui_kit.begin_conversation_presentation()
	if scene_id == "D1_02_A":
		var messages: Array = []
		for i in range(mini(step, lines.size())):
			messages.append(lines[i])
		if step >= lines.size() and not selected.is_empty():
			for choice in choices:
				if str(choice.key) == selected:
					messages.append({"speaker": "Sofi", "text": choice.text})
					break
		if not current.is_empty() and step < lines.size():
			messages.append(current)
		elif step > lines.size():
			messages.append(current)
		main.conversation_ui.show_chat("lobby-de-juego", messages, options, next_action, next_label, additional, main.ui_kit.scaled_text_size(16), note, "Escena adicional")
		return
	if draft_mode and scene_id in ["D1_03_A", "D2_03_A"]:
		var messages: Array = []
		for i in range(mini(step, lines.size())):
			messages.append(lines[i])
		if step >= lines.size() and not selected.is_empty():
			for choice in choices:
				if str(choice.key) == selected:
					messages.append({"speaker": "Sofi", "text": choice.text})
					break
		if not current.is_empty() and (step < lines.size() or step > lines.size()):
			messages.append(current)
		main.conversation_ui.show_direct_chat("Mateo", messages, options, next_action, next_label,
			main.ui_kit.scaled_text_size(16), note)
		return
	var raw_speaker: String = str(current.get("speaker", "Sofi"))
	var speaker: String = raw_speaker.get_slice(" (", 0)
	var is_message: bool = "(mensaje" in raw_speaker
	var active: String = main.ui_kit.scene_sprite_key(speaker, scene_id, selected)
	var partner: String = "Sofi_concerned" if scene_id.begins_with("D4") or scene_id.begins_with("D3") else "Sofi"
	if speaker == "Sofi":
		partner = main.ui_kit.scene_sprite_key("Mateo", scene_id)
	elif speaker == "Kairo" and is_message:
		active = main.ui_kit.scene_sprite_key("Mateo", scene_id)
	if speaker not in ["Sofi", "Mateo", "Kairo", "Camila", "Bruno", "Sebas"]:
		active = ""
		partner = ""
	var background: String = main.router.conversation_background()
	main.conversation_ui.show_scene(background, title, raw_speaker, str(current.get("text", "")), options, next_action, next_label, active, partner, is_message, main.ui_kit.scaled_text_size(18), note, additional, "Escena adicional")

func render_preview() -> void:
	main.modal_kind = "preview"
	main.ui_kit.clear_modal()
	var draft_mode: bool = GameState.flags.get("draft_mode", false)
	main.ui_kit.modal_heading("LA HISTORIA DE SOFI", "dialogue", 20)
	if main.preview_catalog.scenes.is_empty():
		main.ui_kit.modal_text("No se pudo abrir esta escena.", 16)
		return
	var body: VBoxContainer = main.ui_kit.content_box()
	var scene_id: String = GameState.preview_scene
	if scene_id == "ENDINGS_INDEX":
		if draft_mode and GameState.preview_step == 2 and GameState.flags.get("draft_completed", false):
			render_draft_summary(body)
			return
		if GameState.preview_step == 1 and GameState.flags.get("preview_reviewed", false):
			render_preview_summary(body)
			return
		main.ui_kit.add_text(body, "OTRAS HISTORIAS", 21)
		main.ui_kit.add_text(body, "Puedes visitar otras escenas de esta historia.", 15)
		for ending_id in PreviewCatalogScript.ENDING_ORDER:
			var chosen: String = ending_id
			var ending: Dictionary = main.preview_catalog.get_scene(chosen)
			main.ui_kit.add_button(body, scene_title(ending), func(): commit_preview(chosen, 0))
		main.ui_kit.add_button(body, "Volver al menú", main._return_to_menu)
		return
	render_preview_story(scene_id, draft_mode)

func render_draft_summary(body: VBoxContainer) -> void:
	main.ui_kit.add_text(body, "FIN DE LA HISTORIA", 21)
	var ending_name: String = {"F01": "Buscar apoyo", "F02": "Poner un límite", "F03": "Una decisión pendiente"}.get(str(GameState.flags.get("draft_ending", "")), "La historia continúa")
	main.ui_kit.add_text(body, ending_name, 19)
	main.ui_kit.add_text(body, "Sofi y Mateo llegaron hasta aquí juntos. Puedes volver a recorrer sus decisiones.", 15)
	main.ui_kit.add_text(body, "Resultado de la partida: " + GameState.moba_result + " · clase: " + GameState.moba_class, 15)
	for scene_id in DraftFlowScript.MAIN_IDS:
		var selected: String = str(GameState.preview_choices.get(scene_id, ""))
		if not selected.is_empty():
			var selected_scene: Dictionary = main.preview_catalog.get_scene(scene_id)
			main.ui_kit.add_text(body, "Día %d · %s: opción %s" % [int(selected_scene.get("day", 0)), scene_title(selected_scene), selected], 15)
	main.ui_kit.add_button(body, "Volver a vivir los Días 1–4", start_playable_draft)
	main.ui_kit.add_button(body, "Volver al menú", main._return_to_menu)

func draft_terminal_step(scene_id: String) -> int:
	var parts: Dictionary = scene_parts(scene_id, true)
	if not parts.choices.is_empty():
		return parts.lines.size() + 3 + parts.after_choice.size()
	if not parts.later_chat.is_empty():
		return parts.lines.size() + 1 + parts.later_chat.size()
	return parts.lines.size()

func finish_draft() -> bool:
	if not GameState.flags.get("draft_mode", false) or GameState.preview_scene not in ["F01_B", "F02", "F03"] or GameState.preview_step < draft_terminal_step(GameState.preview_scene) - 1:
		return false
	var previous := GameState.snapshot()
	GameState.flags.draft_completed = true
	GameState.flags.draft_ending = main.draft_flow.ending_code(GameState.preview_scene)
	if await commit_preview("ENDINGS_INDEX", 2):
		return true
	GameState.restore(previous)
	return false

func render_preview_summary(body: VBoxContainer) -> void:
	main.ui_kit.add_text(body, "HISTORIA RECORRIDA", 21)
	main.ui_kit.add_text(body, "Puedes regresar a las escenas y explorar otras decisiones.", 15)
	main.ui_kit.add_text(body, "Resultado del MOBA: " + GameState.moba_result, 16)
	main.ui_kit.add_text(body, "Respuestas literales guardadas en esta ranura:", 16)
	var any_choice := false
	for scene_id in PreviewCatalogScript.MAIN_ORDER:
		var selected: String = str(GameState.preview_choices.get(scene_id, ""))
		if selected.is_empty():
			continue
		var scene: Dictionary = main.preview_catalog.get_scene(scene_id)
		for choice in scene.get("choices", []):
			if str(choice.get("key", "")) == selected:
				main.ui_kit.add_text(body, "Día %d · %s: %s" % [int(scene.get("day", 0)), scene_title(scene), choice.get("text", "")], 15)
				any_choice = true
				break
	if not any_choice:
		main.ui_kit.add_text(body, "Todavía no elegiste ninguna respuesta en estas escenas.", 15)
	main.ui_kit.add_button(body, "Volver al Día 1", func(): commit_preview("D1_02_A", 0))
	main.ui_kit.add_button(body, "Ver otras escenas", func(): commit_preview("ENDINGS_INDEX", 0))
	main.ui_kit.add_button(body, "Volver al menú", main._return_to_menu)

func finish_preview() -> bool:
	if not PreviewCatalogScript.ENDING_ORDER.has(GameState.preview_scene):
		return false
	if GameState.preview_step < main.preview_catalog.terminal_step(GameState.preview_scene) - 1:
		return false
	return await commit_preview("ENDINGS_INDEX", 1, "", true)

func render_unplaced_preview() -> void:
	main.modal_kind = "preview_unplaced"
	main.ui_kit.clear_modal()
	main.ui_kit.modal_heading("ESCENA ADICIONAL", "history", 17)
	var body: VBoxContainer = main.ui_kit.content_box()
	var scene: Dictionary = main.preview_catalog.get_scene(GameState.preview_scene)
	for line in scene.get("unplaced_lines", []):
		preview_line(body, line)
	main.ui_kit.add_button(body, "Volver a la escena", render_preview)

func request_preview_choice(scene_id: String, key: String) -> bool:
	if main.save_in_progress or main.modal_kind != "preview" or GameState.preview_scene != scene_id:
		return false
	var scene: Dictionary = main.preview_catalog.get_scene(scene_id)
	var step: int = scene_parts(scene_id, GameState.flags.get("draft_mode", false)).lines.size()
	if GameState.preview_step != step:
		return false
	for choice in scene.get("choices", []):
		if str(choice.get("key", "")) == key:
			var next_step: int = step + (2 if GameState.flags.get("draft_mode", false) else 1)
			return await commit_preview(scene_id, next_step, key)
	return false

func draft_world_key() -> String:
	match GameState.preview_scene:
		"D1_02_A", "D1_03_A": return "draft_d1"
		"D2_03_A", "D2_04_A": return "draft_d2"
		"D3_01_A": return "draft_d3"
		_: return "draft_d4"
