extends Node

const SCHEMA_VERSION := 1
const NARRATIVE_VERSION := "provisional-d0-1"
const PREVIEW_CONTENT_VERSION := "RECOVERED_PREVIEW_D0_v0.2"
const PREVIEW_PACK_VERSION := "RECOVERED_PREVIEW_D0_D4_v0.2"
const DRAFT_CONTENT_VERSION := "PLAYABLE_DRAFT_v0.3"
const CORAL_CONTENT_VERSION := "CORAL_STORY_v0.2"
const CORAL_DECISIONS := ["D1_GATE", "D2_A", "D2_B", "D2_C", "D4_A1", "D4_A2", "D4_B1", "D4_B2", "D4_C1", "D4_C2"]
const CORAL_NODES := ["I_D2_BRUNO", "I_D3_SEBAS", "I_D3_BRUNO", "I_D4_BRUNO", "I_D1_CAMILA", "I_D1_BRUNO", "I_D1_SEBAS", "I_D1_MATEO", "I_TUTOR", "I_LIMIT", "D1_GATE", "D1_A_FOLLOW", "D1_B_FOLLOW", "D1_C_FOLLOW", "D2_A", "D2_B", "D2_C", "N_D2", "D3_A1", "D3_A2", "D3_B1", "D3_B2", "D3_C1", "D3_C2", "D4_A1", "D4_A2", "D4_B1", "D4_B2", "D4_C1", "D4_C2", "F01", "F02", "F03"]
const PREVIEW_SCENES := ["D1_02_A", "D1_03_A", "D2_03_A", "D2_04_A", "D3_01_A", "D4_01_A", "D4_02_A", "D4_03_A", "ENDINGS_INDEX", "F01_A", "F01_B", "F02", "F03"]

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
var coral_state: Dictionary = {}
var returning_from_moba: bool = false

func new_game(chosen_slot: int) -> void:
	returning_from_moba = false
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
	coral_state = {}

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
		"effects_volume": effects_volume,
		"coral_state": coral_state.duplicate(true)}

