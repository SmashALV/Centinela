extends Node2D

const WorldScript = preload("res://scripts/World.gd")
const NarrativeScript = preload("res://scripts/narrative/NarrativeManager.gd")
const PreviewCatalogScript = preload("res://scripts/narrative/RecoveredPreviewCatalog.gd")
const DraftFlowScript = preload("res://scripts/narrative/PlayableDraftFlow.gd")
const CoralFlowScript = preload("res://scripts/narrative/CoralStoryFlow.gd")
const DisplayGuardScript = preload("res://scripts/DisplayGuard.gd")
const ConversationUIScript = preload("res://scripts/ConversationUI.gd")
const DailyRoutineScript = preload("res://scripts/DailyRoutine.gd")
const DesktopUIScript = preload("res://scripts/DesktopUI.gd")
const DAY_0_PREVIEW := "res://data/narrative/day_0_RECOVERED_PREVIEW.json"
const PROLOGUE_LINES := [
	"Sofi tiene 15 años y le encanta jugar con Mateo, Camila, Bruno y Sebas. Entre el colegio y las partidas, siempre encuentran algo de qué hablar.",
	"Hoy hay una mochila por preparar, amigos por encontrar y una partida pendiente. Cada uno llega con sus propias preocupaciones.",
	"Acompaña a Sofi. Explora, escucha y decide cómo responder: una conversación puede cambiar lo que sucede después."
]

