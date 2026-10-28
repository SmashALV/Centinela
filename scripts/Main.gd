extends Node2D

const WorldScript = preload("res://scripts/World.gd")
const NarrativeScript = preload("res://scripts/narrative/NarrativeManager.gd")
const PreviewCatalogScript = preload("res://scripts/narrative/RecoveredPreviewCatalog.gd")
const DraftFlowScript = preload("res://scripts/narrative/PlayableDraftFlow.gd")
const DisplayGuardScript = preload("res://scripts/DisplayGuard.gd")
const DAY_0_PREVIEW := "res://data/narrative/day_0_RECOVERED_PREVIEW.json"
const PROLOGUE_LINES := [
	"¡Hay días que empiezan con una alarma... y acaban convirtiéndose en una gran historia! Esta comienza en el mundo de Sofi: el colegio, sus amistades y las partidas que comparten.",
	"Ella es Sofía Castillo, aunque todos la llaman Sofi. Tiene 15 años y le encanta jugar con Mateo, Bruno, Camila y Sebas. Juntos forman un equipo dentro y fuera de la pantalla.",
	"Hoy acompañarás a Sofi. Explora, habla con el grupo y elige cómo actuar ante situaciones inesperadas en línea. Observa las señales y recuerda: pedir apoyo también cuenta. ¡Empecemos!"
]
const PORTRAITS := {
	"Sofi": "res://assets/portraits/sofi_neutral.png",
	"Mateo": "res://assets/portraits/mateo_neutral.png",
	"Bruno": "res://assets/portraits/bruno_neutral.png",
	"Camila": "res://assets/portraits/camila_neutral.png",
	"Sebas": "res://assets/portraits/sebas_neutral.png"
}
const EMOTION_PORTRAITS := {
	"Mateo_worried": "res://assets/portraits/mateo_worried.png",
	"Mateo_alarmed": "res://assets/portraits/mateo_alarmed.png",
	"Mateo_relieved": "res://assets/portraits/mateo_relieved.png",
	"Sofi_concerned": "res://assets/portraits/sofi_concerned.png"
}
const D0_CHAT_REACTIONS := {
	"D0_05_A_OPT_A": {"speaker": "Camila", "text": "¡Eso! Ya estamos todos. Busquemos partida."},
	"D0_05_A_OPT_B": {"speaker": "Bruno", "text": "Ya, ya, paz. Mejor entremos a jugar."},
	"D0_05_A_OPT_C": {"speaker": "Mateo", "text": "JAJAJA, haré lo posible. Vamos en equipo."}
}
const UI_ICONS := {
	"phone": preload("res://assets/ui/phone.png"),
	"objective": preload("res://assets/ui/objective.png"),
	"pause": preload("res://assets/ui/pause.png"),
	"controls": preload("res://assets/ui/controls.png"),
	"dialogue": preload("res://assets/ui/dialogue.png"),
	"history": preload("res://assets/ui/history.png"),
	"decision": preload("res://assets/ui/decision.png"),
	"save": preload("res://assets/ui/save.png"),
	"result": preload("res://assets/ui/result.png"),
	"interact": preload("res://assets/ui/interact.png"),
	"ability": preload("res://assets/ui/ability.png"),
	"class_attacker": preload("res://assets/ui/class_attacker.png"),
	"class_defender": preload("res://assets/ui/class_defender.png"),
	"class_support": preload("res://assets/ui/class_support.png")
}
const MENU_BANNER := preload("res://assets/ui/menu_banner.png")

