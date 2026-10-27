extends RefCounted
class_name NarrativeManager

const Validator = preload("res://scripts/narrative/NarrativeValidator.gd")

var data: Dictionary = {}
var position: int = 0

func load_story(path: String, allow_test_content: bool = false) -> Array[String]:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_DICTIONARY:
		return ["JSON narrativo inválido: " + path]
	var errors: Array[String] = Validator.validate(parsed, not allow_test_content)
	if errors.is_empty():
		data = parsed
		position = 0
	return errors

func current_node() -> Dictionary:
	if data.is_empty() or position < 0 or position >= data.nodes.size():
		return {}
	return data.nodes[position]

func start_at(key: String) -> bool:
	if data.is_empty() or not data.get("entry_points", {}).has(key):
		return false
	var target: int = int(data.entry_points[key])
	if target < 0 or target >= data.nodes.size():
		return false
	position = target
	return true

func advance(choice_id: String = "") -> bool:
	var node := current_node()
	if node.is_empty():
		return false
	var target: Variant = node.get("next", null)
	if node.get("choices", []).size() > 0:
		target = null
		for choice in node.choices:
			if choice.choice_id == choice_id:
				target = choice.next
				break
	if target == null:
		return false
	position = int(target)
	return true
