extends RefCounted

class_name PlayableDraftFlow

const VERSION := "PLAYABLE_DRAFT_v0.3"
const PATH := "res://data/narrative/playable_draft_v0_3.json"
const MAIN_IDS := ["D1_02_A", "D1_03_A", "D2_03_A", "D2_04_A", "D3_01_A", "D4_01_A", "D4_02_A", "D4_03_A"]
const EXPLORATION_IDS := ["D1_02_A", "D2_03_A", "D3_01_A", "D4_01_A"]
const ENDING_IDS := ["F01_A", "F01_B", "F02", "F03"]

var content: Dictionary = {}

func load_draft() -> Array[String]:
	var errors: Array[String] = []
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if typeof(parsed) != TYPE_DICTIONARY:
		return ["JSON de borrador inválido"]
	if parsed.get("schema_version") != 1 or parsed.get("draft_version") != VERSION or parsed.get("provisional") != true or parsed.get("ready_for_publication") != false:
		return ["Metadatos de borrador inválidos"]
	for result in ["victoria", "derrota", "empate"]:
		var reactions: Variant = parsed.get("camila_reactions", {}).get(result, {})
		for role_name in ["Atacante", "Defensor", "Soporte"]:
			if typeof(reactions) != TYPE_DICTIONARY or str(reactions.get(role_name, "")).is_empty():
				errors.append("Falta reacción de Camila: %s/%s" % [result, role_name])
	for scene_id in MAIN_IDS + ENDING_IDS:
		if str(parsed.get("connectors", {}).get(scene_id, "")).is_empty():
			errors.append("Falta conector: " + scene_id)
	for scene_id in EXPLORATION_IDS:
		var introduction: Variant = parsed.get("day_introductions", {}).get(scene_id, [])
		if typeof(introduction) != TYPE_ARRAY or introduction.size() != 2 or str(introduction[0]).is_empty() or str(introduction[1]).is_empty():
			errors.append("Falta presentación del día: " + scene_id)
	for scene_id in MAIN_IDS:
		if scene_id == "D1_03_A":
			continue
		var reactions: Variant = parsed.get("choice_reactions", {}).get(scene_id, {})
		for letter in ["A", "B", "C"]:
			if typeof(reactions) != TYPE_DICTIONARY or str(reactions.get(letter, "")).is_empty():
				errors.append("Falta reacción: %s/%s" % [scene_id, letter])
		if scene_id != "D1_02_A":
			var ids: Dictionary = parsed.get("educational_ids", {}).get(scene_id, {})
			if str(ids.get("decision_id", "")).is_empty():
				errors.append("Falta ID educativo: " + scene_id)
			for letter in ["A", "B", "C"]:
				if str(ids.get("choices", {}).get(letter, "")).is_empty():
					errors.append("Falta ID de opción: %s/%s" % [scene_id, letter])
	var authored: Variant = parsed.get("authored_scene", {})
	if typeof(authored) != TYPE_DICTIONARY or authored.get("scene_id") != "D2_04_A" or authored.get("day") != 2:
		errors.append("Falta escena D2-04")
	else:
		if typeof(authored.get("lines")) != TYPE_ARRAY or authored.lines.is_empty() or typeof(authored.get("choices")) != TYPE_ARRAY or authored.choices.size() != 3:
			errors.append("Contenido D2-04 incompleto")
		else:
			for i in 3:
				if authored.choices[i].get("key") != ["A", "B", "C"][i] or str(authored.choices[i].get("text", "")).is_empty():
					errors.append("Opción D2-04 inválida")
	var private_scene: Variant = parsed.get("d1_private_scene", {})
	if typeof(private_scene) != TYPE_DICTIONARY or private_scene.get("scene_id") != "D1_03_A" or private_scene.get("day") != 1 or typeof(private_scene.get("lines")) != TYPE_ARRAY or private_scene.lines.size() < 6:
		errors.append("Falta conversación privada D1-03")
	for flag_name in ["CONFIANZA_MATEO_SOFI", "RECONOCE_MANIPULACION"]:
		var triggers: Variant = parsed.get("flag_triggers", {}).get(flag_name, [])
		if typeof(triggers) != TYPE_ARRAY or triggers.is_empty():
			errors.append("Faltan activadores: " + flag_name)
		else:
			for trigger in triggers:
				var parts: PackedStringArray = str(trigger).split(":")
				if parts.size() != 2 or not MAIN_IDS.has(parts[0]) or not ["A", "B", "C"].has(parts[1]):
					errors.append("Activador inválido: " + str(trigger))
	if typeof(parsed.get("ending_rules")) != TYPE_ARRAY or parsed.ending_rules.size() != 5:
		errors.append("Tabla de finales incompleta")
	for ending_id in ENDING_IDS:
		if typeof(parsed.get("ending_tail", {}).get(ending_id)) != TYPE_ARRAY or parsed.ending_tail[ending_id].is_empty():
			errors.append("Cierre incompleto: " + ending_id)
	content = parsed if errors.is_empty() else {}
	if errors.is_empty():
		for letter in ["A", "B", "C"]:
			for both in [false, true]:
				var flags: Dictionary = {"D2_04_A": "A", "D3_01_A": "A"} if both else {}
				var expected: String = "F01_A" if letter == "A" or both else "F02" if letter == "B" else "F03"
				if ending_for(letter, flags) != expected:
					errors.append("Tabla de finales contradictoria: " + letter)
	if not errors.is_empty():
		content = {}
	return errors