var world: Node2D
var canvas: CanvasLayer
var menu_background: TextureRect
var hud: Label
var hud_icon: TextureRect
var prompt: Label
var prompt_icon: TextureRect
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
	menu_background = TextureRect.new()
	menu_background.texture = MENU_BANNER
	menu_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	menu_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	menu_background.position = Vector2.ZERO
	menu_background.size = Vector2(768, 448)
	menu_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(menu_background)
	hud_icon = _screen_icon("objective", Vector2(5, 12), 22)
	hud = _label(Vector2(30, 10), Vector2(718, 42), 16)
	prompt_icon = _screen_icon("interact", Vector2(5, 402), 24)
	prompt = _label(Vector2(30, 402), Vector2(718, 34), 17)
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
	var return_to_result: bool = GameState.returning_from_moba
	GameState.returning_from_moba = false
	if not GameState.code.is_empty():
		AudioManager.apply_preferences()
		AudioManager.enter_context("explore")
	_check_window_size()
	if return_to_result and GameState.phase == "result":
		_start_slot(GameState.slot)

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
		prompt_icon.visible = not world.nearby.is_empty()
	else:
		prompt_icon.visible = false
		if modal_kind == "menu":
			prompt.text = "Selecciona una ranura para comenzar"
		elif modal_kind == "slot_confirm":
			prompt.text = "Esc · cancelar   Elige una opción"
		elif modal_kind == "prologue":
			prompt.text = "Enter · continuar   P · pausa"
		elif modal_kind in ["preview", "preview_unplaced"]:
			prompt.text = "P · pausa   Continúa la historia"
		else:
			prompt.text = "Esc · volver   P · pausa"

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_game") and modal_kind not in ["menu", "slot_confirm"]:
		if modal_kind == "pause":
			_resume_pause()
		else:
			_show_pause()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		if ["phone", "objective", "pause", "class", "desktop", "slot_confirm", "dialogue_history"].has(modal_kind):
			if modal_kind == "pause":
				_resume_pause()
			elif modal_kind == "slot_confirm":
				_show_menu()
			elif modal_kind == "dialogue_history":
				_render_dialogue(true)
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
		if is_instance_valid(dialogue_text_label) and dialogue_visible < dialogue_text_label.text.length() and event.keycode in [KEY_1, KEY_2, KEY_3, KEY_ENTER, KEY_KP_ENTER]:
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
					if dialogue_story.current_node().get("next", null) != null:
						_advance_dialogue()
					else:
						_complete_dialogue()
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

func _screen_icon(key: String, pos: Vector2, icon_size: int) -> TextureRect:
	var icon := TextureRect.new()
	icon.texture = UI_ICONS[key]
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.position = pos
	icon.size = Vector2(icon_size, icon_size)
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(icon)
	return icon

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
	menu_background.visible = false
	modal.position = Vector2(70, 38)
	modal.custom_minimum_size = Vector2(628, 372)
	modal.size = Vector2(628, 372)
	for child in modal_box.get_children():
		modal_box.remove_child(child)
		child.queue_free()
	modal.visible = true
	world.enabled = false

func _close_modal() -> void:
	if modal_kind in ["phone", "objective", "class", "desktop"] and not GameState.ui_modal.is_empty():
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
	menu_background.visible = false
	world.enabled = true

func _modal_text(value: String, size: int = 18) -> void:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.y = 38
	label.add_theme_font_size_override("font_size", _scaled_text_size(size))
	label.add_theme_color_override("font_color", Color("fff3df"))
	modal_box.add_child(label)

func _modal_heading(value: String, icon_key: String, size: int = 23) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	modal_box.add_child(row)
	var icon := TextureRect.new()
	icon.texture = UI_ICONS[icon_key]
	icon.custom_minimum_size = Vector2(32, 32)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	row.add_child(icon)
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", _scaled_text_size(size))
	label.add_theme_color_override("font_color", Color("fff3df"))
	row.add_child(label)

func _button(value: String, callback: Callable, icon_key: String = "", parent: Control = null) -> Button:
	var button := Button.new()
	button.text = value
	button.custom_minimum_size.y = 34
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if not icon_key.is_empty():
		button.icon = UI_ICONS[icon_key]
		button.expand_icon = true
	button.add_theme_font_size_override("font_size", _scaled_text_size(16))
	button.pressed.connect(callback)
	if parent == null:
		modal_box.add_child(button)
	else:
		parent.add_child(button)
	return button

func _show_menu() -> void:
	AudioManager.set_music_paused(false)
	dialogue_key = ""
	modal_kind = "menu"
	_clear_modal()
	menu_background.visible = true
	hud_icon.visible = false
	hud.visible = false
	_modal_heading("CENTINELA 2.0", "controls", 24)
	_modal_text("Acompaña a Sofi y sus amigos desde el primer día.", 15)
	var rows: Array[Dictionary] = []
	for i in range(1, 4):
		var chosen := i
		var label := "Ranura %d · cargando..." % i if OS.has_feature("web") else SaveManager.slot_summary(i)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.custom_minimum_size.y = 34
		modal_box.add_child(row)
		var play := _button(label, func(): _start_slot(chosen), "", row)
		play.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var redo := _button("Rehacer", func(): _confirm_slot_action(chosen, true), "", row)
		var remove := _button("Borrar", func(): _confirm_slot_action(chosen, false), "", row)
		redo.custom_minimum_size.x = 94
		remove.custom_minimum_size.x = 94
		var occupied := SaveManager.slot_exists(i)
		play.disabled = OS.has_feature("web")
		redo.disabled = OS.has_feature("web") or not occupied
		remove.disabled = OS.has_feature("web") or not occupied
		rows.append({"play": play, "redo": redo, "remove": remove})
	if OS.has_feature("web"):
		_refresh_web_menu(rows)
	else:
		rows[0].play.grab_focus()

