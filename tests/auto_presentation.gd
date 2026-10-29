extends Node

var failures := 0

func check(condition: bool, title: String) -> void:
	if condition: print("PASS ", title)
	else:
		failures += 1
		printerr("FAIL ", title)

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	SaveManager.storage_prefix = "user://centinela_AUTO_%d_" % Time.get_ticks_usec()
	var main: Node = preload("res://scenes/Main.tscn").instantiate()
	get_tree().root.add_child(main)
	GameState.new_game(1)
	SaveManager.save_slot()
	main._start_slot(1)
	var ui: Control = main.conversation_ui
	check(ui.find_child("PrologueText", true, false).text == "\n\n".join(main.PROLOGUE_LINES), "introducción completa en una pantalla")
	check(ui.find_children("*", "Button", true, false).is_empty(), "introducción sin botón continuar")
	check(ui.find_children("Sprite_*", "TextureRect", true, false).size() == 5, "caras de Sofi y sus cuatro amigos")
	ui.auto_remaining = 0.01
	ui._process(0.02)
	for frame in range(60):
		await get_tree().process_frame
		if main.modal_kind == "dialogue" and not main.save_in_progress: break
	check(GameState.flags.get("prologue_seen", false) and GameState.dialogue_key == "wakeup", "introducción avanza y guarda sin interacción")
	check(main.dialogue_text_label.visible_characters == main.dialogue_text_label.text.length(), "parlamento visible completo")
	var before: int = GameState.dialogue_position
	main._show_pause()
	ui._process(100.0)
	check(GameState.dialogue_position == before and not ui.auto_action.is_valid(), "pausa detiene avance automático")
	main._resume_pause()
	ui.auto_remaining = 0.01
	ui._process(0.02)
	for frame in range(60):
		await get_tree().process_frame
		if GameState.dialogue_position != before and not main.save_in_progress: break
	check(GameState.dialogue_position > before, "diálogo avanza solo al retomar")
	ui.show_scene("courtyard", "", "Mateo", "Hola, Sofi.", [], Callable(), "", "Mateo", "Sofi", false, 18)
	check(ui.find_child("SpeakerBadge", true, false).position.x > 384, "nombre de Mateo junto al personaje derecho")
	ui.show_scene("courtyard", "", "Sofi", "Hola, Mateo.", [], Callable(), "", "Sofi", "Mateo", false, 18)
	check(ui.find_child("SpeakerBadge", true, false).position.x < 384, "nombre de Sofi junto al personaje izquierdo")
	ui.show_scene("courtyard", "", "Narrador", "La tarde continúa.", [], Callable(), "", "Sofi", "", false, 18)
	check(ui.find_child("SpeakerName", true, false) == null, "narración sin etiqueta de narrador")
	ui.show_scene("courtyard", "", "Sofi", "", [{"label": "Escuchar", "action": func(): pass}], main._advance_dialogue, "", "Sofi", "Mateo", false, 18)
	ui._process(100.0)
	check(not ui.auto_action.is_valid() and GameState.dialogue_position == before + 1, "decisión espera al jugador")
	SaveManager.delete_slot(1)
	SaveManager.storage_prefix = SaveManager.SAVE_PREFIX
	get_tree().quit(1 if failures else 0)
