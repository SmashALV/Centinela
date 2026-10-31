extends Node

var failures := 0
var main: Node

func check(ok: bool, title: String) -> void:
	if ok: print("PASS ", title)
	else:
		failures += 1
		printerr("FAIL ", title)

func settle() -> void:
	for frame in 4: await get_tree().process_frame

func routine_scene() -> void:
	for line in 20:
		if str(main.daily.state().scene).is_empty(): return
		check(await main.daily.advance_scene(), "guarda parlamento de rutina")
	check(false, "rutina no entra en bucle")

func coral_scene(id: String, answer := "A") -> void:
	check(await main._coral_begin_scene(id), "abre " + id)
	for line in 120:
		var state: Dictionary = GameState.coral_state
		if state.mode in ["explore", "summary"]: return
		if state.mode == "reaction":
			check(await main._coral_finish_scene(), "reacción guardada")
			continue
		var scene: Dictionary = main.coral_flow.scene(str(state.node), main.preview_catalog, main.draft_flow, state)
		if int(state.step) == scene.get("lines", []).size() and not scene.get("choices", []).is_empty():
			check(await main._coral_choose(answer), "decisión guardada")
		else: check(await main._coral_advance(), "parlamento guardado")
	check(false, "conversación no entra en bucle")

func d0_dialogue() -> void:
	for line in 45:
		if GameState.dialogue_key.is_empty(): return
		var node: Dictionary = main.dialogue_story.current_node()
		if not node.get("choices", []).is_empty(): await main._choose_dialogue(str(node.choices[0].choice_id))
		elif node.get("next", null) == null: await main._complete_dialogue()
		else: await main._advance_dialogue()
	check(false, "D0 no entra en bucle")

