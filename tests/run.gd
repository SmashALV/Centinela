extends Node

const Validator = preload("res://scripts/narrative/NarrativeValidator.gd")
const Narrative = preload("res://scripts/narrative/NarrativeManager.gd")
const Arena = preload("res://scenes/moba/MOBAArena.tscn")
const MainScene = preload("res://scenes/Main.tscn")
const PreviewCatalog = preload("res://scripts/narrative/RecoveredPreviewCatalog.gd")
const DisplayGuardScript = preload("res://scripts/DisplayGuard.gd")
const WorldScript = preload("res://scripts/World.gd")

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
	var distinct_names := {}
	var distinct_jackets := {}
	var distinct_styles := {}
	for friend in WorldScript.FRIENDS:
		distinct_names[friend.name] = true
		distinct_jackets[friend.jacket] = true
		distinct_styles[friend.style] = true
	_check(distinct_names.size() == 4 and distinct_jackets.size() == 4 and distinct_styles.size() == 4, "grupo del patio tiene cuatro identidades visuales")
	var courtyard_world: Node2D = WorldScript.new()
	courtyard_world.configure("courtyard", Vector2(314, 203))
	courtyard_world._physics_process(0.0)
	_check(courtyard_world.nearby == "friends", "grupo interactuable junto a Mateo")
	_check(courtyard_world.target_label("friends") == "Grupo" and courtyard_world.target_label("exit") == "Salida", "interacciones de exploración etiquetadas en español")
	for map_key in ["draft_d1", "draft_d2", "draft_d3", "draft_d4"]:
		var background: Texture2D = WorldScript.DRAFT_BACKGROUNDS[map_key]
		_check(background != null and background.get_width() >= 768 and background.get_height() >= 448, "fondo generado importado: " + map_key)
		courtyard_world.configure(map_key, Vector2(180, 315))
		_check(courtyard_world.objective_target() == "mateo" and courtyard_world.objects.has("mateo"), "Mateo interactuable sobre fondo: " + map_key)
	for map_key in ["bedroom", "courtyard", "computer"]:
		var day0_background: Texture2D = WorldScript.DAY0_BACKGROUNDS[map_key]
		_check(day0_background != null and day0_background.get_width() >= 768 and day0_background.get_height() >= 448, "fondo D0 importado: " + map_key)
		courtyard_world.configure(map_key, Vector2(384, 280))
		_check(courtyard_world.ground_layer.get_used_cells().size() == 220 and courtyard_world.collision_root.get_child_count() >= 4 and WorldScript.SCENE_PROPS[map_key].size() >= 2, "tiles, props y colisiones separados: " + map_key)
	var saved_flags := GameState.flags.duplicate(true)
	GameState.flags = {}
	courtyard_world.configure("bedroom", Vector2(384, 280))
	_check(courtyard_world.objective_target() == "alarm", "alarma marcada como primer objetivo")
	GameState.flags.alarm = true
	_check(courtyard_world.objective_target() == "backpack", "mochila marcada tras usar alarma")
	GameState.flags.backpack = true
	_check(courtyard_world.objective_target() == "door", "puerta marcada tras completar habitación")
	courtyard_world.configure("courtyard", Vector2(314, 203))
	_check(courtyard_world.objective_target() == "friends", "grupo marcado al llegar al patio")
	GameState.flags.friends = true
	_check(courtyard_world.objective_target() == "exit", "salida marcada tras hablar con grupo")
	courtyard_world.configure("computer", Vector2(384, 320))
	_check(courtyard_world.objective_target() == "pc", "computadora marcada como objetivo nocturno")
	GameState.flags = saved_flags
	courtyard_world.free()
	var physics_world: Node2D = WorldScript.new()
	add_child(physics_world)
	physics_world.configure("draft_d1", Vector2(160, 250))
	_check(physics_world.ground_layer.get_used_cells().size() == 220 and physics_world.collision_root.get_child_count() >= 3, "suelo en tiles y obstáculos físicos separados")
	var tile_source: TileSetAtlasSource = physics_world.ground_layer.tile_set.get_source(physics_world.ground_layer.tile_set.get_source_id(0))
	_check(tile_source.get_tiles_count() == 4 and physics_world.ground_layer.get_cell_atlas_coords(Vector2i(0, 0)) != physics_world.ground_layer.get_cell_atlas_coords(Vector2i(1, 0)), "cuatro variantes de tile alternan sobre el fondo")
	await get_tree().physics_frame
	Input.action_press("move_left")
	await get_tree().create_timer(0.45).timeout
	Input.action_release("move_left")
	_check(physics_world.player_pos.x >= 138.0 and physics_world.player_pos.x < 160.0, "colisión real impide atravesar mobiliario del lobby")
	for day0_case in [
		{"map": "bedroom", "start": Vector2(195, 165), "motion": Vector2(-30, 0), "label": "cama"},
		{"map": "courtyard", "start": Vector2(205, 210), "motion": Vector2(0, -70), "label": "banca"},
		{"map": "computer", "start": Vector2(382, 250), "motion": Vector2(0, -60), "label": "computadora"}
	]:
		physics_world.configure(day0_case.map, day0_case.start)
		await get_tree().physics_frame
		_check(physics_world.player_body.test_move(Transform2D(0.0, day0_case.start), day0_case.motion), "colisión física D0: " + day0_case.label)
	for day0_route in [
		{"map": "bedroom", "from": Vector2(384, 280), "horizontal": Vector2(-179, 0), "turn": Vector2(205, 280), "vertical": Vector2(0, -115)},
		{"map": "courtyard", "from": Vector2(140, 300), "horizontal": Vector2(174, 0), "turn": Vector2(314, 300), "vertical": Vector2(0, -80)},
		{"map": "computer", "from": Vector2(384, 320), "horizontal": Vector2.ZERO, "turn": Vector2(384, 320), "vertical": Vector2(0, -102)}
	]:
		physics_world.configure(day0_route.map, day0_route.from)
		await get_tree().physics_frame
		_check(not physics_world.player_body.test_move(Transform2D(0.0, day0_route.from), day0_route.horizontal) and not physics_world.player_body.test_move(Transform2D(0.0, day0_route.turn), day0_route.vertical), "ruta física D0 despejada: " + day0_route.map)
	for collision_case in [
		{"map": "draft_d2", "start": Vector2(520, 210), "minimum": 511.0, "label": "banca del exterior"},
		{"map": "draft_d3", "start": Vector2(170, 360), "minimum": 161.0, "label": "escalera del pasillo"},
		{"map": "draft_d4", "start": Vector2(320, 185), "minimum": 309.0, "label": "jardinera del patio"}
	]:
		physics_world.configure(collision_case.map, collision_case.start)
		_check(physics_world.ground_layer.get_used_cells().size() == 220 and physics_world.collision_root.get_child_count() >= 3, "capas de tiles y colisión: " + collision_case.map)
		await get_tree().physics_frame
		Input.action_press("move_left")
		await get_tree().create_timer(0.28).timeout
		Input.action_release("move_left")
		_check(physics_world.player_pos.x >= float(collision_case.minimum) and physics_world.player_pos.x < collision_case.start.x, "colisión real: " + collision_case.label)
	for day in ["draft_d1", "draft_d2", "draft_d3", "draft_d4"]:
		physics_world.configure(day, Vector2(180, 315))
		await get_tree().physics_frame
		var route_start := Transform2D(0.0, Vector2(180, 315))
		var route_turn := Transform2D(0.0, Vector2(520, 315))
		_check(not physics_world.player_body.test_move(route_start, Vector2(340, 0)) and not physics_world.player_body.test_move(route_turn, Vector2(0, -90)), "ruta física de Sofi a Mateo despejada: " + day)
	physics_world.configure("draft_d4", Vector2(200, 185))
	_check(physics_world.player_pos == Vector2(180, 315), "guardado dentro de jardinera recupera posición segura")
	physics_world.queue_free()
	await get_tree().process_frame
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
	GameState.flags.backpack = true
	_check(SaveManager.save_slot() and FileAccess.file_exists(SaveManager.backup_path(2)), "segundo guardado conserva copia anterior")
	var broken_file := FileAccess.open(SaveManager.slot_path(2), FileAccess.WRITE)
	broken_file.store_string("{")
	broken_file.close()
	_check(SaveManager.slot_summary(2).contains("copia de recuperación"), "menú identifica copia tras archivo dañado")
	GameState.new_game(1)
	_check(SaveManager.load_slot(2) and SaveManager.recovered_slot == 2 and GameState.snapshot() == saved, "copia recupera partida sin aplicar archivo dañado")
	GameState.flags.friends = true
	var repaired := GameState.snapshot()
	_check(SaveManager.save_slot() and SaveManager.recovered_slot == -1, "guardado repara ranura recuperada")
	GameState.new_game(1)
	_check(SaveManager.load_slot(2) and GameState.snapshot() == repaired, "ranura reparada reabre desde archivo principal")
	_check(FileAccess.file_exists(SaveManager.backup_path(2)) and not FileAccess.file_exists(SaveManager.slot_path(2) + ".tmp"), "copia previa se conserva y temporal se retira")
	_check(DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveManager.slot_path(2))) == OK, "interrupción entre renombres simulada")
	GameState.new_game(1)
	_check(SaveManager.slot_exists(2) and SaveManager.load_slot(2) and GameState.snapshot() == saved, "copia recupera ranura sin archivo principal")
	_check(SaveManager.save_slot(), "ranura sin principal se repara al guardar")
	GameState.new_game(2)
	_check(SaveManager.replace_slot() and not FileAccess.file_exists(SaveManager.backup_path(2)), "rehacer ranura elimina la copia de la partida anterior")
	GameState.new_game(1)
	_check(SaveManager.load_slot(2) and GameState.flags.is_empty() and GameState.phase == "bedroom", "ranura rehecha vuelve al comienzo")
	_check(SaveManager.delete_slot(2) and not SaveManager.slot_exists(2), "borrar ranura elimina principal y copia")
	GameState.restore(saved)
	var bad_save := saved.duplicate(true)
	bad_save.player_position = "corrupto"
	_check(not GameState.restore(bad_save) and GameState.snapshot() == saved, "guardado dañado rechazado sin alterar partida")
	var bad_phone := saved.duplicate(true)
	bad_phone.phone_messages = [42]
	_check(not GameState.restore(bad_phone) and GameState.snapshot() == saved, "mensaje de celular inválido rechazado sin alterar partida")
	var bad_flag := saved.duplicate(true)
	bad_flag.flags.alarm = "sí"
	_check(not GameState.restore(bad_flag) and GameState.snapshot() == saved, "indicador obligatorio inválido rechazado")
	var bad_class := saved.duplicate(true)
	bad_class.moba_class = 17
	_check(not GameState.restore(bad_class) and GameState.snapshot() == saved, "clase de combate inválida rechazada")
	var bad_coordinates := saved.duplicate(true)
	bad_coordinates.player_position = [100000, 20]
	_check(not GameState.restore(bad_coordinates) and GameState.snapshot() == saved, "posición fuera del mundo rechazada")
	var bad_code := saved.duplicate(true)
	bad_code.code = "CTN-+12345"
	_check(not GameState.restore(bad_code) and GameState.snapshot() == saved, "código de participante mal formado rechazado")
	var fractional_slot := saved.duplicate(true)
	fractional_slot.slot = 2.5
	_check(not GameState.restore(fractional_slot) and GameState.snapshot() == saved, "número de ranura fraccionario rechazado")
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
	for emotion_name in ["mateo_worried", "mateo_alarmed", "mateo_relieved", "sofi_concerned"]:
		_check(load("res://assets/portraits/%s.png" % emotion_name) is Texture2D, "expresión %s importada" % emotion_name)
	for vn_name in ["sofi_neutral", "sofi_concerned", "mateo_neutral", "mateo_worried", "mateo_alarmed", "camila_neutral", "bruno_neutral", "sebas_neutral", "kairo_anonymous", "bedroom", "courtyard", "corridor"]:
		_check(load("res://assets/vn/%s.png" % vn_name) is Texture2D, "recurso escénico %s importado" % vn_name)
	var bad_modal := saved.duplicate(true)
	bad_modal.ui_modal = "class"
	_check(not GameState.restore(bad_modal) and GameState.snapshot() == saved, "panel incompatible con fase rechazado sin alterar partida")
	var bad_desktop := saved.duplicate(true)
	bad_desktop.ui_modal = "desktop"
	_check(not GameState.restore(bad_desktop) and GameState.snapshot() == saved, "escritorio fuera de computadora rechazado")
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
	_check(arena.ground.texture == arena.ARENA_GROUND and arena.ground.z_index < 0 and arena.ground.scale.x > 0.0, "mapa MOBA importado detrás de personajes y estructuras")
	_check(arena.LIMIT == 60.0 and arena.timer_hud.text == "60s", "MOBA presenta un minuto desde la cuenta atrás")
	var timer_probe: Node2D = Arena.instantiate()
	get_tree().root.add_child(timer_probe)
	timer_probe.countdown = 0.0
	timer_probe.elapsed = 29.9
	timer_probe._process(0.1)
	_check(timer_probe.timer_hud.text == "30s" and timer_probe.notice.text == "Últimos 30 segundos", "aviso del último medio minuto")
	timer_probe.elapsed = 49.9
	timer_probe._process(0.1)
	_check(timer_probe.timer_hud.text == "10s" and timer_probe.notice.text == "Últimos 10 segundos", "aviso de los últimos diez segundos")
	timer_probe.queue_free()
	var ally_accents := {}
	for hero_index in 5:
		ally_accents[arena.ALLY_ACCENTS[arena.heroes[hero_index].name]] = true
	_check(ally_accents.size() == 5, "cinco aliados tienen marcas visuales distintas en MOBA")
	_check(arena.objective_label.text.contains("destruir la base rival"), "MOBA muestra objetivo durante el combate")
	_check(arena.camera.limit_left == 0 and arena.camera.limit_top == 0 and arena.camera.limit_right == 1152 and arena.camera.limit_bottom == 640, "cámara MOBA limitada a la arena")
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
	var wall_approach_left: Dictionary = geometry._hero("Prueba izquierda", 0, Vector2(526, 320))
	var wall_approach_right: Dictionary = geometry._hero("Prueba derecha", 1, Vector2(626, 320))
	for navigation_step in 120:
		geometry.elapsed += 0.1
		wall_approach_left = geometry._move_ai(wall_approach_left, Vector2(700, 320), 0.1)
		wall_approach_right = geometry._move_ai(wall_approach_right, Vector2(450, 320), 0.1)
	_check(wall_approach_left.pos.x > 620.0 and wall_approach_right.pos.x < 532.0, "IA rodea muro desde ambos lados sin atascarse")
	var moving_goal_runner: Dictionary = geometry._hero("Prueba persecución", 0, Vector2(526, 320))
	for navigation_step in 120:
		geometry.elapsed += 0.1
		moving_goal_runner = geometry._move_ai(moving_goal_runner, Vector2(700, 320 + 32 * sin(navigation_step * 0.1)), 0.1)
	_check(moving_goal_runner.pos.x > 620.0, "IA rodea muro al perseguir objetivo móvil")
	var lane_runner: Dictionary = geometry._hero("Prueba carril", 0, Vector2(160, 224))
	for navigation_step in 200:
		geometry.elapsed += 0.1
		lane_runner = geometry._move_ai(lane_runner, Vector2(852, 320), 0.1)
	_check(lane_runner.pos.x > 740.0, "IA avanza por el carril hasta torre rival")
	var retreat_runner: Dictionary = geometry._hero("Prueba retirada", 0, Vector2(212.3911, 294.9304))
	for navigation_step in 40:
		geometry.elapsed += 0.1
		retreat_runner = geometry._move_ai(retreat_runner, Vector2(120, 320), 0.1)
	_check(retreat_runner.pos.x < 160.0, "IA alcanza zona segura al retirarse")
	geometry.heroes[0].hp = 20.0
	geometry.heroes[0].pos = Vector2(212.3911, 294.9304)
	geometry.elapsed = 0.0
	geometry._update_heroes(0.1)
	_check(geometry.heroes[0].retreating and geometry.heroes[0].pos.x < 212.3911, "héroe herido se mueve hacia zona segura")
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
	var furthest_rival_x := INF
	for step in 400:
		if simulation.ended:
			break
		simulation._process(0.1)
		for ally_index in [0, 1, 3, 4]:
			furthest_ally_x = maxf(furthest_ally_x, simulation.heroes[ally_index].pos.x)
		for rival_index in range(5, 10):
			furthest_rival_x = minf(furthest_rival_x, simulation.heroes[rival_index].pos.x)
	_check(furthest_ally_x > 620.0, "IA aliada cruza el obstáculo en simulación de 40 s")
	_check(furthest_rival_x < 532.0, "IA rival cruza el obstáculo en simulación de 40 s")
	simulation.queue_free()
	GameState.phase = "moba"
	GameState.moba_class = "Atacante"
	var full_match: Node2D = Arena.instantiate()
	get_tree().root.add_child(full_match)
	full_match.countdown = 0.0
	for step in 600:
		if full_match.ended:
			break
		full_match._process(0.1)
	print("MOBA 60 s: resultado=", GameState.moba_result, " tiempo=", full_match.elapsed,
		" daño_estructural=", full_match.effective_damage,
		" HP_bases=", [full_match.buildings[2].hp, full_match.buildings[5].hp])
	_check(full_match.ended and full_match.elapsed <= 60.1, "MOBA finaliza a más tardar a los 60 s")
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
	resumed_arena._set_paused(true)
	_check(resumed_arena.pause_panel.get_node("Content/Menu").text == "Salir al menú", "MOBA permite volver al menú para rehacer la ranura")
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
	_check(main._scene_portrait_path("Mateo", "D4_01_A").ends_with("mateo_alarmed.png") and main._scene_portrait_path("Mateo", "D4_01_A", "A").ends_with("mateo_relieved.png") and main._scene_portrait_path("Sofi", "D4_01_A").ends_with("sofi_concerned.png"), "retrato cambia con la tensión y la respuesta")
	main._show_pause()
	main._resume_pause()
	_check(main.modal_kind == "class", "pausa recupera selección de clase")
	main._show_menu()
	main._start_slot(1)
	_check(main.modal_kind == "prologue" and not GameState.flags.get("prologue_seen", false), "partida nueva presenta prólogo narrado")
	var full_prologue: Label = main.conversation_ui.find_child("PrologueText", true, false)
	_check(full_prologue != null and "Sofi" in full_prologue.text and "NARRADOR" not in full_prologue.text, "prólogo completo sin título ni narrador")
	_check(main.conversation_ui.find_children("*", "Button", true, false).is_empty() and main.conversation_ui.auto_action.is_valid(), "prólogo automático sin botón continuar")
	main._show_pause()
	main._resume_pause()
	_check(main.modal_kind == "prologue" and main.conversation_ui.auto_action.is_valid(), "pausa recupera introducción automática")
	main._show_menu()
	main._start_slot(1)
	_check(main.modal_kind == "prologue", "recarga recupera introducción completa")
	await main._advance_prologue()
	_check(main.modal_kind == "dialogue" and main.dialogue_key == "wakeup" and GameState.flags.get("prologue_seen", false), "prólogo completo inicia diálogo de despertar")
	_check(main.conversation_ui.visible and main.conversation_ui.find_child("Sprite_sofi_neutral", true, false) != null, "diálogo presencial D0 muestra sprite de Sofi")
	_check(main.conversation_ui.find_child("VNBackground", true, false) != null, "diálogo presencial usa fondo escénico")
	var test_sprite: TextureRect = main.conversation_ui.find_child("Sprite_sofi_neutral", true, false)
	_check(test_sprite.size == Vector2(310, 350), "sprite presencial respeta el encuadre")
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
	_check(main.conversation_ui.find_children("*", "ScrollContainer", true, false).size() > 0 and main._scaled_text_size(18) == 23, "diálogo grande usa desplazamiento sin recortar opciones")
	_check(main.dialogue_text_label.visible_characters == main.dialogue_text_label.text.length(), "diálogo nuevo muestra el texto completo")
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
	_check(main.modal_kind == "stage_guide" and not main.world.enabled, "guía del cuarto antes de mover a Sofi")
	await main._finish_stage_guide()
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
	await main._finish_stage_guide()
	main._on_interacted("friends")
	_check(main.modal_kind == "dialogue" and not GameState.flags.get("friends", false), "patio exige terminar conversación")
	while main.dialogue_story.current_node().get("next", null) != null:
		main._advance_dialogue()
	main._complete_dialogue()
	_check(GameState.flags.get("friends", false), "presentación del grupo guardada")
	main._transition("computer", Vector2(384, 320))
	await main._finish_stage_guide()
	main._on_interacted("pc")
	var play_locked := false
	for desktop_button in main.modal_box.get_children():
		if desktop_button is Button and desktop_button.text == "Elegir clase e iniciar partida":
			play_locked = desktop_button.disabled
	_check(main.modal_kind == "desktop" and GameState.ui_modal == "desktop" and play_locked, "PC abre escritorio con juego bloqueado antes del chat")
	main._show_menu()
	main._start_slot(1)
	_check(main.modal_kind == "desktop" and GameState.ui_modal == "desktop", "escritorio se reabre desde guardado")
	main._open_desktop_chat()
	_check(main.modal_kind == "dialogue" and GameState.ui_modal.is_empty(), "chat se abre desde escritorio sin guardar dos paneles")
	var chat_before_shortcuts := GameState.snapshot()
	for shortcut in [KEY_F, KEY_E]:
		var shortcut_event := InputEventKey.new()
		shortcut_event.keycode = shortcut
		shortcut_event.pressed = true
		main._unhandled_input(shortcut_event)
	_check(main.modal_kind == "dialogue" and GameState.snapshot() == chat_before_shortcuts, "F y E no interrumpen el diálogo ni modifican el guardado")
	while main.dialogue_story.current_node().get("next", null) != null:
		main._advance_dialogue()
	_check(main.dialogue_story.current_node().get("choices", []).size() == 3, "chat muestra tres opciones recuperadas")
	_check(main.conversation_ui.find_child("ChannelSidebar", true, false) != null, "chat grupal D0 usa canal y avatares")
	var before_dialogue_choice := GameState.snapshot()
	_check(await main._request_dialogue_choice("D0_05_A_OPT_B") and GameState.dialogue_choice == "D0_05_A_OPT_B" and GameState.snapshot() != before_dialogue_choice, "respuesta D0 se guarda al elegirla")
	_check(main.modal_kind == "dialogue" and main.dialogue_text_label.text == "Ya, ya, paz. Mejor entremos a jugar.", "D0 muestra respuesta inmediata de Bruno")
	main._show_pause()
	main._resume_pause()
	_check(main.modal_kind == "dialogue" and main.dialogue_text_label.text == "Ya, ya, paz. Mejor entremos a jugar.", "pausa conserva reacción D0")
	main._show_menu()
	main._start_slot(1)
	_check(main.modal_kind == "dialogue" and main.dialogue_choice == "D0_05_A_OPT_B", "recarga conserva opción del chat antes de completar")
	main._complete_dialogue()
	_check(main.modal_kind == "desktop" and not main.modal_box.get_child(3).disabled and GameState.flags.get("d0_chat_choice", "") == "D0_05_A_OPT_B", "chat terminado habilita juego en escritorio")
	main._show_class()
	_check(main.modal_kind == "class", "juego del escritorio abre selección de clase")
	main._show_menu()
	main._start_slot(1)
	_check(main.modal_kind == "class" and GameState.ui_modal == "class", "recarga reabre selección de clase")
	_check(GameState.phone_messages.size() == 7 and GameState.phone_messages.back().get("speaker") == "Bruno", "respuesta del compañero persiste en el celular")
	var flags_before_preview := GameState.flags.duplicate(true)
	await main._commit_preview("D1_02_A", 0)
	_check(GameState.phase == "preview" and main.modal_kind == "preview", "resultado abre vista previa D1")
	_check(main.conversation_ui.find_child("ChannelSidebar", true, false) != null, "lobby D1 usa chat grupal")
	var preview_choice_step: int = main.preview_catalog.get_scene("D1_02_A").get("lines", []).size()
	await main._commit_preview("D1_02_A", preview_choice_step)
	var before_preview_choice := GameState.snapshot()
	_check(await main._request_preview_choice("D1_02_A", "B") and GameState.snapshot() != before_preview_choice, "decisión de Sofi se guarda en un paso")
	_check(GameState.preview_choices.get("D1_02_A") == "B" and GameState.preview_step == preview_choice_step + 1 and GameState.flags == flags_before_preview, "respuesta de Mateo aparece justo después de elegir")
	var preview_saved := GameState.snapshot()
	_check(SaveManager.load_slot(GameState.slot) and GameState.snapshot() == preview_saved, "posición narrativa y opción persisten al recargar")
	main._show_pause()
	main._resume_pause()
	_check(main.modal_kind == "preview", "pausa recupera vista previa")
	await main._commit_preview("ENDINGS_INDEX", 0)
	_check(main.modal_kind == "preview" and GameState.preview_scene == "ENDINGS_INDEX", "finales se consultan desde índice manual")
	_check(main.preview_catalog.terminal_step("F02") == main.preview_catalog.get_scene("F02").get("lines", []).size(), "fin de extracto F02 calculado desde líneas recuperadas")
	await main._commit_preview("F02", 0)
	var before_finish := GameState.snapshot()
	_check(not await main._finish_preview() and GameState.snapshot() == before_finish, "no se cierra vista previa antes de leer el extracto")
	await main._commit_preview("F02", main.preview_catalog.terminal_step("F02"))
	_check(await main._finish_preview() and GameState.flags.get("preview_reviewed", false) and GameState.preview_scene == "ENDINGS_INDEX" and GameState.preview_step == 1, "recorrido de vista previa cierra y se guarda")
	var reviewed := GameState.snapshot()
	main._show_menu()
	main._start_slot(1)
	_check(main.modal_kind == "preview" and GameState.snapshot() == reviewed, "resumen de vista previa reabre tras cargar ranura")
	_check(not GameState.flags.has("story_completed") and not GameState.flags.has("ending_assigned"), "cierre de vista previa no declara final canónico")
	var bad_reviewed := reviewed.duplicate(true)
	bad_reviewed.flags.preview_reviewed = "sí"
	_check(not GameState.restore(bad_reviewed) and GameState.snapshot() == reviewed, "marca de lectura inválida rechazada")
	_check(main.draft_flow.content.get("draft_version") == "PLAYABLE_DRAFT_v0.3", "borrador separado carga versión provisional")
	for outcome in ["victoria", "derrota", "empate"]:
		for role_name in ["Atacante", "Defensor", "Soporte"]:
			_check(not main.draft_flow.camila_reaction(outcome, role_name).is_empty(), "Camila responde a %s/%s" % [outcome, role_name])
	for letter in ["A", "B", "C"]:
		_check(main.draft_flow.ending_for(letter) == {"A": "F01_A", "B": "F02", "C": "F03"}[letter], "ruta provisional %s" % letter)
		GameState.moba_result = "victoria"
		GameState.moba_class = "Atacante"
		GameState.phase = "result"
		GameState.flags.erase("d1_interlude_active")
		main._show_result()
		var result_buttons: Array[Node] = main.conversation_ui.find_children("*", "Button", true, false)
		_check(main.conversation_ui.visible and result_buttons.is_empty() and main.conversation_ui.auto_action.is_valid(), "resultado deja una sola continuación lineal")
		_check(await main._show_d1_interlude() and GameState.flags.get("d1_interlude_active", false), "interludio del narrador se guarda tras el resultado")
		var interlude_lines := ""
		for label in main.conversation_ui.find_children("*", "Label", true, false):
			interlude_lines += label.text + "\n"
		_check(not interlude_lines.contains("Narrador") and interlude_lines.contains("Sofi vuelve al grupo"), "interludio cuenta la transición de Sofi")
		var interlude_saved := GameState.snapshot()
		main._show_menu()
		main._start_slot(1)
		_check(GameState.snapshot() == interlude_saved and main.modal_kind == "result" and main.conversation_ui.visible, "interludio reanuda desde la ranura")
		_check(await main._start_playable_draft() and GameState.flags.draft_mode and GameState.preview_scene == "D1_02_A", "borrador inicia y limpia opciones")
		_check(not GameState.flags.has("d1_interlude_active"), "interludio no reaparece durante el Día 1")
		_check(GameState.flags.get("draft_exploring", false) and GameState.flags.get("draft_intro_step", -1) == 0 and main.modal_kind == "day_intro", "narrador presenta el Día 1 antes de explorar")
		main._show_pause()
		main._resume_pause()
		_check(main.modal_kind == "day_intro" and GameState.flags.get("draft_intro_step", -1) == 0, "pausa devuelve a la presentación diaria")
		var exploring_saved := GameState.snapshot()
		main._show_menu()
		main._start_slot(1)
		_check(GameState.snapshot() == exploring_saved and main.modal_kind == "day_intro", "presentación diaria reanuda desde guardado")
		var invalid_exploration := exploring_saved.duplicate(true)
		invalid_exploration.preview_step = 3
		_check(not GameState.restore(invalid_exploration), "exploración con paso narrativo inválido rechazada")
		_check(await main._advance_day_intro() and GameState.flags.get("draft_intro_step", -1) == 1, "segunda línea del narrador se guarda")
		_check(await main._advance_day_intro() and not GameState.flags.has("draft_intro_step") and main.world.enabled, "presentación termina y permite explorar")
		for scene_id in main.draft_flow.MAIN_IDS:
			if main.draft_flow.EXPLORATION_IDS.has(scene_id):
				if scene_id != "D1_02_A":
					await main._commit_preview(scene_id, 0, "", false, true)
					_check(main.modal_kind == "day_intro" and GameState.flags.get("draft_intro_step", -1) == 0, "narrador presenta " + scene_id)
					await main._advance_day_intro()
					await main._advance_day_intro()
				_check(GameState.flags.get("draft_exploring", false) and main.modal_kind == "" and main.world.scene_key == "draft_d" + scene_id.substr(1, 1), "escenario explorable: " + scene_id)
				await main._show_phone()
				_check(main.modal_kind == "phone" and GameState.ui_modal == "phone", "celular accesible durante exploración: " + scene_id)
				if scene_id == "D2_03_A":
					var phone_saved := GameState.snapshot()
					main._show_menu()
					main._start_slot(1)
					_check(GameState.snapshot() == phone_saved and main.modal_kind == "phone", "celular contextual se reabre tras cargar")
				await main._close_modal()
				main.world.player_pos = Vector2(520, 225)
				main.world.player_body.position = main.world.player_pos
				main.world._physics_process(0.0)
				_check(main.world.nearby == "mateo", "Mateo queda al alcance en " + scene_id)
				main.world.interact()
				_check(not GameState.flags.get("draft_exploring", false) and main.modal_kind == "preview", "interacción abre escena: " + scene_id)
			_check(not main.draft_flow.connector(scene_id).is_empty(), "conector presente: " + scene_id)
			if scene_id == "D1_03_A":
				await main._commit_preview(scene_id, 0)
				_check(main.conversation_ui.get_node_or_null("DirectSidebar") != null, "Día 1 amplía la historia en un chat personal")
				await main._commit_preview(scene_id, main._draft_terminal_step(scene_id))
				continue
			if scene_id == "D2_03_A":
				await main._commit_preview(scene_id, 5)
				var dm_labels := ""
				for dm_label in main.conversation_ui.find_children("*", "Label", true, false):
					dm_labels += dm_label.text + "\n"
				_check(main.conversation_ui.get_node_or_null("DirectSidebar") != null and dm_labels.contains("CHAT CON KAIRO · compartido por Mateo"), "Kairo aparece como captura compartida en el chat privado")
			for option in ["A", "B", "C"]:
				_check(not main.draft_flow.choice_reaction(scene_id, option).is_empty(), "reacción presente: %s/%s" % [scene_id, option])
			await main._commit_preview(scene_id, main._scene_parts(scene_id, true).lines.size() + 1, letter)
			await main._commit_preview(scene_id, main._draft_terminal_step(scene_id))
			_check(GameState.preview_choices.get(scene_id) == letter and main.modal_kind == "preview", "escena jugable y opción guardada: " + scene_id)
		_check(main.draft_flow.ending_for(str(GameState.preview_choices.get("D4_03_A", "")), GameState.preview_choices) == {"A": "F01_A", "B": "F02", "C": "F03"}[letter], "desenlace calculado desde decisiones previas y D4")
		var ending_scene: String = main.draft_flow.ending_for(letter, GameState.preview_choices)
		await main._commit_preview(ending_scene, main._draft_terminal_step(ending_scene))
		if ending_scene == "F01_A":
			_check(not await main._finish_draft(), "F01 exige segunda escena")
			ending_scene = "F01_B"
			await main._commit_preview(ending_scene, main._draft_terminal_step(ending_scene))
		_check(await main._finish_draft() and GameState.flags.draft_completed and GameState.flags.draft_ending == ("F01" if letter == "A" else ending_scene), "borrador termina con desenlace %s" % letter)
		var draft_saved := GameState.snapshot()
		main._show_menu()
		main._start_slot(1)
		_check(GameState.snapshot() == draft_saved and main.modal_kind == "preview", "resumen del borrador persiste tras recarga")
		_check(not GameState.flags.has("story_completed") and not GameState.flags.has("ending_assigned"), "borrador no declara final aprobado")
	var bad_draft := GameState.snapshot()
	bad_draft.draft_content_version = "PLAYABLE_DRAFT_v0.0"
	_check(not GameState.restore(bad_draft), "versión de borrador incompatible rechazada")
	var legacy_draft := GameState.snapshot()
	legacy_draft.draft_content_version = "PLAYABLE_DRAFT_v0.1"
	_check(GameState.restore(legacy_draft) and GameState.snapshot().draft_content_version == "PLAYABLE_DRAFT_v0.3", "partida v0.1 se migra a la historia candidata v0.3")
	legacy_draft.draft_content_version = "PLAYABLE_DRAFT_v0.2"
	_check(GameState.restore(legacy_draft) and GameState.snapshot().draft_content_version == "PLAYABLE_DRAFT_v0.3", "partida v0.2 se migra a la historia ampliada v0.3")
	var previous_code := GameState.code
	main._show_menu()
	main._confirm_slot_action(1, true)
	_check(main.modal_kind == "slot_confirm" and main.modal_box.get_child(0).get_child(1).text.contains("REHACER"), "menú pide confirmación para rehacer")
	await main._apply_slot_action(1, true)
	_check(GameState.phase == "bedroom" and GameState.flags.is_empty() and GameState.code != previous_code and main.modal_kind == "prologue", "rehacer inicia una partida desde el prólogo")
	main._show_menu()
	main._confirm_slot_action(1, false)
	await main._apply_slot_action(1, false)
	_check(not SaveManager.slot_exists(1) and main.modal_kind == "menu", "borrar desde menú deja la ranura vacía")
	main.queue_free()
	_finish_tests()

func _finish_tests() -> void:
	var focused: Control = get_viewport().gui_get_focus_owner()
	if focused != null:
		focused.release_focus()
	AudioManager.stop_all()
	for test_slot in [1, 2]:
		var cleaned := true
		for test_path in [SaveManager.slot_path(test_slot), SaveManager.backup_path(test_slot), SaveManager.slot_path(test_slot) + ".tmp"]:
			if FileAccess.file_exists(test_path):
				cleaned = DirAccess.remove_absolute(ProjectSettings.globalize_path(test_path)) == OK and cleaned
		_check(cleaned, "guardado de prueba %d eliminado" % test_slot)
	SaveManager.storage_prefix = SaveManager.SAVE_PREFIX
	print("Pruebas terminadas. Fallos: ", failures)
	await get_tree().process_frame
	get_tree().quit(1 if failures > 0 else 0)
