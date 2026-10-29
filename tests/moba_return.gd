extends Node

const ArenaScene = preload("res://scenes/moba/MOBAArena.tscn")

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	SaveManager.storage_prefix = "user://centinela_RETURN_TEST_ONLY_%d_" % Time.get_ticks_usec()
	GameState.new_game(1)
	GameState.phase = "moba"
	GameState.moba_class = "Defensor"
	if not SaveManager.save_slot():
		get_tree().quit(1)
		return
	var arena: Node2D = ArenaScene.instantiate()
	get_tree().root.add_child(arena)
	get_tree().current_scene = arena
	await arena._finish("victoria")
	if not arena.result_saved or GameState.phase != "result":
		printerr("FAIL resultado del MOBA no guardado")
		get_tree().quit(1)
		return
	arena._return_to_story()
	await get_tree().process_frame
	await get_tree().process_frame
	var story: Node = get_tree().current_scene
	if story == null or story.modal_kind != "result" or GameState.returning_from_moba:
		printerr("FAIL MOBA volvió al menú en vez del resultado narrativo")
		get_tree().quit(1)
		return
	var buttons: Array[Node] = story.conversation_ui.find_children("*", "Button", true, false)
	var rendered_text := ""
	for label in story.conversation_ui.find_children("*", "Label", true, false):
		rendered_text += label.text + "\n"
	if not buttons.is_empty() or not story.conversation_ui.auto_action.is_valid() or not rendered_text.contains("Camila") or not rendered_text.contains("¡Ganamos!"):
		printerr("FAIL resultado no muestra a Camila con avance automático")
		get_tree().quit(1)
		return
	if not await story._show_d1_interlude() or not GameState.flags.get("d1_interlude_active", false):
		printerr("FAIL resultado no avanza al interludio del narrador")
		get_tree().quit(1)
		return
	var interlude_text := ""
	for label in story.conversation_ui.find_children("*", "Label", true, false):
		interlude_text += label.text + "\n"
	if interlude_text.contains("Narrador") or not interlude_text.contains("Sofi vuelve al grupo") or not story.conversation_ui.auto_action.is_valid():
		printerr("FAIL el interludio no presenta la transición automática de Sofi")
		get_tree().quit(1)
		return
	if not await story._start_coral_story() or GameState.phase != "coral" or GameState.coral_state.day != 1 or GameState.flags.has("d1_interlude_active"):
		printerr("FAIL no se inicia la jornada compartida del Día 1")
		get_tree().quit(1)
		return
	await story._coral_advance()
	await story._coral_advance()
	for person in ["camila", "mateo", "sebas", "bruno"]:
		if not story.world.objects.has(person) or GameState.coral_state.mode != "explore":
			printerr("FAIL falta compañero en Día 1: " + person)
			get_tree().quit(1)
			return
	print("PASS MOBA → Camila → narrador con Sofi → Día 1 sin volver al menú")
	SaveManager.delete_slot(1)
	SaveManager.storage_prefix = SaveManager.SAVE_PREFIX
	get_tree().quit(0)
