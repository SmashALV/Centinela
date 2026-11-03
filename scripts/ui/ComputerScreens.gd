extends RefCounted
## PC de Sofi: escritorio, Discord, elección de clase, Arena 5v5 y resultado.
## Se movió desde Main.gd sin cambios de comportamiento (paso 8 de la migración modular).

var main: Node

func show_desktop() -> void:
	if main.daily.active() and not main.daily.can_use_pc():
		main._toast("La computadora está en tu habitación o en la sala de cómputo")
		return
	await main._open_ui_modal("desktop", render_desktop)

func render_desktop() -> void:
	main.modal_kind = "desktop"
	main.ui_kit.clear_modal()
	main.modal.visible = false
	main.hud.visible = false
	main.hud_icon.visible = false
	main.prompt.visible = false
	main.desktop_ui.show_desktop(main)
	return

func inspect_profile() -> void:
	if main.save_in_progress or GameState.flags.get("d0_profile_private", false): return
	var previous: Dictionary = GameState.snapshot()
	GameState.flags.d0_profile_private = true
	main.save_in_progress = true
	if await SaveManager.save_slot_async():
		main.save_in_progress = false
		render_desktop()
	else:
		GameState.restore(previous)
		main.save_in_progress = false
		main._toast("No se pudo guardar la revisión de privacidad")

func open_desktop_chat() -> void:
	if main.daily.active() and main.daily.state().stage != "evening":
		render_discord_history()
		return
	if main.daily.active() and int(main.daily.state().day) > 0:
		if main.daily.state().stage == "evening":
			if int(main.daily.state().day) == 1 and not GameState.coral_state.actions.has("D1_LOBBY_DONE"):
				main.coral.begin_scene("D1_GATE")
			elif not main.daily.state().chat_seen: main.daily.begin_scene("evening_chat")
			else: render_discord_history()
		else: render_discord_history()
		return
	if GameState.flags.get("d0_chat_done", false):
		render_discord_history()
	else:
		main.day0.show_dialogue("group_chat")

func render_discord_history(direct := false) -> void:
	main.desktop_direct = direct
	main.modal_kind = "discord_history"
	main.ui_kit.begin_conversation_presentation()
	var messages: Array = []
	for message in GameState.phone_messages:
		if (message.get("channel", "group") == "mateo") == direct: messages.append(message)
	if direct:
		main.conversation_ui.show_direct_chat("Mateo", messages, [], Callable(), "", main.ui_kit.scaled_text_size(18), "Todavía no hay mensajes privados." if messages.is_empty() else "")
		main.conversation_ui._button("Escritorio", Rect2(626, 9, 121, 32), render_desktop, 13)
	else:
		main.conversation_ui.show_chat("los-chicos", messages, [], Callable(), "", render_desktop, main.ui_kit.scaled_text_size(18), "Todavía no hay mensajes." if messages.is_empty() else "", "Escritorio")
	main.conversation_ui._button("Los chicos" if direct else "Mateo", Rect2(485, 9, 132, 32), func(): render_discord_history(not direct), 13)

func show_class() -> void:
	if main.daily.active() and not main.daily.can_play():
		main._toast("Revisa Discord después de cenar para preparar la partida")
		return
	await main._open_ui_modal("class", render_class)

func render_class() -> void:
	main.modal_kind = "class"
	main.ui_kit.clear_modal()
	main.ui_kit.modal_heading("ELIGE CLASE · MOBA", "ability")
	for hero_class in ["Atacante", "Defensor", "Soporte"]:
		var chosen: String = hero_class
		var class_button: Button = main.ui_kit.make_button(hero_class, func(): start_moba(chosen), "class_" + {"Atacante": "attacker", "Defensor": "defender", "Soporte": "support"}[hero_class])
		class_button.custom_minimum_size.y = 54
		if hero_class == "Atacante":
			class_button.grab_focus()
	main.ui_kit.make_button("Volver al escritorio", show_desktop)

func start_moba(hero_class: String) -> void:
	if main.daily.active() and not main.daily.can_play(): return
	if main.save_in_progress:
		return
	main.save_in_progress = true
	var previous_match: Dictionary = GameState.snapshot()
	GameState.moba_class = hero_class
	GameState.phase = "moba"
	GameState.ui_modal = ""
	if await SaveManager.save_slot_async():
		main.save_in_progress = false
		main.get_tree().change_scene_to_file("res://scenes/moba/MOBAArena.tscn")
	else:
		main.save_in_progress = false
		GameState.restore(previous_match)
		main._toast("No se pudo guardar la clase")

func show_result() -> void:
	main.modal_kind = "result"
	main.ui_kit.begin_conversation_presentation()
	if GameState.flags.get("d1_interlude_active", false):
		main.conversation_ui.show_scene("computer_lab", "Día 1 · Un nuevo jugador", "Narrador", main.draft_flow.connector("D1_02_A"), [], main.coral.start_story, "Continuar", "Sofi", "", false, main.ui_kit.scaled_text_size(18))
		return
	var note: String = "Partida finalizada · " + GameState.moba_result.capitalize()
	var messages: Array = [{"speaker": "Camila", "text": main.draft_flow.camila_reaction(GameState.moba_result, GameState.moba_class)}]
	main.conversation_ui.show_chat("los-chicos", messages, [], main.coral.show_d1_interlude, "Continuar", Callable(), main.ui_kit.scaled_text_size(16), note)
