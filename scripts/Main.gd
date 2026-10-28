extends Node2D

const WorldScript = preload("res://scripts/World.gd")
const NarrativeScript = preload("res://scripts/narrative/NarrativeManager.gd")
const PreviewCatalogScript = preload("res://scripts/narrative/RecoveredPreviewCatalog.gd")
const DraftFlowScript = preload("res://scripts/narrative/PlayableDraftFlow.gd")
const DisplayGuardScript = preload("res://scripts/DisplayGuard.gd")
const DAY_0_PREVIEW := "res://data/narrative/day_0_RECOVERED_PREVIEW.json"
const PORTRAITS := {
	"Sofi": "res://assets/portraits/sofi_neutral.png",
	"Mateo": "res://assets/portraits/mateo_neutral.png",
	"Bruno": "res://assets/portraits/bruno_neutral.png",
	"Camila": "res://assets/portraits/camila_neutral.png",
	"Sebas": "res://assets/portraits/sebas_neutral.png"
}

var world: Node2D
var canvas: CanvasLayer
var hud: Label
var prompt: Label
var modal: PanelContainer
var modal_box: VBoxContainer
var modal_kind: String = ""
var modal_before_pause: String = ""
var toast: Label
var toast_time := 0.0
var autosave_elapsed := 0.0
var dialogue_story: RefCounted
var preview_catalog: RefCounted
var draft_flow: RefCounted
var dialogue_key := ""
var dialogue_choice := ""
var pending_choice: Dictionary = {}
var confirming_choice := false
var dialogue_text_label: Label
var dialogue_visible := 0.0
var slot_loading := false
var save_in_progress := false
var window_guard_layer: CanvasLayer
var window_too_small := false
var window_check_elapsed := 0.0

func _ready() -> void:
	SaveManager.lock_lost.connect(_on_lock_lost)
	dialogue_story = NarrativeScript.new()
	preview_catalog = PreviewCatalogScript.new()
	var preview_errors: Array[String] = preview_catalog.load_catalog()
	if not preview_errors.is_empty():
		push_error("Vista previa narrativa inválida: " + "; ".join(preview_errors))
	draft_flow = DraftFlowScript.new()
	var draft_errors: Array[String] = draft_flow.load_draft()
	if not draft_errors.is_empty():
		push_error("Borrador jugable inválido: " + "; ".join(draft_errors))
	world = WorldScript.new()
	add_child(world)
	world.interacted.connect(_on_interacted)
	canvas = CanvasLayer.new()
	add_child(canvas)
	hud = _label(Vector2(20, 10), Vector2(728, 42), 16)
	prompt = _label(Vector2(20, 402), Vector2(728, 34), 17)
	toast = _label(Vector2(140, 354), Vector2(488, 40), 15)
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	modal = PanelContainer.new()
	modal.position = Vector2(126, 66)
	modal.custom_minimum_size = Vector2(516, 310)
	modal.size = Vector2(516, 310)
	modal.add_theme_stylebox_override("panel", _panel_style())
	canvas.add_child(modal)
	modal_box = VBoxContainer.new()
	modal_box.add_theme_constant_override("separation", 11)
	modal.add_child(modal_box)
	window_guard_layer = DisplayGuardScript.make_overlay(self)
	_show_menu()
	if not GameState.code.is_empty():
		AudioManager.apply_preferences()
		AudioManager.enter_context("explore")
	_check_window_size()

func _process(delta: float) -> void:
	if modal_kind == "dialogue" and is_instance_valid(dialogue_text_label):
		var text_length: int = dialogue_text_label.text.length()
		if dialogue_visible < text_length:
			var chars_per_second: float = {"slow": 18.0, "normal": 36.0, "fast": 72.0}[GameState.dialogue_speed]
			dialogue_visible = minf(float(text_length), dialogue_visible + delta * chars_per_second)
			dialogue_text_label.visible_characters = int(dialogue_visible)
			if dialogue_visible >= text_length:
				_render_dialogue(true)
	window_check_elapsed += delta
	if window_check_elapsed >= 0.25:
		window_check_elapsed = 0.0
		_check_window_size()
	if modal_kind == "" and GameState.phase != "result":
		autosave_elapsed += delta
		if autosave_elapsed >= 10.0:
			autosave_elapsed = 0.0
			_autosave()
	if toast_time > 0:
		toast_time -= delta
		if toast_time <= 0:
			toast.text = ""
	if modal_kind == "":
		var target_label: String = world.target_label(world.nearby)
		prompt.text = "F · interactuar: " + target_label if not world.nearby.is_empty() else "WASD · mover   F · interactuar   E · celular   Tab · objetivo   P · pausa"
	else:
		if modal_kind == "menu":
			prompt.text = "Selecciona una ranura para comenzar"
		elif modal_kind in ["preview", "preview_unplaced"]:
			prompt.text = "P · pausa   Usa los botones para recorrer el fragmento"
		else:
			prompt.text = "Esc · volver   P · pausa"

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_game") and modal_kind != "menu":
		if modal_kind == "pause":
			_resume_pause()
		else:
			_show_pause()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		if ["phone", "objective", "pause", "class", "dialogue_history", "choice_confirm"].has(modal_kind):
			if modal_kind == "pause":
				_resume_pause()
			elif modal_kind == "dialogue_history":
				_render_dialogue(true)
			elif modal_kind == "choice_confirm":
				_cancel_choice_confirm()
			else:
				_close_modal()
			get_viewport().set_input_as_handled()
	elif modal_kind == "phone" and event.is_action_pressed("phone"):
		_close_modal()
		get_viewport().set_input_as_handled()
	elif modal_kind == "preview" and event is InputEventKey and event.pressed and not event.echo:
		var preview_scene: Dictionary = preview_catalog.get_scene(GameState.preview_scene)
		var preview_choices: Array = preview_scene.get("choices", [])
		if GameState.preview_step == preview_scene.get("lines", []).size() and not preview_choices.is_empty():
			var preview_index := -1
			match event.keycode:
				KEY_1: preview_index = 0
				KEY_2: preview_index = 1
				KEY_3: preview_index = 2
			if preview_index >= 0 and preview_index < preview_choices.size():
				_request_preview_choice(GameState.preview_scene, str(preview_choices[preview_index].key))
				get_viewport().set_input_as_handled()
	elif modal_kind == "dialogue" and event is InputEventKey and event.pressed and not event.echo:
		if dialogue_visible < dialogue_story.current_node().get("text", "").length() and event.keycode in [KEY_1, KEY_2, KEY_3, KEY_ENTER, KEY_KP_ENTER]:
			_reveal_dialogue()
			get_viewport().set_input_as_handled()
			return
		var choice_index := -1
		match event.keycode:
			KEY_1: choice_index = 0
			KEY_2: choice_index = 1
			KEY_3: choice_index = 2
			KEY_ENTER, KEY_KP_ENTER:
				if dialogue_story.current_node().get("choices", []).is_empty():
					_advance_dialogue()
		var choices: Array = dialogue_story.current_node().get("choices", [])
		if choice_index >= 0 and choice_index < choices.size():
			_request_dialogue_choice(str(choices[choice_index].choice_id))
			get_viewport().set_input_as_handled()
	elif modal_kind == "":
		if event.is_action_pressed("interact"):
			world.interact()
		elif event.is_action_pressed("phone"):
			_show_phone()
		elif event.is_action_pressed("objective"):
			_show_objective()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(modal):
		if modal_kind != "menu" and modal_kind != "pause":
			_show_pause()