func camila_reaction(result: String, role_name: String) -> String:
	return str(content.get("camila_reactions", {}).get(result, {}).get(role_name, ""))

func connector(scene_id: String) -> String:
	return str(content.get("connectors", {}).get(scene_id, ""))

func choice_reaction(scene_id: String, letter: String) -> String:
	return str(content.get("choice_reactions", {}).get(scene_id, {}).get(letter, ""))

func educational_ids(scene_id: String, letter: String) -> Dictionary:
	var item: Dictionary = content.get("educational_ids", {}).get(scene_id, {})
	if item.is_empty():
		return {}
	return {"decision_id": str(item.get("decision_id", "")), "choice_id": str(item.get("choices", {}).get(letter, ""))}

func authored_scene() -> Dictionary:
	return content.get("authored_scene", {})

func d1_private_scene() -> Dictionary:
	return content.get("d1_private_scene", {})

func day_introduction(scene_id: String) -> Array:
	return content.get("day_introductions", {}).get(scene_id, [])

func next_main(scene_id: String) -> String:
	var index: int = MAIN_IDS.find(scene_id)
	return MAIN_IDS[index + 1] if index >= 0 and index + 1 < MAIN_IDS.size() else ""

func flags_from_choices(choices: Dictionary) -> Dictionary:
	var result := {"CONFIANZA_MATEO_SOFI": false, "RECONOCE_MANIPULACION": false}
	for flag_name in result:
		for trigger in content.get("flag_triggers", {}).get(flag_name, []):
			var parts: PackedStringArray = str(trigger).split(":")
			if choices.get(parts[0], "") == parts[1]:
				result[flag_name] = true
				break
	return result

func ending_for(letter: String, choices: Dictionary = {}) -> String:
	var flags: Dictionary = flags_from_choices(choices)
	var both: bool = flags.CONFIANZA_MATEO_SOFI and flags.RECONOCE_MANIPULACION
	for rule in content.get("ending_rules", []):
		if rule.get("choice") == letter and (letter == "A" or rule.get("requires_both_flags") == both):
			return str(rule.get("scene", ""))
	return ""

func d3_opening(choices: Dictionary) -> Dictionary:
	return content.get("d3_opening_by_d2_choice", {}).get(str(choices.get("D2_04_A", "")), {})

func extra_after_choice(scene_id: String) -> Array:
	return content.get("d1_after_choice", []) if scene_id == "D1_02_A" else []

func ending_tail(scene_id: String) -> Array:
	return content.get("ending_tail", {}).get(scene_id, [])

func f01_context(last_choice: String) -> String:
	var key: String = "direct" if last_choice == "A" else "mateo_initiative"
	return str(content.get("f01_context", {}).get(key, ""))

func ending_code(scene_id: String) -> String:
	return "F01" if scene_id in ["F01_A", "F01_B"] else scene_id
