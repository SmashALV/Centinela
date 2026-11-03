extends RefCounted
## Panel de objetivo y pistas (orientación, observar y comprender).
## Se movió desde Main.gd sin cambios de comportamiento (paso 2 de la migración modular).

const ConversationUIScript = preload("res://scripts/ConversationUI.gd")

var main: Node

func show_objective() -> void:
	await main._open_ui_modal("objective", render_objective)

func render_objective() -> void:
	main.modal_kind = "objective"
	main._clear_modal()
	main._modal_heading("OBJETIVO", "objective")
	main._modal_text(("Orientación: " if GameState.phase != "coral" else "") + main._objective_text(), 19)
	if GameState.phase == "coral":
		var state: Dictionary = GameState.coral_state
		var day_key: String = str(state.get("day", 1))
		var requests: Dictionary = state.get("hint_requests", {})
		var shown: String = str(requests.get(day_key, ""))
		if not shown.is_empty():
			main._modal_text((main.daily.objective() if main.daily.active() else main.coral_flow.navigation_hint(state)) if shown == "nav" else main.coral_flow.educational_hint(state, 1 if shown == "h1" else 2), 15)
		main._button("Pista de orientación", func(): coral_request_hint("nav"))
		main._button("Pista para observar", func(): coral_request_hint("h1"))
		main._button("Pista para comprender", func(): coral_request_hint("h2"))
	else:
		if GameState.phase in ["bedroom", "courtyard", "computer"]:
			if GameState.hint_level > 0: main._modal_text(d0_educational_hint(GameState.hint_level), 15)
			main._button("H1 · Observa", func(): set_d0_hint(1))
			main._button("H2 · Comprende", func(): set_d0_hint(2))
		else:
			main._button("Pista", advance_hint)
	main._button("Cerrar", main._close_modal)

func d0_educational_hint(level: int) -> String:
	if level == 1:
		return "¿Qué podría ver alguien nuevo sobre Sofi? ¿Con quién puede hablar si una conversación le incomoda?"
	return "Revisar privacidad, cuidar los horarios y mantener cerca a personas de confianza ayuda a reconocer y poner límites a una presión futura."

func set_d0_hint(level: int) -> void:
	if main.save_in_progress: return
	var previous: int = GameState.hint_level
	GameState.hint_level = level
	main.save_in_progress = true
	if await SaveManager.save_slot_async():
		main.save_in_progress = false
		render_objective()
	else:
		GameState.hint_level = previous
		main.save_in_progress = false
		main._toast("No se pudo guardar la pista")

func coral_request_hint(kind: String) -> void:
	if main.save_in_progress or GameState.phase != "coral": return
	var previous: Dictionary = GameState.snapshot()
	GameState.coral_state.hint_requests[str(GameState.coral_state.day)] = kind
	var hint_action: String = "HINT_D%d_%s" % [int(GameState.coral_state.day), kind]
	if not GameState.coral_state.actions.has(hint_action): GameState.coral_state.actions.append(hint_action)
	main.save_in_progress = true
	if await SaveManager.save_slot_async():
		main.save_in_progress = false
		render_objective()
	else:
		GameState.restore(previous)
		main.save_in_progress = false
		main._toast("No se pudo guardar la pista")

func advance_hint() -> void:
	if main.save_in_progress:
		return
	main.save_in_progress = true
	var previous: int = GameState.hint_level
	GameState.hint_level = mini(previous + 1, 2)
	if await SaveManager.save_slot_async():
		if GameState.flags.get("draft_exploring", false):
			main._toast("Busca a Mateo en el escenario" if GameState.hint_level == 1 else "Acércate a Mateo y pulsa F")
		else:
			main._toast("Busca el objeto señalado" if GameState.hint_level == 1 else "Acércate al objeto marcado y pulsa F")
	else:
		GameState.hint_level = previous
		main._toast("No se pudo guardar la pista; reintenta")
	main.save_in_progress = false
