extends Node

const UI = preload("res://scripts/ConversationUI.gd")
var failures := 0
var choices := 0

func check(condition: bool, description: String) -> void:
	if condition: print("PASS ", description)
	else:
		failures += 1
		printerr("FAIL ", description)

func _ready() -> void:
	_run.call_deferred()

func click(ui: Control, point: Vector2, double := false) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.double_click = double
	event.position = ui.get_global_transform_with_canvas() * point
	ui._input(event)

func _run() -> void:
	SaveManager.storage_prefix = "user://centinela_CHAT_%d_" % Time.get_ticks_usec()
	var main: Node = preload("res://scenes/Main.tscn").instantiate()
	get_tree().root.add_child(main)
	GameState.new_game(1)
	SaveManager.save_slot()
	main.menu.start_slot(1)
	var ui: Control = main.conversation_ui
	ui.auto_remaining = 13.25
	ui.auto_duration = 31.0
	main.pause_menu.show_pause()
	ui._process(100.0)
	main.pause_menu.render_pause()
	main.pause_menu.resume_pause()
	check(is_equal_approx(ui.auto_remaining, 13.25) and is_equal_approx(ui.auto_duration, 31.0), "pausa conserva segundos y duración de la introducción")
	ui._process(0.4)
	var remaining: float = ui.auto_remaining
	main._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	await main.pause_menu.cycle_text_size()
	main.pause_menu.resume_pause()
	check(is_equal_approx(ui.auto_remaining, remaining), "Alt Tab y cambio de tamaño no reinician el contador")
	click(ui, Vector2(200, 200))
	for frame in range(30):
		await get_tree().process_frame
		if main.modal_kind == "dialogue" and not main.save_in_progress: break
	check(GameState.flags.get("prologue_seen", false) and GameState.dialogue_key == "wakeup", "clic en la introducción avanza y guarda")
	var position: int = GameState.dialogue_position
	click(ui, Vector2(10, 190))
	check(GameState.dialogue_position == position, "clic fuera del recuadro no avanza")
	click(ui, Vector2(240, 320))
	for frame in range(30):
		await get_tree().process_frame
		if not main.save_in_progress: break
	check(GameState.dialogue_position == position + 1, "clic sobre el parlamento avanza una línea")
	click(ui, Vector2(240, 320), true)
	check(GameState.dialogue_position == position + 1, "doble clic no salta otra línea ni elige una respuesta")
	remaining = ui.auto_remaining - 0.2
	ui.auto_remaining = remaining
	main.pause_menu.show_pause()
	main.pause_menu.resume_pause()
	check(is_equal_approx(ui.auto_remaining, remaining), "parlamento D0 conserva su tiempo al pausar")
	check(not ui.can_click_advance(Vector2(680, 25)), "botón de historial no adelanta el diálogo")
	check(UI.dialogue_text("Sí; te escucho: tú decides.") == "Sí. Te escucho. Tú decides.", "puntuación hablada sin dos puntos ni punto y coma")
	var long_text: String = "Quería contarte algo; no sabía cómo: ahora sí. ".repeat(20)
	var messages: Array = [{"speaker": "Sofi", "text": "Hola."}, {"speaker": "Mateo", "text": long_text}]
	for direct in [false, true]:
		if direct: ui.show_direct_chat("Mateo", messages, [], Callable(), "", 24)
		else: ui.show_chat("los-chicos", messages, [], Callable(), "", Callable(), 24)
		for frame in range(3): await get_tree().process_frame
		var avatars: Array[Node] = ui.find_children("MessageAvatar", "PanelContainer", true, false)
		var square := avatars.size() == 2
		for avatar in avatars:
			square = square and is_equal_approx(avatar.size.x, 46.0) and is_equal_approx(avatar.size.y, 46.0)
		check(square, "avatar 46×46 con texto grande y largo: " + ("privado" if direct else "grupo"))
		var scroll: ScrollContainer = ui.get_node("ReadingScroll")
		scroll.scroll_vertical = 80
		var state: Dictionary = ui.capture_reading_state()
		if direct: ui.show_direct_chat("Mateo", messages, [], Callable(), "", 24)
		else: ui.show_chat("los-chicos", messages, [], Callable(), "", Callable(), 24)
		check(ui.restore_reading_state(state), "relectura conserva identidad de chat")
		for frame in range(3): await get_tree().process_frame
		check(ui.get_node("ReadingScroll").scroll_vertical == int(state.ReadingScroll), "desplazamiento de chat se recupera")
	ui.show_scene("courtyard", "", "Sofi", "", [{"label": "Te escucho; tú decides.", "action": func(): choices += 1}], main.day0.advance_dialogue, "", "Sofi", "Mateo", false, 18)
	click(ui, Vector2(240, 320))
	check(choices == 0 and not ui.auto_action.is_valid(), "clic general no selecciona una decisión")
	var button: Button = ui.find_children("*", "Button", true, false)[0]
	check(button.text == "Te escucho. Tú decides.", "opción visible conserva sentido con puntuación revisada")
	button.pressed.emit()
	check(choices == 1, "las opciones siguen respondiendo a su botón")
	GameState.new_game(1)
	GameState.phase = "coral"
	GameState.coral_state = main.coral_flow.new_state()
	GameState.coral_state.mode = "explore"
	main.modal_kind = ""
	main.router.load_phase()
	await main.coral.begin_scene("I_D1_CAMILA")
	check(ui.find_child("VNBackground", true, false).texture.resource_path == "res://assets/vn/computer_lab.png", "Día 1 presenta conversaciones dentro de la sala de cómputo")
	remaining = ui.auto_remaining - 0.3
	ui.auto_remaining = remaining
	main.pause_menu.show_pause()
	main.pause_menu.resume_pause()
	check(is_equal_approx(ui.auto_remaining, remaining), "conversación D1 conserva su contador")
	main.pause_menu.show_pause()
	main.save_in_progress = true
	main.pause_menu.resume_pause()
	check(main.modal_kind == "pause", "la pausa espera si hay un guardado en curso")
	main.save_in_progress = false
	GameState.coral_state.step = 1
	main.router.load_phase()
	check(main.modal_kind == "pause" and main.phase_load_after_pause, "un avance confirmado no cierra la pausa")
	main.pause_menu.resume_pause()
	check(main.modal_kind == "coral" and ui.auto_remaining == ui.auto_duration, "al retomar, la nueva línea recibe su propio tiempo")
	var old_state: Dictionary = ui.capture_reading_state()
	ui.show_scene("courtyard", "Otra escena", "Sofi", "Un texto distinto.", [], main.coral.advance, "", "Sofi", "", false, 18)
	check(not ui.restore_reading_state(old_state), "un contador anterior no se aplica a otra escena")
	SaveManager.delete_slot(1)
	SaveManager.storage_prefix = SaveManager.SAVE_PREFIX
	get_tree().quit(1 if failures else 0)
