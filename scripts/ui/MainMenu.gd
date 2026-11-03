extends RefCounted
## Menú de ranuras: nueva partida, continuar, rehacer y borrar.
## Se movió desde Main.gd sin cambios de comportamiento (paso 8 de la migración modular).

var main: Node

func show() -> void:
	main.paused_reading.clear()
	main.phase_load_after_pause = false
	if is_instance_valid(main.desktop_ui): main.desktop_ui.clear_view()
	AudioManager.set_music_paused(false)
	main.dialogue_key = ""
	main.modal_kind = "menu"
	main.ui_kit.clear_modal()
	main.menu_background.visible = true
	main.hud_icon.visible = false
	main.hud.visible = false
	main.ui_kit.modal_heading("CENTINELA 2.0", "controls", 24)
	main.ui_kit.modal_text("Acompaña a Sofi y sus amigos desde el primer día.", 15)
	var rows: Array[Dictionary] = []
	for i in range(1, 4):
		var chosen := i
		var label := "Ranura %d · cargando..." % i if OS.has_feature("web") else SaveManager.slot_summary(i)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.custom_minimum_size.y = 34
		main.modal_box.add_child(row)
		var play: Button = main.ui_kit.make_button(label, func(): start_slot(chosen), "", row)
		play.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var redo: Button = main.ui_kit.make_button("Rehacer", func(): confirm_slot_action(chosen, true), "", row)
		var remove: Button = main.ui_kit.make_button("Borrar", func(): confirm_slot_action(chosen, false), "", row)
		redo.custom_minimum_size.x = 94
		remove.custom_minimum_size.x = 94
		var occupied := SaveManager.slot_exists(i)
		play.disabled = OS.has_feature("web")
		redo.disabled = OS.has_feature("web") or not occupied
		remove.disabled = OS.has_feature("web") or not occupied
		rows.append({"play": play, "redo": redo, "remove": remove})
	if OS.has_feature("web"):
		refresh_web_menu(rows)
	else:
		rows[0].play.grab_focus()

func refresh_web_menu(rows: Array[Dictionary]) -> void:
	var response: Dictionary = await SaveManager.list_slots_async()
	if not main.is_inside_tree() or main.modal_kind != "menu":
		return
	if not response.get("success", false):
		main.ui_kit.modal_text("No se pudo leer IndexedDB: " + SaveManager.last_error, 15)
		return
	var records: Dictionary = {}
	for record in response.result:
		records[int(record.slot)] = record
	for i in 3:
		var slot_number := i + 1
		if records.has(slot_number):
			rows[i].play.text = "Ranura %d · Partida guardada" % slot_number
		else:
			rows[i].play.text = "Ranura %d · nueva" % slot_number
		rows[i].play.disabled = false
		rows[i].redo.disabled = not records.has(slot_number)
		rows[i].remove.disabled = not records.has(slot_number)
	rows[0].play.grab_focus()

func confirm_slot_action(chosen: int, redo: bool) -> void:
	if main.slot_loading:
		return
	main.modal_kind = "slot_confirm"
	main.ui_kit.clear_modal()
	main.menu_background.visible = true
	main.hud_icon.visible = false
	main.hud.visible = false
	main.ui_kit.modal_heading("REHACER RANURA %d" % chosen if redo else "BORRAR RANURA %d" % chosen, "save")
	main.ui_kit.modal_text("Empezarás de nuevo desde el comienzo. Se perderá el progreso local de esta ranura." if redo else "Se eliminará el guardado local de esta ranura y quedará vacía.", 17)
	var cancel: Button = main.ui_kit.make_button("Cancelar", show)
	cancel.grab_focus()
	main.ui_kit.make_button("Sí, rehacer ranura" if redo else "Sí, borrar ranura", func(): apply_slot_action(chosen, redo))

func apply_slot_action(chosen: int, redo: bool) -> void:
	if main.slot_loading:
		return
	main.slot_loading = true
	SyncManager.on_slot_closed()
	var previous := GameState.snapshot()
	var replacement: Dictionary = {}
	if redo:
		GameState.new_game(chosen)
		main.daily.initialize()
		replacement = GameState.snapshot()
	var succeeded := await SaveManager.clear_slot_async(chosen, replacement)
	main.slot_loading = false
	if not main.is_inside_tree():
		return
	if not succeeded:
		GameState.restore(previous)
		show()
		main._toast("No se pudo modificar la ranura: " + SaveManager.last_error)
		return
	show()
	if redo:
		start_slot(chosen, true, true)
	else:
		main._toast("Ranura %d eliminada" % chosen)

