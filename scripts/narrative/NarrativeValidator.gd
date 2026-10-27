extends RefCounted
class_name NarrativeValidator

const KNOWN_VARIABLES := ["CONFIANZA_MATEO_SOFI", "RECONOCE_MANIPULACION"]
const VALID_ENDINGS := ["F01", "F02", "F03"]

static func validate(data: Dictionary, require_canonical: bool = false) -> Array[String]:
	var errors: Array[String] = []
	if data.get("schema_version") != 1:
		errors.append("schema_version debe ser 1")
	if require_canonical and (data.get("test_only", false) or data.get("provisional", false) or not data.get("ready_for_publication", false)):
		errors.append("Contenido provisional o TEST_ONLY no puede publicarse")
	var nodes: Variant = data.get("nodes")
	if typeof(nodes) != TYPE_ARRAY or nodes.is_empty():
		errors.append("nodes debe ser un array no vacío")
		return errors
	var entry_points: Variant = data.get("entry_points", {})
	if typeof(entry_points) != TYPE_DICTIONARY:
		errors.append("entry_points inválido")
	else:
		for key in entry_points:
			var value: Variant = entry_points[key]
			if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT or int(value) < 0 or int(value) >= nodes.size():
				errors.append("Entrada inválida: " + str(key))
	var decisions := {}
	for i in nodes.size():
		var node: Variant = nodes[i]
		if typeof(node) != TYPE_DICTIONARY:
			errors.append("Nodo %d inválido" % i)
			continue
		if int(node.get("position", -1)) != i:
			errors.append("Posición %d fuera de secuencia" % i)
		var next: Variant = node.get("next", null)
		if next != null and (typeof(next) != TYPE_FLOAT and typeof(next) != TYPE_INT or int(next) < 0 or int(next) >= nodes.size()):
			errors.append("Destino inválido en %d" % i)
		for condition in node.get("conditions", []):
			if typeof(condition) != TYPE_DICTIONARY or not KNOWN_VARIABLES.has(condition.get("variable", "")):
				errors.append("Variable desconocida en %d" % i)
		var choices: Variant = node.get("choices", [])
		if typeof(choices) != TYPE_ARRAY:
			errors.append("Opciones inválidas en %d" % i)
			continue
		if choices.size() > 0:
			var decision_id: String = str(node.get("decision_id", ""))
			if decision_id.is_empty():
				errors.append("Falta decision_id en %d" % i)
			elif decisions.has(decision_id):
				errors.append("decision_id duplicado: " + decision_id)
			decisions[decision_id] = true
			var choice_ids := {}
			for choice in choices:
				if typeof(choice) != TYPE_DICTIONARY:
					errors.append("Opción inválida en %d" % i)
					continue
				var target: Variant = choice.get("next", null)
				if typeof(target) != TYPE_FLOAT and typeof(target) != TYPE_INT or int(target) < 0 or int(target) >= nodes.size():
					errors.append("Destino de opción inválido en %d" % i)
				var choice_id: String = str(choice.get("choice_id", ""))
				if choice_id.is_empty() or choice_ids.has(choice_id):
					errors.append("choice_id ausente o duplicado en %d" % i)
				choice_ids[choice_id] = true
		if node.has("ending") and not VALID_ENDINGS.has(node.ending):
			errors.append("Final inválido en %d" % i)
	return errors
