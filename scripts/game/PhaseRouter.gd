extends RefCounted
## Decide qué se muestra según la fase guardada y elige el fondo de cada conversación.
## Se movió desde Main.gd sin cambios de comportamiento (paso 8 de la migración modular).

const ConversationUIScript = preload("res://scripts/ConversationUI.gd")

var main: Node

func load_phase() -> void:
	if main.modal_kind == "pause":
		main.phase_load_after_pause = true
		return
	if is_instance_valid(main.conversation_ui):
		main.conversation_ui.clear_view()
	main.prompt.visible = true
	main.menu_background.visible = false
	main.hud_icon.visible = true
	main.hud.visible = true
	if main.daily.active():
		main.daily.load_view()
		return
	var world_phase := GameState.phase
	if world_phase == "result":
		world_phase = "computer"
	elif world_phase == "preview":
		world_phase = main.legacy.draft_world_key() if GameState.flags.get("draft_mode", false) else "courtyard"
	elif world_phase == "coral":
		world_phase = main.coral_flow.world_key(GameState.coral_state)
	main.world.configure(world_phase, GameState.player_position)
	if GameState.phase == "coral":
		main.world.configure_story_targets(main.coral.world_targets(), main.coral.primary_target())
	main.hud_view.update()
	if GameState.phase == "courtyard" and GameState.flags.get("friends", false) and not GameState.flags.get("d0_departure_seen", false):
		main.world.begin_departures()
	if not str(GameState.flags.get("d0_guide_active", "")).is_empty():
		main.day0.render_stage_guide()
	elif GameState.phase == "result":
		main.computer.show_result()
	elif GameState.phase == "preview":
		if GameState.flags.get("draft_exploring", false):
			if GameState.flags.has("draft_intro_step"):
				main.legacy.render_day_intro()
			else:
				main.modal_kind = ""
				main.modal.visible = false
				main.world.enabled = true
		else:
			main.legacy.render_preview()
	elif GameState.phase == "coral":
		main.coral.render()

func conversation_background() -> String:
	if main.daily.active():
		var place: String = str(main.daily.state().place)
		if main.daily.is_evening() and place in ["bedroom", "living", "street", "school"]:
			return {"bedroom": "bedroom_night", "living": "living_night", "street": "street_sunset", "school": "courtyard_sunset"}[place]
		return {"bedroom": "bedroom", "living": "living", "street": "street", "school": "courtyard", "classroom": "classroom", "computer": "computer_lab", "tutor": "tutor_office"}.get(place, "courtyard")
	return ConversationUIScript.background_for_world(str(main.world.scene_key))