func _refresh_web_menu(rows: Array[Dictionary]) -> void:
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
			rows[i].play.text = "Ranura %d · %s · %s" % [slot_number, records[slot_number].code, records[slot_number].phase]
		else:
			rows[i].play.text = "Ranura %d · nueva" % slot_number
		rows[i].play.disabled = false
		rows[i].redo.disabled = not records.has(slot_number)
		rows[i].remove.disabled = not records.has(slot_number)
	rows[0].play.grab_focus()

func _confirm_slot_action(chosen: int, redo: bool) -> void:
	if slot_loading:
		return
	modal_kind = "slot_confirm"
	_clear_modal()
	menu_background.visible = true
	hud_icon.visible = false
	hud.visible = false
	_modal_heading("REHACER RANURA %d" % chosen if redo else "BORRAR RANURA %d" % chosen, "save")
	_modal_text("Empezarás de nuevo desde el prólogo. Se perderá el progreso local de esta ranura." if redo else "Se eliminará el guardado local de esta ranura y quedará vacía.", 17)
	var cancel := _button("Cancelar", _show_menu)
	cancel.grab_focus()
	_button("Sí, rehacer ranura" if redo else "Sí, borrar ranura", func(): _apply_slot_action(chosen, redo))

func _apply_slot_action(chosen: int, redo: bool) -> void:
	if slot_loading:
		return
	slot_loading = true
	SyncManager.on_slot_closed()
	var previous := GameState.snapshot()
	var replacement: Dictionary = {}
	if redo:
		GameState.new_game(chosen)
		replacement = GameState.snapshot()
	var succeeded := await SaveManager.clear_slot_async(chosen, replacement)
	slot_loading = false
	if not is_inside_tree():
		return
	if not succeeded:
		GameState.restore(previous)
		_show_menu()
		_toast("No se pudo modificar la ranura: " + SaveManager.last_error)
		return
	_show_menu()
	if redo:
		_start_slot(chosen)
	else:
		_toast("Ranura %d eliminada" % chosen)

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
			"desktop": _render_desktop()
	elif GameState.phase == "bedroom" and not GameState.flags.get("prologue_seen", false) and not GameState.flags.get("wakeup_seen", false):
		_render_prologue()
	elif GameState.phase == "bedroom" and not GameState.flags.get("wakeup_seen", false):
		_show_dialogue("wakeup")
	elif GameState.phase not in ["result", "preview"]:
		_close_modal()
	if recovered_local:
		_toast("Partida recuperada de una copia local")

func _load_phase() -> void:
	menu_background.visible = false
	hud_icon.visible = true
	hud.visible = true
	var world_phase := GameState.phase
	if world_phase == "result":
		world_phase = "computer"
	elif world_phase == "preview":
		world_phase = _draft_world_key() if GameState.flags.get("draft_mode", false) else "courtyard"
	world.configure(world_phase, GameState.player_position)
	_update_hud()
	if GameState.phase == "result":
		_show_result()
	elif GameState.phase == "preview":
		if GameState.flags.get("draft_exploring", false):
			modal_kind = ""
			modal.visible = false
			world.enabled = true
		else:
			_render_preview()

func _draft_world_key() -> String:
	match GameState.preview_scene:
		"D1_02_A": return "draft_d1"
		"D2_03_A": return "draft_d2"
		"D3_01_A": return "draft_d3"
		_: return "draft_d4"

func _update_hud() -> void:
	if GameState.phase == "preview":
		if GameState.flags.get("draft_exploring", false):
			var day_number: int = int(GameState.preview_scene.substr(1, 1))
			hud.text = "DÍA %d · %s | %s" % [day_number, GameState.code, _objective_text()]
		else:
			var active_scene: Dictionary = preview_catalog.get_scene(GameState.preview_scene)
			hud.text = "%s · %s" % [GameState.code, _scene_title(active_scene)]
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
		"preview": return "Habla con Mateo" if GameState.flags.get("draft_exploring", false) else "Continúa la conversación"
	return ""

