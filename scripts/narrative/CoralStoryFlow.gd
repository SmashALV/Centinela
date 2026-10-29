extends RefCounted
class_name CoralStoryFlow

const VERSION := "CORAL_STORY_v0.1"
const PATH := "res://data/narrative/coral_story_v0_1.json"
const ROUTES := ["A", "B", "C"]
const D2_FACTS := {"A": "camila_request_shared", "B": "mateo_secret_shared", "C": "sebas_fatigue_observed"}

var content: Dictionary = {}

func load_story() -> Array[String]:
	var errors: Array[String] = []
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if typeof(parsed) != TYPE_DICTIONARY:
		return ["Guion coral inválido"]
	if parsed.get("version") != VERSION or parsed.get("provisional") != true or parsed.get("ready_for_publication") != false:
		errors.append("Metadatos de guion coral inválidos")
	var expected: Array[String] = ["D1_GATE", "D2_A", "D2_B", "D2_C", "D4_A1", "D4_A2", "D4_B1", "D4_B2", "D4_C1", "D4_C2"]
	if parsed.get("decision_ids", []) != expected:
		errors.append("Las diez decisiones principales no coinciden")
	for day in [1, 2, 3, 4]:
		var intro: Variant = parsed.get("day_intros", {}).get(str(day), [])
		if typeof(intro) != TYPE_ARRAY or intro.size() != 2:
			errors.append("Introducción incompleta para Día %d" % day)
	for scene_id in expected:
		var scene: Variant = parsed.get("scenes", {}).get(scene_id, {})
		if typeof(scene) != TYPE_DICTIONARY or scene.get("choices", []).size() != (3 if scene_id == "D1_GATE" else 2):
			errors.append("Decisión incompleta: " + scene_id)
		elif not parsed.get("reactions", {}).has(scene_id):
			errors.append("Faltan reacciones: " + scene_id)
	for route in ROUTES:
		if not parsed.get("scenes", {}).has("D1_%s_FOLLOW" % route):
			errors.append("Falta consecuencia del Día 1: " + route)
		for branch in ["1", "2"]:
			if not parsed.get("scenes", {}).has("D3_%s%s" % [route, branch]):
				errors.append("Falta desarrollo de Día 3: " + route + branch)
			if not parsed.get("epilogue_by_branch", {}).has(route + branch):
				errors.append("Falta epílogo de rama: " + route + branch)
	for scene_id in parsed.get("scenes", {}):
		var item: Variant = parsed.scenes[scene_id]
		if typeof(item) != TYPE_DICTIONARY or typeof(item.get("lines", [])) != TYPE_ARRAY or typeof(item.get("source_scenes", [])) != TYPE_ARRAY:
			errors.append("Estructura de escena inválida: " + str(scene_id))
			continue
		if item.get("lines", []).is_empty() and item.get("source_scenes", []).is_empty():
			errors.append("Escena sin contenido: " + str(scene_id))
		for line in item.get("lines", []):
			if typeof(line) != TYPE_DICTIONARY or str(line.get("speaker", "")).is_empty() or str(line.get("text", "")).is_empty():
				errors.append("Parlamento inválido en " + str(scene_id))
		for source_id in item.get("source_scenes", []):
			if source_id not in ["D1_02_A", "D1_03_A", "D2_03_A", "D2_04_A", "D3_01_A", "D4_01_A", "D4_02_A", "D4_03_A"]:
				errors.append("Fuente recuperada desconocida: " + str(source_id))
		for choice in item.get("choices", []):
			if typeof(choice) != TYPE_DICTIONARY or choice.get("key") not in ["A", "B", "C"] or str(choice.get("text", "")).is_empty():
				errors.append("Opción inválida en " + str(scene_id))
	for ending_id in ["F01", "F02", "F03"]:
		if typeof(parsed.get("ending_lines", {}).get(ending_id)) != TYPE_ARRAY or parsed.ending_lines[ending_id].is_empty():
			errors.append("Falta final: " + ending_id)
	if not errors.is_empty():
		return errors
	content = parsed
	return []

func new_state() -> Dictionary:
	return {"version": VERSION, "day": 1, "mode": "intro", "node": "", "step": 0,
		"route": "", "branch": "", "choices": {}, "companion_states": {}, "actions": [], "observed": [],
		"seen_narrator": [], "hint_requests": {}, "adult_support_started": false,
		"limit_completed": false, "chapter_scene_done": false, "ending": ""}

