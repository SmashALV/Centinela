extends RefCounted
## Pistas y consejos del tutor. Orientan al jugador sin elegir por él.
## Son funciones puras: dependen solo del estado coral que reciben.

# Hecho que Sofi conoce después de cada conversación del recreo (D2).
const OBSERVED_FACTS := {"A": "camila_request_shared", "B": "mateo_secret_shared", "C": "sebas_fatigue_observed"}
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
const DEFAULT_ADVICE := "Piensa qué respuesta respeta lo que tu compañero decide contar y abre la puerta a pedir apoyo."


## Consejo para una decisión concreta (botón «Pide un consejo al tutor»).
static func decision_advice(scene_id: String) -> String:
	return str(DECISION_ADVICE.get(scene_id, DEFAULT_ADVICE))


## Consejo del día que el tutor añade en tutoría.
static func tutor_tip(state: Dictionary) -> String:
	return "Un consejo: " + educational_hint(state, 2)


## Pista de orientación: dónde están los compañeros y la salida.
static func navigation_hint(_state: Dictionary) -> String:
	return "Los cuatro compañeros están en el escenario. Puedes hablarles en cualquier orden. La salida cierra la jornada cuando termines; tutoría está a la izquierda."


## Pista educativa: nivel 1 invita a observar; nivel 2 ayuda a comprender.
static func educational_hint(state: Dictionary, level: int) -> String:
	var day: int = int(state.get("day", 1))
	if day == 1:
		return "¿Mateo puede escoger cuándo jugar y con quién hablar sin sentirse obligado?" if level == 1 else "La atención o los halagos no crean una obligación. Observa si se respeta un no y el contacto con otras amistades."
	if day == 2:
		return _recess_hint(state, level)
	if day == 3:
		return "¿Qué teme perder tu compañero si dice que no?" if level == 1 else "Pedir apoyo no traiciona una amistad. No necesitas reunir pruebas ni exigir un relato completo."
	return "¿Qué paso concreto pueden iniciar hoy sin ir al encuentro?" if level == 1 else "La presión también puede ocurrir en línea. No hay que responder, pagar ni demostrar nada para pedir apoyo."


## Pista del recreo (D2): depende del compañero en foco y de lo que Sofi ya observó.
static func _recess_hint(state: Dictionary, level: int) -> String:
	var route: String = str(state.get("focus", ""))
	if not state.get("observed", []).has(OBSERVED_FACTS.get(route, "")):
		return "¿Qué ha observado Sofi realmente? Escucha primero sin suponer qué mensajes recibió cada compañero." if level == 1 else "Un regalo o el cansancio aislados no demuestran abuso. Puedes ofrecer apoyo sin investigar ni pedir pruebas."
	if route == "A": return "¿Qué eligió contar Camila y qué pidió que no se compartiera?" if level == 1 else "Escuchar una confidencia no da permiso para publicarla ni compartir horarios de otras personas."
	if route == "B": return "¿Qué condición apareció junto al regalo que Mateo quería?" if level == 1 else "Un regalo no obliga a guardar un secreto incómodo ni a corresponder; Mateo decide qué mostrar."
	return "¿Qué dice Sebas sobre su horario y cómo se siente?" if level == 1 else "El cansancio puede tener muchas causas. Escuchar sin acusar permite conocer lo que Sebas quiera contar."