func _on_interacted(target: String) -> void:
	match GameState.phase:
		"preview":
			if GameState.flags.get("draft_exploring", false) and target == "mateo":
				_commit_preview(GameState.preview_scene, 0)
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
				_show_desktop()

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
	_modal_heading("CELULAR · chats y contactos", "phone")
	var body := _preview_content()
	if GameState.phone_messages.is_empty():
		_preview_text(body, "No hay mensajes guardados. La conversación recuperada del Día 0 aparece al usar la computadora.", 16)
	else:
		_preview_text(body, "Los chicos", 15)
		for message in GameState.phone_messages:
			_preview_text(body, "%s: %s" % [message.get("speaker", ""), message.get("text", "")], 14)
	if GameState.flags.get("draft_mode", false):
		if GameState.preview_choices.has("D2_03_A"):
			_preview_text(body, "La captura la mostró Mateo en su propio teléfono. No se guardó en el celular de Sofi.", 15)
		elif GameState.flags.get("draft_exploring", false) and GameState.preview_scene == "D2_03_A":
			_preview_text(body, "Mateo tiene una captura en su propio teléfono. Acércate a él para verla.", 15)
	_button("Cerrar", _close_modal)

func _show_objective() -> void:
	await _open_ui_modal("objective", Callable(self, "_render_objective"))

func _render_objective() -> void:
	modal_kind = "objective"
	_clear_modal()
	_modal_heading("OBJETIVO", "objective")
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
		if GameState.flags.get("draft_exploring", false):
			_toast("Busca a Mateo en el escenario" if GameState.hint_level == 1 else "Acércate a Mateo y pulsa F")
		else:
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
	_modal_heading("PAUSA · " + GameState.code, "pause")
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
	_preview_button(body, "Guardar", _manual_save, "save")
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
		"prologue": _render_prologue()
		"phone": _render_phone()
		"objective": _render_objective()
		"class": _render_class()
		"desktop": _render_desktop()
		"dialogue": _render_dialogue(true)
		"dialogue_history": _render_dialogue_history()
		"result": _show_result()
		"preview": _render_preview()
		"preview_unplaced": _render_unplaced_preview()
		_: _close_modal()
	modal_before_pause = ""

func _render_prologue() -> void:
	modal_kind = "prologue"
	_clear_modal()
	modal.position = Vector2(70, 47)
	modal.custom_minimum_size = Vector2(628, 342)
	modal.size = Vector2(628, 342)
	hud_icon.visible = false
	hud.visible = false
	_modal_heading("PRÓLOGO · EL DÍA DE SOFI", "dialogue", 21)
	var body := _preview_content()
	body.get_parent().custom_minimum_size.y = 190
	var step: int = clampi(int(GameState.flags.get("prologue_step", 0)), 0, PROLOGUE_LINES.size() - 1)
	_preview_text(body, "NARRADOR", 15)
	if step == 1:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		body.add_child(row)
		_preview_text(row, PROLOGUE_LINES[step], 19, 420)
		var portrait := TextureRect.new()
		portrait.name = "PrologueSofiPortrait"
		portrait.texture = load(PORTRAITS["Sofi"]) as Texture2D
		portrait.custom_minimum_size = Vector2(100, 100)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(portrait)
	else:
		_preview_text(body, PROLOGUE_LINES[step], 19)
	_preview_text(body, "%d / %d" % [step + 1, PROLOGUE_LINES.size()], 14)
	_button("Comenzar" if step == PROLOGUE_LINES.size() - 1 else "Continuar", _advance_prologue).grab_focus()

func _advance_prologue() -> void:
	if save_in_progress or modal_kind != "prologue":
		return
	save_in_progress = true
	var previous: Dictionary = GameState.flags.duplicate(true)
	var next_step: int = int(GameState.flags.get("prologue_step", 0)) + 1
	if next_step >= PROLOGUE_LINES.size():
		GameState.flags.erase("prologue_step")
		GameState.flags.prologue_seen = true
	else:
		GameState.flags.prologue_step = next_step
	if await SaveManager.save_slot_async():
		save_in_progress = false
		if not is_inside_tree():
			return
		AudioManager.play_effect("confirm")
		if next_step >= PROLOGUE_LINES.size():
			hud_icon.visible = true
			hud.visible = true
			_show_dialogue("wakeup")
		else:
			_render_prologue()
	else:
		GameState.flags = previous
		save_in_progress = false
		_toast("No se pudo guardar el prólogo; reintenta")

func _show_desktop() -> void:
	await _open_ui_modal("desktop", Callable(self, "_render_desktop"))

func _render_desktop() -> void:
	modal_kind = "desktop"
	_clear_modal()
	_modal_heading("ESCRITORIO · PC DE SOFI", "controls")
	_modal_text("Mensajes y juego del grupo", 18)
	var chat_done: bool = GameState.flags.get("d0_chat_done", false)
	var chat_button := _button("Ver chat guardado" if chat_done else "Abrir chat del grupo", _open_desktop_chat, "phone")
	var play_button := _button("Elegir clase e iniciar partida", _show_class, "ability")
	play_button.disabled = not chat_done
	if chat_done:
		play_button.grab_focus()
	else:
		chat_button.grab_focus()
		_modal_text("Primero conversa con el grupo para preparar la partida.", 15)
	_button("Cerrar escritorio", _close_modal)

