extends RefCounted
# Telemetría descriptiva: hechos de juego sin texto libre, datos personales ni puntaje.
# Los eventos se derivan comparando el último estado guardado con el que se va a guardar,
# de modo que cada hecho viaja en la misma transacción que el snapshot que lo produce.

const CoralFlowScript = preload("res://scripts/narrative/CoralStoryFlow.gd")

const MAX_EVENTS_PER_SAVE := 10
const STORY_ACTIONS := ["D1_LOBBY_DONE", "TUTOR_INFO_SEEN", "ADULT_SUPPORT_STARTED",
	"DIGITAL_LIMIT_COMPLETED", "REPAIR_OFFERED", "SUPPORT_PLANNED", "LIMIT_PLANNED"]
const PROFILE_CODES := {"Protectora": "protective", "En aprendizaje": "learning", "De riesgo": "risk"}

static func capture(game_state: Object) -> Dictionary:
	return {"day": current_day(game_state), "coral": game_state.coral_state.duplicate(true)}

static func current_day(game_state: Object) -> int:
	var routine: Variant = game_state.flags.get("routine", {})
	if typeof(routine) == TYPE_DICTIONARY and routine.has("day"):
		return clampi(int(routine.day), 0, 4)
	return clampi(int(game_state.coral_state.get("day", 0)), 0, 4)

static func closed(baseline: Dictionary) -> bool:
	return not str(baseline.get("coral", {}).get("ending", "")).is_empty()

static func fact(kind: String, day: int, scene: String, context: Dictionary = {}) -> Dictionary:
	return {"kind": kind, "day": clampi(day, 0, 4), "scene": safe_scene(scene), "context": context}

const SCENE_CHARACTERS := "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_.-"

static func safe_scene(scene: String) -> String:
	var cleaned := ""
	for character in scene:
		cleaned += character if character in SCENE_CHARACTERS else "_"
	cleaned = cleaned.substr(0, 64)
	return cleaned if not cleaned.is_empty() else "general"

static func diff(before: Dictionary, after: Dictionary, profile: Dictionary = {}) -> Array:
	var events: Array = []
	if before.is_empty() or closed(before):
		return events
	var day: int = int(after.get("day", 0))
	var old_coral: Dictionary = before.get("coral", {})
	var coral: Dictionary = after.get("coral", {})
	if day != int(before.get("day", 0)):
		events.append(fact("day_start", day, "D%d" % day))
	var node: String = str(coral.get("node", ""))
	if coral.get("mode") == "scene" and not node.is_empty() and (node != str(old_coral.get("node", "")) or old_coral.get("mode") != "scene"):
		events.append(fact("scene_start", day, node))
	var old_choices: Dictionary = old_coral.get("choices", {})
	var choices: Dictionary = coral.get("choices", {})
	for decision_id in choices:
		if old_choices.has(decision_id): continue
		var key: String = str(choices[decision_id])
		var behavior: String = str(CoralFlowScript.CHOICE_BEHAVIOR.get(decision_id, {}).get(key, ""))
		if behavior.is_empty() or key not in ["A", "B", "C"]: continue
		events.append(fact("story_choice", day, str(decision_id),
			{"decision_id": str(decision_id), "choice_id": key, "behavior": behavior}))
	var old_actions: Array = old_coral.get("actions", [])
	for action in coral.get("actions", []):
		if action in STORY_ACTIONS and not old_actions.has(action):
			events.append(fact("story_action", day, node if not node.is_empty() else str(old_coral.get("node", "D%d" % day)), {"action": str(action)}))
	var old_hints: Dictionary = old_coral.get("hint_requests", {})
	var hints: Dictionary = coral.get("hint_requests", {})
	for hint_day in hints:
		if old_hints.get(hint_day) != hints[hint_day] and hints[hint_day] in ["nav", "h1", "h2"]:
			events.append(fact("hint_request", int(hint_day), "D%s" % hint_day, {"level": str(hints[hint_day])}))
	var ending: String = str(coral.get("ending", ""))
	if ending in ["F01", "F02", "F03"]:
		var counts: Dictionary = profile.get("counts", {})
		events.append(fact("ending_reached", day, ending, {"ending": ending,
			"profile": str(PROFILE_CODES.get(str(profile.get("label", "")), "learning")),
			"protective_choices": int(counts.get("protectora", 0)),
			"limit_choices": int(counts.get("limite", 0)),
			"risk_choices": int(counts.get("riesgo", 0))}))
	return events.slice(0, MAX_EVENTS_PER_SAVE)
