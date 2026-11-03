extends RefCounted
## Textos de las escenas de la rutina diaria (despertar, desayuno, clase, despedida, cena,
## chat de la noche y reacción tras la partida). Los textos viven en data/routine/scenes.json;
## este módulo solo los lee y elige la versión del día.

const PATH := "res://data/routine/scenes.json"
const VERSION := "ROUTINE_SCENES_v1"
const DAYS := 5

static var _scenes: Dictionary = {}


## Escenas cargadas desde el JSON (se leen una sola vez).
static func scenes() -> Dictionary:
	if _scenes.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		if typeof(parsed) == TYPE_DICTIONARY and parsed.get("version") == VERSION:
			_scenes = parsed.get("scenes", {})
		else:
			push_error("Textos de la rutina inválidos: " + PATH)
	return _scenes


## Parlamentos de una escena para un día. `tokens` reemplaza marcadores como {camila_reaction}.
static func scene_lines(scene: String, day: int, tokens: Dictionary = {}) -> Array:
	var result: Array = []
	for line in scenes().get(scene, []):
		var text: String = text_for_day(line.get("text", ""), day)
		if not tokens.is_empty(): text = text.format(tokens)
		result.append({"speaker": str(line.get("speaker", "")), "text": text})
	return result


## Un texto puede ser único o una lista con una versión por día (0 a 4).
static func text_for_day(text: Variant, day: int) -> String:
	if typeof(text) == TYPE_ARRAY: return str(text[clampi(day, 0, text.size() - 1)])
	return str(text)


## Errores de estructura del JSON (vacío si todo está bien). Lo usan las pruebas.
static func validate() -> Array[String]:
	var errors: Array[String] = []
	for scene in ["wake", "breakfast", "lesson", "goodbye", "dinner", "evening_chat", "match_reply"]:
		var lines: Variant = scenes().get(scene)
		if typeof(lines) != TYPE_ARRAY or lines.is_empty():
			errors.append("Falta la escena " + scene)
			continue
		for line in lines:
			if typeof(line) != TYPE_DICTIONARY or str(line.get("speaker", "")).is_empty():
				errors.append("Parlamento sin hablante en " + scene)
			elif typeof(line.get("text")) == TYPE_ARRAY and line.text.size() != DAYS:
				errors.append("Texto por día incompleto en " + scene)
			elif typeof(line.get("text")) not in [TYPE_STRING, TYPE_ARRAY]:
				errors.append("Texto inválido en " + scene)
	return errors