func _open_desktop_chat() -> void:
	if GameState.flags.get("d0_chat_done", false):
		_show_phone()
	else:
		_show_dialogue("group_chat")

func _show_class() -> void:
	await _open_ui_modal("class", Callable(self, "_render_class"))

func _render_class() -> void:
	modal_kind = "class"
	_clear_modal()
	_modal_heading("ELIGE CLASE · MOBA", "ability")
	for hero_class in ["Atacante", "Defensor", "Soporte"]:
		var chosen: String = hero_class
		var class_button := _button(hero_class, func(): _start_moba(chosen), "class_" + {"Atacante": "attacker", "Defensor": "defender", "Soporte": "support"}[hero_class])
		class_button.custom_minimum_size.y = 54
		if hero_class == "Atacante":
			class_button.grab_focus()
	_button("Volver al escritorio", _show_desktop)

func _show_dialogue(key: String) -> void:
	if save_in_progress:
		return
	var errors: Array[String] = dialogue_story.load_story(DAY_0_PREVIEW, true)
	if not errors.is_empty() or not dialogue_story.start_at(key):
		_toast("No se pudo abrir la conversación")
		return
	save_in_progress = true
	var previous := GameState.snapshot()
	GameState.dialogue_key = key
	GameState.dialogue_position = dialogue_story.position
	GameState.dialogue_choice = ""
	GameState.dialogue_history = []
	GameState.ui_modal = ""
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
	_modal_heading("CONVERSACIÓN", "dialogue", 20)
	var body := _preview_content()
	var reaction: Dictionary = D0_CHAT_REACTIONS.get(dialogue_choice, {}) if dialogue_key == "group_chat" and node.get("speaker") == "Sofi" else {}
	var message: String = str(reaction.get("text", node.get("text", "")))
	var speaker: String = str(reaction.get("speaker", node.get("speaker", "")))
	dialogue_text_label = _dialogue_line(body, speaker, message)
	if is_instance_valid(dialogue_text_label):
		dialogue_text_label.visible_characters = int(dialogue_visible)
	var revealing: bool = dialogue_visible < message.length()
	var choices: Array = node.get("choices", [])
	if revealing:
		_preview_button(body, "Mostrar texto", _reveal_dialogue).grab_focus()
	elif not choices.is_empty():
		_preview_text(body, "¿Qué responde Sofi?", 16)
		for i in choices.size():
			var choice_id: String = str(choices[i].choice_id)
			var option := _preview_button(body, "%d. %s" % [i + 1, choices[i].text], func(): _request_dialogue_choice(choice_id))
			if i == 0:
				option.grab_focus()
	elif node.get("next", null) != null:
		_preview_button(body, "Continuar", _advance_dialogue).grab_focus()
	else:
		_preview_button(body, "Continuar", _complete_dialogue).grab_focus()
	_preview_button(body, "Historial de esta conversación", _render_dialogue_history, "history")

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
		picture.tooltip_text = "Retrato de " + speaker
		frame.add_child(picture)
		text_parent = VBoxContainer.new()
		text_parent.custom_minimum_size.x = 420
		row.add_child(text_parent)
		width = 420
	if not speaker.is_empty():
		_preview_text(text_parent, speaker, 21, width)
	return _preview_text(text_parent, message, 18, width) if not message.is_empty() else null

func _reveal_dialogue() -> void:
	dialogue_visible = float(dialogue_text_label.text.length()) if is_instance_valid(dialogue_text_label) else 0.0
	_render_dialogue(true)

func _render_dialogue_history() -> void:
	modal_kind = "dialogue_history"
	_clear_modal()
	_modal_heading("HISTORIAL · conversación actual", "history", 20)
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

func _request_dialogue_choice(choice_id: String) -> bool:
	if save_in_progress or modal_kind != "dialogue":
		return false
	for choice in dialogue_story.current_node().get("choices", []):
		if str(choice.get("choice_id", "")) == choice_id:
			return await _choose_dialogue(choice_id)
	return false

