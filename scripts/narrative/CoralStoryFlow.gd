extends RefCounted
class_name CoralStoryFlow

const VERSION := "CORAL_STORY_v0.2"
const PATH := "res://data/narrative/coral_story_v0_2.json"
const ROUTES := ["A", "B", "C"]
const D2_FACTS := {"A": "camila_request_shared", "B": "mateo_secret_shared", "C": "sebas_fatigue_observed"}
# Clasificación descriptiva de cada respuesta (sin puntaje): protectora, límite o de riesgo.
const CHOICE_BEHAVIOR := {
	"D1_GATE": {"A": "protectora", "B": "protectora", "C": "riesgo"},
	"D2_A": {"A": "protectora", "B": "riesgo"}, "D2_B": {"A": "protectora", "B": "riesgo"}, "D2_C": {"A": "protectora", "B": "riesgo"},
	"D4_A1": {"A": "protectora", "B": "limite"}, "D4_B1": {"A": "protectora", "B": "limite"}, "D4_C1": {"A": "protectora", "B": "limite"},
	"D4_A2": {"A": "protectora", "B": "riesgo"}, "D4_B2": {"A": "protectora", "B": "riesgo"}, "D4_C2": {"A": "protectora", "B": "riesgo"}}
const BEHAVIOR_LABELS := {"protectora": "Protectora", "limite": "Protectora con límite", "riesgo": "De riesgo"}
const DECISION_NAMES := {"D1_GATE": "D1 · El nuevo jugador", "D2_A": "Recreo D2 · Confidencia de Camila", "D2_B": "Recreo D2 · Regalo de Mateo", "D2_C": "Recreo D2 · Cansancio de Sebas",
	"D4_A1": "D4 · Plan con Camila", "D4_A2": "D4 · Reparar con Camila", "D4_B1": "D4 · Presión sobre Mateo", "D4_B2": "D4 · Retomar con Mateo", "D4_C1": "D4 · Apoyo para Sebas", "D4_C2": "D4 · Rectificar con Bruno"}
