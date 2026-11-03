extends Node2D

const WorldScript = preload("res://scripts/World.gd")
const NarrativeScript = preload("res://scripts/narrative/NarrativeManager.gd")
const PreviewCatalogScript = preload("res://scripts/narrative/RecoveredPreviewCatalog.gd")
const DraftFlowScript = preload("res://scripts/narrative/PlayableDraftFlow.gd")
const CoralFlowScript = preload("res://scripts/narrative/CoralStoryFlow.gd")
const PreviewFlowScript = preload("res://scripts/legacy/PreviewFlow.gd")
const CoralControllerScript = preload("res://scripts/story/CoralController.gd")
const UiKitScript = preload("res://scripts/ui/UiKit.gd")
const MainMenuScript = preload("res://scripts/ui/MainMenu.gd")
const HudScript = preload("res://scripts/ui/Hud.gd")
const InventoryScript = preload("res://scripts/game/Inventory.gd")
const Day0FlowScript = preload("res://scripts/story/Day0Flow.gd")
const ComputerScreensScript = preload("res://scripts/ui/ComputerScreens.gd")
const PhaseRouterScript = preload("res://scripts/game/PhaseRouter.gd")
const PauseMenuScript = preload("res://scripts/ui/PauseMenu.gd")
const PhoneModalScript = preload("res://scripts/ui/PhoneModal.gd")
const ObjectiveModalScript = preload("res://scripts/ui/ObjectiveModal.gd")
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
var legacy: RefCounted  # Vista previa y borrador heredados (scripts/legacy/PreviewFlow.gd)
var pause_menu: RefCounted  # scripts/ui/PauseMenu.gd
var phone_modal: RefCounted  # scripts/ui/PhoneModal.gd
var objective_modal: RefCounted  # scripts/ui/ObjectiveModal.gd
var coral: RefCounted  # scripts/story/CoralController.gd
var ui_kit: RefCounted  # scripts/ui/UiKit.gd
var menu: RefCounted  # scripts/ui/MainMenu.gd
var hud_view: RefCounted  # scripts/ui/Hud.gd
var inventory: RefCounted  # scripts/game/Inventory.gd
var day0: RefCounted  # scripts/story/Day0Flow.gd
var computer: RefCounted  # scripts/ui/ComputerScreens.gd
var router: RefCounted  # scripts/game/PhaseRouter.gd
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
	ui_kit = UiKitScript.new()
	ui_kit.main = self
	menu = MainMenuScript.new()
	menu.main = self
	hud_view = HudScript.new()
	hud_view.main = self
	inventory = InventoryScript.new()
	inventory.main = self
	day0 = Day0FlowScript.new()
	day0.main = self
	computer = ComputerScreensScript.new()
	computer.main = self
	router = PhaseRouterScript.new()
	router.main = self
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
	legacy = PreviewFlowScript.new()
	legacy.main = self
	coral = CoralControllerScript.new()
	coral.main = self
	pause_menu = PauseMenuScript.new()
	pause_menu.main = self
	phone_modal = PhoneModalScript.new()
	phone_modal.main = self
	objective_modal = ObjectiveModalScript.new()
	objective_modal.main = self
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
	hud_icon = ui_kit.make_screen_icon("objective", Vector2(5, 12), 22)
	hud = ui_kit.make_label(Vector2(30, 10), Vector2(718, 42), 16)
	hud_view.build_inventory_panel()
	prompt_icon = ui_kit.make_screen_icon("interact", Vector2(5, 402), 24)
	prompt = ui_kit.make_label(Vector2(30, 402), Vector2(718, 34), 17)
	toast = ui_kit.make_label(Vector2(140, 354), Vector2(488, 40), 15)
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	modal = PanelContainer.new()
	modal.position = Vector2(126, 66)
	modal.custom_minimum_size = Vector2(516, 310)
	modal.size = Vector2(516, 310)
	modal.add_theme_stylebox_override("panel", ui_kit.panel_style())
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
	menu.show()
	var return_to_result: bool = GameState.returning_from_moba
	GameState.returning_from_moba = false
	if not GameState.code.is_empty():
		AudioManager.apply_preferences()
		AudioManager.enter_context("explore")
	_check_window_size()
	if return_to_result and GameState.phase == "result":
		menu.start_slot(GameState.slot)

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
			pause_menu.resume_pause()
		else:
			pause_menu.show_pause()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		if ["phone", "objective", "pause", "class", "desktop", "discord_history", "slot_confirm", "dialogue_history", "observation"].has(modal_kind):
			if modal_kind == "pause":
				pause_menu.resume_pause()
			elif modal_kind == "slot_confirm":
				menu.show()
			elif modal_kind == "dialogue_history":
				day0.render_dialogue(true)
			elif modal_kind == "discord_history": computer.render_desktop()
			else:
				ui_kit.close_modal()
			get_viewport().set_input_as_handled()
	elif modal_kind == "phone" and event.is_action_pressed("phone"):
		ui_kit.close_modal()
		get_viewport().set_input_as_handled()
	elif modal_kind == "coral" and event is InputEventKey and event.pressed and not event.echo:
		if GameState.coral_state.get("mode") == "scene" and event.keycode in [KEY_1, KEY_2, KEY_3]:
			var coral_scene: Dictionary = coral_flow.scene(str(GameState.coral_state.node), preview_catalog, draft_flow, GameState.coral_state)
			var coral_index: int = [KEY_1, KEY_2, KEY_3].find(event.keycode)
			if int(GameState.coral_state.step) == coral_scene.get("lines", []).size() and coral_index < coral_scene.get("choices", []).size():
				coral.choose(str(coral_scene.choices[coral_index].key))
				get_viewport().set_input_as_handled()
	elif modal_kind == "preview" and event is InputEventKey and event.pressed and not event.echo:
		var preview_scene: Dictionary = preview_catalog.get_scene(GameState.preview_scene)
		var preview_choices: Array = preview_scene.get("choices", [])
		if GameState.preview_step == legacy.scene_parts(GameState.preview_scene, GameState.flags.get("draft_mode", false)).lines.size() and not preview_choices.is_empty():
			var preview_index := -1
			match event.keycode:
				KEY_1: preview_index = 0
				KEY_2: preview_index = 1
				KEY_3: preview_index = 2
			if preview_index >= 0 and preview_index < preview_choices.size():
				legacy.request_preview_choice(GameState.preview_scene, str(preview_choices[preview_index].key))
				get_viewport().set_input_as_handled()
	elif modal_kind == "dialogue" and event is InputEventKey and event.pressed and not event.echo:
		if is_instance_valid(dialogue_text_label) and dialogue_visible < dialogue_text_label.text.length() and event.keycode in [KEY_1, KEY_2, KEY_3, KEY_ENTER, KEY_KP_ENTER]:
			day0.reveal_dialogue()
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
						day0.advance_dialogue()
					else:
						day0.complete_dialogue()
		var choices: Array = dialogue_story.current_node().get("choices", [])
		if choice_index >= 0 and choice_index < choices.size():
			day0.request_dialogue_choice(str(choices[choice_index].choice_id))
			get_viewport().set_input_as_handled()
	elif modal_kind == "":
		if event.is_action_pressed("interact"):
			world.interact()
		elif event.is_action_pressed("phone"):
			phone_modal.show_phone()
		elif event.is_action_pressed("objective"):
			objective_modal.show_objective()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(modal):
		if modal_kind != "menu" and modal_kind != "pause":
			pause_menu.show_pause()