func _request_preview_choice(scene_id: String, key: String) -> bool:
	if save_in_progress or modal_kind != "preview" or GameState.preview_scene != scene_id:
		return false
	var scene: Dictionary = preview_catalog.get_scene(scene_id)
	var step: int = scene.get("lines", []).size()
	if GameState.preview_step != step:
		return false
	for choice in scene.get("choices", []):
		if str(choice.get("key", "")) == key:
			var next_step: int = step + (2 if GameState.flags.get("draft_mode", false) else 1)
			return await _commit_preview(scene_id, next_step, key)
	return false

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
			var reply: Dictionary = D0_CHAT_REACTIONS.get(dialogue_choice, {})
			if not reply.is_empty():
				GameState.phone_messages.append({"speaker": reply.speaker, "text": reply.text})
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
		_show_desktop()
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
	_modal_heading("PARTIDA FINALIZADA", "result")
	_modal_text("Resultado: " + GameState.moba_result, 19)
	var body := _preview_content()
	_preview_text(body, "Camila: " + draft_flow.camila_reaction(GameState.moba_result, GameState.moba_class), 17)
	_preview_text(body, draft_flow.connector("D1_02_A"), 16)
	var draft_button := _preview_button(body, "Continuar historia · Día 1", _start_playable_draft)
	draft_button.disabled = preview_catalog.scenes.is_empty() or draft_flow.content.is_empty()
	if not draft_button.disabled:
		draft_button.grab_focus()
		body.get_parent().set_deferred("scroll_vertical", 0)
	var preview_button := _preview_button(body, "Explorar otras escenas", func(): _commit_preview("D1_02_A", 0))
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
	if await _commit_preview("D1_02_A", 0, "", false, true):
		return true
	GameState.restore(previous)
	return false

func _commit_preview(next_scene: String, next_step: int, choice_key: String = "", mark_reviewed: bool = false, explore: bool = false) -> bool:
	if save_in_progress or preview_catalog.scenes.is_empty():
		return false
	save_in_progress = true
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
		_toast("No se pudo guardar el avance; reintenta")
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

func _preview_text(parent: Container, value: String, size: int = 16, width: int = 545) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = width
	label.add_theme_font_size_override("font_size", _scaled_text_size(size))
	label.add_theme_color_override("font_color", Color("fff3df"))
	parent.add_child(label)
	return label

func _preview_button(parent: VBoxContainer, value: String, callback: Callable, icon_key: String = "") -> Button:
	var button := Button.new()
	button.text = value
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.custom_minimum_size = Vector2(545, 44)
	if not icon_key.is_empty():
		button.icon = UI_ICONS[icon_key]
		button.expand_icon = true
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

func _scene_title(scene: Dictionary) -> String:
	var title: String = str(scene.get("title", "Historia"))
	if title.begins_with("F0") and " · " in title:
		return title.get_slice(" · ", 1).capitalize()
	return title

func _scene_portrait_path(speaker: String, scene_id: String, choice: String = "") -> String:
	if speaker == "Sofi" and scene_id in ["D3_01_A", "D4_01_A", "D4_02_A", "D4_03_A", "F03"]:
		return EMOTION_PORTRAITS["Sofi_concerned"]
	if speaker == "Mateo":
		if choice == "A" and scene_id in ["D3_01_A", "D4_01_A", "D4_02_A", "D4_03_A", "F01_A", "F01_B"]:
			return EMOTION_PORTRAITS["Mateo_relieved"]
		if scene_id in ["D4_01_A", "F03"]:
			return EMOTION_PORTRAITS["Mateo_alarmed"]
		if scene_id in ["D2_03_A", "D3_01_A", "D4_02_A", "D4_03_A", "F02"]:
			return EMOTION_PORTRAITS["Mateo_worried"]
	return str(PORTRAITS.get(speaker, ""))

func _vn_portrait(parent: Container, portrait_path: String, size: int = 116) -> void:
	var frame := PanelContainer.new()
	frame.custom_minimum_size = Vector2(size, size)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("263550")
	style.border_color = Color("78bdbb")
	style.set_border_width_all(1)
	frame.add_theme_stylebox_override("panel", style)
	parent.add_child(frame)
	var picture := TextureRect.new()
	picture.name = "CharacterPortrait"
	picture.texture = load(portrait_path) as Texture2D if not portrait_path.is_empty() else UI_ICONS["dialogue"]
	picture.custom_minimum_size = Vector2(size - 2, size - 2)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	frame.add_child(picture)

func _vn_line(parent: VBoxContainer, line: Dictionary, scene_id: String, choice: String = "") -> void:
	var raw_speaker: String = str(line.get("speaker", ""))
	var speaker: String = raw_speaker.get_slice(" (", 0)
	var is_message: bool = "(mensaje" in raw_speaker
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	parent.add_child(row)
	var portrait_path: String = "" if speaker == "Kairo" and is_message else _scene_portrait_path(speaker, scene_id, choice)
	_vn_portrait(row, portrait_path)
	var dialogue_box := VBoxContainer.new()
	dialogue_box.custom_minimum_size.x = 405
	row.add_child(dialogue_box)
	_preview_text(dialogue_box, ("Mensaje de " if is_message else "") + speaker, 19, 405)
	_preview_text(dialogue_box, str(line.get("text", "")), 19, 405)