const PORTRAITS := {
	"Sofi": "res://assets/portraits/sofi_v4.tres",
	"Mateo": "res://assets/portraits/mateo_v4.tres",
	"Bruno": "res://assets/portraits/bruno_v4.tres",
	"Camila": "res://assets/portraits/camila_v4.tres",
	"Sebas": "res://assets/portraits/sebas_v4.tres"
}
const EMOTION_PORTRAITS := {
	"Mateo_worried": "res://assets/portraits/mateo_worried_v4.tres",
	"Mateo_alarmed": "res://assets/portraits/mateo_alarmed_v4.tres",
	"Mateo_relieved": "res://assets/portraits/mateo_v4.tres",
	"Sofi_concerned": "res://assets/portraits/sofi_concerned_v4.tres"
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
var inventory_panel: PanelContainer
var inventory_label: Label
var prompt: Label
var prompt_icon: TextureRect
var modal: PanelContainer
var modal_box: VBoxContainer
var conversation_ui: Control
var daily: Node
var desktop_ui: Control
var desktop_direct := false
var modal_kind: String = ""
var modal_before_pause: String = ""
var paused_reading: Dictionary = {}
var phase_load_after_pause := false
var toast: Label
var toast_time := 0.0
var autosave_elapsed := 0.0
var dialogue_story: RefCounted
var preview_catalog: RefCounted
var draft_flow: RefCounted
var coral_flow: RefCounted
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
	else:
		preview_catalog.scenes["D2_04_A"] = draft_flow.authored_scene()
		preview_catalog.scenes["D1_03_A"] = draft_flow.d1_private_scene()
	coral_flow = CoralFlowScript.new()
	var coral_errors: Array[String] = coral_flow.load_story()
	if not coral_errors.is_empty():
		push_error("Guion coral inválido: " + "; ".join(coral_errors))
	world = WorldScript.new()
	add_child(world)
	world.interacted.connect(_on_interacted)
	world.departure_finished.connect(_on_departure_finished)
	world.boundary_reached.connect(func(edge):
		if daily.active(): daily.boundary(edge))
	daily = DailyRoutineScript.new()
	daily.main = self
	add_child(daily)
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
	_build_inventory_panel()
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
	conversation_ui = ConversationUIScript.new()
	canvas.add_child(conversation_ui)
	desktop_ui = DesktopUIScript.new()
	canvas.add_child(desktop_ui)
	conversation_ui.auto_guard = func(): return not save_in_progress and not window_too_small and modal_kind not in ["pause", "menu"]
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
		elif modal_kind in ["prologue", "stage_guide"]:
			prompt.text = "Lectura automática · P para pausar"
		elif modal_kind in ["preview", "preview_unplaced", "day_intro", "coral"]:
			prompt.text = "Lectura automática · P para pausar"
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
		if ["phone", "objective", "pause", "class", "desktop", "discord_history", "slot_confirm", "dialogue_history", "observation"].has(modal_kind):
			if modal_kind == "pause":
				_resume_pause()
			elif modal_kind == "slot_confirm":
				_show_menu()
			elif modal_kind == "dialogue_history":
				_render_dialogue(true)
			elif modal_kind == "discord_history": _render_desktop()
			else:
				_close_modal()
			get_viewport().set_input_as_handled()
	elif modal_kind == "phone" and event.is_action_pressed("phone"):
		_close_modal()
		get_viewport().set_input_as_handled()
	elif modal_kind == "coral" and event is InputEventKey and event.pressed and not event.echo:
		if GameState.coral_state.get("mode") == "scene" and event.keycode in [KEY_1, KEY_2, KEY_3]:
			var coral_scene: Dictionary = coral_flow.scene(str(GameState.coral_state.node), preview_catalog, draft_flow, GameState.coral_state)
			var coral_index: int = [KEY_1, KEY_2, KEY_3].find(event.keycode)
			if int(GameState.coral_state.step) == coral_scene.get("lines", []).size() and coral_index < coral_scene.get("choices", []).size():
				_coral_choose(str(coral_scene.choices[coral_index].key))
				get_viewport().set_input_as_handled()
	elif modal_kind == "preview" and event is InputEventKey and event.pressed and not event.echo:
		var preview_scene: Dictionary = preview_catalog.get_scene(GameState.preview_scene)
		var preview_choices: Array = preview_scene.get("choices", [])
		if GameState.preview_step == _scene_parts(GameState.preview_scene, GameState.flags.get("draft_mode", false)).lines.size() and not preview_choices.is_empty():
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
	style.bg_color = Color("594060")
	style.border_color = Color("d5a4ca")
	style.set_border_width_all(3)
	style.set_content_margin_all(20)
	return style

func _clear_modal() -> void:
	if is_instance_valid(desktop_ui): desktop_ui.clear_view()
	if is_instance_valid(conversation_ui):
		conversation_ui.clear_view()
	prompt.visible = true
	hud.visible = not GameState.code.is_empty()
	hud_icon.visible = hud.visible
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
	if modal_kind in ["phone", "objective", "class", "desktop", "discord_history"] and not GameState.ui_modal.is_empty():
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
	if is_instance_valid(desktop_ui): desktop_ui.clear_view()
	modal.visible = false
	if is_instance_valid(conversation_ui):
		conversation_ui.clear_view()
	prompt.visible = true
	menu_background.visible = false
	world.enabled = true
	hud.visible = not GameState.code.is_empty()
	hud_icon.visible = hud.visible

func _begin_conversation_presentation() -> void:
	_clear_modal()
	modal.visible = false
	hud.visible = false
	hud_icon.visible = false
	prompt.visible = false
	prompt_icon.visible = false

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
	paused_reading.clear()
	phase_load_after_pause = false
	if is_instance_valid(desktop_ui): desktop_ui.clear_view()
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
			rows[i].play.text = "Ranura %d · Partida guardada" % slot_number
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
	_modal_text("Empezarás de nuevo desde el comienzo. Se perderá el progreso local de esta ranura." if redo else "Se eliminará el guardado local de esta ranura y quedará vacía.", 17)
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
		daily.initialize()
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

func _start_slot(chosen: int, upgrade_routine := true) -> void:
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
			if upgrade_routine: daily.initialize()
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
			if upgrade_routine: daily.initialize()
			if not SaveManager.save_slot():
				slot_loading = false
				_toast("No se pudo crear la partida")
				return
	slot_loading = false
	if upgrade_routine and not daily.active() and GameState.phase in ["bedroom", "courtyard", "computer", "result", "coral", "moba"] and not GameState.coral_state.get("mode") in ["ending", "summary"]:
		var old_phase: String = GameState.phase
		var resumed_day: int = int(GameState.coral_state.get("day", 0))
		daily.initialize(resumed_day)
		if old_phase == "courtyard" or old_phase == "coral":
			daily.state().stage = "arrival"
			daily.state().place = "computer" if resumed_day == 1 else "school"
		elif old_phase in ["computer", "result", "moba"]:
			daily.state().stage = "evening"
			daily.state().place = "bedroom"
		daily.state().messages_checked = true
		if not await SaveManager.save_slot_async():
			_toast("No se pudo actualizar la rutina de esta ranura")
			_show_menu()
			return
	SyncManager.on_slot_opened()
	AudioManager.apply_preferences()
	if GameState.phase != "moba":
		AudioManager.enter_context("explore")
	_refresh_static_fonts()
	if GameState.phase == "moba":
		get_tree().change_scene_to_file("res://scenes/moba/MOBAArena.tscn")
		return
	_load_phase()
	if daily.active():
		if not GameState.dialogue_key.is_empty(): _resume_saved_dialogue()
		elif GameState.ui_modal == "desktop": _render_desktop()
		elif GameState.ui_modal == "class": _render_class()
		elif GameState.ui_modal == "phone": _render_phone()
		elif GameState.ui_modal == "objective": _render_objective()
		return
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
	elif not str(GameState.flags.get("d0_guide_active", "")).is_empty():
		_render_stage_guide()
	elif GameState.phase == "bedroom" and not GameState.flags.get("prologue_seen", false) and not GameState.flags.get("wakeup_seen", false):
		_render_prologue()
	elif GameState.phase == "bedroom" and not GameState.flags.get("wakeup_seen", false):
		_show_dialogue("wakeup")
	elif GameState.phase == "bedroom" and not GameState.flags.get("d0_guide_bedroom_seen", false):
		_begin_stage_guide("bedroom")
	elif GameState.phase not in ["result", "preview", "coral"]:
		_close_modal()
	if recovered_local:
		_toast("Partida recuperada de una copia local")

func _load_phase() -> void:
	if modal_kind == "pause":
		phase_load_after_pause = true
		return
	if is_instance_valid(conversation_ui):
		conversation_ui.clear_view()
	prompt.visible = true
	menu_background.visible = false
	hud_icon.visible = true
	hud.visible = true
	if daily.active():
		daily.load_view()
		return
	var world_phase := GameState.phase
	if world_phase == "result":
		world_phase = "computer"
	elif world_phase == "preview":
		world_phase = _draft_world_key() if GameState.flags.get("draft_mode", false) else "courtyard"
	elif world_phase == "coral":
		world_phase = coral_flow.world_key(GameState.coral_state)
	world.configure(world_phase, GameState.player_position)
	if GameState.phase == "coral":
		world.configure_story_targets(_coral_targets(), _coral_primary_target())
	_update_hud()
	if GameState.phase == "courtyard" and GameState.flags.get("friends", false) and not GameState.flags.get("d0_departure_seen", false):
		world.begin_departures()
	if not str(GameState.flags.get("d0_guide_active", "")).is_empty():
		_render_stage_guide()
	elif GameState.phase == "result":
		_show_result()
	elif GameState.phase == "preview":
		if GameState.flags.get("draft_exploring", false):
			if GameState.flags.has("draft_intro_step"):
				_render_day_intro()
			else:
				modal_kind = ""
				modal.visible = false
				world.enabled = true
		else:
			_render_preview()
	elif GameState.phase == "coral":
		_render_coral()

func _draft_world_key() -> String:
	match GameState.preview_scene:
		"D1_02_A", "D1_03_A": return "draft_d1"
		"D2_03_A", "D2_04_A": return "draft_d2"
		"D3_01_A": return "draft_d3"
		_: return "draft_d4"

func _build_inventory_panel() -> void:
	# Hijo del HUD: se oculta junto con él en menús y conversaciones.
	inventory_panel = PanelContainer.new()
	inventory_panel.name = "InventoryPanel"
	inventory_panel.position = Vector2(560, 352)
	inventory_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color("10192bd9")
	style.border_color = Color("f5d479")
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(5)
	inventory_panel.add_theme_stylebox_override("panel", style)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	inventory_panel.add_child(row)
	var icon := TextureRect.new()
	icon.texture = WorldScript.OBJECT_SPRITES.backpack
	icon.custom_minimum_size = Vector2(26, 26)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(icon)
	inventory_label = Label.new()
	inventory_label.name = "InventoryText"
	inventory_label.add_theme_font_size_override("font_size", 13)
	inventory_label.add_theme_color_override("font_color", Color("fff3df"))
	row.add_child(inventory_label)
	hud.add_child(inventory_panel)
	inventory_panel.visible = false

func _refresh_inventory() -> void:
	if not is_instance_valid(inventory_panel): return
	var items: Array = GameState.flags.get("inventory", [])
	inventory_panel.visible = not items.is_empty()
	inventory_label.text = "Inventario: " + ", ".join(items.map(func(item): return str(item).capitalize()))

func _pick_up_item(item: String, flag: String, message: String) -> void:
	if save_in_progress: return
	if GameState.has_item(item):
		_toast("Ya llevas la " + item + " en tu inventario")
		return
	var previous: Dictionary = GameState.snapshot()
	GameState.add_item(item)
	GameState.flags[flag] = true
	save_in_progress = true
	world.enabled = false
	if await SaveManager.save_slot_async():
		save_in_progress = false
		if not is_inside_tree(): return
		# El objeto desaparece del mapa: deja de ser objetivo y de dibujarse.
		world.objects.erase(flag)
		if daily.active(): world.configure_story_targets(daily.targets(), daily._primary_target())
		_update_hud()
		AudioManager.play_effect("pickup")
		world.enabled = modal_kind == ""
		_toast(message)
	else:
		GameState.restore(previous)
		save_in_progress = false
		if modal_kind == "": world.enabled = true
		_toast("Error al guardar")

func _update_hud() -> void:
	_refresh_inventory()
	if daily.active():
		hud.text = "DÍA %d · %s" % [int(daily.state().day), daily.objective()]
		return
	if GameState.phase == "coral":
		hud.text = "DÍA %d · %s" % [int(GameState.coral_state.get("day", 1)), _objective_text()]
		return
	if GameState.phase == "preview":
		if GameState.flags.get("draft_exploring", false):
			var day_number: int = int(GameState.preview_scene.substr(1, 1))
			hud.text = "DÍA %d · %s" % [day_number, _objective_text()]
		else:
			var active_scene: Dictionary = preview_catalog.get_scene(GameState.preview_scene)
			hud.text = _scene_title(active_scene)
		return
	var place: String = {"bedroom": "HABITACIÓN", "courtyard": "PATIO", "computer": "COMPUTADORA", "result": "RESULTADO"}.get(GameState.phase, GameState.phase.to_upper())
	hud.text = "DÍA 0 · %s | %s" % [place, _objective_text()]

func _objective_text() -> String:
	if daily.active(): return daily.objective()
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
		"coral": return coral_flow.objective(GameState.coral_state)
	return ""

func _on_interacted(target: String) -> void:
	if daily.active():
		if target != "backpack": AudioManager.play_effect("interact")
		daily.interact(target)
		return
	match GameState.phase:
		"coral":
			_coral_interact(target)
		"preview":
			if GameState.flags.get("draft_exploring", false) and target == "mateo":
				_commit_preview(GameState.preview_scene, 0)
		"bedroom":
			if target == "backpack":
				_pick_up_item("mochila", "backpack", "Mochila guardada en el inventario")
			elif target == "alarm":
				_commit_flag(target, "Interacción registrada: " + world.target_label(target))
			elif target == "door":
				if not GameState.flags.get("alarm", false) or not GameState.flags.get("backpack", false):
					_toast("Completa la alarma y la mochila primero")
				else:
					_transition("courtyard", Vector2(140, 300))
			else:
				if target in ["photo", "desk"]: _inspect_d0(target)
		"courtyard":
			if target == "friends":
				if not GameState.flags.get("friends", false): _show_dialogue("courtyard")
			elif target == "exit":
				if GameState.flags.get("friends", false):
					_transition("computer", Vector2(384, 320))
				else:
					_toast("Primero acércate al grupo")
			elif target == "tutoria":
				_inspect_d0("tutoria")
		"computer":
			if target == "pc":
				_show_desktop()

func _begin_stage_guide(place: String) -> void:
	if save_in_progress: return
	var previous: Dictionary = GameState.snapshot()
	GameState.flags.d0_guide_active = place
	save_in_progress = true
	if await SaveManager.save_slot_async():
		save_in_progress = false
		_render_stage_guide()
	else:
		GameState.restore(previous)
		save_in_progress = false
		_toast("No se pudo guardar la guía")

func _render_stage_guide() -> void:
	modal_kind = "stage_guide"
	_begin_conversation_presentation()
	var place: String = str(GameState.flags.get("d0_guide_active", GameState.phase))
	var title: String = {"bedroom": "Antes de salir", "courtyard": "Un momento con tus amigos", "computer": "De vuelta en casa"}.get(place, "")
	var message: String = {
		"bedroom": "Sofi se prepara para ir al colegio. Muévete con WASD, acércate a la alarma y pulsa F. Después recoge la mochila y busca la puerta. La marca dorada indica dónde seguir; puedes mirar otros objetos antes de salir.",
		"courtyard": "Antes de entrar a clase, Sofi se encuentra con sus amigos en el patio. Acércate al grupo y pulsa F para conversar. Al terminar, sus amigos se despedirán y podrás ir hacia la salida.",
		"computer": "Pasaron las clases. Por la tarde, Sofi vuelve a casa, termina sus tareas y enciende la computadora. Sus amigos la esperan en el chat para preparar una partida. Acércate a la PC y pulsa F."
	}.get(place, "")
	conversation_ui.show_stage_card(title, message, _finish_stage_guide, _scaled_text_size(18))

func _finish_stage_guide() -> bool:
	if save_in_progress or modal_kind != "stage_guide": return false
	var previous: Dictionary = GameState.snapshot()
	GameState.flags["d0_guide_" + GameState.phase + "_seen"] = true
	GameState.flags.erase("d0_guide_active")
	save_in_progress = true
	if await SaveManager.save_slot_async():
		save_in_progress = false
		_close_modal()
		return true
	GameState.restore(previous)
	save_in_progress = false
	return false

func _on_departure_finished() -> void:
	GameState.flags.d0_departure_seen = true
	_autosave()

func _transition(next_phase: String, position: Vector2) -> void:
	var old_phase: String = GameState.phase
	var old_position: Vector2 = GameState.player_position
	var old_flags: Dictionary = GameState.flags.duplicate(true)
	if next_phase in ["courtyard", "computer"] and not GameState.flags.get("d0_guide_" + next_phase + "_seen", false): GameState.flags.d0_guide_active = next_phase
	GameState.phase = next_phase
	GameState.player_position = position
	world.enabled = false
	if await SaveManager.save_slot_async():
		if not is_inside_tree():
			return
		_load_phase()
		AudioManager.play_effect("confirm")
		world.enabled = str(GameState.flags.get("d0_guide_active", "")).is_empty()
	else:
		GameState.flags = old_flags
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

func _inspect_d0(target: String) -> void:
	if save_in_progress: return
	var flag_name: String = "d0_" + target + "_seen"
	if not GameState.flags.get(flag_name, false):
		var previous: Dictionary = GameState.snapshot()
		GameState.flags[flag_name] = true
		save_in_progress = true
		if not await SaveManager.save_slot_async():
			GameState.restore(previous)
			save_in_progress = false
			_toast("No se pudo guardar la observación")
			return
		save_in_progress = false
	_clear_modal()
	modal_kind = "observation"
	_modal_heading("SOFI OBSERVA", "objective")
	var descriptions := {
		"photo": "Sofi mira una foto con Mateo, Camila, Bruno y Sebas. Juegan juntos desde hace tiempo, aunque cada uno necesita su propio espacio y sus propios horarios.",
		"desk": "En su escritorio, Sofi recuerda el acuerdo del grupo: avisar cuando alguien se desconecte, no compartir datos de otra persona y aceptar un no sin insistir.",
		"tutoria": "El cartel de tutoría recuerda que se puede hablar con una persona adulta de confianza aun sin tener todas las respuestas. Pedir apoyo es una opción disponible desde el comienzo."
	}
	_modal_text(str(descriptions.get(target, "")), 18)
	_button("Volver", _close_modal)

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
	var checked_before: bool = daily.state().get("messages_checked", false) if daily.active() else false
	if daily.active() and kind in ["phone", "desktop"]: daily.state().messages_checked = true
	GameState.ui_modal = kind
	if await SaveManager.save_slot_async():
		if is_inside_tree():
			if modal_kind == "pause":
				modal_before_pause = kind
			else:
				renderer.call()
	else:
		GameState.ui_modal = previous
		if daily.active(): daily.state().messages_checked = checked_before
		_toast("No se pudo abrir el panel; reintenta")
	save_in_progress = false

func _render_phone() -> void:
	modal_kind = "phone"
	_clear_modal()
	_modal_heading("CELULAR · chats y contactos", "phone")
	var body := _preview_content()
	if GameState.phone_messages.is_empty():
		_preview_text(body, "No hay mensajes nuevos. El grupo se conectará esta noche.", 16)
	else:
		_preview_text(body, "Los chicos", 15)
		for message in GameState.phone_messages:
			if message.get("channel", "group") == "mateo": continue
			_preview_text(body, "%s\n%s" % [message.get("speaker", ""), ConversationUIScript.dialogue_text(str(message.get("text", "")))], 14)
		var private_messages: Array = GameState.phone_messages.filter(func(message): return message.get("channel", "group") == "mateo")
		if not private_messages.is_empty(): _preview_text(body, "Mateo · Mensajes directos", 15)
		for message in private_messages:
			_preview_text(body, "%s\n%s" % [message.get("speaker", ""), ConversationUIScript.dialogue_text(str(message.get("text", "")))], 14)
	if GameState.flags.get("draft_mode", false):
		if GameState.preview_choices.has("D2_03_A"):
			_preview_text(body, "La captura la mostró Mateo en su propio teléfono. No se guardó en el celular de Sofi.", 15)
		elif GameState.flags.get("draft_exploring", false) and GameState.preview_scene == "D2_03_A":
			_preview_text(body, "Mateo tiene una captura en su propio teléfono. Acércate a él para verla.", 15)
	if GameState.phase == "coral":
		var facts: Array = GameState.coral_state.get("observed", [])
		_preview_text(body, "LIBRETA DE SOFI", 16)
		var fact_labels := {"camila_request_shared": "Camila recibió una pregunta sobre los horarios de Mateo y pidió discreción.", "mateo_secret_shared": "Mateo mostró un regalo vinculado a una petición de secreto que lo incomoda.", "sebas_fatigue_observed": "Sebas contó que teme perder ayuda en el juego si no sigue el horario de Kairo."}
		if facts.is_empty(): _preview_text(body, "Todavía no hay hechos registrados.", 14)
		for fact in facts:
			_preview_text(body, str(fact_labels.get(fact, "Una conversación quedó registrada.")), 14)
		_preview_text(body, "Esta libreta distingue lo observado de las suposiciones. No necesitas recopilar pruebas para ofrecer apoyo.", 14)
	_button("Cerrar", _close_modal)

func _show_objective() -> void:
	await _open_ui_modal("objective", Callable(self, "_render_objective"))

func _render_objective() -> void:
	modal_kind = "objective"
	_clear_modal()
	_modal_heading("OBJETIVO", "objective")
	_modal_text(("Orientación: " if GameState.phase != "coral" else "") + _objective_text(), 19)
	if GameState.phase == "coral":
		var state: Dictionary = GameState.coral_state
		var day_key: String = str(state.get("day", 1))
		var requests: Dictionary = state.get("hint_requests", {})
		var shown: String = str(requests.get(day_key, ""))
		if not shown.is_empty():
			_modal_text((daily.objective() if daily.active() else coral_flow.navigation_hint(state)) if shown == "nav" else coral_flow.educational_hint(state, 1 if shown == "h1" else 2), 15)
		_button("Pista de orientación", func(): _coral_request_hint("nav"))
		_button("Pista para observar", func(): _coral_request_hint("h1"))
		_button("Pista para comprender", func(): _coral_request_hint("h2"))
	else:
		if GameState.phase in ["bedroom", "courtyard", "computer"]:
			if GameState.hint_level > 0: _modal_text(_d0_educational_hint(GameState.hint_level), 15)
			_button("H1 · Observa", func(): _set_d0_hint(1))
			_button("H2 · Comprende", func(): _set_d0_hint(2))
		else:
			_button("Pista", _advance_hint)
	_button("Cerrar", _close_modal)

func _d0_educational_hint(level: int) -> String:
	if level == 1:
		return "¿Qué podría ver alguien nuevo sobre Sofi? ¿Con quién puede hablar si una conversación le incomoda?"
	return "Revisar privacidad, cuidar los horarios y mantener cerca a personas de confianza ayuda a reconocer y poner límites a una presión futura."

func _set_d0_hint(level: int) -> void:
	if save_in_progress: return
	var previous: int = GameState.hint_level
	GameState.hint_level = level
	save_in_progress = true
	if await SaveManager.save_slot_async():
		save_in_progress = false
		_render_objective()
	else:
		GameState.hint_level = previous
		save_in_progress = false
		_toast("No se pudo guardar la pista")

func _coral_request_hint(kind: String) -> void:
	if save_in_progress or GameState.phase != "coral": return
	var previous: Dictionary = GameState.snapshot()
	GameState.coral_state.hint_requests[str(GameState.coral_state.day)] = kind
	var hint_action: String = "HINT_D%d_%s" % [int(GameState.coral_state.day), kind]
	if not GameState.coral_state.actions.has(hint_action): GameState.coral_state.actions.append(hint_action)
	save_in_progress = true
	if await SaveManager.save_slot_async():
		save_in_progress = false
		_render_objective()
	else:
		GameState.restore(previous)
		save_in_progress = false
		_toast("No se pudo guardar la pista")

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
	if modal_kind == "pause": return
	paused_reading = conversation_ui.capture_reading_state()
	modal_before_pause = modal_kind
	AudioManager.set_music_paused(true)
	_render_pause()

func _render_pause() -> void:
	modal_kind = "pause"
	_clear_modal()
	_modal_heading("PAUSA", "pause")
	var body := _preview_content()
	_preview_text(body, "Tu progreso se guarda en este dispositivo.", 15)
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
	if window_too_small or save_in_progress:
		return
	AudioManager.set_music_paused(false)
	modal_kind = modal_before_pause
	if phase_load_after_pause:
		phase_load_after_pause = false
		modal_kind = ""
		_load_phase()
		if daily.active():
			conversation_ui.restore_reading_state(paused_reading)
			paused_reading.clear()
			modal_before_pause = ""
			return
		if not GameState.dialogue_key.is_empty(): _resume_saved_dialogue()
		elif GameState.phase in ["bedroom", "courtyard", "computer"] and not GameState.flags.has("d0_guide_active"): _close_modal()
		conversation_ui.restore_reading_state(paused_reading)
		paused_reading.clear()
		modal_before_pause = ""
		return
	match modal_before_pause:
		"prologue": _render_prologue()
		"stage_guide": _render_stage_guide()
		"phone": _render_phone()
		"objective": _render_objective()
		"class": _render_class()
		"desktop": _render_desktop()
		"discord_history": _render_discord_history(desktop_direct)
		"dialogue": _render_dialogue(true)
		"dialogue_history": _render_dialogue_history()
		"result": _show_result()
		"day_intro": _render_day_intro()
		"preview": _render_preview()
		"preview_unplaced": _render_unplaced_preview()
		"coral": _render_coral()
		"routine": daily._render_scene()
		"sleep": daily._render_sleep()
		_: _close_modal()
	conversation_ui.restore_reading_state(paused_reading)
	paused_reading.clear()
	modal_before_pause = ""

func _render_prologue() -> void:
	modal_kind = "prologue"
	_begin_conversation_presentation()
	conversation_ui.show_prologue("\n\n".join(PROLOGUE_LINES), _advance_prologue, _scaled_text_size(18))

func _advance_prologue() -> void:
	if save_in_progress or modal_kind != "prologue": return
	save_in_progress = true
	var previous: Dictionary = GameState.flags.duplicate(true)
	GameState.flags.erase("prologue_step")
	GameState.flags.prologue_seen = true
	if await SaveManager.save_slot_async():
		save_in_progress = false
		if is_inside_tree(): _show_dialogue("wakeup")
	else:
		GameState.flags = previous
		save_in_progress = false
		_toast("No se pudo guardar el prólogo; reintentando")

func _show_desktop() -> void:
	if daily.active() and not daily.can_use_pc():
		_toast("La computadora está en tu habitación o en la sala de cómputo")
		return
	await _open_ui_modal("desktop", Callable(self, "_render_desktop"))

func _render_desktop() -> void:
	modal_kind = "desktop"
	_clear_modal()
	modal.visible = false
	hud.visible = false
	hud_icon.visible = false
	prompt.visible = false
	desktop_ui.show_desktop(self)
	return

func _inspect_profile() -> void:
	if save_in_progress or GameState.flags.get("d0_profile_private", false): return
	var previous: Dictionary = GameState.snapshot()
	GameState.flags.d0_profile_private = true
	save_in_progress = true
	if await SaveManager.save_slot_async():
		save_in_progress = false
		_render_desktop()
	else:
		GameState.restore(previous)
		save_in_progress = false
		_toast("No se pudo guardar la revisión de privacidad")

func _open_desktop_chat() -> void:
	if daily.active() and daily.state().stage != "evening":
		_render_discord_history()
		return
	if daily.active() and int(daily.state().day) > 0:
		if daily.state().stage == "evening":
			if int(daily.state().day) == 1 and not GameState.coral_state.actions.has("D1_LOBBY_DONE"):
				_coral_begin_scene("D1_GATE")
			elif not daily.state().chat_seen: daily.begin_scene("evening_chat")
			else: _render_discord_history()
		else: _render_discord_history()
		return
	if GameState.flags.get("d0_chat_done", false):
		_render_discord_history()
	else:
		_show_dialogue("group_chat")

func _render_discord_history(direct := false) -> void:
	desktop_direct = direct
	modal_kind = "discord_history"
	_begin_conversation_presentation()
	var messages: Array = []
	for message in GameState.phone_messages:
		if (message.get("channel", "group") == "mateo") == direct: messages.append(message)
	if direct:
		conversation_ui.show_direct_chat("Mateo", messages, [], Callable(), "", _scaled_text_size(18), "Todavía no hay mensajes privados." if messages.is_empty() else "")
		conversation_ui._button("Escritorio", Rect2(626, 9, 121, 32), _render_desktop, 13)
	else:
		conversation_ui.show_chat("los-chicos", messages, [], Callable(), "", _render_desktop, _scaled_text_size(18), "Todavía no hay mensajes." if messages.is_empty() else "", "Escritorio")
	conversation_ui._button("Los chicos" if direct else "Mateo", Rect2(485, 9, 132, 32), func(): _render_discord_history(not direct), 13)

func _show_class() -> void:
	if daily.active() and not daily.can_play():
		_toast("Revisa Discord después de cenar para preparar la partida")
		return
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
	if modal_kind == "pause":
		modal_before_pause = "dialogue"
		return
	modal_kind = "dialogue"
	var node: Dictionary = dialogue_story.current_node()
	if not preserve_reveal:
		dialogue_visible = 0.0
	var reaction: Dictionary = D0_CHAT_REACTIONS.get(dialogue_choice, {}) if dialogue_key == "group_chat" and node.get("speaker") == "Sofi" else {}
	var message: String = str(reaction.get("text", node.get("text", "")))
	var speaker: String = str(reaction.get("speaker", node.get("speaker", "")))
	dialogue_visible = float(message.length())
	var revealing: bool = false
	var choices: Array = node.get("choices", [])
	var options: Array = []
	if not revealing:
		for i in choices.size():
			var choice_id: String = str(choices[i].choice_id)
			options.append({"label": "%d · %s" % [i + 1, choices[i].text], "action": func(): _request_dialogue_choice(choice_id)})
	var next_action: Callable = _reveal_dialogue if revealing else _advance_dialogue if node.get("next", null) != null else _complete_dialogue
	var next_label: String = "Mostrar" if revealing else "Continuar"
	_begin_conversation_presentation()
	if dialogue_key == "group_chat":
		var messages: Array = []
		for position in GameState.dialogue_history:
			var past: Dictionary = dialogue_story.data.nodes[int(position)]
			if not str(past.get("text", "")).is_empty():
				messages.append({"speaker": past.speaker, "text": past.text})
		if not reaction.is_empty():
			messages.append({"speaker": node.speaker, "text": node.text})
		if not message.is_empty():
			messages.append({"speaker": speaker, "text": message})
		dialogue_text_label = conversation_ui.show_chat("los-chicos", messages, options, next_action, next_label, _render_dialogue_history, _scaled_text_size(16))
		if message.is_empty():
			dialogue_text_label = null
	else:
		var partner: String = "Sofi" if dialogue_key == "courtyard" and speaker != "Sofi" else "Mateo" if dialogue_key == "courtyard" else ""
		dialogue_text_label = conversation_ui.show_scene("bedroom" if dialogue_key == "wakeup" else "courtyard", "Día 0 · " + ("Habitación" if dialogue_key == "wakeup" else "Patio"), speaker, message, options, next_action, next_label, speaker, partner, false, _scaled_text_size(18), "", _render_dialogue_history)
	if is_instance_valid(dialogue_text_label):
		dialogue_visible = float(dialogue_text_label.text.length())
		dialogue_text_label.visible_characters = dialogue_text_label.text.length()

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
		_preview_text(body, "%s\n%s" % [line.get("speaker", ""), ConversationUIScript.dialogue_text(str(line.get("text", "")))], 17)
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
	var step: int = _scene_parts(scene_id, GameState.flags.get("draft_mode", false)).lines.size()
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
		"wakeup":
			GameState.flags.wakeup_seen = true
			if not GameState.flags.get("d0_guide_bedroom_seen", false): GameState.flags.d0_guide_active = "bedroom"
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
	if modal_kind == "pause":
		if finished_key == "group_chat": _show_desktop()
		else: phase_load_after_pause = true
		return
	if finished_key == "group_chat":
		_show_desktop()
	else:
		_close_modal()
		_load_phase()

func _start_moba(hero_class: String) -> void:
	if daily.active() and not daily.can_play(): return
	if save_in_progress:
		return
	save_in_progress = true
	var previous_match: Dictionary = GameState.snapshot()
	GameState.moba_class = hero_class
	GameState.phase = "moba"
	GameState.ui_modal = ""
	if await SaveManager.save_slot_async():
		save_in_progress = false
		get_tree().change_scene_to_file("res://scenes/moba/MOBAArena.tscn")
	else:
		save_in_progress = false
		GameState.restore(previous_match)
		_toast("No se pudo guardar la clase")

func _show_result() -> void:
	modal_kind = "result"
	_begin_conversation_presentation()
	if GameState.flags.get("d1_interlude_active", false):
		conversation_ui.show_scene("computer_lab", "Día 1 · Un nuevo jugador", "Narrador", draft_flow.connector("D1_02_A"), [], _start_coral_story, "Continuar", "Sofi", "", false, _scaled_text_size(18))
		return
	var note: String = "Partida finalizada · " + GameState.moba_result.capitalize()
	var messages: Array = [{"speaker": "Camila", "text": draft_flow.camila_reaction(GameState.moba_result, GameState.moba_class)}]
	conversation_ui.show_chat("los-chicos", messages, [], _show_d1_interlude, "Continuar", Callable(), _scaled_text_size(16), note)

func _show_d1_interlude() -> bool:
	if save_in_progress or GameState.phase != "result":
		return false
	save_in_progress = true
	GameState.flags.d1_interlude_active = true
	if await SaveManager.save_slot_async():
		save_in_progress = false
		_show_result()
		return true
	GameState.flags.erase("d1_interlude_active")
	save_in_progress = false
	_toast("No se pudo guardar el avance; reintenta")
	return false

func _start_coral_story() -> bool:
	if save_in_progress or coral_flow.content.is_empty() or GameState.phase != "result":
		return false
	var previous: Dictionary = GameState.snapshot()
	GameState.phase = "coral"
	GameState.coral_state = coral_flow.new_state()
	GameState.flags.erase("d1_interlude_active")
	GameState.player_position = Vector2(180, 315)
	return await _save_coral(previous)

func _coral_targets() -> Dictionary:
	var targets := {"camila": Vector2(310, 240), "bruno": Vector2(230, 250),
		"sebas": Vector2(420, 250), "mateo": Vector2(525, 235),
		"tutoria": Vector2(165, 310), "salida": Vector2(385, 345)}
	if int(GameState.coral_state.get("day", 1)) == 1: targets.lobby = Vector2(650, 318)
	if int(GameState.coral_state.get("day", 1)) == 4: targets.pc = Vector2(650, 318)
	return targets

func _coral_primary_target() -> String:
	return coral_flow.route_target(GameState.coral_state)

func _save_coral(previous: Dictionary) -> bool:
	if save_in_progress:
		return false
	save_in_progress = true
	if await SaveManager.save_slot_async():
		save_in_progress = false
		if is_inside_tree():
			_load_phase()
		return true
	GameState.restore(previous)
	save_in_progress = false
	_toast("No se pudo guardar el avance; reintenta")
	return false

func _coral_begin_scene(scene_id: String) -> bool:
	if save_in_progress or GameState.phase != "coral": return false
	var previous: Dictionary = GameState.snapshot()
	GameState.coral_state.mode = "scene"
	GameState.coral_state.node = scene_id
	GameState.coral_state.step = 0
	return await _save_coral(previous)

func _coral_interact(target: String) -> void:
	var state: Dictionary = GameState.coral_state
	if state.get("mode") != "explore" or save_in_progress: return
	var day: int = int(state.get("day", 1))
	if target in ["camila", "mateo", "sebas", "bruno"]:
		if coral_flow.talked_today(state, target):
			_toast("Ya conversaste con " + target.capitalize() + " hoy. Puedes acercarte a los demás antes de salir.")
		else: _coral_begin_scene(coral_flow.companion_scene(state, target))
	elif target == "tutoria":
		_coral_begin_scene("I_TUTOR")
	elif target == "lobby" and day == 1:
		if state.get("actions", []).has("D1_LOBBY_DONE"):
			_toast("La partida ya está preparada. Puedes seguir conversando antes de salir.")
		else: _coral_begin_scene("D1_GATE")
	elif target == "pc" and day == 4:
		_coral_begin_scene("I_LIMIT")
	elif target == "salida":
		if not coral_flow.everyone_heard(state):
			_toast("Todavía puedes conversar con los compañeros que faltan")
		elif day == 1 and not state.get("actions", []).has("D1_LOBBY_DONE"):
			_toast("Prepara la partida en el lobby antes de salir")
		elif day == 4: _coral_finish_day()
		else: _coral_next_day()

func _coral_next_day() -> bool:
	if daily.active(): return false
	if save_in_progress or GameState.phase != "coral" or not coral_flow.everyone_heard(GameState.coral_state): return false
	if int(GameState.coral_state.day) >= 4: return false
	if int(GameState.coral_state.day) == 1 and not GameState.coral_state.actions.has("D1_LOBBY_DONE"): return false
	var previous: Dictionary = GameState.snapshot()
	GameState.coral_state.day = int(GameState.coral_state.day) + 1
	GameState.coral_state.mode = "intro"
	GameState.coral_state.node = ""
	GameState.coral_state.step = 0
	GameState.coral_state.chapter_scene_done = false
	GameState.player_position = Vector2(180, 315)
	return await _save_coral(previous)

func _coral_advance() -> bool:
	if save_in_progress or GameState.phase != "coral": return false
	var state: Dictionary = GameState.coral_state
	var previous: Dictionary = GameState.snapshot()
	if state.mode == "intro":
		var narrator_id: String = "D%d_INTRO_%d" % [int(state.day), int(state.step)]
		if not state.seen_narrator.has(narrator_id): state.seen_narrator.append(narrator_id)
		state.step = int(state.step) + 1
		if int(state.step) >= 2:
			state.mode = "explore"
			state.step = 0
		return await _save_coral(previous)
	if state.mode != "scene" and state.mode != "ending": return false
	var scene: Dictionary = coral_flow.scene(str(state.node), preview_catalog, draft_flow, state)
	var lines: Array = scene.get("lines", [])
	if int(state.step) < lines.size() - 1 or (int(state.step) == lines.size() - 1 and not scene.get("choices", []).is_empty()):
		state.step = int(state.step) + 1
		return await _save_coral(previous)
	return await _coral_finish_scene(previous)

func _coral_choose(key: String) -> bool:
	if save_in_progress or GameState.phase != "coral" or GameState.coral_state.get("mode") != "scene": return false
	var state: Dictionary = GameState.coral_state
	var scene_id: String = str(state.node)
	var scene: Dictionary = coral_flow.scene(scene_id, preview_catalog, draft_flow, state)
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
	state.behavior = coral_flow.behavior_profile(state).label
	state.mode = "reaction"
	state.step = 0
	var saved: bool = await _save_coral(previous)
	if saved and not kind.is_empty():
		_toast("Respuesta registrada como: " + str(CoralFlowScript.BEHAVIOR_LABELS[kind]).to_lower())
	return saved

func _coral_finish_scene(previous: Dictionary = {}) -> bool:
	if save_in_progress or GameState.phase != "coral": return false
	var rollback: Dictionary = previous if not previous.is_empty() else GameState.snapshot()
	var state: Dictionary = GameState.coral_state
	var scene_id: String = str(state.node)
	if daily.active() and scene_id in ["D1_GATE", "D1_B_FOLLOW"]:
		for line in coral_flow.scene(scene_id, preview_catalog, draft_flow, state).get("lines", []):
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
		state.chapter_scene_done = int(state.day) == 4 and coral_flow.everyone_heard(state)
	elif scene_id.begins_with("F0"):
		state.mode = "summary"
	return await _save_coral(rollback)

func _coral_finish_day() -> bool:
	if daily.active(): return false
	if save_in_progress or GameState.phase != "coral" or int(GameState.coral_state.get("day", 0)) != 4 or not GameState.coral_state.get("chapter_scene_done", false): return false
	var previous: Dictionary = GameState.snapshot()
	var state: Dictionary = GameState.coral_state
	state.ending = coral_flow.ending_for(state)
	state.node = str(state.ending)
	state.step = 0
	state.mode = "ending"
	return await _save_coral(previous)

func _render_coral() -> void:
	var state: Dictionary = GameState.coral_state
	var mode: String = str(state.get("mode", "explore"))
	if mode == "explore":
		_close_modal()
		return
	if mode == "summary":
		_render_coral_summary()
		return
	modal_kind = "coral"
	_begin_conversation_presentation()
	if mode == "intro":
		var intro: Array = coral_flow.content.get("day_intros", {}).get(str(state.day), [])
		if int(state.step) >= intro.size(): return
		conversation_ui.show_scene(_conversation_background(), "Día %d" % state.day, "Narrador", str(intro[int(state.step)]), [], _coral_advance, "Continuar", "Sofi", "", false, _scaled_text_size(18))
		return
	var scene_id: String = str(state.get("node", ""))
	var scene: Dictionary = coral_flow.scene(scene_id, preview_catalog, draft_flow, state)
	var lines: Array = scene.get("lines", [])
	var selected: String = str(state.get("choices", {}).get(scene_id, ""))
	var current: Dictionary = {}
	var options: Array = []
	var next_action: Callable = _coral_advance
	if mode == "reaction":
		current = coral_flow.content.get("reactions", {}).get(scene_id, {}).get(selected, {})
		next_action = _coral_finish_scene
	elif int(state.step) < lines.size():
		current = lines[int(state.step)]
	elif not scene.get("choices", []).is_empty():
		for choice in scene.choices:
			var key: String = str(choice.get("key", ""))
			options.append({"label": str(choice.get("text", "")), "action": func(): _coral_choose(key)})
		options.append({"label": "¿No sabes qué responder? Pide un consejo al tutor (no elige por ti)", "action": func(): _show_tutor_advice(scene_id)})
	else:
		return
	var presentation: String = str(scene.get("presentation", "vn"))
	if presentation in ["group", "dm"] and str(current.get("speaker", "")) == "Narrador" and options.is_empty():
		conversation_ui.show_scene(_conversation_background(), "Día %d · %s" % [int(scene.get("day", state.day)), str(scene.get("title", "Historia"))], "Narrador", str(current.get("text", "")), [], next_action, "Continuar", "Sofi", "", false, _scaled_text_size(18))
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
			conversation_ui.show_chat("lobby-de-juego", messages, options, next_action, "Continuar", Callable(), _scaled_text_size(15), system_note)
		else:
			conversation_ui.show_direct_chat("Mateo", messages, options, next_action, "Continuar", _scaled_text_size(15), system_note)
		return
	var speaker: String = str(current.get("speaker", "Narrador"))
	var actor: String = str(scene.get("actor", ""))
	if actor.is_empty() and scene_id.begins_with("I_D1_"): actor = scene_id.trim_prefix("I_D1_").capitalize()
	var sprite: String = _scene_sprite_key(speaker, scene_id, selected)
	if "(mensaje)" in speaker and not actor.is_empty(): sprite = _scene_sprite_key(actor, scene_id, selected)
	if not ConversationUIScript.SPRITES.has(sprite): sprite = speaker if ConversationUIScript.SPRITES.has(speaker) else actor
	var partner: String = "Sofi" if speaker != "Sofi" and actor != "Sofi" else actor
	if speaker == "Narrador": sprite = "Sofi"
	var background: String = _conversation_background()
	conversation_ui.show_scene(background, "Día %d · %s" % [int(scene.get("day", state.day)), str(scene.get("title", "Historia"))], speaker, str(current.get("text", "")), options, next_action, "Continuar", sprite, partner, "(mensaje)" in speaker, _scaled_text_size(18))

func _render_coral_summary() -> void:
	modal_kind = "coral"
	_clear_modal()
	_modal_heading("HISTORIA CONCLUIDA", "result")
	var body := _preview_content()
	var ending: String = str(GameState.coral_state.get("ending", "F03"))
	var description: String = {"F01": "Se inició una conversación de apoyo con una persona adulta.", "F02": "Se ajustó la privacidad o el contacto con permiso.", "F03": "Hay pasos de protección pendientes; aún se puede pedir ayuda."}.get(ending, "")
	_preview_text(body, description, 20)
	_preview_text(body, "Sofi pudo escuchar a todo el grupo. Sus respuestas cambiaron la confianza de cada compañero y las acciones que concretaron juntos.", 16)
	var profile: Dictionary = coral_flow.behavior_profile(GameState.coral_state)
	_preview_text(body, "Clasificación del comportamiento: %s (%d protectoras, %d con límite, %d de riesgo)" % [profile.label, profile.counts.protectora, profile.counts.limite, profile.counts.riesgo], 17)
	for detail in profile.details:
		_preview_text(body, "· %s: %s" % [detail.name, detail.label], 14)
	if int(profile.unrepaired_recess) >= 2 and ending == "F03" and GameState.coral_state.get("limit_completed", false):
		_preview_text(body, "Las respuestas del recreo sin reparar impidieron que el límite acordado sostuviera al grupo.", 15)
	_preview_button(body, "Volver al menú", _return_to_menu)

func _show_tutor_advice(scene_id: String) -> void:
	var state: Dictionary = GameState.coral_state
	var action_id: String = "ADVICE_" + scene_id
	if not state.get("actions", []).has(action_id) and state.get("actions", []).size() < 100: state.actions.append(action_id)
	conversation_ui.show_advice("Tutor", coral_flow.decision_advice(scene_id))

func _start_playable_draft() -> bool:
	if save_in_progress or draft_flow.content.is_empty() or preview_catalog.scenes.is_empty():
		return false
	var previous := GameState.snapshot()
	GameState.flags.draft_mode = true
	GameState.flags.draft_completed = false
	GameState.flags.draft_ending = ""
	GameState.flags.erase("d1_interlude_active")
	GameState.preview_choices.clear()
	if await _commit_preview("D1_02_A", 0, "", false, true):
		return true
	GameState.restore(previous)
	return false

func _render_day_intro() -> void:
	var scene_id: String = GameState.preview_scene
	var introduction: Array = draft_flow.day_introduction(scene_id)
	var step: int = int(GameState.flags.get("draft_intro_step", 0))
	if step < 0 or step >= introduction.size():
		push_error("Presentación diaria inválida: " + scene_id)
		return
	modal_kind = "day_intro"
	_begin_conversation_presentation()
	var scene: Dictionary = preview_catalog.get_scene(scene_id)
	var title: String = "Día %d · %s" % [int(scene.get("day", 1)), _scene_title(scene)]
	var background: String = _conversation_background()
	conversation_ui.show_scene(background, title, "Narrador", str(introduction[step]), [], _advance_day_intro,
		"Continuar", "Sofi", "", false, _scaled_text_size(18))

func _advance_day_intro() -> bool:
	if save_in_progress or GameState.phase != "preview" or not GameState.flags.get("draft_mode", false) or not GameState.flags.get("draft_exploring", false) or not GameState.flags.has("draft_intro_step"):
		return false
	var previous: Dictionary = GameState.snapshot()
	var next_step: int = int(GameState.flags.draft_intro_step) + 1
	if next_step < draft_flow.day_introduction(GameState.preview_scene).size():
		GameState.flags.draft_intro_step = next_step
	else:
		GameState.flags.erase("draft_intro_step")
	save_in_progress = true
	if await SaveManager.save_slot_async():
		save_in_progress = false
		_load_phase()
		return true
	GameState.restore(previous)
	save_in_progress = false
	_toast("No se pudo guardar la presentación del día")
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
			GameState.flags.draft_intro_step = 0
		else:
			GameState.flags.erase("draft_intro_step")
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
		style.border_color = Color("d5a4ca")
		style.set_border_width_all(1)
		style.set_content_margin_all(10)
		card.add_theme_stylebox_override("panel", style)
		parent.add_child(card)
		var message_box := VBoxContainer.new()
		card.add_child(message_box)
		_preview_text(message_box, "CHAT MOSTRADO POR MATEO" if GameState.preview_scene == "D2_03_A" else "MENSAJE RECUPERADO", 13, 515)
		_preview_text(message_box, speaker, 16, 515)
		_preview_text(message_box, "«" + ConversationUIScript.dialogue_text(str(line.get("text", ""))) + "»", 18, 515)
	else:
		_preview_text(parent, speaker, 18)
		_preview_text(parent, "«" + ConversationUIScript.dialogue_text(str(line.get("text", ""))) + "»", 19)

func _scene_title(scene: Dictionary) -> String:
	var title: String = str(scene.get("title", "Historia"))
	if title.begins_with("F0") and " · " in title:
		return title.get_slice(" · ", 1).capitalize()
	return title

func _scene_portrait_path(speaker: String, scene_id: String, choice: String = "") -> String:
	if speaker == "Kairo":
		return "res://assets/vn/kairo_v4.png"
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

func _scene_sprite_key(speaker: String, scene_id: String, choice: String = "") -> String:
	if speaker == "Mateo" and scene_id in ["D4_B1", "D4_B2", "D4_A1", "D4_A2"]: return "Mateo_alarmed"
	if speaker == "Mateo" and scene_id in ["D2_B", "D3_B1", "D3_B2"]: return "Mateo_worried"
	if speaker == "Sofi" and (scene_id.begins_with("D3_") or scene_id.begins_with("D4_")): return "Sofi_concerned"
	if speaker == "Sofi" and scene_id in ["D3_01_A", "D4_01_A", "D4_02_A", "D4_03_A", "F03"]:
		return "Sofi_concerned"
	if speaker == "Mateo":
		if choice == "A" and scene_id in ["D3_01_A", "D4_01_A", "D4_02_A", "D4_03_A"]:
			return "Mateo"
		if scene_id in ["D4_01_A", "F03"]:
			return "Mateo_alarmed"
		if scene_id in ["D2_03_A", "D2_04_A", "D3_01_A", "D4_02_A", "D4_03_A", "F02"]:
			return "Mateo_worried"
	return speaker

func _scene_parts(scene_id: String, draft_mode: bool) -> Dictionary:
	var scene: Dictionary = preview_catalog.get_scene(scene_id)
	var lines: Array = scene.get("lines", []).duplicate(true)
	var after_choice: Array = scene.get("after_choice", []).duplicate(true)
	var later_chat: Array = scene.get("later_chat", []).duplicate(true)
	if draft_mode:
		if scene_id == "D3_01_A":
			var opening: Dictionary = draft_flow.d3_opening(GameState.preview_choices)
			if not opening.is_empty():
				lines.insert(2, opening)
		elif scene_id == "F03":
			later_chat.append_array(draft_flow.ending_tail(scene_id))
		elif DraftFlowScript.ENDING_IDS.has(scene_id):
			lines.append_array(draft_flow.ending_tail(scene_id))
		after_choice.append_array(draft_flow.extra_after_choice(scene_id))
	return {"lines": lines, "after_choice": after_choice, "later_chat": later_chat, "choices": scene.get("choices", [])}

func _preview_next_action(scene_id: String) -> Callable:
	if GameState.flags.get("draft_mode", false):
		var next_id: String = draft_flow.next_main(scene_id)
		if scene_id == "D4_03_A":
			next_id = draft_flow.ending_for(str(GameState.preview_choices.get(scene_id, "")), GameState.preview_choices)
		elif scene_id == "F01_A":
			next_id = "F01_B"
		if not next_id.is_empty():
			var next_explore: bool = DraftFlowScript.EXPLORATION_IDS.has(next_id) and scene_id not in ["D4_01_A", "D4_02_A"]
			return func(): _commit_preview(next_id, 0, "", false, next_explore)
		return _finish_draft
	var independent_next: String = preview_catalog.next_main(scene_id) if PreviewCatalogScript.MAIN_ORDER.has(scene_id) else ""
	if not independent_next.is_empty():
		return func(): _commit_preview(independent_next, 0)
	if PreviewCatalogScript.MAIN_ORDER.has(scene_id):
		return func(): _commit_preview("ENDINGS_INDEX", 0)
	return _finish_preview

func _render_preview_story(scene_id: String, draft_mode: bool) -> void:
	var scene: Dictionary = preview_catalog.get_scene(scene_id)
	if scene.is_empty():
		_modal_heading("ESCENA", "dialogue")
		_modal_text("Esta escena no está disponible.")
		return
	var step: int = GameState.preview_step
	var parts: Dictionary = _scene_parts(scene_id, draft_mode)
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
		next_action = func(): _commit_preview(scene_id, step + 1)
	elif not choices.is_empty():
		if step == lines.size():
			for i in choices.size():
				var key: String = str(choices[i].key)
				options.append({"label": "%d · %s" % [i + 1, choices[i].text], "action": func(): _request_preview_choice(scene_id, key)})
		elif draft_mode and step == lines.size() + 1:
			current = {"speaker": "Mateo", "text": draft_flow.choice_reaction(scene_id, selected)}
			next_action = func(): _commit_preview(scene_id, step + 2)
		elif step == lines.size() + (2 if draft_mode else 1):
			current = {"speaker": "Mateo", "text": draft_flow.choice_reaction(scene_id, selected)}
			next_action = func(): _commit_preview(scene_id, step + 1)
		elif step < lines.size() + 2 + after_choice.size() + (1 if draft_mode else 0):
			current = after_choice[step - lines.size() - 2 - (1 if draft_mode else 0)]
			next_action = func(): _commit_preview(scene_id, step + 1)
	elif not later_chat.is_empty():
		if step == lines.size():
			current = {"speaker": "Narrador", "text": "Mateo recibe nuevos mensajes."}
		else:
			var later_index: int = step - lines.size() - 1
			if later_index < later_chat.size():
				current = later_chat[later_index]
		if not current.is_empty():
			next_action = func(): _commit_preview(scene_id, step + 1)
	var terminal_step: int = _draft_terminal_step(scene_id) if draft_mode else preview_catalog.terminal_step(scene_id)
	if not current.is_empty() and options.is_empty() and step == terminal_step - 1:
		next_action = _preview_next_action(scene_id)
	if current.is_empty() and options.is_empty():
		terminal = true
		current = {"speaker": "Narrador", "text": "La conversación continúa."}
		next_action = _preview_next_action(scene_id)
		next_label = "Continuar"
	var additional: Callable = _render_unplaced_preview if terminal and not draft_mode and scene.has("unplaced_lines") else Callable()
	var day_label: String = "Final" if scene.get("day") == null else "Día " + str(int(scene.day))
	var title: String = day_label + " · " + _scene_title(scene)
	var note: String = draft_flow.connector(scene_id) if draft_mode and step == 0 and scene_id != "D1_02_A" else ""
	if draft_mode and step == 0 and scene_id == "F01_A":
		note = draft_flow.f01_context(str(GameState.preview_choices.get("D4_03_A", "")))
	_begin_conversation_presentation()
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
		conversation_ui.show_chat("lobby-de-juego", messages, options, next_action, next_label, additional, _scaled_text_size(16), note, "Escena adicional")
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
		conversation_ui.show_direct_chat("Mateo", messages, options, next_action, next_label,
			_scaled_text_size(16), note)
		return
	var raw_speaker: String = str(current.get("speaker", "Sofi"))
	var speaker: String = raw_speaker.get_slice(" (", 0)
	var is_message: bool = "(mensaje" in raw_speaker
	var active: String = _scene_sprite_key(speaker, scene_id, selected)
	var partner: String = "Sofi_concerned" if scene_id.begins_with("D4") or scene_id.begins_with("D3") else "Sofi"
	if speaker == "Sofi":
		partner = _scene_sprite_key("Mateo", scene_id)
	elif speaker == "Kairo" and is_message:
		active = _scene_sprite_key("Mateo", scene_id)
	if speaker not in ["Sofi", "Mateo", "Kairo", "Camila", "Bruno", "Sebas"]:
		active = ""
		partner = ""
	var background: String = _conversation_background()
	conversation_ui.show_scene(background, title, raw_speaker, str(current.get("text", "")), options, next_action, next_label, active, partner, is_message, _scaled_text_size(18), note, additional, "Escena adicional")

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
	_render_preview_story(scene_id, draft_mode)

func _render_draft_summary(body: VBoxContainer) -> void:
	_preview_text(body, "FIN DE LA HISTORIA", 21)
	var ending_name: String = {"F01": "Buscar apoyo", "F02": "Poner un límite", "F03": "Una decisión pendiente"}.get(str(GameState.flags.get("draft_ending", "")), "La historia continúa")
	_preview_text(body, ending_name, 19)
	_preview_text(body, "Sofi y Mateo llegaron hasta aquí juntos. Puedes volver a recorrer sus decisiones.", 15)
	_preview_text(body, "Resultado de la partida: " + GameState.moba_result + " · clase: " + GameState.moba_class, 15)
	for scene_id in DraftFlowScript.MAIN_IDS:
		var selected: String = str(GameState.preview_choices.get(scene_id, ""))
		if not selected.is_empty():
			var selected_scene: Dictionary = preview_catalog.get_scene(scene_id)
			_preview_text(body, "Día %d · %s: opción %s" % [int(selected_scene.get("day", 0)), _scene_title(selected_scene), selected], 15)
	_preview_button(body, "Volver a vivir los Días 1–4", _start_playable_draft)
	_preview_button(body, "Volver al menú", _return_to_menu)

func _draft_terminal_step(scene_id: String) -> int:
	var parts: Dictionary = _scene_parts(scene_id, true)
	if not parts.choices.is_empty():
		return parts.lines.size() + 3 + parts.after_choice.size()
	if not parts.later_chat.is_empty():
		return parts.lines.size() + 1 + parts.later_chat.size()
	return parts.lines.size()

func _finish_draft() -> bool:
	if not GameState.flags.get("draft_mode", false) or GameState.preview_scene not in ["F01_B", "F02", "F03"] or GameState.preview_step < _draft_terminal_step(GameState.preview_scene) - 1:
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
	if GameState.preview_step < preview_catalog.terminal_step(GameState.preview_scene) - 1:
		return false
	return await _commit_preview("ENDINGS_INDEX", 1, "", true)

func _render_unplaced_preview() -> void:
	modal_kind = "preview_unplaced"
	_clear_modal()
	_modal_heading("ESCENA ADICIONAL", "history", 17)
	var body := _preview_content()
	var scene: Dictionary = preview_catalog.get_scene(GameState.preview_scene)
	for line in scene.get("unplaced_lines", []):
		_preview_line(body, line)
	_preview_button(body, "Volver a la escena", _render_preview)

func _conversation_background() -> String:
	if daily.active():
		var place: String = str(daily.state().place)
		if daily.is_evening() and place in ["bedroom", "living", "street", "school"]:
			return {"bedroom": "bedroom_night", "living": "living_night", "street": "street_sunset", "school": "courtyard_sunset"}[place]
		return {"bedroom": "bedroom", "living": "living", "street": "street", "school": "courtyard", "classroom": "classroom", "computer": "computer_lab", "tutor": "tutor_office"}.get(place, "courtyard")
	return ConversationUIScript.background_for_world(str(world.scene_key))
