extends Node

const MainScene = preload("res://scenes/Main.tscn")
const ROUTES := {
	"A": {"early": "A", "final": "A", "ending": "F01"},
	"B": {"early": "B", "final": "B", "ending": "F02"},
	"C": {"early": "C", "final": "C", "ending": "F03"},
	"B_PROTECT": {"early": "A", "final": "B", "ending": "F01"},
	"C_PROTECT": {"early": "A", "final": "C", "ending": "F01"}
}

func _ready() -> void:
	_run.call_deferred()

func _press_button(story: Node, prefix: String) -> bool:
	var before: Dictionary = GameState.snapshot()
	for button in story.conversation_ui.find_children("*", "Button", true, false):
		if button.visible and button.text.begins_with(prefix):
			button.pressed.emit()
			for frame in range(120):
				await get_tree().process_frame
				if not story.save_in_progress and GameState.snapshot() != before:
					return true
			return false
	return false

func _fail(message: String) -> void:
	printerr("FAIL ruta completa: " + message)
	SaveManager.storage_prefix = SaveManager.SAVE_PREFIX
	get_tree().quit(1)

func _run() -> void:
	var story: Node = MainScene.instantiate()
	get_tree().root.add_child(story)
	for route in ROUTES:
		var plan: Dictionary = ROUTES[route]
		SaveManager.storage_prefix = "user://centinela_ROUTE_%s_%d_" % [route, Time.get_ticks_usec()]
		GameState.new_game(1)
		GameState.phase = "result"
		GameState.moba_class = "Defensor"
		GameState.moba_result = "victoria"
		if not SaveManager.save_slot():
			_fail("no se pudo crear la partida " + route)
			return
		story._load_phase()
		if not await _press_button(story, "Continuar") or not GameState.flags.get("d1_interlude_active", false):
			_fail("no se abrió el interludio en ruta " + route)
			return
		if not await _press_button(story, "Continuar") or not GameState.flags.get("draft_exploring", false):
			_fail("no se abrió el Día 1 en ruta " + route)
			return
		var visited: Array[String] = []
		var completed := false
		for transition in range(180):
			if GameState.flags.get("draft_completed", false):
				completed = true
				break
			var scene_id: String = GameState.preview_scene
			if scene_id.is_empty():
				_fail("se perdió la escena en ruta " + route)
				return
			if not visited.has(scene_id):
				visited.append(scene_id)
			if GameState.flags.get("draft_exploring", false):
				if not await story._commit_preview(scene_id, 0):
					_fail("no se abrió la conversación " + scene_id)
					return
				continue
			var scene: Dictionary = story.preview_catalog.get_scene(scene_id)
			var choices: Array = scene.get("choices", [])
			var choice_step: int = story._scene_parts(scene_id, true).lines.size()
			var prefix := "Continuar"
			if not choices.is_empty() and GameState.preview_step == choice_step:
				var letter: String = plan.final if scene_id == "D4_03_A" else plan.early
				prefix = "%d ·" % (["A", "B", "C"].find(letter) + 1)
			if not await _press_button(story, prefix):
				_fail("botón inaccesible o avance sin guardar en " + scene_id + " paso " + str(GameState.preview_step))
				return
		if not completed or str(GameState.flags.get("draft_ending", "")) != plan.ending:
			_fail("desenlace incorrecto en ruta " + route)
			return
		for main_id in story.draft_flow.MAIN_IDS:
			if not visited.has(main_id):
				_fail("falta escena " + main_id + " en ruta " + route)
				return
		var saved: Dictionary = GameState.snapshot()
		GameState.new_game(1)
		if not SaveManager.load_slot(1) or GameState.snapshot() != saved:
			_fail("desenlace no se recupera desde guardado en ruta " + route)
			return
		print("PASS ruta %s → %s, botones narrativos, guardado y reanudación" % [route, plan.ending])
		SaveManager.delete_slot(1)
	SaveManager.storage_prefix = SaveManager.SAVE_PREFIX
	get_tree().quit(0)