func _vn_choice_stage(parent: VBoxContainer, scene_id: String, choices: Array) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	parent.add_child(row)
	_vn_portrait(row, _scene_portrait_path("Sofi", scene_id), 92)
	var prompt_box := VBoxContainer.new()
	prompt_box.custom_minimum_size.x = 335
	row.add_child(prompt_box)
	_preview_text(prompt_box, "SOFI", 16, 335)
	_preview_text(prompt_box, "¿Qué le dices a Mateo?", 20, 335)
	_vn_portrait(row, _scene_portrait_path("Mateo", scene_id), 92)
	for index in choices.size():
		var choice: Dictionary = choices[index]
		var key: String = str(choice.key)
		var button := _preview_button(parent, "%d · %s" % [index + 1, str(choice.text)], func(): _request_preview_choice(scene_id, key))
		if index == 0:
			button.grab_focus()

func _render_preview() -> void:
	modal_kind = "preview"
	_clear_modal()
	var draft_mode: bool = GameState.flags.get("draft_mode", false)
	_modal_heading("LA HISTORIA DE SOFI", "dialogue", 20)
	if preview_catalog.scenes.is_empty():
		_modal_text("No se pudo abrir esta escena.", 16)
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
		_preview_text(body, "OTRAS HISTORIAS", 21)
		_preview_text(body, "Puedes visitar otras escenas de esta historia.", 15)
		for ending_id in PreviewCatalogScript.ENDING_ORDER:
			var chosen: String = ending_id
			var ending: Dictionary = preview_catalog.get_scene(chosen)
			_preview_button(body, _scene_title(ending), func(): _commit_preview(chosen, 0))
		_preview_button(body, "Volver al menú", _return_to_menu)
		return
	var scene: Dictionary = preview_catalog.get_scene(scene_id)
	if scene.is_empty():
		_preview_text(body, "Esta escena no está disponible. Vuelve al menú.")
		_preview_button(body, "Menú", _return_to_menu)
		return
	var day_label := "Final" if scene.get("day") == null else "Día " + str(int(scene.day))
	var step: int = GameState.preview_step
	if step != scene.get("lines", []).size() or scene.get("choices", []).is_empty():
		_preview_text(body, "%s · %s" % [day_label, _scene_title(scene)], 21)
	var lines: Array = scene.get("lines", [])
	var choices: Array = scene.get("choices", [])
	var after_choice: Array = scene.get("after_choice", [])
	var later_chat: Array = scene.get("later_chat", [])
	if draft_mode and step == 0:
		_preview_text(body, "NARRADOR · " + draft_flow.connector(scene_id), 15)
	var terminal := false
	if step < lines.size():
		_vn_line(body, lines[step], scene_id)
		_preview_button(body, "Continuar", func(): _commit_preview(scene_id, step + 1))
	elif not choices.is_empty():
		if step == lines.size():
			_vn_choice_stage(body, scene_id, choices)
		elif draft_mode and step == lines.size() + 1:
			var old_selection: String = str(GameState.preview_choices.get(scene_id, ""))
			_vn_line(body, {"speaker": "Mateo", "text": draft_flow.choice_reaction(scene_id, old_selection)}, scene_id, old_selection)
			_preview_button(body, "Continuar", func(): _commit_preview(scene_id, step + 2))
		elif step == lines.size() + (2 if draft_mode else 1):
			var selected: String = str(GameState.preview_choices.get(scene_id, ""))
			_vn_line(body, {"speaker": "Mateo", "text": draft_flow.choice_reaction(scene_id, selected)}, scene_id, selected)
			_preview_button(body, "Continuar", func(): _commit_preview(scene_id, step + 1))
		elif step < lines.size() + 2 + after_choice.size() + (1 if draft_mode else 0):
			_vn_line(body, after_choice[step - lines.size() - 2 - (1 if draft_mode else 0)], scene_id)
			_preview_button(body, "Continuar", func(): _commit_preview(scene_id, step + 1))
		else:
			terminal = true
	elif not later_chat.is_empty():
		if step == lines.size():
			_preview_button(body, "Ver los mensajes", func(): _commit_preview(scene_id, step + 1))
		elif step < lines.size() + 1 + later_chat.size():
			_vn_line(body, later_chat[step - lines.size() - 1], scene_id)
			_preview_button(body, "Continuar", func(): _commit_preview(scene_id, step + 1))
		else:
			terminal = true
	else:
		terminal = true
	if terminal:
		_render_preview_terminal(body, scene_id, scene)

