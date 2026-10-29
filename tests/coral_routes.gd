extends Node

const MainScene = preload("res://scenes/Main.tscn")
const CASES := [
	{"route": "A", "d2": "A", "d4": "A", "action": "early_support", "ending": "F01"},
	{"route": "A", "d2": "B", "d4": "B", "action": "limit", "ending": "F02"},
	{"route": "B", "d2": "A", "d4": "B", "action": "none", "ending": "F03"},
	{"route": "B", "d2": "B", "d4": "A", "action": "support", "ending": "F01"},
	{"route": "C", "d2": "A", "d4": "B", "action": "limit", "ending": "F02"},
	{"route": "C", "d2": "B", "d4": "B", "action": "none", "ending": "F03"}
]

func _ready() -> void:
	_run.call_deferred()

func _fail(message: String) -> void:
	printerr("FAIL guion coral: " + message)
	SaveManager.storage_prefix = SaveManager.SAVE_PREFIX
	get_tree().quit(1)

func _advance_intro(story: Node) -> bool:
	for ignored in range(2):
		if story.modal_kind != "coral" or not await story._coral_advance(): return false
	return GameState.coral_state.mode == "explore"

func _play_scene(story: Node, scene_id: String, choice: String = "") -> bool:
	if not await story._coral_begin_scene(scene_id): return false
	if story.conversation_ui.visible == false: return false
	var scene: Dictionary = story.coral_flow.scene(scene_id, story.preview_catalog, story.draft_flow, GameState.coral_state)
	if scene.get("lines", []).is_empty(): return false
	for ignored in range(scene.lines.size()):
		if not await story._coral_advance(): return false
	if choice.is_empty():
		return true
	if GameState.coral_state.mode != "scene" or GameState.coral_state.step != scene.lines.size(): return false
	var option_text: String = ""
	for option in scene.get("choices", []):
		if option.key == choice: option_text = str(option.text)
	var pressed := false
	for button in story.conversation_ui.find_children("*", "Button", true, false):
		if button.text == option_text:
			button.pressed.emit()
			pressed = true
			break
	if not pressed: return false
	for frame in range(120):
		await get_tree().process_frame
		if not story.save_in_progress and GameState.coral_state.mode == "reaction": break
	if GameState.coral_state.mode != "reaction": return false
	if GameState.coral_state.choices.get(scene_id) != choice: return false
	return await story._coral_finish_scene()

func _run() -> void:
	var story: Node = MainScene.instantiate()
	get_tree().root.add_child(story)
	if story.coral_flow.content.is_empty():
		_fail("contenido no cargado")
		return
	for case_data in CASES:
		var label: String = "%s%s" % [case_data.route, case_data.d2]
		SaveManager.storage_prefix = "user://centinela_CORAL_%s_%d_" % [label, Time.get_ticks_usec()]
		GameState.new_game(1)
		GameState.phase = "result"
		GameState.moba_class = "Defensor"
		GameState.moba_result = "victoria"
		if not SaveManager.save_slot() or not await story._start_coral_story():
			_fail("inicio " + label)
			return
		if not await _advance_intro(story):
			_fail("introducción D1 " + label)
			return
		for actor in ["camila", "mateo"]:
			if not await _play_scene(story, "I_D1_" + actor.to_upper()):
				_fail("charla D1 " + label)
				return
		if not await _play_scene(story, "D1_GATE", case_data.route):
			_fail("decisión D1 " + label)
			return
		if GameState.coral_state.node != "D1_%s_FOLLOW" % case_data.route:
			_fail("consecuencia inmediata D1 " + label)
			return
		if case_data.route == "B" and story.conversation_ui.find_child("DirectSidebar", true, false) == null:
			_fail("privado de Mateo D1 " + label)
			return
		var follow: Dictionary = story.coral_flow.scene("D1_%s_FOLLOW" % case_data.route, story.preview_catalog, story.draft_flow, GameState.coral_state)
		for ignored in range(follow.lines.size()):
			if not await story._coral_advance():
				_fail("escena inmediata D1 " + label)
				return
		if GameState.coral_state.route != case_data.route or GameState.coral_state.day != 2:
			_fail("ruta D1 no persistió " + label)
			return
		if case_data.action == "early_support":
			if not await _advance_intro(story) or not await _play_scene(story, "I_TUTOR"):
				_fail("apoyo temprano " + label)
				return
		else:
			if not await _advance_intro(story):
				_fail("introducción D2 " + label)
				return
		if not story.coral_flow.educational_hint(GameState.coral_state, 2).contains("aislado"):
			_fail("pista prematura revela información " + label)
			return
		if not await _play_scene(story, "D2_" + case_data.route, case_data.d2):
			_fail("decisión D2 " + label)
			return
		if case_data.route == "B" and story.conversation_ui.find_child("DirectSidebar", true, false) == null:
			# La escena siguiente ya reemplazó el chat: comprobar por su tipo declarado.
			if story.coral_flow.scene("D2_B", story.preview_catalog, story.draft_flow, GameState.coral_state).presentation != "dm":
				_fail("chat privado de Mateo " + label)
				return
		var branch: String = case_data.route + ("1" if case_data.d2 == "A" else "2")
		if GameState.coral_state.branch != branch or GameState.coral_state.observed.is_empty():
			_fail("consecuencia D2 " + label)
			return
		if not await _play_scene(story, "N_D2") or GameState.coral_state.day != 3:
			_fail("narrador de ruta " + label)
			return
		var saved: Dictionary = GameState.snapshot()
		GameState.new_game(1)
		if not SaveManager.load_slot(1) or GameState.snapshot() != saved:
			_fail("reanudar D3 " + label)
			return
		story._load_phase()
		if not await _advance_intro(story) or not await _play_scene(story, "D3_" + branch):
			_fail("escena D3 " + label)
			return
		if GameState.coral_state.day != 4 or not await _advance_intro(story):
			_fail("introducción D4 " + label)
			return
		if not await _play_scene(story, "D4_" + branch, case_data.d4):
			_fail("decisión D4 " + label)
			return
		if case_data.action == "support" and not await _play_scene(story, "I_TUTOR"):
			_fail("apoyo final " + label)
			return
		if case_data.action == "limit" and not await _play_scene(story, "I_LIMIT"):
			_fail("límite digital " + label)
			return
		if not await story._coral_finish_day() or GameState.coral_state.ending != case_data.ending:
			_fail("final por acciones " + label)
			return
		var ending_scene: Dictionary = story.coral_flow.scene(case_data.ending, story.preview_catalog, story.draft_flow, GameState.coral_state)
		if ending_scene.lines.size() < 4:
			_fail("epílogo de compañeros " + label)
			return
		for ignored in range(ending_scene.lines.size()):
			if not await story._coral_advance():
				_fail("avance epílogo " + label)
				return
		if GameState.coral_state.mode != "summary":
			_fail("cierre " + label)
			return
		print("PASS ruta coral %s → %s con guardado, pistas y epílogo" % [label, case_data.ending])
		SaveManager.delete_slot(1)
	SaveManager.storage_prefix = SaveManager.SAVE_PREFIX
	get_tree().quit(0)