const DECISION_ADVICE := {
	"D1_GATE": "Piensa si tu respuesta deja que Mateo elija cuándo jugar y con quién hablar. Escuchar o acordar límites con el grupo protege; restar importancia puede dejarlo solo.",
	"D2_A": "Camila te contó algo en confianza. Pregúntate si ella decidió qué compartir y con quién. Una confidencia no se difunde sin permiso.",
	"D2_B": "Un regalo que llega con una petición de secreto merece atención. Puedes escuchar a Mateo sin exigir pruebas ni minimizar lo que siente.",
	"D2_C": "El cansancio de Sebas puede tener muchas causas. Una burla corta la conversación; escuchar sin acusar le da espacio para contar lo que quiera.",
	"D4_A1": "Ambas opciones protegen: pedir apoyo a un adulto de confianza o ajustar privacidad con permiso. Elige el paso que Mateo pueda dar hoy.",
	"D4_B1": "Mateo decide qué contar. Acompañarlo a tutoría o revisar bloqueo y privacidad con su permiso son pasos de protección.",
	"D4_C1": "Pedir apoyo adulto y acordar un límite de contacto ayudan. Ninguna opción exige reunir pruebas.",
	"D4_A2": "Reconocer un error y ofrecer acompañamiento ayuda a reparar. Esperar sin hacer nada deja el problema abierto.",
	"D4_B2": "Todavía puedes cambiar tu respuesta: retomar la conversación con Mateo y buscar apoyo es mejor que dejarlo para después.",
	"D4_C2": "Una disculpa sin exigir perdón y la invitación a buscar apoyo pueden reparar al grupo. Esperar a que se arregle solo rara vez funciona."}

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
		"route": "", "branch": "", "focus": "", "choices": {}, "companion_states": {}, "actions": [], "observed": [],
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
		if scene_id == "I_TUTOR" and state.get("observed", []).is_empty():
			return {"day": int(state.get("day", 1)), "title": "Conocer tutoría", "presentation": "vn", "actor": "Tutor", "lines": [{"speaker": "Tutor", "text": "Este espacio está abierto si quieren conversar sobre algo del colegio, del grupo o de internet. Pueden volver cuando necesiten hablar."}, {"speaker": "Tutor", "text": tutor_tip(state)}], "choices": []}
		var key: String = "TUTOR" if scene_id == "I_TUTOR" else "LIMIT"
		var interaction: Dictionary = content.get("interactions", {}).get(key, {})
		var lines: Array = []
		if scene_id == "I_TUTOR":
			var reason: String = "Nos preocupa algo que pasó en el grupo y queremos hablarlo con alguien de confianza."
			if state.get("observed", []).has("mateo_secret_shared"): reason = "Mateo me contó que un regalo vino con una petición de secreto que lo incomoda. Quiere ayuda para decidir qué hacer."
			elif state.get("observed", []).has("camila_request_shared"): reason = "Camila recibió preguntas sobre los horarios de Mateo. Le incomodó y quiere decidir qué compartir antes de hablarlo."
			elif state.get("observed", []).has("sebas_fatigue_observed"): reason = "Sebas siente que debe conectarse para no perder la ayuda de alguien. Queremos hablar de esa preocupación."
			lines.append({"speaker": "Sofi", "text": reason})
		for text_line in interaction.get("lines", []):
			lines.append({"speaker": interaction.get("speaker", "Narrador"), "text": text_line})
		if scene_id == "I_TUTOR": lines.append({"speaker": "Tutor", "text": tutor_tip(state)})
		return {"day": int(state.get("day", 1)), "title": "Pedir apoyo" if key == "TUTOR" else "Marcar un límite", "presentation": "vn", "actor": "Tutor" if key == "TUTOR" else "", "lines": lines, "choices": []}
	if scene_id == "N_D2":
		return {"day": 2, "title": "Lo que Sofi observó", "presentation": "vn", "lines": [{"speaker": "Narrador", "text": content.get("narrator_after_d2", {}).get(state.get("focus", "A"), "")}], "choices": []}
	if scene_id.begins_with("F0"):
		var ending_lines: Array = content.get("ending_lines", {}).get(scene_id, []).duplicate(true)
		for companion in ["A", "B", "C"]:
			var branch: String = companion + ("1" if state.get("choices", {}).get("D2_" + companion, "A") == "A" else "2")
			var epilogue: Dictionary = content.get("epilogue_by_branch", {}).get(branch, {})
			if not epilogue.is_empty(): ending_lines.append(epilogue)
		ending_lines.append({"speaker": "Bruno", "text": "Seguiré invitándolos sin exigir explicaciones. Podemos cuidar nuestra amistad y respetar el espacio de cada uno."})
		ending_lines.append_array(closing_lines(state))
		return {"day": 4, "title": "Después de lo vivido", "presentation": "vn", "lines": ending_lines, "choices": []}
	var authored: Dictionary = content.get("scenes", {}).get(scene_id, {}).duplicate(true)
	var lines: Array = []
	for source_id in authored.get("source_scenes", []):
		var source_scene: Dictionary = draft.authored_scene() if source_id == "D2_04_A" else recovered.get_scene(str(source_id))
		lines.append_array(source_scene.get("lines", []))
	lines.append_array(authored.get("lines", []))
	authored.lines = lines
	return authored

func closing_lines(state: Dictionary) -> Array:
	var result: Array = []
	var choices: Dictionary = state.get("choices", {})
	var reflections := {
		"D2_A": {"A": "Respetaste lo que Camila quería compartir. Escuchar una confidencia no da permiso para difundirla.", "B": "Avisaste al grupo sin permiso de Camila. Querer ayudar también requiere cuidar su voz; reconocer el error permite empezar a reparar."},
		"D2_B": {"A": "Escuchaste la presión que Mateo sentía junto al regalo. Aceptar ayuda o una skin no obliga a guardar secretos ni a corresponder.", "B": "Al principio restaste importancia al secreto de Mateo. Volver a escuchar y tomar en serio su incomodidad permite cambiar la respuesta."},
		"D2_C": {"A": "Dejaste que Sebas explicara cómo se sentía. El cansancio no prueba una causa por sí solo; escuchar ayuda a conocer lo que quiere contar.", "B": "La broma hizo que Sebas dejara de hablar. Ofrecer una disculpa sin exigir perdón y escuchar de nuevo puede abrir otra conversación."}}
	for text_line in content.get("closing_common", []):
		result.append({"speaker": "Narrador", "text": str(text_line)})
	for id in ["D2_A", "D2_B", "D2_C"]:
		if choices.has(id): result.append({"speaker": "Narrador", "text": reflections[id].get(str(choices[id]), "")})
	return result

