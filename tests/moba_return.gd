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
	var content: VBoxContainer = story.modal_box.get_child(2).get_child(0)
	var rendered_text := ""
	for child in content.get_children():
		if child is Label:
			rendered_text += child.text + "\n"
		elif child is Button:
			rendered_text += child.text + "\n"
	if not rendered_text.contains("Al día siguiente") or not rendered_text.contains("Continuar historia · Día 1"):
		printerr("FAIL falta enlace narrativo hacia el Día 1")
		get_tree().quit(1)
		return
	if not await story._start_playable_draft() or GameState.phase != "preview" or GameState.preview_scene != "D1_02_A" or not GameState.flags.get("draft_exploring", false):
		printerr("FAIL continuar no inicia la exploración del Día 1")
		get_tree().quit(1)
		return
	print("PASS MOBA → resultado de Camila → Día 1 sin volver al menú")
	SaveManager.delete_slot(1)
	SaveManager.storage_prefix = SaveManager.SAVE_PREFIX
	get_tree().quit(0)
