extends Node

var failures := 0

func check(condition: bool, description: String) -> void:
	if condition: print("PASS ", description)
	else:
		failures += 1
		printerr("FAIL ", description)

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	SaveManager.storage_prefix = "user://centinela_TEACHER_%d_" % Time.get_ticks_usec()
	var main: Node = preload("res://scenes/Main.tscn").instantiate()
	get_tree().root.add_child(main)
	GameState.new_game(1)
	GameState.flags = {"prologue_seen": true, "wakeup_seen": true}
	SaveManager.save_slot()
	var code: String = GameState.code
	for place in ["bedroom", "courtyard", "computer"]:
		if place == "bedroom": await main._begin_stage_guide(place)
		else: await main._transition(place, Vector2(180, 315))
		check(main.modal_kind == "stage_guide" and not main.world.enabled, "guía antes del movimiento: " + place)
		var before: Vector2 = main.world.player_pos
		main.world._physics_process(1.0)
		check(main.world.player_pos == before, "Sofi espera durante la guía: " + place)
		if place == "computer":
			check(main.conversation_ui.find_child("StageGuideText", true, false).text.contains("Pasaron las clases"), "transición colegio → tareas → PC")
		var snapshot: Dictionary = GameState.snapshot()
		check(SaveManager.load_slot(1) and GameState.snapshot() == snapshot, "guía activa se recupera: " + place)
		main.pause_menu.show_pause()
		main.pause_menu.resume_pause()
		check(main.modal_kind == "stage_guide", "pausa conserva guía: " + place)
		check(await main._finish_stage_guide() and main.world.enabled, "guía terminada habilita exploración: " + place)
		main._update_hud()
		check(not main.hud.text.contains(code), "código interno oculto en HUD: " + place)
	main.pause_menu.show_pause()
	var pause_text := ""
	for label in main.modal.find_children("*", "Label", true, false): pause_text += label.text
	check(not pause_text.contains(code), "código interno oculto en pausa")
	check(not SaveManager.slot_summary(1).contains(code) and GameState.code == code, "ranura mantiene código sin mostrarlo")
	main._close_modal()
	GameState.phase = "courtyard"
	GameState.flags.friends = true
	main._load_phase()
	check(main.world.departures.size() == 4, "cuatro despedidas activas")
	var starts: Dictionary = main.world.departures.duplicate(true)
	var destinations := {}
	for person in starts: destinations[starts[person].path[-1]] = true
	check(destinations.size() == 4, "destinos de despedida distintos")
	main.world._update_departures(0.5)
	var moved := true
	for person in starts:
		moved = moved and main.world.departures[person].position != starts[person].position
	check(moved, "los cuatro amigos caminan al despedirse")
	for frame in range(50): main.world._update_departures(0.5)
	check(main.world.departures.is_empty() and GameState.flags.get("d0_departure_seen", false), "despedida finaliza y queda guardada")
	GameState.phase = "coral"
	GameState.coral_state = main.coral_flow.new_state()
	GameState.coral_state.mode = "explore"
	await main.coral.begin_scene("I_TUTOR")
	await main.coral.finish_scene()
	check(not GameState.coral_state.adult_support_started, "conocer tutoría no simula una petición de ayuda")
	GameState.coral_state.observed.append("camila_request_shared")
	var tutor_scene: Dictionary = main.coral_flow.scene("I_TUTOR", main.preview_catalog, main.draft_flow, GameState.coral_state)
	check(tutor_scene.lines[0].text.contains("Camila"), "visita de apoyo tiene un motivo conocido")
	await main.coral.begin_scene("I_TUTOR")
	await main.coral.finish_scene()
	check(GameState.coral_state.adult_support_started, "preocupación compartida inicia apoyo")
	for ending in ["F01", "F02", "F03"]:
		GameState.coral_state.choices = {"D2_A": "B", "D2_B": "A", "D2_C": "B"}
		var scene: Dictionary = main.coral_flow.scene(ending, main.preview_catalog, main.draft_flow, GameState.coral_state)
		var prose := ""
		for line in scene.lines: prose += line.text + " "
		check(prose.contains("grooming") and prose.contains("nunca son tu culpa") and prose.contains("Avisaste al grupo sin permiso") and prose.contains("Escuchaste la presión"), "devolución y orientación en " + ending)
	main.conversation_ui.show_scene("courtyard", "", "Camila", "¿Hablamos?", [], Callable(), "", "Camila", "Sofi", false, 18)
	check(main.conversation_ui.find_child("CharacterName_Sofi", true, false) != null and main.conversation_ui.find_child("SpeakerName", true, false).text == "Camila", "ambos personajes tienen nombre visible")
	check(load("res://assets/portraits/camila_v3.tres") is AtlasTexture and load("res://assets/characters/camila_directions_v3.png") is Texture2D, "nueva identidad de Camila en avatar y mapa")
	SaveManager.delete_slot(1)
	SaveManager.storage_prefix = SaveManager.SAVE_PREFIX
	get_tree().quit(1 if failures else 0)