func companion_scene(state: Dictionary, person: String) -> String:
	var day: int = int(state.get("day", 1))
	var choices: Dictionary = state.get("choices", {})
	if day == 1: return "I_D1_" + person.to_upper()
	if day == 2: return {"camila": "D2_A", "mateo": "D2_B", "sebas": "D2_C", "bruno": "I_D2_BRUNO"}.get(person, "")
	var a: String = "1" if choices.get("D2_A", "A") == "A" else "2"
	var b: String = "1" if choices.get("D2_B", "A") == "A" else "2"
	var c: String = "1" if choices.get("D2_C", "A") == "A" else "2"
	if day == 3:
		return {"camila": "D3_A" + a, "mateo": "D3_B" + b, "sebas": "D3_C1" if c == "1" else "I_D3_SEBAS", "bruno": "I_D3_BRUNO" if c == "1" else "D3_C2"}.get(person, "")
	return {"camila": "D4_A" + a, "mateo": "D4_B" + b, "sebas": "D4_C1", "bruno": "I_D4_BRUNO" if c == "1" else "D4_C2"}.get(person, "")

func talked_today(state: Dictionary, person: String) -> bool:
	if int(state.get("day", 1)) == 1:
		return state.get("actions", []).has("D1_TALK_" + person.to_upper())
	return state.get("actions", []).has("DONE_" + companion_scene(state, person))

func everyone_heard(state: Dictionary) -> bool:
	for person in ["camila", "mateo", "sebas", "bruno"]:
		if not talked_today(state, person): return false
	return true

func route_target(state: Dictionary) -> String:
	for person in ["camila", "mateo", "sebas", "bruno"]:
		if not talked_today(state, person): return person
	if int(state.get("day", 1)) == 1 and not state.get("actions", []).has("D1_LOBBY_DONE"): return "lobby"
	return "salida"

func world_key(state: Dictionary) -> String:
	return {1: "draft_d1", 2: "draft_d2", 3: "draft_d3", 4: "draft_d4"}.get(int(state.get("day", 1)), "draft_d4")

func objective(state: Dictionary) -> String:
	if state.get("mode") == "intro": return "Escucha al narrador"
	if state.get("mode") == "summary": return "Historia concluida"
	if state.get("mode") in ["scene", "reaction", "ending"]: return "Continúa la conversación"
	var total: int = 0
	for person in ["camila", "mateo", "sebas", "bruno"]:
		if talked_today(state, person): total += 1
	if total < 4: return "Conversa con tus compañeros (%d/4)" % total
	if int(state.get("day", 1)) == 1 and not state.get("actions", []).has("D1_LOBBY_DONE"): return "Entra al lobby para preparar la partida"
	if int(state.get("day", 1)) == 4:
		if state.get("actions", []).has("SUPPORT_PLANNED") and not state.get("adult_support_started", false): return "Acordaron pedir apoyo: ve a tutoría y habla con el tutor"
		if state.get("actions", []).has("LIMIT_PLANNED") and not state.get("limit_completed", false): return "Acordaron un límite: revisa bloqueo y privacidad en la PC"
		return "Busca apoyo o revisa bloqueo y privacidad en la PC; después ve a la salida"
	return "Ve a la salida para cerrar la jornada"

func navigation_hint(state: Dictionary) -> String:
	return "Los cuatro compañeros están en el escenario. Puedes hablarles en cualquier orden. La salida cierra la jornada cuando termines; tutoría está a la izquierda."