func restore(data: Dictionary) -> bool:
	if data.get("schema_version") != SCHEMA_VERSION or data.get("narrative_version") != NARRATIVE_VERSION:
		return false
	if data.has("preview_content_version") and data.preview_content_version != PREVIEW_CONTENT_VERSION:
		return false
	if data.has("preview_pack_version") and data.preview_pack_version != PREVIEW_PACK_VERSION:
		return false
	if typeof(data.get("flags")) == TYPE_DICTIONARY and data.flags.get("draft_mode", false) and data.get("draft_content_version") not in [DRAFT_CONTENT_VERSION, "PLAYABLE_DRAFT_v0.2", "PLAYABLE_DRAFT_v0.1"]:
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
	for flag in ["prologue_seen", "wakeup_seen", "alarm", "backpack", "friends", "d0_chat_done", "d0_photo_seen", "d0_desk_seen", "d0_tutoria_seen", "d0_profile_private", "d0_guide_bedroom_seen", "d0_guide_courtyard_seen", "d0_guide_computer_seen", "d0_departure_seen", "preview_reviewed", "draft_mode", "draft_completed", "draft_exploring", "d1_interlude_active"]:
		if data.flags.has(flag) and typeof(data.flags[flag]) != TYPE_BOOL:
			return false
	if data.flags.has("d0_guide_active") and (data.flags.d0_guide_active not in ["bedroom", "courtyard", "computer"] or data.flags.d0_guide_active != data.get("phase")):
		return false
	if data.flags.get("d1_interlude_active", false) and data.get("phase") != "result":
		return false
	if data.flags.has("prologue_step"):
		var prologue_step: Variant = data.flags.prologue_step
		if typeof(prologue_step) not in [TYPE_INT, TYPE_FLOAT] or float(prologue_step) != float(int(prologue_step)) or int(prologue_step) < 0 or int(prologue_step) > 2 or data.get("phase") != "bedroom" or data.flags.get("prologue_seen", false) or data.flags.get("wakeup_seen", false):
			return false
	if data.flags.get("draft_exploring", false) and (not data.flags.get("draft_mode", false) or data.get("phase") != "preview" or data.get("preview_scene", "") not in ["D1_02_A", "D2_03_A", "D3_01_A", "D4_01_A"] or data.get("preview_step", 0) != 0):
		return false
	if data.flags.has("draft_intro_step"):
		var intro_step: Variant = data.flags.draft_intro_step
		if typeof(intro_step) not in [TYPE_INT, TYPE_FLOAT] or float(intro_step) != float(int(intro_step)) or int(intro_step) not in [0, 1] or not data.flags.get("draft_exploring", false):
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
	if not ["bedroom", "courtyard", "computer", "moba", "result", "preview", "coral"].has(data.get("phase", "")):
		return false
	var coral: Variant = data.get("coral_state", {})
	if typeof(coral) != TYPE_DICTIONARY:
		return false
	if data.get("phase") == "coral":
		if coral.get("version") not in [CORAL_CONTENT_VERSION, "CORAL_STORY_v0.1"] or int(coral.get("day", 0)) not in [1, 2, 3, 4] or coral.get("mode") not in ["intro", "explore", "scene", "reaction", "ending", "summary"] or typeof(coral.get("node", "")) != TYPE_STRING or typeof(coral.get("step", 0)) not in [TYPE_INT, TYPE_FLOAT] or int(coral.get("step", 0)) < 0 or int(coral.get("step", 0)) > 100 or coral.get("route", "") not in ["", "A", "B", "C"]:
			return false
		for field in ["choices", "hint_requests", "companion_states"]:
			if typeof(coral.get(field)) != TYPE_DICTIONARY:
				return false
		for field in ["actions", "observed", "seen_narrator"]:
			if typeof(coral.get(field)) != TYPE_ARRAY or coral[field].size() > 100:
				return false
		for field in ["adult_support_started", "limit_completed", "chapter_scene_done"]:
			if typeof(coral.get(field)) != TYPE_BOOL:
				return false
		if coral.get("branch", "") not in ["", "A1", "A2", "B1", "B2", "C1", "C2"] or coral.get("ending", "") not in ["", "F01", "F02", "F03"]:
			return false
		var coral_mode: String = str(coral.mode)
		var coral_node: String = str(coral.node)
		if float(coral.step) != float(int(coral.step)) or float(coral.day) != float(int(coral.day)): return false
		if (coral_mode in ["intro", "explore", "summary"] and not coral_node.is_empty()) or (coral_mode in ["scene", "reaction", "ending"] and coral_node not in CORAL_NODES) or (coral_mode == "reaction" and coral_node not in CORAL_DECISIONS) or (coral_mode == "ending" and coral_node not in ["F01", "F02", "F03"]):
			return false
		for decision_id in coral.choices:
			if decision_id not in CORAL_DECISIONS or coral.choices[decision_id] not in (["A", "B", "C"] if decision_id == "D1_GATE" else ["A", "B"]):
				return false
		for hint_day in coral.hint_requests:
			if hint_day not in ["1", "2", "3", "4"] or coral.hint_requests[hint_day] not in ["nav", "h1", "h2"]:
				return false
		for companion in coral.companion_states:
			if companion not in ["A", "B", "C"] or typeof(coral.companion_states[companion]) != TYPE_DICTIONARY:
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
	if typeof(saved_modal) != TYPE_STRING or saved_modal not in ["", "phone", "objective", "class", "desktop"] or \
		typeof(saved_hint) not in [TYPE_FLOAT, TYPE_INT] or int(saved_hint) < 0 or int(saved_hint) > 2 or float(saved_hint) != float(int(saved_hint)):
		return false
	for level in [saved_music, saved_effects]:
		if typeof(level) not in [TYPE_INT, TYPE_FLOAT] or int(level) not in [0, 25, 50, 75, 100] or float(level) != float(int(level)):
			return false
	if (not active_dialogue.is_empty() and not saved_modal.is_empty()) or \
		(saved_modal in ["class", "desktop"] and data.get("phase") != "computer") or \
		(saved_modal in ["phone", "objective"] and data.get("phase") not in ["bedroom", "courtyard", "computer", "coral"] and not data.flags.get("draft_exploring", false)):
		return false
	if (active_dialogue == "wakeup" and data.get("phase") != "bedroom") or \
		(active_dialogue == "courtyard" and data.get("phase") != "courtyard") or \
		(active_dialogue == "group_chat" and data.get("phase") != "computer"):
		return false
	if int(step) < 0 or int(step) > 100 or float(step) != float(int(step)) or (not scene.is_empty() and not PREVIEW_SCENES.has(scene)):
		return false
	if scene in ["D1_03_A", "D2_04_A"] and not data.flags.get("draft_mode", false):
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
	if flags.has("draft_intro_step"):
		flags.draft_intro_step = int(flags.draft_intro_step)
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
	coral_state = coral.duplicate(true)
	if phase == "coral" and coral_state.get("version") == "CORAL_STORY_v0.1":
		coral_state.version = CORAL_CONTENT_VERSION
		coral_state.focus = str(coral_state.get("route", ""))
		for decision_id in coral_state.get("choices", {}):
			if str(decision_id).begins_with("D2_") and not coral_state.actions.has("DONE_" + str(decision_id)):
				coral_state.actions.append("DONE_" + str(decision_id))
		if coral_state.mode not in ["ending", "summary"]:
			coral_state.day = mini(int(coral_state.day), 2)
			coral_state.mode = "intro"
			coral_state.node = ""
			coral_state.step = 0
			coral_state.chapter_scene_done = false
			if int(coral_state.day) == 2 and not coral_state.actions.has("D1_LOBBY_DONE"):
				coral_state.actions.append("D1_LOBBY_DONE")
	if coral_state.has("step"):
		coral_state.step = int(coral_state.step)
	if coral_state.has("day"):
		coral_state.day = int(coral_state.day)
	return true
