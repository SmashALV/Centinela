extends RefCounted
## Celular de Sofi: mensajes del grupo, privados y libreta de hechos observados.
## Se movió desde Main.gd sin cambios de comportamiento (paso 2 de la migración modular).

const ConversationUIScript = preload("res://scripts/ConversationUI.gd")

var main: Node

func show_phone() -> void:
	await main._open_ui_modal("phone", render_phone)

func render_phone() -> void:
	main.modal_kind = "phone"
	main.ui_kit.clear_modal()
	main.ui_kit.modal_heading("CELULAR · chats y contactos", "phone")
	var body: VBoxContainer = main.ui_kit.content_box()
	if GameState.phone_messages.is_empty():
		main.ui_kit.add_text(body, "No hay mensajes nuevos. El grupo se conectará esta noche.", 16)
	else:
		main.ui_kit.add_text(body, "Los chicos", 15)
		for message in GameState.phone_messages:
			if message.get("channel", "group") == "mateo": continue
			main.ui_kit.add_text(body, "%s\n%s" % [message.get("speaker", ""), ConversationUIScript.dialogue_text(str(message.get("text", "")))], 14)
		var private_messages: Array = GameState.phone_messages.filter(func(message): return message.get("channel", "group") == "mateo")
		if not private_messages.is_empty(): main.ui_kit.add_text(body, "Mateo · Mensajes directos", 15)
		for message in private_messages:
			main.ui_kit.add_text(body, "%s\n%s" % [message.get("speaker", ""), ConversationUIScript.dialogue_text(str(message.get("text", "")))], 14)
	if GameState.flags.get("draft_mode", false):
		if GameState.preview_choices.has("D2_03_A"):
			main.ui_kit.add_text(body, "La captura la mostró Mateo en su propio teléfono. No se guardó en el celular de Sofi.", 15)
		elif GameState.flags.get("draft_exploring", false) and GameState.preview_scene == "D2_03_A":
			main.ui_kit.add_text(body, "Mateo tiene una captura en su propio teléfono. Acércate a él para verla.", 15)
	if GameState.phase == "coral":
		var facts: Array = GameState.coral_state.get("observed", [])
		main.ui_kit.add_text(body, "LIBRETA DE SOFI", 16)
		var fact_labels := {"camila_request_shared": "Camila recibió una pregunta sobre los horarios de Mateo y pidió discreción.", "mateo_secret_shared": "Mateo mostró un regalo vinculado a una petición de secreto que lo incomoda.", "sebas_fatigue_observed": "Sebas contó que teme perder ayuda en el juego si no sigue el horario de Kairo."}
		if facts.is_empty(): main.ui_kit.add_text(body, "Todavía no hay hechos registrados.", 14)
		for fact in facts:
			main.ui_kit.add_text(body, str(fact_labels.get(fact, "Una conversación quedó registrada.")), 14)
		main.ui_kit.add_text(body, "Esta libreta distingue lo observado de las suposiciones. No necesitas recopilar pruebas para ofrecer apoyo.", 14)
	main.ui_kit.make_button("Cerrar", main.ui_kit.close_modal)