func edge(direction: String, expected_place: String, expected_stage: String) -> void:
	main.world.edge_latched = ""
	main.world.player_pos = {"left": Vector2(46, 285), "right": Vector2(722, 285), "up": Vector2(385, 124), "down": Vector2(385, 378)}[direction]
	main.world.check_boundary({"left": Vector2.LEFT, "right": Vector2.RIGHT, "up": Vector2.UP, "down": Vector2.DOWN}[direction])
	await settle()
	check(main.daily.state().place == expected_place and main.daily.state().stage == expected_stage, "borde %s conduce a %s (%s)" % [direction, expected_place, expected_stage])

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	main = preload("res://scenes/Main.tscn").instantiate()
	get_tree().root.add_child(main)
	main.set_process(false)
	main.world.set_physics_process(false)
	main.daily.set_process(false)
	main.conversation_ui.set_process(false)
	for ending in ["F01", "F02", "F03"]:
		SaveManager.storage_prefix = "user://centinela_DAILY_%d_" % Time.get_ticks_usec()
		GameState.new_game(1)
		main.daily.initialize()
		GameState.flags.prologue_seen = true
		GameState.flags.wakeup_seen = true
		GameState.moba_class = "Atacante"
		SaveManager.save_slot()
		main.modal_kind = ""
		main._load_phase()
		for day in range(5):
			check(int(main.daily.state().day) == day and main.daily.state().place == "bedroom", "día %d comienza en la habitación" % day)
			if day > 0: await routine_scene()
			await main._open_ui_modal("phone", main._render_phone)
			await main._close_modal()
			main.daily.interact("backpack")
			await settle()
			check(GameState.has_item("mochila") and not main.world.objects.has("backpack"), "la mochila pasa al inventario y desaparece del cuarto")
			main.daily.interact("backpack")
			await settle()
			check(GameState.flags.inventory.size() == 1 and GameState.restore(GameState.snapshot()), "la mochila no se recoge dos veces y el inventario se guarda")
			await edge("right", "living", "breakfast")
			await edge("right", "living", "breakfast")
			check(not main.daily.can_use_pc() and not main.world.objects.has("pc"), "sala sin computadora")
			await main.daily.begin_scene("breakfast")
			await routine_scene()
			check(main.daily.state().stage == "outbound" and not main.world.objects.has("meal"), "desayuno no puede repetirse como cena")
			await edge("right", "street", "outbound")
			await edge("right", "school", "arrival")
			await edge("up", "school", "arrival")
			if day == 0:
				main.daily.interact("friends")
				await d0_dialogue()
			else:
				for companion in ["mateo", "bruno", "camila", "sebas"]:
					check(main.world.objects.has(companion), "compañero disponible " + companion)
					await coral_scene(main.coral_flow.companion_scene(GameState.coral_state, companion), "B" if ending == "F03" else "A")
				check(not await main._coral_next_day(), "la salida no cambia el día")
			if day == 4 and ending == "F01":
				await edge("left", "tutor", "arrival")
				await coral_scene("I_TUTOR")
				await edge("right", "school", "arrival")
			await edge("right", "computer", "arrival")
			check(main.daily.can_use_pc(), "PC solo en sala de cómputo o dormitorio")
			await edge("left", "school", "arrival")
			await edge("up", "classroom", "class")
			await main.daily.begin_scene("lesson")
			await routine_scene()
			check(main.daily.state().stage == "class_exit", "la campana permite salir sin teletransporte")
			await edge("down", "school", "farewell")
			check(main.world.evening_light, "colegio al atardecer")
			await main.daily.begin_scene("goodbye")
			await routine_scene()
			await edge("down", "street", "homeward")
			check(main.world.evening_light, "calle al atardecer")
			await edge("left", "living", "dinner")
			await main.daily.begin_scene("dinner")
			await routine_scene()
			await edge("left", "bedroom", "evening")
			if day == 0:
				main._open_desktop_chat()
				await d0_dialogue()
			elif day == 1: await coral_scene("D1_GATE", "A")
			else:
				await main.daily.begin_scene("evening_chat")
				await routine_scene()
			if day == 4 and ending == "F02": await coral_scene("I_LIMIT")
			check(main.daily.can_play(), "partida habilitada después de cenar y conversar")
			main._render_desktop()
			check(main.desktop_ui.get_node("Wallpaper").texture != null and main.desktop_ui.find_child("App_Discord", true, false) != null, "escritorio con fondo y Discord")
			check(GameState.restore(GameState.snapshot()), "guardado válido en escritorio")
			main._render_discord_history()
			check(main.conversation_ui.get_node_or_null("ChannelSidebar") != null, "Discord conserva presentación de canal")
			main._render_discord_history(true)
			check(main.conversation_ui.get_node_or_null("DirectSidebar") != null, "Discord permite consultar privado de Mateo")
			# El combate se prueba en RunTests. Aquí verificamos su retorno confirmado a la rutina.
			GameState.phase = "result"
			GameState.ui_modal = ""
			GameState.moba_result = "victoria"
			main.modal_kind = ""
			main._load_phase()
			await routine_scene()
			check(main.daily.state().stage == "bedtime" and not main.daily.can_play(), "una partida devuelve a casa y al descanso")
			await main.daily.go("sleep", "bedroom", Vector2(155, 208))
			check(main.modal_kind == "sleep", "animación al dormir")
			check(Rect2(79, 112, 104, 113).encloses(main.daily.sleep_overlay.get_node("SleepingSofi").get_rect()), "sprite dormida queda dentro de la cama")
			check(GameState.restore(GameState.snapshot()), "guardado válido durante el descanso")
			check(await main.daily.finish_sleep(), "noche completada")
		check(GameState.coral_state.node == ending and main.daily.state().matches.size() == 5, "cinco jornadas completas conducen a " + ending)
		check(GameState.restore(GameState.snapshot()), "final reanudable")
		for slot in range(1, 4):
			for path in [SaveManager.slot_path(slot), SaveManager.backup_path(slot)]:
				if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
	main.queue_free()
	await settle()
	print("Rutina diaria: ", failures, " fallos")
	get_tree().quit(1 if failures else 0)