func _check_window_size() -> void:
	window_too_small = DisplayGuardScript.too_small(DisplayGuardScript.window_size())
	window_guard_layer.visible = window_too_small
	if window_too_small and modal_kind not in ["menu", "pause"]:
		pause_menu.show_pause()

func _on_interacted(target: String) -> void:
	if daily.active():
		if target != "backpack": AudioManager.play_effect("interact")
		daily.interact(target)
		return
	match GameState.phase:
		"coral":
			coral.interact(target)
		"preview":
			if GameState.flags.get("draft_exploring", false) and target == "mateo":
				legacy.commit_preview(GameState.preview_scene, 0)
		"bedroom":
			if target == "backpack":
				inventory.pick_up("mochila", "backpack", "Mochila guardada en el inventario")
			elif target == "alarm":
				day0.commit_flag(target, "Interacción registrada: " + world.target_label(target))
			elif target == "door":
				if not GameState.flags.get("alarm", false) or not GameState.flags.get("backpack", false):
					_toast("Completa la alarma y la mochila primero")
				else:
					day0.transition("courtyard", Vector2(140, 300))
			else:
				if target in ["photo", "desk"]: day0.inspect(target)
		"courtyard":
			if target == "friends":
				if not GameState.flags.get("friends", false): day0.show_dialogue("courtyard")
			elif target == "exit":
				if GameState.flags.get("friends", false):
					day0.transition("computer", Vector2(384, 320))
				else:
					_toast("Primero acércate al grupo")
			elif target == "tutoria":
				day0.inspect("tutoria")
		"computer":
			if target == "pc":
				computer.show_desktop()

func _on_departure_finished() -> void:
	GameState.flags.d0_departure_seen = true
	_autosave()

func _autosave() -> void:
	if not await SaveManager.save_slot_async() and is_inside_tree():
		_toast("No se pudo guardar la posición")

func _manual_save() -> void:
	_toast("Guardado" if await SaveManager.save_slot_async() else "Error de guardado")

func _on_lock_lost() -> void:
	SyncManager.on_slot_closed()
	menu.show()
	_toast("Esta partida está abierta en otra pestaña")

func _toast(message: String) -> void:
	toast.text = message
	toast_time = 3.5

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

func _return_to_menu() -> void:
	SyncManager.on_slot_closed()
	await SaveManager.release_slot_async()
	if is_inside_tree():
		menu.show()