func educational_hint(state: Dictionary, level: int) -> String:
	var day: int = int(state.get("day", 1))
	if day == 1:
		return "¿Mateo puede escoger cuándo jugar y con quién hablar sin sentirse obligado?" if level == 1 else "La atención o los halagos no crean una obligación. Observa si se respeta un no y el contacto con otras amistades."
	if day == 2:
		var route: String = str(state.get("focus", ""))
		if not state.get("observed", []).has(D2_FACTS.get(route, "")):
			return "¿Qué ha observado Sofi realmente? Escucha primero sin suponer qué mensajes recibió cada compañero." if level == 1 else "Un regalo o el cansancio aislados no demuestran abuso. Puedes ofrecer apoyo sin investigar ni pedir pruebas."
		if route == "A": return "¿Qué eligió contar Camila y qué pidió que no se compartiera?" if level == 1 else "Escuchar una confidencia no da permiso para publicarla ni compartir horarios de otras personas."
		if route == "B": return "¿Qué condición apareció junto al regalo que Mateo quería?" if level == 1 else "Un regalo no obliga a guardar un secreto incómodo ni a corresponder; Mateo decide qué mostrar."
		return "¿Qué dice Sebas sobre su horario y cómo se siente?" if level == 1 else "El cansancio puede tener muchas causas. Escuchar sin acusar permite conocer lo que Sebas quiera contar."
	if day == 3:
		return "¿Qué teme perder tu compañero si dice que no?" if level == 1 else "Pedir apoyo no traiciona una amistad. No necesitas reunir pruebas ni exigir un relato completo."
	return "¿Qué paso concreto pueden iniciar hoy sin ir al encuentro?" if level == 1 else "La presión también puede ocurrir en línea. No hay que responder, pagar ni demostrar nada para pedir apoyo."

func decision_advice(scene_id: String) -> String:
	return str(DECISION_ADVICE.get(scene_id, "Piensa qué respuesta respeta lo que tu compañero decide contar y abre la puerta a pedir apoyo."))

func tutor_tip(state: Dictionary) -> String:
	# Consejo del día para quien no sabe qué hacer; no decide por el jugador.
	return "Un consejo: " + educational_hint(state, 2)

func behavior_profile(state: Dictionary) -> Dictionary:
	var counts := {"protectora": 0, "limite": 0, "riesgo": 0}
	var details: Array = []
	var choices: Dictionary = state.get("choices", {})
	for decision_id in CHOICE_BEHAVIOR:
		if not choices.has(decision_id): continue
		var kind: String = str(CHOICE_BEHAVIOR[decision_id].get(str(choices[decision_id]), ""))
		if kind.is_empty(): continue
		counts[kind] += 1
		details.append({"decision": decision_id, "name": DECISION_NAMES.get(decision_id, decision_id), "kind": kind, "label": BEHAVIOR_LABELS[kind]})
	var total: int = counts.protectora + counts.limite + counts.riesgo
	var protective: float = float(counts.protectora + counts.limite) / float(maxi(total, 1))
	var label: String = "Sin decisiones aún" if total == 0 else "Protectora" if protective >= 0.75 else "En aprendizaje" if protective >= 0.4 else "De riesgo"
	return {"label": label, "counts": counts, "total": total, "details": details, "unrepaired_recess": unrepaired_recess(state)}

func unrepaired_recess(state: Dictionary) -> int:
	# Respuestas de riesgo en el recreo (D2) que no se repararon en D4.
	var choices: Dictionary = state.get("choices", {})
	var total: int = 0
	for companion in ROUTES:
		if choices.get("D2_" + companion, "") == "B" and choices.get("D4_%s2" % companion, "") != "A": total += 1
	return total

func ending_for(state: Dictionary) -> String:
	# Pedir apoyo adulto nunca se bloquea por respuestas anteriores.
	if state.get("adult_support_started", false): return "F01"
	# Un límite solo sostiene al grupo si la confianza del recreo no quedó rota.
	if state.get("limit_completed", false) and unrepaired_recess(state) < 2: return "F02"
	return "F03"
