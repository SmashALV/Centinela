extends Node

const SCHEMA_VERSION := 1
const NARRATIVE_VERSION := "provisional-d0-1"
const PREVIEW_CONTENT_VERSION := "RECOVERED_PREVIEW_D0_v0.2"
const PREVIEW_PACK_VERSION := "RECOVERED_PREVIEW_D0_D4_v0.2"
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
var ui_modal: String = ""
var hint_level: int = 0

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
	ui_modal = ""
	hint_level = 0

func snapshot() -> Dictionary:
	return {"schema_version": SCHEMA_VERSION, "narrative_version": NARRATIVE_VERSION,
		"preview_content_version": PREVIEW_CONTENT_VERSION,
		"preview_pack_version": PREVIEW_PACK_VERSION,
		"slot": slot, "code": code, "phase": phase, "flags": flags.duplicate(true),
		"player_position": [player_position.x, player_position.y],
		"moba_class": moba_class, "moba_result": moba_result,
		"phone_messages": phone_messages.duplicate(true),
		"preview_scene": preview_scene, "preview_step": preview_step,
		"preview_choices": preview_choices.duplicate(true), "text_size": text_size,
		"dialogue_key": dialogue_key, "dialogue_position": dialogue_position,
		"dialogue_choice": dialogue_choice, "ui_modal": ui_modal,
		"hint_level": hint_level}

func restore(data: Dictionary) -> bool:
	if data.get("schema_version") != SCHEMA_VERSION or data.get("narrative_version") != NARRATIVE_VERSION:
		return false
	if data.has("preview_content_version") and data.preview_content_version != PREVIEW_CONTENT_VERSION:
		return false
	if data.has("preview_pack_version") and data.preview_pack_version != PREVIEW_PACK_VERSION:
		return false
	if typeof(data.get("slot")) != TYPE_FLOAT and typeof(data.get("slot")) != TYPE_INT:
		return false
	if int(data.slot) < 1 or int(data.slot) > 3 or typeof(data.get("flags")) != TYPE_DICTIONARY:
		return false
	if typeof(data.get("phone_messages")) != TYPE_ARRAY or typeof(data.get("code")) != TYPE_STRING:
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
	var saved_modal: Variant = data.get("ui_modal", "")
	var saved_hint: Variant = data.get("hint_level", 0)
	if typeof(scene) != TYPE_STRING or typeof(step) not in [TYPE_FLOAT, TYPE_INT] or typeof(choices) != TYPE_DICTIONARY:
		return false
	if typeof(size_setting) != TYPE_STRING or size_setting not in ["small", "normal", "large"]:
		return false
	if typeof(active_dialogue) != TYPE_STRING or active_dialogue not in ["", "wakeup", "courtyard", "group_chat"] or \
		typeof(active_position) not in [TYPE_FLOAT, TYPE_INT] or typeof(active_choice) != TYPE_STRING:
		return false
	if int(active_position) < 0 or int(active_position) > 100 or \
		(not active_dialogue.is_empty() and data.get("phase") not in ["bedroom", "courtyard", "computer"]) or \
		(active_dialogue.is_empty() and (int(active_position) != 0 or not active_choice.is_empty())):
		return false
	if not active_choice.is_empty() and active_choice not in ["D0_05_A_OPT_A", "D0_05_A_OPT_B", "D0_05_A_OPT_C"]:
		return false
	if typeof(saved_modal) != TYPE_STRING or saved_modal not in ["", "phone", "objective", "class"] or \
		typeof(saved_hint) not in [TYPE_FLOAT, TYPE_INT] or int(saved_hint) < 0 or int(saved_hint) > 2:
		return false
	if (not active_dialogue.is_empty() and not saved_modal.is_empty()) or \
		(saved_modal == "class" and data.get("phase") != "computer") or \
		(saved_modal in ["phone", "objective"] and data.get("phase") not in ["bedroom", "courtyard", "computer"]):
		return false
	if (active_dialogue == "wakeup" and data.get("phase") != "bedroom") or \
		(active_dialogue == "courtyard" and data.get("phase") != "courtyard") or \
		(active_dialogue == "group_chat" and data.get("phase") != "computer"):
		return false
	if int(step) < 0 or int(step) > 100 or (not scene.is_empty() and not PREVIEW_SCENES.has(scene)):
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
	ui_modal = saved_modal
	hint_level = int(saved_hint)
	return true
