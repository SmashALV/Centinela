extends Node

const MainScene = preload("res://scenes/Main.tscn")
const CASES := [
	{"answers": ["A", "A", "A"], "action": "support", "ending": "F01", "order": ["camila", "mateo", "sebas", "bruno"]},
	{"answers": ["B", "B", "B"], "action": "limit", "ending": "F02", "order": ["bruno", "sebas", "mateo", "camila"]},
	{"answers": ["B", "A", "B"], "action": "none", "ending": "F03", "order": ["mateo", "camila", "bruno", "sebas"]}
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
	for text_line in story.PROLOGUE_LINES:
		if "grooming" in str(text_line).to_lower():
			_fail("prólogo anticipa el concepto")
			return
	for plan in CASES:
		SaveManager.storage_prefix = "user://centinela_ENSEMBLE_%d_" % Time.get_ticks_usec()
		GameState.new_game(1)
		GameState.phase = "result"
		GameState.moba_class = "Defensor"
		GameState.moba_result = "victoria"
		if not SaveManager.save_slot() or not await story._start_coral_story():
			_fail("inicio coral")
			return
		for day in [1, 2, 3, 4]:
			if not await _advance_intro(story):
				_fail("introducción día " + str(day))
				return
			if await story._coral_next_day():
				_fail("salida prematura")
				return
			for person in plan.order:
				for available in ["camila", "mateo", "sebas", "bruno"]:
					if not story.world.objects.has(available):
						_fail("compañero excluido: " + available)
						return
				var id: String = story.coral_flow.companion_scene(GameState.coral_state, person)
				var option: String = ""
				if day == 2 and id.begins_with("D2_"):
					option = str(plan.answers[["A", "B", "C"].find(id.trim_prefix("D2_"))])
				elif day == 4 and id.begins_with("D4_"): option = "A"
				if not await _play_scene(story, id, option):
					_fail("conversación " + id)
					return
				if GameState.coral_state.node == "N_D2":
					if not await story._coral_advance():
						_fail("narrador después de observar")
						return
				if not story.coral_flow.talked_today(GameState.coral_state, person) or GameState.coral_state.day != day:
					_fail("avance automático o charla sin registrar")
					return
				var saved: Dictionary = GameState.snapshot()
				GameState.new_game(1)
				if not SaveManager.load_slot(1) or GameState.snapshot() != saved:
					_fail("reanudación entre compañeros")
					return
				story._load_phase()
			if day == 1:
				if not await _play_scene(story, "D1_GATE", "A"):
					_fail("lobby")
					return
				for follow_id in ["D1_A_FOLLOW", "D1_B_FOLLOW"]:
					var follow: Dictionary = story.coral_flow.scene(follow_id, story.preview_catalog, story.draft_flow, GameState.coral_state)
					for ignored in range(follow.lines.size()):
						if not await story._coral_advance():
							_fail("continuidad lobby y privado")
							return
			if day < 4:
				if not await story._coral_next_day():
					_fail("cierre de jornada")
					return
		if GameState.coral_state.observed.size() != 3:
			_fail("faltan situaciones conocidas del grupo")
			return
		if plan.action == "support": await _play_scene(story, "I_TUTOR")
		if plan.action == "limit": await _play_scene(story, "I_LIMIT")
		if not await story._coral_finish_day() or GameState.coral_state.ending != plan.ending:
			_fail("final por acciones")
			return
		var ending_scene: Dictionary = story.coral_flow.scene(plan.ending, story.preview_catalog, story.draft_flow, GameState.coral_state)
		var voices: Array = []
		for line in ending_scene.lines: voices.append(line.speaker)
		for person in ["Camila", "Mateo", "Sebas", "Bruno"]:
			if person not in voices:
				_fail("falta voz en epílogo: " + person)
				return
		for ignored in range(ending_scene.lines.size()): await story._coral_advance()
		print("PASS jornada compartida D1–D4, cuatro compañeros, orden %s, final %s y reanudación" % [str(plan.order), plan.ending])
		SaveManager.delete_slot(1)
	var old_save: Dictionary = GameState.snapshot()
	old_save.phase = "coral"
	old_save.coral_state.version = "CORAL_STORY_v0.1"
	old_save.coral_state.mode = "explore"
	old_save.coral_state.node = ""
	old_save.coral_state.day = 3
	if not GameState.restore(old_save) or GameState.coral_state.version != "CORAL_STORY_v0.2" or GameState.coral_state.day != 2:
		_fail("migración de partida con compañero exclusivo")
		return
	print("PASS migración a jornada compartida y prólogo sin definición anticipada")
	SaveManager.storage_prefix = SaveManager.SAVE_PREFIX
	get_tree().quit(0)
