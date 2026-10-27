extends RefCounted
class_name RecoveredPreviewCatalog

const VERSION := "RECOVERED_PREVIEW_D0_D4_v0.2"
const MAIN_ORDER := ["D1_02_A", "D2_03_A", "D3_01_A", "D4_01_A", "D4_02_A", "D4_03_A"]
const ENDING_ORDER := ["F01_A", "F01_B", "F02", "F03"]
const FILES := [
	"res://data/narrative/day_1_RECOVERED_PREVIEW.json",
	"res://data/narrative/day_2_RECOVERED_PREVIEW.json",
	"res://data/narrative/day_3_RECOVERED_PREVIEW.json",
	"res://data/narrative/day_4_RECOVERED_PREVIEW.json",
	"res://data/narrative/endings_RECOVERED_PREVIEW.json"
]

var scenes: Dictionary = {}

func load_catalog() -> Array[String]:
	var errors: Array[String] = []
	scenes.clear()
	for path in FILES:
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if typeof(parsed) != TYPE_DICTIONARY:
			errors.append("JSON de vista previa inválido: " + path)
			continue
		if parsed.get("schema_version") != 1 or parsed.get("preview_version") != VERSION or \
			parsed.get("provisional") != true or parsed.get("ready_for_publication") != false:
			errors.append("Versión o marca provisional inválida: " + path)
			continue
		if typeof(parsed.get("scenes")) != TYPE_ARRAY:
			errors.append("Lista de escenas inválida: " + path)
			continue
		for scene in parsed.scenes:
			if typeof(scene) != TYPE_DICTIONARY:
				errors.append("Escena inválida: " + path)
				continue
			var scene_id: String = str(scene.get("scene_id", ""))
			if scene_id.is_empty() or scenes.has(scene_id):
				errors.append("ID de vista previa ausente o duplicado: " + scene_id)
				continue
			if not MAIN_ORDER.has(scene_id) and not ENDING_ORDER.has(scene_id):
				errors.append("Escena no declarada: " + scene_id)
				continue
			if typeof(scene.get("lines")) != TYPE_ARRAY or scene.lines.is_empty():
				errors.append("Líneas ausentes: " + scene_id)
				continue
			for field in ["lines", "after_choice", "unplaced_lines", "later_chat"]:
				if scene.has(field):
					if typeof(scene[field]) != TYPE_ARRAY:
						errors.append("Lista inválida en " + scene_id + ": " + field)
						continue
					for line in scene[field]:
						if typeof(line) != TYPE_DICTIONARY or str(line.get("speaker", "")).is_empty() or str(line.get("text", "")).is_empty():
							errors.append("Parlamento inválido en " + scene_id)
			var choices: Variant = scene.get("choices", [])
			if typeof(choices) != TYPE_ARRAY:
				errors.append("Opciones inválidas en " + scene_id)
			elif not choices.is_empty():
				if choices.size() != 3:
					errors.append("La vista previa exige opciones A/B/C en " + scene_id)
				else:
					for i in 3:
						if typeof(choices[i]) != TYPE_DICTIONARY or choices[i].get("key") != ["A", "B", "C"][i] or str(choices[i].get("text", "")).is_empty():
							errors.append("Opción inválida en " + scene_id)
			scenes[scene_id] = scene
	for scene_id in MAIN_ORDER + ENDING_ORDER:
		if not scenes.has(scene_id):
			errors.append("Falta fragmento: " + scene_id)
	if not errors.is_empty():
		scenes.clear()
	return errors

func get_scene(scene_id: String) -> Dictionary:
	return scenes.get(scene_id, {})

func next_main(scene_id: String) -> String:
	var index := MAIN_ORDER.find(scene_id)
	if index < 0 or index + 1 >= MAIN_ORDER.size():
		return ""
	return MAIN_ORDER[index + 1]