func scene(scene_id: String, recovered: Object, draft: Object, state: Dictionary) -> Dictionary:
	if scene_id.begins_with("I_D1_"):
		var interaction: Dictionary = content.get("interactions", {}).get(scene_id.trim_prefix("I_"), {})
		var lines: Array = []
		for text_line in interaction.get("lines", []):
			lines.append({"speaker": interaction.get("speaker", "Narrador"), "text": text_line})
		return {"day": 1, "title": "Conocer al grupo", "presentation": "vn", "lines": lines, "choices": []}
	if scene_id == "I_TUTOR" or scene_id == "I_LIMIT":
		var key: String = "TUTOR" if scene_id == "I_TUTOR" else "LIMIT"
		var interaction: Dictionary = content.get("interactions", {}).get(key, {})
		var lines: Array = []
		for text_line in interaction.get("lines", []):
			lines.append({"speaker": interaction.get("speaker", "Narrador"), "text": text_line})
		return {"day": int(state.get("day", 1)), "title": "Pedir apoyo" if key == "TUTOR" else "Marcar un límite", "presentation": "vn", "lines": lines, "choices": []}
	if scene_id == "N_D2":
		return {"day": 2, "title": "Lo que Sofi observó", "presentation": "vn", "lines": [{"speaker": "Narrador", "text": content.get("narrator_after_d2", {}).get(state.get("route", ""), "")}], "choices": []}
	if scene_id.begins_with("F0"):
		var ending_lines: Array = content.get("ending_lines", {}).get(scene_id, []).duplicate(true)
		ending_lines.append_array(content.get("epilogue_by_route", {}).get(state.get("route", ""), []))
		var branch_epilogue: Dictionary = content.get("epilogue_by_branch", {}).get(state.get("branch", ""), {})
		if not branch_epilogue.is_empty(): ending_lines.append(branch_epilogue)
		if str(state.get("branch", "")).ends_with("2"):
			ending_lines.append(content.get("repair_epilogue", {}))
		return {"day": 4, "title": "Epílogo " + scene_id, "presentation": "vn", "lines": ending_lines, "choices": []}
	var authored: Dictionary = content.get("scenes", {}).get(scene_id, {}).duplicate(true)
	var lines: Array = []
	for source_id in authored.get("source_scenes", []):
		var source_scene: Dictionary = draft.authored_scene() if source_id == "D2_04_A" else recovered.get_scene(str(source_id))
		lines.append_array(source_scene.get("lines", []))
	lines.append_array(authored.get("lines", []))
	authored.lines = lines
	return authored

func route_target(state: Dictionary) -> String:
	if int(state.get("day", 1)) == 1:
		return "lobby"
	var route: String = str(state.get("route", ""))
	if route == "A": return "camila"
	if route == "B": return "mateo"
	return "sebas" if str(state.get("branch", "")) != "C2" or int(state.get("day", 1)) == 2 else "bruno"

func world_key(state: Dictionary) -> String:
	var day: int = int(state.get("day", 1))
	if day == 1: return "draft_d1"
	if day == 2: return "draft_d2"
	if day == 4 and state.get("chapter_scene_done", false): return "draft_d4"
	var scene_id: String = "D%d_%s" % [day, str(state.get("branch", ""))]
	var place: String = str(content.get("scenes", {}).get(scene_id, {}).get("place", "patio"))
	if place == "habitación": return "bedroom"
	if place == "pasillo": return "draft_d3"
	if place in ["árbol", "banco", "exterior"]: return "draft_d2"
	return "draft_d4"

func objective(state: Dictionary) -> String:
	var day: int = int(state.get("day", 1))
	if state.get("mode") == "intro": return "Escucha al narrador"
	if state.get("mode") == "summary": return "Historia concluida"
	if state.get("mode") in ["scene", "reaction", "ending"]: return "Continúa la conversación"
	if day == 1:
		var talks: int = 0
		for action in state.get("actions", []):
			if str(action).begins_with("D1_TALK_"): talks += 1
		return "Habla con dos compañeros (%d/2); después usa el lobby" % mini(talks, 2)
	if day == 4 and state.get("chapter_scene_done", false):
		return "Inicia apoyo en tutoría, completa un límite en la PC o ve a la salida"
	return "Busca a %s y escucha su conversación" % route_target(state).capitalize()

func navigation_hint(state: Dictionary) -> String:
	var day: int = int(state.get("day", 1))
	if day == 1: return "Habla con dos amigos marcados. Después usa el lobby a la derecha del patio."
	if day == 4 and state.get("chapter_scene_done", false): return "Tutoría está a la izquierda, la PC a la derecha y la salida abajo."
	return "Acércate a %s y pulsa F. Tutoría está disponible a la izquierda." % route_target(state).capitalize()

func educational_hint(state: Dictionary, level: int) -> String:
	var day: int = int(state.get("day", 1))
	if day == 1:
		return "¿Mateo puede escoger cuándo jugar y con quién hablar sin sentirse obligado?" if level == 1 else "La atención o los halagos no crean una obligación. Observa si se respeta un no y el contacto con otras amistades."
	if day == 2:
		var route: String = str(state.get("route", ""))
		if not state.get("observed", []).has(D2_FACTS.get(route, "")):
			return "¿Qué ha observado Sofi realmente? Escucha primero sin suponer qué mensajes recibió cada compañero." if level == 1 else "Un regalo o el cansancio aislados no demuestran abuso. Puedes ofrecer apoyo sin investigar ni pedir pruebas."
		if route == "A": return "¿Qué eligió contar Camila y qué pidió que no se compartiera?" if level == 1 else "Escuchar una confidencia no da permiso para publicarla ni compartir horarios de otras personas."
		if route == "B": return "¿Qué condición apareció junto al regalo que Mateo quería?" if level == 1 else "Un regalo no obliga a guardar un secreto incómodo ni a corresponder; Mateo decide qué mostrar."
		return "¿Qué dice Sebas sobre su horario y cómo se siente?" if level == 1 else "El cansancio puede tener muchas causas. Escuchar sin acusar permite conocer lo que Sebas quiera contar."
	if day == 3:
		return "¿Qué teme perder tu compañero si dice que no?" if level == 1 else "Pedir apoyo no traiciona una amistad. No necesitas reunir pruebas ni exigir un relato completo."
	return "¿Qué paso concreto pueden iniciar hoy sin ir al encuentro?" if level == 1 else "La presión también puede ocurrir en línea. No hay que responder, pagar ni demostrar nada para pedir apoyo."

func ending_for(state: Dictionary) -> String:
	if state.get("adult_support_started", false): return "F01"
	if state.get("limit_completed", false): return "F02"
	return "F03"
