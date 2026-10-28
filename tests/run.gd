extends Node

const Validator = preload("res://scripts/narrative/NarrativeValidator.gd")
const Narrative = preload("res://scripts/narrative/NarrativeManager.gd")
const Arena = preload("res://scenes/moba/MOBAArena.tscn")
const MainScene = preload("res://scenes/Main.tscn")
const PreviewCatalog = preload("res://scripts/narrative/RecoveredPreviewCatalog.gd")
const DisplayGuardScript = preload("res://scripts/DisplayGuard.gd")

var failures := 0

func _ready() -> void:
	_run.call_deferred()

func _check(condition: bool, description: String) -> void:
	if condition:
		print("PASS ", description)
	else:
		failures += 1
		printerr("FAIL ", description)

func _run() -> void:
	SaveManager.storage_prefix = "user://centinela_TEST_ONLY_%d_" % Time.get_ticks_usec()
	var story := Narrative.new()
	var errors: Array[String] = story.load_story("res://data/narrative/day_0_TEST_ONLY.json", true)
	_check(errors.is_empty(), "fixture narrativa válida")
	_check(story.current_node().position == 0, "posición inicial")
	_check(story.advance(), "avance secuencial")
	_check(story.advance("TEST_A") and story.position == 2, "ramificación por índice")
	var content: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/narrative/day_0_TEST_ONLY.json"))
	_check(not Validator.validate(content, true).is_empty(), "TEST_ONLY bloqueado en validación canónica")
	var recovered: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/narrative/day_0_RECOVERED_PREVIEW.json"))
	_check(Validator.validate(recovered).is_empty(), "guion recuperado válido como vista previa")
	_check(not Validator.validate(recovered, true).is_empty(), "guion provisional bloqueado para publicación")
	_check(story.load_story("res://data/narrative/day_0_RECOVERED_PREVIEW.json", true).is_empty() and story.start_at("courtyard") and story.current_node().speaker == "Camila", "entrada de conversación recuperada")
	var preview := PreviewCatalog.new()
	_check(preview.load_catalog().is_empty() and preview.scenes.size() == 10, "catálogo D1–D4 y finales carga diez fragmentos")
	_check(preview.get_scene("D4_01_A").get("choices", []).size() == 3 and preview.next_main("D4_03_A").is_empty(), "opciones D4 presentes y final sin enlace automático")
	_check(not DisplayGuardScript.too_small(Vector2i(768, 448)) and DisplayGuardScript.too_small(Vector2i(767, 448)) and DisplayGuardScript.too_small(Vector2i(768, 447)), "ventana mínima exacta 768×448")
	_check(DisplayGuardScript.RESIZE_MESSAGE == "Amplía la ventana del navegador o activa la pantalla completa para continuar jugando", "aviso de ventana insuficiente usa texto aprobado")
	var bad_destination := content.duplicate(true)
	bad_destination.nodes[0].next = 99
	_check(not Validator.validate(bad_destination).is_empty(), "destino imposible rechazado")
	var bad_variable := content.duplicate(true)
	bad_variable.nodes[0].conditions = [{"variable": "DESCONOCIDA"}]
	_check(not Validator.validate(bad_variable).is_empty(), "variable desconocida rechazada")
	var duplicate := content.duplicate(true)
	duplicate.nodes[2].decision_id = "TEST_ONLY_D0_01"
	duplicate.nodes[2].choices = [{"choice_id": "X", "next": 0}]
	_check(not Validator.validate(duplicate).is_empty(), "decisión duplicada rechazada")
	GameState.new_game(2)
	GameState.flags.alarm = true
	GameState.text_size = "large"
	GameState.music_volume = 25
	GameState.effects_volume = 100
	GameState.player_position = Vector2(123, 234)
	var saved := GameState.snapshot()
	_check(SaveManager.save_slot(), "guardado de ranura")
	GameState.new_game(1)
	_check(SaveManager.load_slot(2), "carga de ranura")
	_check(GameState.snapshot() == saved, "snapshot y variables restaurados")
	var bad_save := saved.duplicate(true)
	bad_save.player_position = "corrupto"
	_check(not GameState.restore(bad_save) and GameState.snapshot() == saved, "guardado dañado rechazado sin alterar partida")
	var other_preview := saved.duplicate(true)
	other_preview.preview_content_version = "otra-version"
	_check(not GameState.restore(other_preview) and GameState.snapshot() == saved, "versión de vista previa incompatible rechazada")
	var bad_text_size := saved.duplicate(true)
	bad_text_size.text_size = "huge"
	_check(not GameState.restore(bad_text_size) and GameState.snapshot() == saved, "tamaño de texto inválido rechazado sin alterar partida")
	var old_text_save := saved.duplicate(true)
	old_text_save.erase("text_size")
	_check(GameState.restore(old_text_save) and GameState.text_size == "normal", "guardado anterior sin preferencia usa tamaño mediano")
	GameState.restore(saved)
	var old_audio_save := saved.duplicate(true)
	old_audio_save.erase("music_volume")
	old_audio_save.erase("effects_volume")
	_check(GameState.restore(old_audio_save) and GameState.music_volume == 50 and GameState.effects_volume == 75, "guardado anterior usa niveles de audio predeterminados")
	GameState.restore(saved)
	var old_reading_save := saved.duplicate(true)
	old_reading_save.erase("dialogue_speed")
	old_reading_save.erase("dialogue_history")
	_check(GameState.restore(old_reading_save) and GameState.dialogue_speed == "normal" and GameState.dialogue_history.is_empty(), "guardado anterior usa lectura normal sin historial")
	GameState.restore(saved)
	var bad_reading := saved.duplicate(true)
	bad_reading.dialogue_history = [999]
	_check(not GameState.restore(bad_reading) and GameState.snapshot() == saved, "historial inválido rechazado sin alterar partida")
	var bad_audio := saved.duplicate(true)
	bad_audio.effects_volume = 30
	_check(not GameState.restore(bad_audio) and GameState.snapshot() == saved, "nivel de audio inválido rechazado sin alterar partida")
	_check(ResourceLoader.exists("res://assets/audio/explore_loop.wav") and ResourceLoader.exists("res://assets/audio/ability.wav"), "audio provisional importado")
	for portrait_name in ["sofi", "mateo", "bruno", "camila", "sebas"]:
		_check(load("res://assets/portraits/%s_neutral.png" % portrait_name) is Texture2D, "retrato %s importado" % portrait_name)
	var bad_modal := saved.duplicate(true)
	bad_modal.ui_modal = "class"
	_check(not GameState.restore(bad_modal) and GameState.snapshot() == saved, "panel incompatible con fase rechazado sin alterar partida")
	var bad_hint := saved.duplicate(true)
	bad_hint.hint_level = 3
	_check(not GameState.restore(bad_hint) and GameState.snapshot() == saved, "nivel de pista inválido rechazado")
	var arena: Node2D = Arena.instantiate()
	get_tree().root.add_child(arena)
	if arena.get_script() == null:
		_check(false, "script del MOBA carga sin errores")
		_finish_tests()
		return
	_check(arena.heroes.size() == 10, "MOBA 5v5")
	_check(arena.pause_panel.get_node("Content/Music") is Button and arena.pause_panel.get_node("Content/Effects") is Button, "pausa MOBA incluye ajustes de audio")
	_check(arena.result_panel.has_node("Content/Title"), "panel de resultado tiene título accesible")
	arena._set_paused(true)
	_check(arena.get_viewport().gui_get_focus_owner() == arena.pause_panel.get_node("Content/Continue"), "pausa MOBA enfoca continuar para teclado")
	arena.window_too_small = true
	arena._resume_match()
	_check(arena.paused and arena.pause_panel.visible, "MOBA no reanuda con ventana insuficiente")
	arena.window_too_small = false
	arena._resume_match()
	_check(not arena.paused and not arena.pause_panel.visible, "botón continuar cierra pausa del MOBA")
	arena._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	_check(arena.paused and arena.pause_panel.visible, "MOBA pausa al perder foco")
	arena._resume_match()
	_check(arena.buildings.size() == 6, "estructuras por lado")
	_check(arena._timeout_result() == "empate", "desempate idéntico")
	arena._damage_hero(5, 12)
	_check(arena.heroes[5].hp == 68.0, "ataque de 12 HP")
	arena.heroes[5].pos = Vector2(250, 320)
	arena.shots.append(arena._shot(Vector2(180, 320), Vector2.RIGHT, 0, 12.0, 384.0, 192.0, false, false))
	arena._update_shots(0.25)
	_check(arena.heroes[5].hp == 56.0, "proyectil rápido no atraviesa héroe")
	arena._damage_building(0, arena.buildings[4], 12.0)
	_check(arena.buildings[4].hp == 240.0, "torre interior bloqueada")
	arena._damage_building(0, arena.buildings[3], 12.0)
	_check(arena.buildings[3].hp == 228.0 and arena.effective_damage[0] == 12.0, "daño estructural efectivo")
	arena.heroes[5].hp = 24.0
	arena._update_heroes(0.1)
	_check(arena.heroes[5].retreating, "IA se retira al llegar a 24 HP")
	arena.heroes[5].hp = 64.0
	arena._update_heroes(0.1)
	_check(not arena.heroes[5].retreating, "IA vuelve al llegar a 64 HP")
	for ally_index in [0, 1, 3, 4]:
		arena.heroes[ally_index].pos = Vector2(160, 224 + ally_index * 48)
	arena.heroes[2].hp = 0.0
	arena.heroes[2].pos = Vector2(160, 320)
	arena._update_camera()
	_check(arena.camera.position == arena.heroes[1].pos, "cámara sigue compañero vivo si Sofi cae")
	arena.queue_free()
	var combat: Node2D = Arena.instantiate()
	get_tree().root.add_child(combat)
	combat._add_shield(0, 20.0)
	combat.elapsed = 1.0
	combat._add_shield(0, 10.0)
	combat._damage_hero(0, 12.0)
	_check(combat.heroes[0].hp == 80.0 and combat.heroes[0].shield == 18.0 and combat.heroes[0].shields[0].remaining == 8.0, "escudo consume primero la capa de vencimiento cercano")
	combat.elapsed = 4.1
	combat._update_heroes(0.0)
	_check(combat.heroes[0].shield == 10.0 and combat.heroes[0].shields.size() == 1, "escudos apilados caducan por separado")
	combat._damage_hero(0, 12.0)
	_check(combat.heroes[0].hp == 78.0, "daño restante atraviesa el escudo")
	combat.heroes[0].pos = Vector2(500, 200)
	combat.heroes[5].pos = Vector2(650, 200)
	combat._use_ai_q(0, 5)
	_check(combat.heroes[0].q_cd == 12.0 and combat.shots.back().piercing and combat.shots.back().damage == 24.0, "IA atacante usa Q de 24 HP")
	combat.heroes[5].hp = 40.0
	combat.heroes[8].pos = Vector2(700, 200)
	combat._use_ai_q(8, 0)
	_check(combat.heroes[5].shield == 20.0 and combat.heroes[8].q_cd == 16.0, "IA defensora protege aliado herido")
	combat.heroes[9].pos = Vector2(700, 200)
	combat._use_ai_q(9, 0)
	_check(combat.heroes[5].buff_until == combat.elapsed + 5.0 and combat.heroes[9].q_cd == 9.0, "IA soporte usa aura de velocidad")
	combat.heroes[2].hp = 0.0
	combat.heroes[2].dead_until = combat.elapsed
	combat.q_cd = 8.0
	combat._update_heroes(0.0)
	_check(combat.heroes[2].hp == 80.0 and combat.q_cd == 0.0 and combat.heroes[2].immune_until == combat.elapsed + 1.0, "Sofi reaparece con Q e inmunidad restauradas")
	combat.queue_free()
	var timing: Node2D = Arena.instantiate()
	get_tree().root.add_child(timing)
	timing.heroes[0].hp = 40.0
	timing.heroes[0].last_combat = 0.0
	timing.elapsed = 4.1
	timing._update_heroes(0.2)
	_check(is_equal_approx(timing.heroes[0].hp, 40.4), "curación de héroe empieza tras 4 s exactos")
	timing.buildings[2].hp = 380.0
	timing.buildings[2].last_hit = 0.0
	timing.elapsed = 5.1
	timing._update_buildings(0.2)
	_check(is_equal_approx(timing.buildings[2].hp, 380.4), "regeneración de base empieza tras 5 s exactos")
	timing.queue_free()
	var tower_timing: Node2D = Arena.instantiate()
	get_tree().root.add_child(tower_timing)
	tower_timing.countdown = 0.0
	for hero_index in tower_timing.heroes.size():
		if hero_index != 5:
			tower_timing.heroes[hero_index].hp = 0.0
			tower_timing.heroes[hero_index].dead_until = 999.0
	tower_timing.heroes[5].pos = Vector2(340, 320)
	tower_timing._process(1.4)
	var first_volley: int = tower_timing.shots.filter(func(shot: Dictionary) -> bool: return shot.tower).size()
	tower_timing._process(0.1)
	var second_volley: int = tower_timing.shots.filter(func(shot: Dictionary) -> bool: return shot.tower).size()
	_check(first_volley == 0 and second_volley > 0, "torres disparan después de 1,5 s")
	tower_timing._update_shots(0.2)
	_check(tower_timing.heroes[5].hp < 80.0 and int(80.0 - tower_timing.heroes[5].hp) % 12 == 0, "proyectil de torre inflige 12 HP")
	tower_timing.queue_free()
	var rules: Node2D = Arena.instantiate()
	get_tree().root.add_child(rules)
	rules.effective_damage = [30.0, 20.0]
	_check(rules._timeout_result() == "victoria", "desempate por daño efectivo favorece aliados")
	rules.effective_damage = [20.0, 30.0]
	_check(rules._timeout_result() == "derrota", "desempate por daño efectivo favorece rivales")
	rules.effective_damage = [20.0, 20.0]
	_check(rules._timeout_result() == "empate", "igualdad total produce empate")
	rules.buildings[3].hp = 0.0
	rules.effective_damage = [0.0, 999.0]
	_check(rules._timeout_result() == "victoria", "torres destruidas preceden al daño acumulado")
	rules.queue_free()
	var pause_rules: Node2D = Arena.instantiate()
	get_tree().root.add_child(pause_rules)
	pause_rules.countdown = 0.0
	pause_rules.paused = true
	pause_rules._process(10.0)
	_check(pause_rules.elapsed == 0.0 and pause_rules.shots.is_empty(), "pausa detiene cronómetro y combate")
	pause_rules.queue_free()
	var win_rules: Node2D = Arena.instantiate()
	get_tree().root.add_child(win_rules)
	win_rules.buildings[3].hp = 0.0
	win_rules.buildings[4].hp = 0.0
	win_rules.buildings[5].hp = 1.0
	win_rules._damage_building(0, win_rules.buildings[5], 1.0)
	_check(win_rules.ended and GameState.moba_result == "victoria" and win_rules.elapsed == 0.0, "base rival destruida causa victoria inmediata")
	win_rules.queue_free()
	var loss_rules: Node2D = Arena.instantiate()
	get_tree().root.add_child(loss_rules)
	loss_rules.buildings[0].hp = 0.0
	loss_rules.buildings[1].hp = 0.0
	loss_rules.buildings[2].hp = 1.0
	loss_rules._damage_building(1, loss_rules.buildings[2], 1.0)
	_check(loss_rules.ended and GameState.moba_result == "derrota" and loss_rules.elapsed == 0.0, "base aliada destruida causa derrota inmediata")
	loss_rules.queue_free()
	var geometry: Node2D = Arena.instantiate()
	get_tree().root.add_child(geometry)
	_check(geometry._sweep_move(Vector2(520, 320), Vector2(50, 0)) == Vector2(520, 320), "obstáculo bloquea movimiento")
	_check(geometry._sweep_move(Vector2(520, 220), Vector2(50, 0)) == Vector2(570, 220), "paso lateral permanece libre")
	_check(not geometry._has_line_of_sight(Vector2(500, 320), Vector2(650, 320)), "obstáculo bloquea visión")
	var route: PackedVector2Array = geometry.navigation.get_point_path(Vector2i(15, 10), Vector2i(20, 10))
	_check(route.size() > 2, "IA encuentra ruta alrededor del obstáculo")
	geometry.heroes[5].pos = Vector2(650, 320)
	geometry.shots.append(geometry._shot(Vector2(500, 320), Vector2.RIGHT, 0, 12.0, 384.0, 192.0, false, false))
	geometry._update_shots(0.5)
	_check(geometry.heroes[5].hp == 80.0 and geometry.shots.is_empty(), "obstáculo detiene proyectil")
	geometry.buildings[3].hp = 12.0
	geometry.heroes[5].pos = geometry.buildings[3].pos
	geometry._damage_building(0, geometry.buildings[3], 12.0)
	var ruin: Rect2i = geometry._ruin_cells(geometry.buildings[3])
	_check(geometry.navigation.is_point_solid(ruin.position) and not geometry._has_line_of_sight(Vector2(800, 320), Vector2(900, 320)), "torre destruida crea ruina sólida 2x2")
	var ruin_rect := Rect2(Vector2(ruin.position * 32), Vector2(ruin.size * 32))
	_check(not ruin_rect.grow(13.0).has_point(geometry.heroes[5].pos), "héroe sale de la ruina al destruirse torre")
	geometry.queue_free()
	var simulation: Node2D = Arena.instantiate()
	get_tree().root.add_child(simulation)
	simulation.countdown = 0.0
	var furthest_ally_x := 0.0
	for step in 400:
		if simulation.ended:
			break
		simulation._process(0.1)
		for ally_index in [0, 1, 3, 4]:
			furthest_ally_x = maxf(furthest_ally_x, simulation.heroes[ally_index].pos.x)
	_check(furthest_ally_x > 620.0, "IA aliada cruza el obstáculo en simulación de 40 s")
	simulation.queue_free()
	GameState.phase = "moba"
	GameState.moba_class = "Atacante"
	var full_match: Node2D = Arena.instantiate()
	get_tree().root.add_child(full_match)
	full_match.countdown = 0.0
	for step in 1800:
		if full_match.ended:
			break
		full_match._process(0.1)
	print("MOBA 180 s: resultado=", GameState.moba_result, " tiempo=", full_match.elapsed,
		" daño_estructural=", full_match.effective_damage,
		" HP_bases=", [full_match.buildings[2].hp, full_match.buildings[5].hp])
	_check(full_match.ended and full_match.elapsed <= 180.1, "MOBA finaliza a más tardar a los 180 s")
	_check(full_match.effective_damage[0] + full_match.effective_damage[1] > 0.0, "MOBA registra daño estructural real")
	_check(full_match.result_panel.visible and full_match.result_panel.get_node("Content/Title").text.begins_with("Resultado: "), "resultado visible al finalizar MOBA")
	full_match.queue_free()
	GameState.new_game(2)
	GameState.phase = "moba"
	GameState.moba_class = "Soporte"
	_check(SaveManager.save_slot(), "MOBA interrumpido guarda clase")
	GameState.new_game(1)
	_check(SaveManager.load_slot(2), "MOBA interrumpido carga ranura")
	var resumed_arena: Node2D = Arena.instantiate()
	get_tree().root.add_child(resumed_arena)
	_check(GameState.phase == "moba" and GameState.moba_class == "Soporte" and resumed_arena.elapsed == 0.0 and resumed_arena.countdown == 3.0, "MOBA reanuda desde inicio con clase conservada")
	resumed_arena.queue_free()
	var main: Node2D = MainScene.instantiate()
	get_tree().root.add_child(main)
	if main.get_script() == null:
		_check(false, "script principal carga sin errores")
		_finish_tests()
		return
	main._render_phone()
	main._show_pause()
	main._resume_pause()
	_check(main.modal_kind == "phone", "pausa recupera celular")
	main._render_class()
	main._show_pause()
	main._resume_pause()
	_check(main.modal_kind == "class", "pausa recupera selección de clase")
	main._show_menu()
	main._start_slot(1)
	_check(main.modal_kind == "dialogue" and main.dialogue_key == "wakeup", "partida nueva inicia diálogo de despertar")
	var dialogue_body: VBoxContainer = main.modal_box.get_child(1).get_child(0)
	_check(dialogue_body.get_child(0).has_node("PortraitFrame/Portrait"), "diálogo D0 muestra retrato de Sofi")
	main._show_pause()
	await main._cycle_text_size()
	_check(GameState.text_size == "large" and main.modal_kind == "pause", "tamaño de texto grande se guarda desde pausa")
	await main._cycle_audio("music")
	await main._cycle_audio("effects")
	_check(GameState.music_volume == 75 and GameState.effects_volume == 100, "volúmenes cambiados desde pausa")
	await main._cycle_dialogue_speed()
	_check(GameState.dialogue_speed == "fast", "velocidad de diálogo cambiada desde pausa")
	_check(SaveManager.load_slot(1) and GameState.text_size == "large", "preferencia de texto sobrevive recarga")
	_check(GameState.music_volume == 75 and GameState.effects_volume == 100, "volúmenes sobreviven recarga")
	_check(GameState.dialogue_speed == "fast", "velocidad de diálogo sobrevive recarga")
	main.window_too_small = true
	main._resume_pause()
	_check(main.modal_kind == "pause", "diálogo no reanuda con ventana insuficiente")
	main.window_too_small = false
	main._resume_pause()
	_check(main.modal_kind == "dialogue" and main.dialogue_key == "wakeup", "pausa recupera diálogo con texto grande")
	_check(main.modal_box.get_child(1) is ScrollContainer and main._scaled_text_size(18) == 23, "diálogo grande usa desplazamiento sin recortar opciones")
	_check(main.dialogue_text_label.visible_characters == 0, "diálogo nuevo empieza con texto oculto")
	main._reveal_dialogue()
	_check(main.dialogue_text_label.visible_characters == main.dialogue_story.current_node().text.length(), "primer toque revela línea completa")
	main._render_dialogue_history()
	_check(main.modal_kind == "dialogue_history" and GameState.dialogue_history.is_empty(), "historial inicial no adelanta líneas")
	main._render_dialogue(true)
	_check(main.dialogue_text_label.visible_characters == main.dialogue_story.current_node().text.length(), "volver del historial conserva texto revelado")
	main._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	_check(main.modal_kind == "pause", "diálogo pausa al perder foco")
	main._resume_pause()
	main._advance_dialogue()
	_check(GameState.dialogue_history == [0], "avance guarda posición de historial")
	var saved_dialogue_position: int = main.dialogue_story.position
	main._show_menu()
	main._start_slot(1)
	_check(main.modal_kind == "dialogue" and main.dialogue_key == "wakeup" and main.dialogue_story.position == saved_dialogue_position, "recarga reanuda nodo exacto de despertar")
	_check(GameState.dialogue_history == [0], "historial persiste al recargar")
	main._render_dialogue_history()
	var history_body: VBoxContainer = main.modal_box.get_child(1).get_child(0)
	_check(history_body.get_child(0).text == "Sofi: Ay, nooo... ¿Ya es hora?", "historial muestra línea literal anterior")
	main._render_dialogue(true)
	while main.dialogue_story.current_node().get("next", null) != null:
		main._advance_dialogue()
	main._complete_dialogue()
	_check(GameState.flags.get("wakeup_seen", false) and main.modal_kind == "", "despertar completado y guardado")
	_check(GameState.dialogue_history.is_empty(), "historial se limpia al terminar conversación")
	await main._show_phone()
	_check(main.modal_kind == "phone" and GameState.ui_modal == "phone", "celular abierto se guarda")
	main._show_menu()
	main._start_slot(1)
	_check(main.modal_kind == "phone", "recarga reabre celular")
	await main._close_modal()
	_check(GameState.ui_modal.is_empty() and main.modal_kind == "", "cierre de celular se guarda")
	await main._show_objective()
	await main._advance_hint()
	main._show_menu()
	main._start_slot(1)
	_check(main.modal_kind == "objective" and GameState.hint_level == 1, "recarga reabre objetivo y conserva pista")
	await main._close_modal()
	main._transition("courtyard", Vector2(140, 300))
	main._on_interacted("friends")
	_check(main.modal_kind == "dialogue" and not GameState.flags.get("friends", false), "patio exige terminar conversación")
	while main.dialogue_story.current_node().get("next", null) != null:
		main._advance_dialogue()
	main._complete_dialogue()
	_check(GameState.flags.get("friends", false), "presentación del grupo guardada")
	main._transition("computer", Vector2(384, 320))
	main._on_interacted("pc")
	while main.dialogue_story.current_node().get("next", null) != null:
		main._advance_dialogue()
	_check(main.dialogue_story.current_node().get("choices", []).size() == 3, "chat muestra tres opciones recuperadas")
	var before_dialogue_choice := GameState.snapshot()
	main._request_dialogue_choice("D0_05_A_OPT_B")
	_check(main.modal_kind == "choice_confirm" and GameState.snapshot() == before_dialogue_choice, "selección D0 espera confirmación sin guardar")
	main._show_pause()
	main._resume_pause()
	_check(main.modal_kind == "choice_confirm", "pausa recupera confirmación D0")
	main._cancel_choice_confirm()
	_check(main.modal_kind == "dialogue" and SaveManager.load_slot(1) and GameState.snapshot() == before_dialogue_choice, "cancelar D0 conserva guardado anterior")
	main._request_dialogue_choice("D0_05_A_OPT_B")
	await main._confirm_choice()
	_check(GameState.dialogue_choice == "D0_05_A_OPT_B" and main.pending_choice.is_empty(), "confirmar D0 guarda opción una vez")
	main._show_menu()
	main._start_slot(1)
	_check(main.modal_kind == "dialogue" and main.dialogue_choice == "D0_05_A_OPT_B", "recarga conserva opción del chat antes de completar")
	main._complete_dialogue()
	_check(main.modal_kind == "class" and GameState.flags.get("d0_chat_choice", "") == "D0_05_A_OPT_B", "elección provisional habilita clase")
	main._show_menu()
	main._start_slot(1)
	_check(main.modal_kind == "class" and GameState.ui_modal == "class", "recarga reabre selección de clase")
	_check(GameState.phone_messages.size() == 6, "chat recuperado persiste en celular")
	var flags_before_preview := GameState.flags.duplicate(true)
	await main._commit_preview("D1_02_A", 0)
	_check(GameState.phase == "preview" and main.modal_kind == "preview", "resultado abre vista previa D1")
	var preview_choice_step: int = main.preview_catalog.get_scene("D1_02_A").get("lines", []).size()
	await main._commit_preview("D1_02_A", preview_choice_step)
	var before_preview_choice := GameState.snapshot()
	main._request_preview_choice("D1_02_A", "B")
	_check(main.modal_kind == "choice_confirm" and GameState.snapshot() == before_preview_choice, "selección de vista previa espera confirmación")
	main._cancel_choice_confirm()
	_check(main.modal_kind == "preview" and SaveManager.load_slot(1) and GameState.snapshot() == before_preview_choice, "cancelar vista previa conserva guardado anterior")
	main._request_preview_choice("D1_02_A", "B")
	await main._confirm_choice()
	_check(GameState.preview_choices.get("D1_02_A") == "B" and GameState.flags == flags_before_preview, "opción provisional se guarda sin puntuar")
	var preview_saved := GameState.snapshot()
	_check(SaveManager.load_slot(GameState.slot) and GameState.snapshot() == preview_saved, "posición narrativa y opción persisten al recargar")
	main._show_pause()
	main._resume_pause()
	_check(main.modal_kind == "preview", "pausa recupera vista previa")
	await main._commit_preview("ENDINGS_INDEX", 0)
	_check(main.modal_kind == "preview" and GameState.preview_scene == "ENDINGS_INDEX", "finales se consultan desde índice manual")
	main.queue_free()
	_finish_tests()

func _finish_tests() -> void:
	var focused: Control = get_viewport().gui_get_focus_owner()
	if focused != null:
		focused.release_focus()
	AudioManager.stop_all()
	for test_slot in [1, 2]:
		if SaveManager.slot_exists(test_slot):
			var test_save := ProjectSettings.globalize_path(SaveManager.slot_path(test_slot))
			_check(DirAccess.remove_absolute(test_save) == OK, "guardado de prueba %d eliminado" % test_slot)
	SaveManager.storage_prefix = SaveManager.SAVE_PREFIX
	print("Pruebas terminadas. Fallos: ", failures)
	await get_tree().process_frame
	get_tree().quit(1 if failures > 0 else 0)
