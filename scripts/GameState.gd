extends Node

const SCHEMA_VERSION := 1
const NARRATIVE_VERSION := "provisional-d0-1"
const PREVIEW_CONTENT_VERSION := "RECOVERED_PREVIEW_D0_v0.2"
const PREVIEW_PACK_VERSION := "RECOVERED_PREVIEW_D0_D4_v0.2"
const DRAFT_CONTENT_VERSION := "PLAYABLE_DRAFT_v0.1"
const PREVIEW_SCENES := ["D1_02_A", "D2_03_A", "D3_01_A", "D4_01_A", "D4_02_A", "D4_03_A", "ENDINGS_INDEX", "F01_A", "F01_B", "F02", "F03"]

var slot: int = 1
var code: String = ""
var phase: String = "bedroom"
var flags: Dictionary = {}
var player_position: Vector2 = Vector2(384, 280)
var moba_class: String = ""
var moba_result: String = ""
var phone_messages: Array = []
var preview_scene: String = ""
var preview_step: int = 0
var preview_choices: Dictionary = {}
var text_size: String = "normal"
var dialogue_key: String = ""
var dialogue_position: int = 0
var dialogue_choice: String = ""
var dialogue_history: Array = []
var dialogue_speed: String = "normal"
var ui_modal: String = ""
var hint_level: int = 0
var music_volume: int = 50
var effects_volume: int = 75

func new_game(chosen_slot: int) -> void:
	slot = chosen_slot
	code = "CTN-%06d" % randi_range(0, 999999)
	phase = "bedroom"
	flags = {}
	player_position = Vector2(384, 280)
	moba_class = ""
	moba_result = ""
	phone_messages = []
	preview_scene = ""
	preview_step = 0
	preview_choices = {}
	text_size = "normal"
	dialogue_key = ""
	dialogue_position = 0
	dialogue_choice = ""
	dialogue_history = []
	dialogue_speed = "normal"
	ui_modal = ""
	hint_level = 0
	music_volume = 50
	effects_volume = 75

func snapshot() -> Dictionary:
	return {"schema_version": SCHEMA_VERSION, "narrative_version": NARRATIVE_VERSION,
		"preview_content_version": PREVIEW_CONTENT_VERSION,
		"preview_pack_version": PREVIEW_PACK_VERSION,
		"draft_content_version": DRAFT_CONTENT_VERSION,
		"slot": slot, "code": code, "phase": phase, "flags": flags.duplicate(true),
		"player_position": [player_position.x, player_position.y],
		"moba_class": moba_class, "moba_result": moba_result,
		"phone_messages": phone_messages.duplicate(true),
		"preview_scene": preview_scene, "preview_step": preview_step,
		"preview_choices": preview_choices.duplicate(true), "text_size": text_size,
		"dialogue_key": dialogue_key, "dialogue_position": dialogue_position,
		"dialogue_choice": dialogue_choice, "dialogue_history": dialogue_history.duplicate(),
		"dialogue_speed": dialogue_speed, "ui_modal": ui_modal,
		"hint_level": hint_level, "music_volume": music_volume,
		"effects_volume": effects_volume}

