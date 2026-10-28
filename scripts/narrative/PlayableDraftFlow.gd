extends RefCounted

class_name PlayableDraftFlow

const VERSION := "PLAYABLE_DRAFT_v0.1"
const PATH := "res://data/narrative/playable_draft_v0_1.json"
const MAIN_IDS := ["D1_02_A", "D2_03_A", "D3_01_A", "D4_01_A", "D4_02_A", "D4_03_A"]
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
	for scene_id in MAIN_IDS:
		var reactions: Variant = parsed.get("choice_reactions", {}).get(scene_id, {})
		for letter in ["A", "B", "C"]:
			if typeof(reactions) != TYPE_DICTIONARY or str(reactions.get(letter, "")).is_empty():
				errors.append("Falta reacción: %s/%s" % [scene_id, letter])
	var endings: Variant = parsed.get("ending_by_last_choice", {})
	if typeof(endings) != TYPE_DICTIONARY or endings.get("A") != "F01_A" or endings.get("B") != "F02" or endings.get("C") != "F03":
		errors.append("Reglas provisionales de finales inválidas")
	content = parsed if errors.is_empty() else {}
	return errors

func camila_reaction(result: String, role_name: String) -> String:
	return str(content.get("camila_reactions", {}).get(result, {}).get(role_name, ""))

func connector(scene_id: String) -> String:
	return str(content.get("connectors", {}).get(scene_id, ""))

func choice_reaction(scene_id: String, letter: String) -> String:
	return str(content.get("choice_reactions", {}).get(scene_id, {}).get(letter, ""))

func ending_for(letter: String) -> String:
	return str(content.get("ending_by_last_choice", {}).get(letter, ""))

func ending_code(scene_id: String) -> String:
	return "F01" if scene_id in ["F01_A", "F01_B"] else scene_id