func start_slot(chosen: int, upgrade_routine := true, fresh_slot := false) -> void:
	if main.slot_loading:
		return
	main.slot_loading = true
	var recovered_local := false
	var resumed := not fresh_slot
	if OS.has_feature("web"):
		if not await SaveManager.acquire_slot_async(chosen):
			main.slot_loading = false
			main._toast("No se pudo abrir la ranura: " + SaveManager.last_error)
			return
		var response: Dictionary = await SaveManager.load_slot_data_async(chosen)
		if not main.is_inside_tree():
			return
		if not response.get("success", false):
			main.slot_loading = false
			main._toast("No se pudo leer la partida: " + SaveManager.last_error)
			await SaveManager.release_slot_async()
			return
		if response.result == null:
			GameState.new_game(chosen)
			resumed = false
			if upgrade_routine: main.daily.initialize()
			if not await SaveManager.save_slot_async():
				main.slot_loading = false
				main._toast("No se pudo crear la partida")
				await SaveManager.release_slot_async()
				return
		elif typeof(response.result) != TYPE_DICTIONARY or not GameState.restore(response.result):
			main.slot_loading = false
			main._toast("Ranura incompatible o dañada; no se sobrescribió")
			await SaveManager.release_slot_async()
			return
	else:
		if SaveManager.slot_exists(chosen):
			if not SaveManager.load_slot(chosen):
				main.slot_loading = false
				main._toast("Ranura incompatible o dañada; no se sobrescribió")
				return
			recovered_local = SaveManager.recovered_slot == chosen
		else:
			GameState.new_game(chosen)
			resumed = false
			if upgrade_routine: main.daily.initialize()
			if not SaveManager.save_slot():
				main.slot_loading = false
				main._toast("No se pudo crear la partida")
				return
	main.slot_loading = false
	if upgrade_routine and not main.daily.active() and GameState.phase in ["bedroom", "courtyard", "computer", "result", "coral", "moba"] and not GameState.coral_state.get("mode") in ["ending", "summary"]:
		var old_phase: String = GameState.phase
		var resumed_day: int = int(GameState.coral_state.get("day", 0))
		main.daily.initialize(resumed_day)
		if old_phase == "courtyard" or old_phase == "coral":
			main.daily.state().stage = "arrival"
			main.daily.state().place = "computer" if resumed_day == 1 else "school"
		elif old_phase in ["computer", "result", "moba"]:
			main.daily.state().stage = "evening"
			main.daily.state().place = "bedroom"
		main.daily.state().messages_checked = true
		if not await SaveManager.save_slot_async():
			main._toast("No se pudo actualizar la rutina de esta ranura")
			show()
			return
	await SaveManager.begin_telemetry_session(resumed)
	if not main.is_inside_tree():
		return
	SyncManager.on_slot_opened()
	AudioManager.apply_preferences()
	if GameState.phase != "moba":
		AudioManager.enter_context("explore")
	main.ui_kit.refresh_static_fonts()
	if GameState.phase == "moba":
		main.get_tree().change_scene_to_file("res://scenes/moba/MOBAArena.tscn")
		return
	main.router.load_phase()
	if main.daily.active():
		if not GameState.dialogue_key.is_empty(): main.day0.resume_saved_dialogue()
		elif GameState.ui_modal == "desktop": main.computer.render_desktop()
		elif GameState.ui_modal == "class": main.computer.render_class()
		elif GameState.ui_modal == "phone": main.phone_modal.render_phone()
		elif GameState.ui_modal == "objective": main.objective_modal.render_objective()
		return
	if not GameState.dialogue_key.is_empty():
		if not main.day0.resume_saved_dialogue():
			show()
			main._toast("No se pudo reanudar el diálogo guardado")
	elif not GameState.ui_modal.is_empty():
		match GameState.ui_modal:
			"phone": main.phone_modal.render_phone()
			"objective": main.objective_modal.render_objective()
			"class": main.computer.render_class()
			"desktop": main.computer.render_desktop()
	elif not str(GameState.flags.get("d0_guide_active", "")).is_empty():
		main.day0.render_stage_guide()
	elif GameState.phase == "bedroom" and not GameState.flags.get("prologue_seen", false) and not GameState.flags.get("wakeup_seen", false):
		main.day0.render_prologue()
	elif GameState.phase == "bedroom" and not GameState.flags.get("wakeup_seen", false):
		main.day0.show_dialogue("wakeup")
	elif GameState.phase == "bedroom" and not GameState.flags.get("d0_guide_bedroom_seen", false):
		main.day0.begin_stage_guide("bedroom")
	elif GameState.phase not in ["result", "preview", "coral"]:
		main.ui_kit.close_modal()
	if recovered_local:
		main._toast("Partida recuperada de una copia local")