func restore(data: Dictionary) -> bool:
	if data.get("schema_version") != SCHEMA_VERSION or data.get("narrative_version") != NARRATIVE_VERSION:
		return false
	if data.has("preview_content_version") and data.preview_content_version != PREVIEW_CONTENT_VERSION:
		return false
	if data.has("preview_pack_version") and data.preview_pack_version != PREVIEW_PACK_VERSION:
		return false
	if typeof(data.get("flags")) == TYPE_DICTIONARY and data.flags.get("draft_mode", false) and data.get("draft_content_version") != DRAFT_CONTENT_VERSION:
		return false
	if typeof(data.get("slot")) != TYPE_FLOAT and typeof(data.get("slot")) != TYPE_INT:
		return false
	if int(data.slot) < 1 or int(data.slot) > 3 or float(data.slot) != float(int(data.slot)) or typeof(data.get("flags")) != TYPE_DICTIONARY:
		return false
	if typeof(data.get("phone_messages")) != TYPE_ARRAY or typeof(data.get("code")) != TYPE_STRING:
		return false
	if data.code.length() != 10 or not data.code.begins_with("CTN-"):
		return false
	for index in range(4, 10):
		if data.code.unicode_at(index) < 48 or data.code.unicode_at(index) > 57:
			return false
	for flag in ["prologue_seen", "wakeup_seen", "alarm", "backpack", "friends", "d0_chat_done", "preview_reviewed", "draft_mode", "draft_completed", "draft_exploring"]:
		if data.flags.has(flag) and typeof(data.flags[flag]) != TYPE_BOOL:
			return false
	if data.flags.has("prologue_step"):
		var prologue_step: Variant = data.flags.prologue_step
		if typeof(prologue_step) not in [TYPE_INT, TYPE_FLOAT] or float(prologue_step) != float(int(prologue_step)) or int(prologue_step) < 0 or int(prologue_step) > 2 or data.get("phase") != "bedroom" or data.flags.get("prologue_seen", false) or data.flags.get("wakeup_seen", false):
			return false
	if data.flags.get("draft_exploring", false) and (not data.flags.get("draft_mode", false) or data.get("phase") != "preview" or data.get("preview_scene", "") not in ["D1_02_A", "D2_03_A", "D3_01_A", "D4_01_A"] or data.get("preview_step", 0) != 0):
		return false
	if data.flags.has("draft_ending") and data.flags.draft_ending not in ["", "F01", "F02", "F03"]:
		return false
	if data.flags.has("d0_chat_choice") and data.flags.d0_chat_choice not in ["D0_05_A_OPT_A", "D0_05_A_OPT_B", "D0_05_A_OPT_C"]:
		return false
	if data.phone_messages.size() > 100:
		return false
	for message in data.phone_messages:
		if typeof(message) != TYPE_DICTIONARY or typeof(message.get("speaker")) != TYPE_STRING or typeof(message.get("text")) != TYPE_STRING:
			return false
		if message.speaker.length() > 100 or message.text.length() > 2000:
			return false
	if typeof(data.get("moba_class", "")) != TYPE_STRING or data.get("moba_class", "") not in ["", "Atacante", "Defensor", "Soporte"]:
		return false
	if typeof(data.get("moba_result", "")) != TYPE_STRING or data.get("moba_result", "") not in ["", "victoria", "derrota", "empate"]:
		return false
	if not ["bedroom", "courtyard", "computer", "moba", "result", "preview"].has(data.get("phase", "")):
		return false
	var scene: Variant = data.get("preview_scene", "")
	var step: Variant = data.get("preview_step", 0)
	var choices: Variant = data.get("preview_choices", {})
	var size_setting: Variant = data.get("text_size", "normal")
	var active_dialogue: Variant = data.get("dialogue_key", "")
	var active_position: Variant = data.get("dialogue_position", 0)
	var active_choice: Variant = data.get("dialogue_choice", "")
	var saved_history: Variant = data.get("dialogue_history", [])
	var saved_speed: Variant = data.get("dialogue_speed", "normal")
	var saved_modal: Variant = data.get("ui_modal", "")
	var saved_hint: Variant = data.get("hint_level", 0)
	var saved_music: Variant = data.get("music_volume", 50)
	var saved_effects: Variant = data.get("effects_volume", 75)
	if typeof(scene) != TYPE_STRING or typeof(step) not in [TYPE_FLOAT, TYPE_INT] or typeof(choices) != TYPE_DICTIONARY:
		return false
	if typeof(size_setting) != TYPE_STRING or size_setting not in ["small", "normal", "large"]:
		return false
	if typeof(active_dialogue) != TYPE_STRING or active_dialogue not in ["", "wakeup", "courtyard", "group_chat"] or \
		typeof(active_position) not in [TYPE_FLOAT, TYPE_INT] or typeof(active_choice) != TYPE_STRING:
		return false
	if typeof(saved_history) != TYPE_ARRAY or saved_history.size() > 100 or \
		typeof(saved_speed) != TYPE_STRING or saved_speed not in ["slow", "normal", "fast"]:
		return false
	for visited in saved_history:
		if typeof(visited) not in [TYPE_INT, TYPE_FLOAT] or int(visited) < 0 or int(visited) > 100 or float(visited) != float(int(visited)):
			return false
	if int(active_position) < 0 or int(active_position) > 100 or float(active_position) != float(int(active_position)) or \
		(not active_dialogue.is_empty() and data.get("phase") not in ["bedroom", "courtyard", "computer"]) or \
		(active_dialogue.is_empty() and (int(active_position) != 0 or not active_choice.is_empty() or not saved_history.is_empty())):
		return false
	if not active_dialogue.is_empty():
		var bounds: Array = {"wakeup": [0, 2], "courtyard": [3, 13], "group_chat": [14, 22]}[active_dialogue]
		if int(active_position) < bounds[0] or int(active_position) > bounds[1] or float(active_position) != float(int(active_position)):
			return false
		var last_visited: int = int(bounds[0]) - 1
		for visited in saved_history:
			if int(visited) < bounds[0] or int(visited) >= int(active_position) or int(visited) <= last_visited:
				return false
			last_visited = int(visited)
	if not active_choice.is_empty() and active_choice not in ["D0_05_A_OPT_A", "D0_05_A_OPT_B", "D0_05_A_OPT_C"]:
		return false
	if typeof(saved_modal) != TYPE_STRING or saved_modal not in ["", "phone", "objective", "class"] or \
		typeof(saved_hint) not in [TYPE_FLOAT, TYPE_INT] or int(saved_hint) < 0 or int(saved_hint) > 2 or float(saved_hint) != float(int(saved_hint)):
		return false
	for level in [saved_music, saved_effects]:
		if typeof(level) not in [TYPE_INT, TYPE_FLOAT] or int(level) not in [0, 25, 50, 75, 100] or float(level) != float(int(level)):
			return false
	if (not active_dialogue.is_empty() and not saved_modal.is_empty()) or \
		(saved_modal == "class" and data.get("phase") != "computer") or \
		(saved_modal in ["phone", "objective"] and data.get("phase") not in ["bedroom", "courtyard", "computer"] and not data.flags.get("draft_exploring", false)):
		return false
	if (active_dialogue == "wakeup" and data.get("phase") != "bedroom") or \
		(active_dialogue == "courtyard" and data.get("phase") != "courtyard") or \
		(active_dialogue == "group_chat" and data.get("phase") != "computer"):
		return false
	if int(step) < 0 or int(step) > 100 or float(step) != float(int(step)) or (not scene.is_empty() and not PREVIEW_SCENES.has(scene)):
		return false
	if data.get("phase") == "preview" and scene.is_empty():
		return false
	for choice_scene in choices:
		if not PREVIEW_SCENES.has(choice_scene) or not ["A", "B", "C"].has(choices[choice_scene]):
			return false
	if typeof(data.get("player_position")) != TYPE_ARRAY:
		return false
	var p: Array = data.player_position
	if p.size() != 2 or not (typeof(p[0]) in [TYPE_FLOAT, TYPE_INT]) or not (typeof(p[1]) in [TYPE_FLOAT, TYPE_INT]):
		return false
	if float(p[0]) < 0.0 or float(p[0]) > 768.0 or float(p[1]) < 0.0 or float(p[1]) > 448.0:
		return false
	slot = int(data.get("slot", 1))
	code = str(data.get("code", ""))
	phase = str(data.phase)
	flags = data.get("flags", {}).duplicate(true)
	player_position = Vector2(float(p[0]), float(p[1]))
	moba_class = str(data.get("moba_class", ""))
	moba_result = str(data.get("moba_result", ""))
	phone_messages = data.get("phone_messages", []).duplicate(true)
	preview_scene = scene
	preview_step = int(step)
	preview_choices = choices.duplicate(true)
	text_size = size_setting
	dialogue_key = active_dialogue
	dialogue_position = int(active_position)
	dialogue_choice = active_choice
	dialogue_history = []
	for visited in saved_history:
		dialogue_history.append(int(visited))
	dialogue_speed = saved_speed
	ui_modal = saved_modal
	hint_level = int(saved_hint)
	music_volume = int(saved_music)
	effects_volume = int(saved_effects)
	return true
