extends RefCounted
## Reglas educativas de la historia coral: clasificación de respuestas y final.
## Son funciones puras: reciben el estado y devuelven un resultado, sin tocar la escena.

const COMPANIONS := ["A", "B", "C"]
# Clasificación descriptiva de cada respuesta (sin puntaje): protectora, límite o de riesgo.
const CHOICE_BEHAVIOR := {
	"D1_GATE": {"A": "protectora", "B": "protectora", "C": "riesgo"},
	"D2_A": {"A": "protectora", "B": "riesgo"}, "D2_B": {"A": "protectora", "B": "riesgo"}, "D2_C": {"A": "protectora", "B": "riesgo"},
	"D4_A1": {"A": "protectora", "B": "limite"}, "D4_B1": {"A": "protectora", "B": "limite"}, "D4_C1": {"A": "protectora", "B": "limite"},
	"D4_A2": {"A": "protectora", "B": "riesgo"}, "D4_B2": {"A": "protectora", "B": "riesgo"}, "D4_C2": {"A": "protectora", "B": "riesgo"}}
const BEHAVIOR_LABELS := {"protectora": "Protectora", "limite": "Protectora con límite", "riesgo": "De riesgo"}
const DECISION_NAMES := {"D1_GATE": "D1 · El nuevo jugador", "D2_A": "Recreo D2 · Confidencia de Camila", "D2_B": "Recreo D2 · Regalo de Mateo", "D2_C": "Recreo D2 · Cansancio de Sebas",
	"D4_A1": "D4 · Plan con Camila", "D4_A2": "D4 · Reparar con Camila", "D4_B1": "D4 · Presión sobre Mateo", "D4_B2": "D4 · Retomar con Mateo", "D4_C1": "D4 · Apoyo para Sebas", "D4_C2": "D4 · Rectificar con Bruno"}


## Tipo de respuesta ("protectora", "limite" o "riesgo"); vacío si la decisión no se clasifica.
static func classify(decision_id: String, key: String) -> String:
	return str(CHOICE_BEHAVIOR.get(decision_id, {}).get(key, ""))


## Perfil del jugador: etiqueta global, conteos y detalle por decisión.
static func profile(state: Dictionary) -> Dictionary:
	var counts := {"protectora": 0, "limite": 0, "riesgo": 0}
	var details: Array = []
	var choices: Dictionary = state.get("choices", {})
	for decision_id in CHOICE_BEHAVIOR:
		if not choices.has(decision_id): continue
		var kind: String = classify(decision_id, str(choices[decision_id]))
		if kind.is_empty(): continue
		counts[kind] += 1
		details.append({"decision": decision_id, "name": DECISION_NAMES.get(decision_id, decision_id), "kind": kind, "label": BEHAVIOR_LABELS[kind]})
	var total: int = counts.protectora + counts.limite + counts.riesgo
	return {"label": profile_label(counts), "counts": counts, "total": total, "details": details, "unrepaired_recess": unrepaired_recess(state)}


## Etiqueta global según la proporción de respuestas protectoras.
static func profile_label(counts: Dictionary) -> String:
	var total: int = counts.protectora + counts.limite + counts.riesgo
	if total == 0: return "Sin decisiones aún"
	var protective: float = float(counts.protectora + counts.limite) / float(total)
	return "Protectora" if protective >= 0.75 else "En aprendizaje" if protective >= 0.4 else "De riesgo"


## Respuestas de riesgo en el recreo (D2) que no se repararon en D4.
static func unrepaired_recess(state: Dictionary) -> int:
	var choices: Dictionary = state.get("choices", {})
	var total: int = 0
	for companion in COMPANIONS:
		if choices.get("D2_" + companion, "") == "B" and choices.get("D4_%s2" % companion, "") != "A": total += 1
	return total


## Final según lo que el grupo hizo: F01 apoyo adulto, F02 límite con confianza, F03 pendiente.
static func ending_for(state: Dictionary) -> String:
	# Pedir apoyo adulto nunca se bloquea por respuestas anteriores.
	if state.get("adult_support_started", false): return "F01"
	# Un límite solo sostiene al grupo si la confianza del recreo no quedó rota.
	if state.get("limit_completed", false) and unrepaired_recess(state) < 2: return "F02"
	return "F03"