func _render_draft_summary(body: VBoxContainer) -> void:
	_preview_text(body, "FIN DE LA HISTORIA", 21)
	var ending_name: String = {"F01": "Buscar apoyo", "F02": "Poner un límite", "F03": "Una decisión pendiente"}.get(str(GameState.flags.get("draft_ending", "")), "La historia continúa")
	_preview_text(body, ending_name, 19)
	_preview_text(body, "Sofi y Mateo llegaron hasta aquí juntos. Puedes volver a recorrer sus decisiones.", 15)
	_preview_text(body, "Resultado de la partida: " + GameState.moba_result + " · clase: " + GameState.moba_class, 15)
	for scene_id in PreviewCatalogScript.MAIN_ORDER:
		var selected: String = str(GameState.preview_choices.get(scene_id, ""))
		if not selected.is_empty():
			var selected_scene: Dictionary = preview_catalog.get_scene(scene_id)
			_preview_text(body, "Día %d · %s: opción %s" % [int(selected_scene.get("day", 0)), _scene_title(selected_scene), selected], 15)
	_preview_button(body, "Volver a vivir los Días 1–4", _start_playable_draft)
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
	_preview_text(body, "HISTORIA RECORRIDA", 21)
	_preview_text(body, "Puedes regresar a las escenas y explorar otras decisiones.", 15)
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
				_preview_text(body, "Día %d · %s: %s" % [int(scene.get("day", 0)), _scene_title(scene), choice.get("text", "")], 15)
				any_choice = true
				break
	if not any_choice:
		_preview_text(body, "Todavía no elegiste ninguna respuesta en estas escenas.", 15)
	_preview_button(body, "Volver al Día 1", func(): _commit_preview("D1_02_A", 0))
	_preview_button(body, "Ver otras escenas", func(): _commit_preview("ENDINGS_INDEX", 0))
	_preview_button(body, "Volver al menú", _return_to_menu)

func _finish_preview() -> bool:
	if not PreviewCatalogScript.ENDING_ORDER.has(GameState.preview_scene):
		return false
	if GameState.preview_step < preview_catalog.terminal_step(GameState.preview_scene):
		return false
	return await _commit_preview("ENDINGS_INDEX", 1, "", true)

func _render_preview_terminal(body: VBoxContainer, scene_id: String, scene: Dictionary) -> void:
	if GameState.flags.get("draft_mode", false):
		_preview_text(body, "La conversación continúa.", 15)
		var next_id: String = preview_catalog.next_main(scene_id)
		if scene_id == "D4_03_A":
			next_id = draft_flow.ending_for(str(GameState.preview_choices.get(scene_id, "")))
		elif scene_id == "F01_A":
			next_id = "F01_B"
		if not next_id.is_empty():
			var next_explore: bool = DraftFlowScript.EXPLORATION_IDS.has(next_id) and scene_id not in ["D4_01_A", "D4_02_A"]
			var next_scene: Dictionary = preview_catalog.get_scene(next_id)
			_preview_button(body, "Continuar · " + _scene_title(next_scene), func(): _commit_preview(next_id, 0, "", false, next_explore)).grab_focus()
		elif scene_id in ["F01_B", "F02", "F03"]:
			_preview_button(body, "Terminar historia", _finish_draft).grab_focus()
		_preview_button(body, "Volver al menú", _return_to_menu)
		return
	_preview_text(body, "La conversación continúa.", 15)
	if scene.has("unplaced_lines"):
		_preview_button(body, "Escena adicional", _render_unplaced_preview)
	if PreviewCatalogScript.MAIN_ORDER.has(scene_id):
		var next_id: String = preview_catalog.next_main(scene_id)
		if next_id.is_empty():
			_preview_button(body, "Ver otras escenas", func(): _commit_preview("ENDINGS_INDEX", 0))
		else:
			_preview_button(body, "Continuar · " + _scene_title(preview_catalog.get_scene(next_id)), func(): _commit_preview(next_id, 0))
	else:
		_preview_button(body, "Terminar historia", _finish_preview).grab_focus()
		_preview_button(body, "Ver otras escenas", func(): _commit_preview("ENDINGS_INDEX", 0))
	_preview_button(body, "Volver al menú", _return_to_menu)

func _render_unplaced_preview() -> void:
	modal_kind = "preview_unplaced"
	_clear_modal()
	_modal_heading("ESCENA ADICIONAL", "history", 17)
	var body := _preview_content()
	var scene: Dictionary = preview_catalog.get_scene(GameState.preview_scene)
	for line in scene.get("unplaced_lines", []):
		_preview_line(body, line)
	_preview_button(body, "Volver a la escena", _render_preview)