func _check_window_size() -> void:
	window_too_small = DisplayGuardScript.too_small(DisplayGuardScript.window_size())
	window_guard_layer.visible = window_too_small
	if window_too_small and modal_kind not in ["menu", "pause"]:
		_show_pause()

func _label(pos: Vector2, dimensions: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.position = pos
	label.size = dimensions
	label.add_theme_font_size_override("font_size", _scaled_text_size(font_size))
	label.add_theme_color_override("font_color", Color("fff3df"))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(label)
	return label

func _scaled_text_size(base: int) -> int:
	match GameState.text_size:
		"small": return maxi(12, roundi(base * 0.9))
		"large": return roundi(base * 1.3)
	return base

func _refresh_static_fonts() -> void:
	hud.add_theme_font_size_override("font_size", _scaled_text_size(16))
	prompt.add_theme_font_size_override("font_size", _scaled_text_size(17))
	toast.add_theme_font_size_override("font_size", _scaled_text_size(15))

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("10192b")
	style.border_color = Color("78bdbb")
	style.set_border_width_all(3)
	style.set_content_margin_all(20)
	return style

func _clear_modal() -> void:
	modal.position = Vector2(70, 38)
	modal.custom_minimum_size = Vector2(628, 372)
	modal.size = Vector2(628, 372)
	for child in modal_box.get_children():
		modal_box.remove_child(child)
		child.queue_free()
	modal.visible = true
	world.enabled = false

func _close_modal() -> void:
	if modal_kind in ["phone", "objective", "class"] and not GameState.ui_modal.is_empty():
		if save_in_progress:
			return
		save_in_progress = true
		var previous: String = GameState.ui_modal
		GameState.ui_modal = ""
		if not await SaveManager.save_slot_async():
			GameState.ui_modal = previous
			save_in_progress = false
			_toast("No se pudo guardar el cierre; reintenta")
			return
		save_in_progress = false
	modal_kind = ""
	modal.visible = false
	world.enabled = true

func _modal_text(value: String, size: int = 18) -> void:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.y = 38
	label.add_theme_font_size_override("font_size", _scaled_text_size(size))
	label.add_theme_color_override("font_color", Color("fff3df"))
	modal_box.add_child(label)

func _button(value: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = value
	button.custom_minimum_size.y = 34
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.add_theme_font_size_override("font_size", _scaled_text_size(16))
	button.pressed.connect(callback)
	modal_box.add_child(button)
	return button

func _show_menu() -> void:
	AudioManager.set_music_paused(false)
	dialogue_key = ""
	pending_choice.clear()
	modal_kind = "menu"
	_clear_modal()
	_modal_text("CENTINELA 2.0 · prototipo jugable", 24)
	_modal_text("Día 0 con texto recuperado en vista previa. Falta validar el guion canónico completo.", 15)
	var buttons: Array[Button] = []
	for i in range(1, 4):
		var chosen := i
		var label := "Ranura %d · cargando..." % i if OS.has_feature("web") else SaveManager.slot_summary(i)
		var button := _button(label, func(): _start_slot(chosen))
		button.disabled = OS.has_feature("web")
		buttons.append(button)
	if OS.has_feature("web"):
		_refresh_web_menu(buttons)
	else:
		buttons[0].grab_focus()

func _refresh_web_menu(buttons: Array[Button]) -> void:
	var response: Dictionary = await SaveManager.list_slots_async()
	if not is_inside_tree() or modal_kind != "menu":
		return
	if not response.get("success", false):
		_modal_text("No se pudo leer IndexedDB: " + SaveManager.last_error, 15)
		return
	var records: Dictionary = {}
	for record in response.result:
		records[int(record.slot)] = record
	for i in 3:
		var slot_number := i + 1
		if records.has(slot_number):
			buttons[i].text = "Ranura %d · %s · %s" % [slot_number, records[slot_number].code, records[slot_number].phase]
		else:
			buttons[i].text = "Ranura %d · nueva" % slot_number
		buttons[i].disabled = false
	buttons[0].grab_focus()

func _start_slot(chosen: int) -> void:
	if slot_loading:
		return
	slot_loading = true
	var recovered_local := false
	if OS.has_feature("web"):
		if not await SaveManager.acquire_slot_async(chosen):
			slot_loading = false
			_toast("No se pudo abrir la ranura: " + SaveManager.last_error)
			return
		var response: Dictionary = await SaveManager.load_slot_data_async(chosen)
		if not is_inside_tree():
			return
		if not response.get("success", false):
			slot_loading = false
			_toast("No se pudo leer la partida: " + SaveManager.last_error)
			await SaveManager.release_slot_async()
			return
		if response.result == null:
			GameState.new_game(chosen)
			if not await SaveManager.save_slot_async():
				slot_loading = false
				_toast("No se pudo crear la partida")
				await SaveManager.release_slot_async()
				return
		elif typeof(response.result) != TYPE_DICTIONARY or not GameState.restore(response.result):
			slot_loading = false
			_toast("Ranura incompatible o dañada; no se sobrescribió")
			await SaveManager.release_slot_async()
			return
	else:
		if SaveManager.slot_exists(chosen):
			if not SaveManager.load_slot(chosen):
				slot_loading = false
				_toast("Ranura incompatible o dañada; no se sobrescribió")
				return
			recovered_local = SaveManager.recovered_slot == chosen
		else:
			GameState.new_game(chosen)
			if not SaveManager.save_slot():
				slot_loading = false
				_toast("No se pudo crear la partida")
				return
	slot_loading = false
	SyncManager.on_slot_opened()
	AudioManager.apply_preferences()
	if GameState.phase != "moba":
		AudioManager.enter_context("explore")
	_refresh_static_fonts()
	if GameState.phase == "moba":
		get_tree().change_scene_to_file("res://scenes/moba/MOBAArena.tscn")
		return
	_load_phase()
	if not GameState.dialogue_key.is_empty():
		if not _resume_saved_dialogue():
			_show_menu()
			_toast("No se pudo reanudar el diálogo guardado")
	elif not GameState.ui_modal.is_empty():
		match GameState.ui_modal:
			"phone": _render_phone()
			"objective": _render_objective()
			"class": _render_class()
	elif GameState.phase == "bedroom" and not GameState.flags.get("wakeup_seen", false):
		_show_dialogue("wakeup")
	elif GameState.phase not in ["result", "preview"]:
		_close_modal()
	if recovered_local:
		_toast("Partida recuperada de una copia local")

func _load_phase() -> void:
	var world_phase := GameState.phase
	if world_phase == "result":
		world_phase = "computer"
	elif world_phase == "preview":
		world_phase = "courtyard"
	world.configure(world_phase, GameState.player_position)
	_update_hud()
	if GameState.phase == "result":
		_show_result()
	elif GameState.phase == "preview":
		_render_preview()

func _update_hud() -> void:
	if GameState.phase == "preview":
		hud.text = ("BORRADOR · %s · %s" if GameState.flags.get("draft_mode", false) else "VISTA PREVIA · %s · %s") % [GameState.code, GameState.preview_scene]
		return
	var place: String = {"bedroom": "HABITACIÓN", "courtyard": "PATIO", "computer": "COMPUTADORA", "result": "RESULTADO"}.get(GameState.phase, GameState.phase.to_upper())
	hud.text = "DÍA 0  ·  %s  ·  %s  |  %s" % [GameState.code, place, _objective_text()]

func _objective_text() -> String:
	match GameState.phase:
		"bedroom":
			if not GameState.flags.get("alarm", false): return "Usa la alarma"
			if not GameState.flags.get("backpack", false): return "Recoge la mochila"
			return "Ve a la puerta"
		"courtyard":
			if not GameState.flags.get("friends", false): return "Acércate al grupo"
			return "Ve a la salida"
		"computer": return "Usa la computadora"
		"result": return "Continúa la historia D1–D4"
		"preview": return "Fragmentos recuperados; conectores pendientes"
	return ""

func _on_interacted(target: String) -> void:
	match GameState.phase:
		"bedroom":
			if ["alarm", "backpack"].has(target):
				_commit_flag(target, "Interacción registrada: " + world.target_label(target))
			elif target == "door":
				if not GameState.flags.get("alarm", false) or not GameState.flags.get("backpack", false):
					_toast("Completa la alarma y la mochila primero")
				else:
					_transition("courtyard", Vector2(140, 300))
			else:
				_toast("Objeto opcional: " + world.target_label(target))
		"courtyard":
			if target == "friends":
				_show_dialogue("courtyard")
			elif target == "exit":
				if GameState.flags.get("friends", false):
					_transition("computer", Vector2(384, 320))
				else:
					_toast("Primero acércate al grupo")
		"computer":
			if target == "pc":
				if GameState.flags.get("d0_chat_done", false):
					_show_class()
				else:
					_show_dialogue("group_chat")

func _transition(next_phase: String, position: Vector2) -> void:
	var old_phase: String = GameState.phase
	var old_position: Vector2 = GameState.player_position
	GameState.phase = next_phase
	GameState.player_position = position
	world.enabled = false
	if await SaveManager.save_slot_async():
		if not is_inside_tree():
			return
		_load_phase()
		AudioManager.play_effect("confirm")
		world.enabled = true
	else:
		GameState.phase = old_phase
		GameState.player_position = old_position
		if modal_kind == "":
			world.enabled = true
		_toast("Error al guardar. Reintenta la transición.")

func _commit_flag(flag: String, message: String) -> void:
	var old_flags := GameState.flags.duplicate(true)
	GameState.flags[flag] = true
	world.enabled = false
	if await SaveManager.save_slot_async():
		if not is_inside_tree():
			return
		_update_hud()
		AudioManager.play_effect("interact")
		world.enabled = true
		_toast(message)
	else:
		GameState.flags = old_flags
		if modal_kind == "":
			world.enabled = true
		_toast("Error al guardar")

func _autosave() -> void:
	if not await SaveManager.save_slot_async() and is_inside_tree():
		_toast("No se pudo guardar la posición")

func _manual_save() -> void:
	_toast("Guardado" if await SaveManager.save_slot_async() else "Error de guardado")

func _on_lock_lost() -> void:
	SyncManager.on_slot_closed()
	_show_menu()
	_toast("Esta partida está abierta en otra pestaña")

func _toast(message: String) -> void:
	toast.text = message
	toast_time = 3.5

func _show_phone() -> void:
	await _open_ui_modal("phone", Callable(self, "_render_phone"))

func _open_ui_modal(kind: String, renderer: Callable) -> void:
	if save_in_progress:
		return
	if GameState.ui_modal == kind:
		renderer.call()
		return
	save_in_progress = true
	var previous: String = GameState.ui_modal
	GameState.ui_modal = kind
	if await SaveManager.save_slot_async():
		if is_inside_tree():
			if modal_kind == "pause":
				modal_before_pause = kind
			else:
				renderer.call()
	else:
		GameState.ui_modal = previous
		_toast("No se pudo abrir el panel; reintenta")
	save_in_progress = false

func _render_phone() -> void:
	modal_kind = "phone"
	_clear_modal()
	_modal_text("CELULAR · chats y contactos", 23)
	if GameState.phone_messages.is_empty():
		_modal_text("No hay mensajes guardados. La conversación recuperada del Día 0 aparece al usar la computadora.", 16)
	else:
		_modal_text("Los chicos · texto recuperado, vista previa", 15)
		var scroll := ScrollContainer.new()
		scroll.custom_minimum_size = Vector2(460, 170)
		var lines := VBoxContainer.new()
		for message in GameState.phone_messages:
			var line := Label.new()
			line.text = "%s: %s" % [message.get("speaker", ""), message.get("text", "")]
			line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			line.custom_minimum_size.x = 444
			line.add_theme_font_size_override("font_size", _scaled_text_size(14))
			lines.add_child(line)
		scroll.add_child(lines)
		modal_box.add_child(scroll)
	_button("Cerrar", _close_modal)

func _show_objective() -> void:
	await _open_ui_modal("objective", Callable(self, "_render_objective"))

func _render_objective() -> void:
	modal_kind = "objective"
	_clear_modal()
	_modal_text("OBJETIVO", 23)
	_modal_text(_objective_text(), 19)
	_button("Pista", _advance_hint)
	_button("Cerrar", _close_modal)

func _advance_hint() -> void:
	if save_in_progress:
		return
	save_in_progress = true
	var previous: int = GameState.hint_level
	GameState.hint_level = mini(previous + 1, 2)
	if await SaveManager.save_slot_async():
		_toast("Busca el objeto señalado" if GameState.hint_level == 1 else "Acércate al objeto marcado y pulsa F")
	else:
		GameState.hint_level = previous
		_toast("No se pudo guardar la pista; reintenta")
	save_in_progress = false

func _show_pause() -> void:
	modal_before_pause = modal_kind
	AudioManager.set_music_paused(true)
	_render_pause()

func _render_pause() -> void:
	modal_kind = "pause"
	_clear_modal()
	_modal_text("PAUSA · " + GameState.code, 23)
	var body := _preview_content()
	_preview_text(body, SyncManager.status_label(), 15)
	if SyncManager.configured:
		_preview_button(body, "Reintentar sincronización", SyncManager.retry_now)
	var continue_button := _preview_button(body, "Continuar", _resume_pause)
	continue_button.grab_focus()
	var size_label: String = {"small": "Pequeño", "normal": "Mediano", "large": "Grande"}[GameState.text_size]
	_preview_button(body, "Tamaño de texto: " + size_label, _cycle_text_size)
	_preview_button(body, "Música: %d %%" % GameState.music_volume, func(): _cycle_audio("music"))
	_preview_button(body, "Efectos: %d %%" % GameState.effects_volume, func(): _cycle_audio("effects"))
	var speed_label: String = {"slow": "Lenta", "normal": "Normal", "fast": "Rápida"}[GameState.dialogue_speed]
	_preview_button(body, "Velocidad de diálogo: " + speed_label, _cycle_dialogue_speed)
	_preview_button(body, "Guardar", _manual_save)
	_preview_button(body, "Menú", _return_to_menu)

func _cycle_text_size() -> void:
	if save_in_progress:
		return
	save_in_progress = true
	var previous: String = GameState.text_size
	match previous:
		"small": GameState.text_size = "normal"
		"normal": GameState.text_size = "large"
		_: GameState.text_size = "small"
	if await SaveManager.save_slot_async():
		_refresh_static_fonts()
		if is_inside_tree():
			_render_pause()
	else:
		GameState.text_size = previous
		_toast("No se pudo guardar el tamaño de texto")
	save_in_progress = false

func _cycle_audio(which: String) -> void:
	if save_in_progress:
		return
	save_in_progress = true
	var saved: bool = await AudioManager.cycle_level(which)
	save_in_progress = false
	if saved:
		if is_inside_tree():
			_render_pause()
	else:
		_toast("No se pudo guardar el ajuste de audio")

func _cycle_dialogue_speed() -> void:
	if save_in_progress:
		return
	save_in_progress = true
	var previous: String = GameState.dialogue_speed
	match previous:
		"slow": GameState.dialogue_speed = "normal"
		"normal": GameState.dialogue_speed = "fast"
		_: GameState.dialogue_speed = "slow"
	if await SaveManager.save_slot_async():
		if is_inside_tree():
			_render_pause()
	else:
		GameState.dialogue_speed = previous
		_toast("No se pudo guardar la velocidad de diálogo")
	save_in_progress = false

func _return_to_menu() -> void:
	SyncManager.on_slot_closed()
	await SaveManager.release_slot_async()
	if is_inside_tree():
		_show_menu()

func _resume_pause() -> void:
	if window_too_small:
		return
	AudioManager.set_music_paused(false)
	match modal_before_pause:
		"phone": _render_phone()
		"objective": _render_objective()
		"class": _render_class()
		"dialogue": _render_dialogue(true)
		"dialogue_history": _render_dialogue_history()
		"choice_confirm": _render_choice_confirm()
		"result": _show_result()
		"preview": _render_preview()
		"preview_unplaced": _render_unplaced_preview()
		_: _close_modal()
	modal_before_pause = ""

func _show_class() -> void:
	await _open_ui_modal("class", Callable(self, "_render_class"))

func _render_class() -> void:
	modal_kind = "class"
	_clear_modal()
	_modal_text("ELIGE CLASE · MOBA", 23)
	for hero_class in ["Atacante", "Defensor", "Soporte"]:
		var chosen: String = hero_class
		var class_button := _button(hero_class, func(): _start_moba(chosen))
		if hero_class == "Atacante":
			class_button.grab_focus()
	_button("Volver", _close_modal)

func _show_dialogue(key: String) -> void:
	if save_in_progress:
		return
	var errors: Array[String] = dialogue_story.load_story(DAY_0_PREVIEW, true)
	if not errors.is_empty() or not dialogue_story.start_at(key):
		_toast("CANONICAL_SCRIPT_MISSING: vista previa no disponible")
		return
	save_in_progress = true
	var previous := GameState.snapshot()
	GameState.dialogue_key = key
	GameState.dialogue_position = dialogue_story.position
	GameState.dialogue_choice = ""
	GameState.dialogue_history = []
	if await SaveManager.save_slot_async():
		dialogue_key = key
		dialogue_choice = ""
		dialogue_visible = 0.0
		if is_inside_tree():
			_render_dialogue()
	else:
		GameState.restore(previous)
		_toast("No se pudo guardar el diálogo; reintenta")
	save_in_progress = false

func _resume_saved_dialogue() -> bool:
	var errors: Array[String] = dialogue_story.load_story(DAY_0_PREVIEW, true)
	if not errors.is_empty() or GameState.dialogue_position >= dialogue_story.data.get("nodes", []).size():
		return false
	dialogue_story.position = GameState.dialogue_position
	dialogue_key = GameState.dialogue_key
	dialogue_choice = GameState.dialogue_choice
	dialogue_visible = 0.0
	_render_dialogue()
	return true

func _render_dialogue(preserve_reveal: bool = false) -> void:
	modal_kind = "dialogue"
	_clear_modal()
	var node: Dictionary = dialogue_story.current_node()
	if not preserve_reveal:
		dialogue_visible = 0.0
	_modal_text("TEXTO RECUPERADO · VISTA PREVIA", 16)
	var body := _preview_content()
	var message: String = str(node.get("text", ""))
	dialogue_text_label = _dialogue_line(body, str(node.get("speaker", "")), message)
	if is_instance_valid(dialogue_text_label):
		dialogue_text_label.visible_characters = int(dialogue_visible)
	var revealing: bool = dialogue_visible < message.length()
	var choices: Array = node.get("choices", [])
	if revealing:
		_preview_button(body, "Mostrar texto", _reveal_dialogue).grab_focus()
	elif not choices.is_empty():
		_preview_text(body, "Elige una respuesta (1–3). Identificadores provisionales.", 14)
		for i in choices.size():
			var choice_id: String = str(choices[i].choice_id)
			var option := _preview_button(body, "%d. %s" % [i + 1, choices[i].text], func(): _request_dialogue_choice(choice_id))
			if i == 0:
				option.grab_focus()
	elif node.get("next", null) != null:
		_preview_button(body, "Continuar", _advance_dialogue).grab_focus()
	else:
		_preview_button(body, "Continuar", _complete_dialogue).grab_focus()
	_preview_button(body, "Historial de esta conversación", _render_dialogue_history)

func _dialogue_line(parent: VBoxContainer, speaker: String, message: String) -> Label:
	var path: String = PORTRAITS.get(speaker, "")
	var portrait: Texture2D = load(path) as Texture2D if not path.is_empty() else null
	var text_parent: VBoxContainer = parent
	var width := 545
	if portrait != null:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		parent.add_child(row)
		var frame := PanelContainer.new()
		frame.name = "PortraitFrame"
		frame.custom_minimum_size = Vector2(112, 112)
		var frame_style := StyleBoxFlat.new()
		frame_style.bg_color = Color("263550")
		frame_style.border_color = Color("78bdbb")
		frame_style.set_border_width_all(1)
		frame.add_theme_stylebox_override("panel", frame_style)
		row.add_child(frame)
		var picture := TextureRect.new()
		picture.name = "Portrait"
		picture.texture = portrait
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		picture.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		picture.custom_minimum_size = Vector2(110, 110)
		picture.tooltip_text = "Retrato provisional de " + speaker
		frame.add_child(picture)
		text_parent = VBoxContainer.new()
		text_parent.custom_minimum_size.x = 420
		row.add_child(text_parent)
		width = 420
	if not speaker.is_empty():
		_preview_text(text_parent, speaker, 21, width)
	return _preview_text(text_parent, message, 18, width) if not message.is_empty() else null

func _reveal_dialogue() -> void:
	dialogue_visible = float(str(dialogue_story.current_node().get("text", "")).length())
	_render_dialogue(true)

func _render_dialogue_history() -> void:
	modal_kind = "dialogue_history"
	_clear_modal()
	_modal_text("HISTORIAL · conversación actual", 20)
	var body := _preview_content()
	var positions: Array = GameState.dialogue_history.duplicate()
	if positions.is_empty():
		_preview_text(body, "Todavía no hay líneas anteriores en esta conversación.", 16)
	for position in positions:
		if int(position) < 0 or int(position) >= dialogue_story.data.get("nodes", []).size():
			continue
		var line: Dictionary = dialogue_story.data.nodes[int(position)]
		if str(line.get("text", "")).is_empty():
			continue
		_preview_text(body, "%s: %s" % [line.get("speaker", ""), line.get("text", "")], 17)
	_preview_button(body, "Volver al diálogo", func(): _render_dialogue(true)).grab_focus()

func _request_dialogue_choice(choice_id: String) -> void:
	if save_in_progress or confirming_choice or modal_kind != "dialogue":
		return
	for choice in dialogue_story.current_node().get("choices", []):
		if str(choice.get("choice_id", "")) == choice_id:
			pending_choice = {"kind": "dialogue", "id": choice_id,
				"text": str(choice.get("text", "")), "position": dialogue_story.position}
			_render_choice_confirm()
			return

func _request_preview_choice(scene_id: String, key: String) -> void:
	if save_in_progress or confirming_choice or modal_kind != "preview" or GameState.preview_scene != scene_id:
		return
	var scene: Dictionary = preview_catalog.get_scene(scene_id)
	var step: int = scene.get("lines", []).size()
	if GameState.preview_step != step:
		return
	for choice in scene.get("choices", []):
		if str(choice.get("key", "")) == key:
			pending_choice = {"kind": "preview", "scene": scene_id, "key": key,
				"text": str(choice.get("text", "")), "step": step}
			_render_choice_confirm()
			return

func _render_choice_confirm() -> void:
	if pending_choice.is_empty():
		return
	modal_kind = "choice_confirm"
	_clear_modal()
	_modal_text("CONFIRMAR RESPUESTA", 21)
	var body := _preview_content()
	_preview_text(body, "«" + str(pending_choice.get("text", "")) + "»", 19)
	_preview_text(body, "La respuesta se guardará al confirmar.", 15)
	_preview_button(body, "Confirmar", _confirm_choice).grab_focus()
	_preview_button(body, "Volver", _cancel_choice_confirm)

func _cancel_choice_confirm() -> void:
	if confirming_choice:
		return
	var kind: String = str(pending_choice.get("kind", ""))
	pending_choice.clear()
	if kind == "dialogue":
		_render_dialogue(true)
	elif kind == "preview":
		_render_preview()

func _confirm_choice() -> void:
	if confirming_choice or pending_choice.is_empty():
		return
	var selected: Dictionary = pending_choice.duplicate()
	var kind: String = str(selected.get("kind", ""))
	if (kind == "dialogue" and (dialogue_story.position != selected.get("position") or GameState.dialogue_key != dialogue_key)) or \
		(kind == "preview" and (GameState.preview_scene != selected.get("scene") or GameState.preview_step != selected.get("step"))):
		_cancel_choice_confirm()
		return
	confirming_choice = true
	var saved := false
	if kind == "dialogue":
		saved = await _choose_dialogue(str(selected.id))
	elif kind == "preview":
		saved = await _commit_preview(str(selected.scene), int(selected.step) + 1, str(selected.key))
	if saved:
		pending_choice.clear()
	confirming_choice = false

func _advance_dialogue() -> void:
	if save_in_progress:
		return
	var previous_position: int = dialogue_story.position
	var previous_history: Array = GameState.dialogue_history.duplicate()
	if not dialogue_story.advance():
		return
	save_in_progress = true
	GameState.dialogue_position = dialogue_story.position
	GameState.dialogue_history.append(previous_position)
	if await SaveManager.save_slot_async():
		if is_inside_tree():
			AudioManager.play_effect("confirm")
			_render_dialogue()
	else:
		dialogue_story.position = previous_position
		GameState.dialogue_position = previous_position
		GameState.dialogue_history = previous_history
		_toast("No se pudo guardar el avance; reintenta")
	save_in_progress = false

func _choose_dialogue(choice_id: String) -> bool:
	if save_in_progress:
		return false
	var previous_position: int = dialogue_story.position
	var previous_history: Array = GameState.dialogue_history.duplicate()
	if not dialogue_story.advance(choice_id):
		return false
	save_in_progress = true
	GameState.dialogue_position = dialogue_story.position
	GameState.dialogue_choice = choice_id
	GameState.dialogue_history.append(previous_position)
	if await SaveManager.save_slot_async():
		dialogue_choice = choice_id
		if is_inside_tree():
			AudioManager.play_effect("confirm")
			_render_dialogue()
		save_in_progress = false
		return true
	else:
		dialogue_story.position = previous_position
		GameState.dialogue_position = previous_position
		GameState.dialogue_choice = dialogue_choice
		GameState.dialogue_history = previous_history
		_toast("No se pudo guardar la opción; reintenta")
	save_in_progress = false
	return false

func _complete_dialogue() -> void:
	if save_in_progress:
		return
	save_in_progress = true
	var previous := GameState.snapshot()
	match dialogue_key:
		"wakeup": GameState.flags.wakeup_seen = true
		"courtyard": GameState.flags.friends = true
		"group_chat":
			if dialogue_choice.is_empty():
				save_in_progress = false
				return
			GameState.flags.d0_chat_done = true
			GameState.flags.d0_chat_choice = dialogue_choice
			GameState.phone_messages = []
			for i in range(14, 19):
				var node: Dictionary = dialogue_story.data.nodes[i]
				GameState.phone_messages.append({"speaker": node.speaker, "text": node.text})
			var answer: Dictionary = dialogue_story.current_node()
			GameState.phone_messages.append({"speaker": answer.speaker, "text": answer.text})
	GameState.dialogue_key = ""
	GameState.dialogue_position = 0
	GameState.dialogue_choice = ""
	GameState.dialogue_history = []
	if not await SaveManager.save_slot_async():
		save_in_progress = false
		GameState.restore(previous)
		_toast("No se pudo guardar el diálogo; reintenta")
		return
	save_in_progress = false
	_update_hud()
	var finished_key := dialogue_key
	dialogue_key = ""
	if finished_key == "group_chat":
		_show_class()
	else:
		_close_modal()

func _start_moba(hero_class: String) -> void:
	if save_in_progress:
		return
	save_in_progress = true
	var old_class: String = GameState.moba_class
	var old_modal: String = GameState.ui_modal
	GameState.moba_class = hero_class
	GameState.phase = "moba"
	GameState.ui_modal = ""
	if await SaveManager.save_slot_async():
		save_in_progress = false
		get_tree().change_scene_to_file("res://scenes/moba/MOBAArena.tscn")
	else:
		save_in_progress = false
		GameState.moba_class = old_class
		GameState.phase = "computer"
		GameState.ui_modal = old_modal
		_toast("No se pudo guardar la clase")

func _show_result() -> void:
	modal_kind = "result"
	_clear_modal()
	_modal_text("PARTIDA FINALIZADA", 23)
	_modal_text("Resultado: " + GameState.moba_result, 19)
	var body := _preview_content()
	_preview_text(body, "BORRADOR · Camila: " + draft_flow.camila_reaction(GameState.moba_result, GameState.moba_class), 16)
	_preview_text(body, "Puedes continuar la historia provisional D1–D4. Los conectores y desenlaces aún requieren aprobación.", 16)
	var draft_button := _preview_button(body, "Continuar borrador jugable", _start_playable_draft)
	draft_button.disabled = preview_catalog.scenes.is_empty() or draft_flow.content.is_empty()
	if not draft_button.disabled:
		draft_button.grab_focus()
		body.get_parent().set_deferred("scroll_vertical", 0)
	var preview_button := _preview_button(body, "Ver fragmentos D1–D4", func(): _commit_preview("D1_02_A", 0))
	preview_button.disabled = preview_catalog.scenes.is_empty()
	_preview_button(body, "Volver al menú", _return_to_menu)

func _start_playable_draft() -> bool:
	if save_in_progress or draft_flow.content.is_empty() or preview_catalog.scenes.is_empty():
		return false
	var previous := GameState.snapshot()
	GameState.flags.draft_mode = true
	GameState.flags.draft_completed = false
	GameState.flags.draft_ending = ""
	GameState.preview_choices.clear()
	if await _commit_preview("D1_02_A", 0):
		return true
	GameState.restore(previous)
	return false

func _commit_preview(next_scene: String, next_step: int, choice_key: String = "", mark_reviewed: bool = false) -> bool:
	if save_in_progress or preview_catalog.scenes.is_empty():
		return false
	save_in_progress = true
	var previous := GameState.snapshot()
	GameState.phase = "preview"
	GameState.ui_modal = ""
	GameState.preview_scene = next_scene
	GameState.preview_step = next_step
	if not choice_key.is_empty():
		GameState.preview_choices[next_scene] = choice_key
	if mark_reviewed:
		GameState.flags.preview_reviewed = true
	if await SaveManager.save_slot_async():
		save_in_progress = false
		if is_inside_tree():
			_load_phase()
		return true
	else:
		GameState.restore(previous)
		save_in_progress = false
		_toast("No se pudo guardar la vista previa; reintenta")
	return false

func _preview_content() -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(565, 256)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	modal_box.add_child(scroll)
	var body := VBoxContainer.new()
	body.custom_minimum_size.x = 555
	body.add_theme_constant_override("separation", 10)
	scroll.add_child(body)
	return body

func _preview_text(parent: VBoxContainer, value: String, size: int = 16, width: int = 545) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = width
	label.add_theme_font_size_override("font_size", _scaled_text_size(size))
	label.add_theme_color_override("font_color", Color("fff3df"))
	parent.add_child(label)
	return label

func _preview_button(parent: VBoxContainer, value: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = value
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.custom_minimum_size = Vector2(545, 44)
	button.add_theme_font_size_override("font_size", _scaled_text_size(16))
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _preview_line(parent: VBoxContainer, line: Dictionary) -> void:
	var speaker: String = str(line.get("speaker", ""))
	if "(mensaje)" in speaker:
		var card := PanelContainer.new()
		card.custom_minimum_size.x = 545
		var style := StyleBoxFlat.new()
		style.bg_color = Color("263550")
		style.border_color = Color("78bdbb")
		style.set_border_width_all(1)
		style.set_content_margin_all(10)
		card.add_theme_stylebox_override("panel", style)
		parent.add_child(card)
		var message_box := VBoxContainer.new()
		card.add_child(message_box)
		_preview_text(message_box, "CHAT MOSTRADO POR MATEO" if GameState.preview_scene == "D2_03_A" else "MENSAJE RECUPERADO", 13, 515)
		_preview_text(message_box, speaker + ":", 16, 515)
		_preview_text(message_box, "«" + str(line.get("text", "")) + "»", 18, 515)
	else:
		_preview_text(parent, speaker + ":", 18)
		_preview_text(parent, "«" + str(line.get("text", "")) + "»", 19)

func _render_preview() -> void:
	modal_kind = "preview"
	_clear_modal()
	var draft_mode: bool = GameState.flags.get("draft_mode", false)
	_modal_text("BORRADOR JUGABLE · PROVISIONAL" if draft_mode else "TEXTO RECUPERADO · VISTA PREVIA", 17)
	if preview_catalog.scenes.is_empty():
		_modal_text("No se pudieron cargar los fragmentos.", 16)
		return
	var body := _preview_content()
	var scene_id: String = GameState.preview_scene
	if scene_id == "ENDINGS_INDEX":
		if draft_mode and GameState.preview_step == 2 and GameState.flags.get("draft_completed", false):
			_render_draft_summary(body)
			return
		if GameState.preview_step == 1 and GameState.flags.get("preview_reviewed", false):
			_render_preview_summary(body)
			return
		_preview_text(body, "Finales recuperados · selección manual", 21)
		_preview_text(body, "Las condiciones para asignar un final no están confirmadas. Elige un fragmento para leerlo; esta selección no establece el final de la partida.", 15)
		for ending_id in PreviewCatalogScript.ENDING_ORDER:
			var chosen: String = ending_id
			var ending: Dictionary = preview_catalog.get_scene(chosen)
			_preview_button(body, "%s · %s" % [chosen, ending.get("title", "")], func(): _commit_preview(chosen, 0))
		_preview_button(body, "Volver al menú", _return_to_menu)
		return
	var scene: Dictionary = preview_catalog.get_scene(scene_id)
	if scene.is_empty():
		_preview_text(body, "Fragmento no disponible. Vuelve al menú.")
		_preview_button(body, "Menú", _return_to_menu)
		return
	var day_label := "Final" if scene.get("day") == null else "Día " + str(int(scene.day))
	_preview_text(body, "%s · %s" % [day_label, str(scene.get("title", scene_id))], 21)
	var fragment_note := "conversación continua confirmada; reacciones parciales" if scene_id in ["D4_01_A", "D4_02_A", "D4_03_A"] else "orden y conectores provisionales"
	_preview_text(body, "Fragmento %s · %s" % [scene_id, fragment_note], 14)
	if draft_mode:
		_preview_text(body, "BORRADOR · conector: " + draft_flow.connector(scene_id), 15)
	var lines: Array = scene.get("lines", [])
	var choices: Array = scene.get("choices", [])
	var after_choice: Array = scene.get("after_choice", [])
	var later_chat: Array = scene.get("later_chat", [])
	var step: int = GameState.preview_step
	var terminal := false
	if step < lines.size():
		_preview_line(body, lines[step])
		_preview_button(body, "Continuar", func(): _commit_preview(scene_id, step + 1))
	elif not choices.is_empty():
		if step == lines.size():
			_preview_text(body, "Elige la respuesta literal de Sofi (1–3). No se aplica puntuación educativa.", 15)
			for i in choices.size():
				var choice: Dictionary = choices[i]
				var letter: String = str(choice.key)
				var option := _preview_button(body, "%d · %s. «%s»" % [i + 1, letter, str(choice.text)], func(): _request_preview_choice(scene_id, letter))
				if i == 0:
					option.grab_focus()
		elif step == lines.size() + 1:
			var selected: String = str(GameState.preview_choices.get(scene_id, ""))
			var found := false
			for choice in choices:
				if choice.key == selected:
					_preview_line(body, {"speaker": "Sofi", "text": choice.text})
					found = true
			if not found:
				_preview_text(body, "La opción guardada no está disponible.")
			_preview_button(body, "Continuar", func(): _commit_preview(scene_id, step + 1))
		elif draft_mode and step == lines.size() + 2:
			_preview_text(body, "BORRADOR · reacción: " + draft_flow.choice_reaction(scene_id, str(GameState.preview_choices.get(scene_id, ""))), 18)
			_preview_button(body, "Continuar", func(): _commit_preview(scene_id, step + 1))
		elif step < lines.size() + 2 + after_choice.size() + (1 if draft_mode else 0):
			_preview_text(body, "Continuación recuperada: no consta su enlace con la opción elegida.", 14)
			_preview_line(body, after_choice[step - lines.size() - 2 - (1 if draft_mode else 0)])
			_preview_button(body, "Continuar", func(): _commit_preview(scene_id, step + 1))
		else:
			terminal = true
	elif not later_chat.is_empty():
		if step == lines.size():
			_preview_text(body, "El guion contiene un chat posterior, pero no especifica cómo se conecta con estas líneas.", 15)
			_preview_button(body, "Leer chat posterior", func(): _commit_preview(scene_id, step + 1))
		elif step < lines.size() + 1 + later_chat.size():
			_preview_line(body, later_chat[step - lines.size() - 1])
			_preview_button(body, "Continuar", func(): _commit_preview(scene_id, step + 1))
		else:
			terminal = true
	else:
		terminal = true
	if terminal:
		_render_preview_terminal(body, scene_id, scene)

func _render_draft_summary(body: VBoxContainer) -> void:
	_preview_text(body, "BORRADOR JUGABLE TERMINADO", 21)
	_preview_text(body, "Desenlace provisional: " + str(GameState.flags.get("draft_ending", "")), 19)
	_preview_text(body, "Regla temporal: la última respuesta del Día 4 determina este desenlace. No hay puntuación educativa ni final canónico asignado.", 15)
	_preview_text(body, "Resultado de la partida: " + GameState.moba_result + " · clase: " + GameState.moba_class, 15)
	for scene_id in PreviewCatalogScript.MAIN_ORDER:
		var selected: String = str(GameState.preview_choices.get(scene_id, ""))
		if not selected.is_empty():
			_preview_text(body, "%s: opción %s" % [scene_id, selected], 15)
	_preview_button(body, "Jugar de nuevo el borrador D1–D4", _start_playable_draft)
	_preview_button(body, "Volver al menú", _return_to_menu)

func _draft_terminal_step(scene_id: String) -> int:
	return preview_catalog.terminal_step(scene_id) + (1 if DraftFlowScript.MAIN_IDS.has(scene_id) else 0)

func _finish_draft() -> bool:
	if not GameState.flags.get("draft_mode", false) or GameState.preview_scene not in ["F01_B", "F02", "F03"] or GameState.preview_step < _draft_terminal_step(GameState.preview_scene):
		return false
	var previous := GameState.snapshot()
	GameState.flags.draft_completed = true
	GameState.flags.draft_ending = draft_flow.ending_code(GameState.preview_scene)
	if await _commit_preview("ENDINGS_INDEX", 2):
		return true
	GameState.restore(previous)
	return false

func _render_preview_summary(body: VBoxContainer) -> void:
	_preview_text(body, "RECORRIDO DE VISTA PREVIA TERMINADO", 21)
	_preview_text(body, "Leíste un extracto de final recuperado. Esta lectura no asigna un final oficial ni completa la historia canónica; faltan sus reglas y parlamentos aprobados.", 15)
	_preview_text(body, "Resultado del MOBA: " + GameState.moba_result, 16)
	_preview_text(body, "Respuestas literales guardadas en esta ranura:", 16)
	var any_choice := false
	for scene_id in PreviewCatalogScript.MAIN_ORDER:
		var selected: String = str(GameState.preview_choices.get(scene_id, ""))
		if selected.is_empty():
			continue
		var scene: Dictionary = preview_catalog.get_scene(scene_id)
		for choice in scene.get("choices", []):
			if str(choice.get("key", "")) == selected:
				_preview_text(body, "Día %d · %s · %s: %s" % [int(scene.get("day", 0)), scene_id, selected, choice.get("text", "")], 15)
				any_choice = true
				break
	if not any_choice:
		_preview_text(body, "No se registraron respuestas en los fragmentos recuperados.", 15)
	_preview_button(body, "Releer fragmentos D1–D4", func(): _commit_preview("D1_02_A", 0))
	_preview_button(body, "Revisar finales recuperados", func(): _commit_preview("ENDINGS_INDEX", 0))
	_preview_button(body, "Volver al menú", _return_to_menu)

func _finish_preview() -> bool:
	if not PreviewCatalogScript.ENDING_ORDER.has(GameState.preview_scene):
		return false
	if GameState.preview_step < preview_catalog.terminal_step(GameState.preview_scene):
		return false
	return await _commit_preview("ENDINGS_INDEX", 1, "", true)

func _render_preview_terminal(body: VBoxContainer, scene_id: String, scene: Dictionary) -> void:
	if GameState.flags.get("draft_mode", false):
		_preview_text(body, "Fin de escena · recorrido provisional. Los textos recuperados permanecen literales; los conectores y reacciones son borrador.", 15)
		if scene.has("unplaced_lines"):
			_preview_button(body, "Leer líneas sin posición confirmada", _render_unplaced_preview)
		var next_id: String = preview_catalog.next_main(scene_id)
		if scene_id == "D4_03_A":
			next_id = draft_flow.ending_for(str(GameState.preview_choices.get(scene_id, "")))
		elif scene_id == "F01_A":
			next_id = "F01_B"
		if not next_id.is_empty():
			_preview_button(body, "Continuar historia: " + next_id, func(): _commit_preview(next_id, 0)).grab_focus()
		elif scene_id in ["F01_B", "F02", "F03"]:
			_preview_button(body, "Terminar borrador jugable", _finish_draft).grab_focus()
		_preview_button(body, "Volver al menú", _return_to_menu)
		return
	if ["D4_01_A", "D4_02_A"].has(scene_id):
		_preview_text(body, "Fin del fragmento. El guion confirma que la conversación del Día 4 continúa, pero no reconstruye todas las reacciones a cada respuesta.", 15)
	else:
		_preview_text(body, "Fin del fragmento recuperado. No se conocen todos los conectores ni las reacciones de cada opción.", 15)
	if scene.has("unplaced_lines"):
		_preview_button(body, "Leer líneas sin posición confirmada", _render_unplaced_preview)
	if PreviewCatalogScript.MAIN_ORDER.has(scene_id):
		var next_id: String = preview_catalog.next_main(scene_id)
		if next_id.is_empty():
			_preview_button(body, "Explorar fragmentos de finales", func(): _commit_preview("ENDINGS_INDEX", 0))
		else:
			_preview_button(body, "Siguiente fragmento recuperado: " + next_id, func(): _commit_preview(next_id, 0))
	else:
		_preview_button(body, "Terminar recorrido de vista previa", _finish_preview).grab_focus()
		_preview_button(body, "Volver al índice de finales", func(): _commit_preview("ENDINGS_INDEX", 0))
	_preview_button(body, "Volver al menú", _return_to_menu)

func _render_unplaced_preview() -> void:
	modal_kind = "preview_unplaced"
	_clear_modal()
	_modal_text("LÍNEAS SIN POSICIÓN CONFIRMADA", 17)
	var body := _preview_content()
	var scene: Dictionary = preview_catalog.get_scene(GameState.preview_scene)
	_preview_text(body, "El guion conserva estas líneas, pero no indica después de qué opción aparecen.", 15)
	for line in scene.get("unplaced_lines", []):
		_preview_line(body, line)
	_preview_button(body, "Volver al fragmento", _render_preview)
