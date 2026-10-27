extends Node2D

const DisplayGuardScript = preload("res://scripts/DisplayGuard.gd")

const ARENA := Vector2(1152, 640)
const LIMIT := 180.0
const HERO_SPEED := 96.0
const COLORS := [Color("74c9c2"), Color("dc827d")]
const TILE_SIZE := 32
const MAP_CELLS := Vector2i(36, 20)
const STATIC_OBSTACLES := [Rect2i(17, 8, 2, 4)]

var heroes: Array[Dictionary] = []
var buildings: Array[Dictionary] = []
var shots: Array[Dictionary] = []
var elapsed := 0.0
var countdown := 3.0
var paused := false
var ended := false
var result_saved := false
var result_event_id := ""
var result_request_id := ""
var result_occurred_at := ""
var result_snapshot: Dictionary = {}
var _crypto := Crypto.new()
var basic_cd := 0.0
var q_cd := 0.0
var tower_cd := 1.5
var player_index := 2
var camera: Camera2D
var layer: CanvasLayer
var hud: Label
var notice: Label
var pause_panel: PanelContainer
var result_panel: PanelContainer
var music_button: Button
var effects_button: Button
var effective_damage := [0.0, 0.0]
var navigation: AStarGrid2D
var window_guard_layer: CanvasLayer
var window_too_small := false
var window_check_elapsed := 0.0

func _ready() -> void:
	SaveManager.lock_lost.connect(_on_lock_lost)
	_create_entities()
	camera = Camera2D.new()
	camera.position = heroes[player_index].pos
	camera.enabled = true
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0
	add_child(camera)
	layer = CanvasLayer.new()
	add_child(layer)
	hud = Label.new()
	hud.position = Vector2(10, 8)
	hud.size = Vector2(748, 35)
	hud.add_theme_font_size_override("font_size", _font_size(16))
	layer.add_child(hud)
	notice = Label.new()
	notice.position = Vector2(180, 46)
	notice.size = Vector2(408, 40)
	notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notice.add_theme_font_size_override("font_size", _font_size(24))
	layer.add_child(notice)
	pause_panel = _create_panel("PAUSA", "Continuar", _resume_match)
	_add_audio_controls()
	pause_panel.visible = false
	result_panel = _create_panel("Resultado", "Continuar", _return_to_story)
	result_panel.visible = false
	window_guard_layer = DisplayGuardScript.make_overlay(self)
	AudioManager.apply_preferences()
	if GameState.phase == "moba":
		AudioManager.enter_context("arena")
	_check_window_size()

func _font_size(base: int) -> int:
	match GameState.text_size:
		"small": return maxi(12, roundi(base * 0.9))
		"large": return roundi(base * 1.3)
	return base

func _on_lock_lost() -> void:
	ended = true
	SyncManager.on_slot_closed()
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _create_panel(title: String, button_text: String, action: Callable) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = Vector2(200, 110)
	panel.size = Vector2(368, 208)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("10192b")
	style.set_content_margin_all(24)
	panel.add_theme_stylebox_override("panel", style)
	var box := VBoxContainer.new()
	box.name = "Content"
	panel.add_child(box)
	var label := Label.new()
	label.name = "Title"
	label.text = title
	label.add_theme_font_size_override("font_size", _font_size(23))
	box.add_child(label)
	var button := Button.new()
	button.name = "Continue"
	button.text = button_text
	button.custom_minimum_size.y = 42
	button.add_theme_font_size_override("font_size", _font_size(18))
	button.pressed.connect(action)
	box.add_child(button)
	layer.add_child(panel)
	return panel

func _resume_match() -> void:
	if window_too_small:
		return
	_set_paused(false)

func _set_paused(value: bool) -> void:
	paused = value
	pause_panel.visible = value
	AudioManager.set_music_paused(value)
	if value:
		pause_panel.get_node("Content/Continue").grab_focus()
	else:
		pause_panel.get_node("Content/Continue").release_focus()

func _add_audio_controls() -> void:
	pause_panel.position = Vector2(200, 78)
	pause_panel.size = Vector2(368, 280)
	var box: VBoxContainer = pause_panel.get_node("Content")
	music_button = Button.new()
	music_button.name = "Music"
	music_button.custom_minimum_size.y = 38
	music_button.pressed.connect(func(): _cycle_audio("music"))
	box.add_child(music_button)
	effects_button = Button.new()
	effects_button.name = "Effects"
	effects_button.custom_minimum_size.y = 38
	effects_button.pressed.connect(func(): _cycle_audio("effects"))
	box.add_child(effects_button)
	_refresh_audio_labels()

func _refresh_audio_labels() -> void:
	music_button.text = "Música: %d %%" % GameState.music_volume
	effects_button.text = "Efectos: %d %%" % GameState.effects_volume

func _cycle_audio(which: String) -> void:
	if await AudioManager.cycle_level(which):
		_refresh_audio_labels()
	else:
		notice.text = "No se pudo guardar el audio"

func _create_entities() -> void:
	var ally_names := ["Mateo", "Bruno", "Sofi", "Camila", "Sebas"]
	for i in 5:
		heroes.append(_hero(ally_names[i], 0, Vector2(160, 224 + i * 48)))
	var enemy_classes := ["Atacante", "Atacante", "Atacante", "Defensor", "Soporte"]
	for i in 5:
		var hero := _hero("Rival %d" % (i + 1), 1, Vector2(992, 224 + i * 48))
		hero.hero_class = enemy_classes[i]
		heroes.append(hero)
	heroes[player_index].hero_class = GameState.moba_class
	for side in 2:
		var xs := [300.0, 420.0, 80.0] if side == 0 else [852.0, 732.0, 1072.0]
		for i in 3:
			buildings.append({"side": side, "tier": i, "pos": Vector2(xs[i], 320),
				"hp": 400.0 if i == 2 else 240.0, "max_hp": 400.0 if i == 2 else 240.0,
				"last_hit": -100.0})
	_build_navigation()

func _build_navigation() -> void:
	navigation = AStarGrid2D.new()
	navigation.region = Rect2i(Vector2i.ZERO, MAP_CELLS)
	navigation.cell_size = Vector2(TILE_SIZE, TILE_SIZE)
	navigation.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	navigation.update()
	for obstacle in STATIC_OBSTACLES:
		_mark_solid_cells(obstacle)

func _mark_solid_cells(cells: Rect2i) -> void:
	# Los héroes tienen radio 13 px: la navegación necesita una casilla de margen.
	for x in range(maxi(0, cells.position.x - 1), mini(MAP_CELLS.x, cells.end.x + 1)):
		for y in range(maxi(0, cells.position.y - 1), mini(MAP_CELLS.y, cells.end.y + 1)):
			navigation.set_point_solid(Vector2i(x, y), true)

func _ruin_cells(building: Dictionary) -> Rect2i:
	return Rect2i(int(building.pos.x / TILE_SIZE), int(building.pos.y / TILE_SIZE) - 1, 2, 2)

func _solid_rects() -> Array[Rect2]:
	var rects: Array[Rect2] = []
	for obstacle in STATIC_OBSTACLES:
		rects.append(Rect2(Vector2(obstacle.position * TILE_SIZE), Vector2(obstacle.size * TILE_SIZE)))
	for building in buildings:
		if building.tier < 2 and building.hp <= 0:
			var cells := _ruin_cells(building)
			rects.append(Rect2(Vector2(cells.position * TILE_SIZE), Vector2(cells.size * TILE_SIZE)))
	return rects

func _move_heroes_out_of_ruin(building: Dictionary) -> void:
	var cells := _ruin_cells(building)
	var rect := Rect2(Vector2(cells.position * TILE_SIZE), Vector2(cells.size * TILE_SIZE))
	for i in heroes.size():
		var hero: Dictionary = heroes[i]
		if hero.hp <= 0 or not rect.grow(13.0).has_point(hero.pos):
			continue
		var candidates := [
			Vector2(rect.position.x - 14.0, hero.pos.y),
			Vector2(rect.end.x + 14.0, hero.pos.y),
			Vector2(hero.pos.x, rect.position.y - 14.0),
			Vector2(hero.pos.x, rect.end.y + 14.0)
		]
		candidates.sort_custom(func(a: Vector2, b: Vector2) -> bool: return hero.pos.distance_squared_to(a) < hero.pos.distance_squared_to(b))
		for candidate in candidates:
			var clear := true
			for solid in _solid_rects():
				if solid.grow(13.0).has_point(candidate):
					clear = false
					break
			if clear:
				hero.pos = _clamp_arena(candidate)
				hero.nav_path = PackedVector2Array()
				heroes[i] = hero
				break

func _hero(name: String, side: int, pos: Vector2) -> Dictionary:
	return {"name": name, "side": side, "pos": pos, "hp": 80.0, "shield": 0.0,
		"shields": [], "dead_until": 0.0, "immune_until": 0.0,
		"last_combat": 0.0, "attack_cd": 0.0, "hero_class": "Atacante",
		"buff_until": 0.0, "q_cd": 0.0, "retreating": false,
		"nav_path": PackedVector2Array(), "nav_index": 0, "nav_goal": Vector2i(-1, -1), "nav_until": 0.0}

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_game") or event.is_action_pressed("ui_cancel"):
		if not ended:
			_set_paused(not paused if not window_too_small else true)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ability") and not paused and countdown <= 0 and not ended:
		_use_player_q()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and not ended:
		if is_instance_valid(pause_panel):
			_set_paused(true)

func _check_window_size() -> void:
	window_too_small = DisplayGuardScript.too_small(DisplayGuardScript.window_size())
	window_guard_layer.visible = window_too_small
	if window_too_small and not ended:
		_set_paused(true)

func _process(delta: float) -> void:
	window_check_elapsed += delta
	if window_check_elapsed >= 0.25:
		window_check_elapsed = 0.0
		_check_window_size()
	if ended or paused:
		return
	if countdown > 0:
		countdown -= delta
		notice.text = str(ceili(countdown)) if countdown > 0 else "¡Comienza!"
		queue_redraw()
		return
	elapsed = minf(LIMIT, elapsed + delta)
	if LIMIT - elapsed < 0.0001:
		elapsed = LIMIT
	basic_cd = maxf(0.0, basic_cd - delta)
	q_cd = maxf(0.0, q_cd - delta)
	tower_cd -= delta
	_move_player(delta)
	_update_heroes(delta)
	_update_camera()
	_update_shots(delta)
	_update_buildings(delta)
	if tower_cd <= 0.0001:
		_towers_fire()
		tower_cd += 1.5
	var remaining := maxi(0, ceili(LIMIT - elapsed))
	hud.text = "%s  ·  %ds  ·  HP %d  ·  Q %.1fs  ·  clic: atacar  P: pausa" % [GameState.moba_class, remaining, ceili(heroes[player_index].hp), q_cd]
	if remaining <= 10:
		notice.text = "Últimos 10 segundos"
	elif remaining <= 30:
		notice.text = "Últimos 30 segundos"
	else:
		notice.text = ""
	if elapsed >= LIMIT:
		_finish(_timeout_result())
	queue_redraw()

func _move_player(delta: float) -> void:
	var hero: Dictionary = heroes[player_index]
	if hero.hp <= 0:
		return
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var speed := HERO_SPEED * (1.25 if hero.buff_until > elapsed else 1.0)
	hero.pos = _sweep_move(hero.pos, direction * speed * delta)
	heroes[player_index] = hero
	camera.position = hero.pos
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and basic_cd <= 0:
		var aim := get_global_mouse_position()
		var vector: Vector2 = (aim - hero.pos).normalized()
		if vector.length() > 0:
			shots.append(_shot(hero.pos, vector, 0, 12.0, 384.0, 192.0, false, false))
			AudioManager.play_effect("interact")
			basic_cd = 1.0
			hero.immune_until = 0.0
			hero.last_combat = elapsed
			heroes[player_index] = hero

func _clamp_arena(pos: Vector2) -> Vector2:
	return Vector2(clampf(pos.x, 24, ARENA.x - 24), clampf(pos.y, 40, ARENA.y - 40))

func _sweep_move(start: Vector2, displacement: Vector2) -> Vector2:
	var position := start
	for step in [Vector2(displacement.x, 0), Vector2(0, displacement.y)]:
		var candidate := _clamp_arena(position + step)
		var clear := true
		for rect in _solid_rects():
			if _segment_rect_hit_t(position, candidate, rect.grow(13.0)) >= 0:
				clear = false
				break
		if clear:
			position = candidate
	return position

func _nav_cell(pos: Vector2) -> Vector2i:
	return Vector2i(clampi(int(pos.x / TILE_SIZE), 0, MAP_CELLS.x - 1), clampi(int(pos.y / TILE_SIZE), 0, MAP_CELLS.y - 1))

func _move_ai(hero: Dictionary, goal: Vector2, delta: float) -> Dictionary:
	var goal_cell := _nav_cell(goal)
	if elapsed >= hero.nav_until or hero.nav_goal != goal_cell or hero.nav_path.is_empty():
		hero.nav_path = navigation.get_point_path(_nav_cell(hero.pos), goal_cell)
		hero.nav_index = 1 if hero.nav_path.size() > 1 else 0
		hero.nav_goal = goal_cell
		hero.nav_until = elapsed + 0.4
	var waypoint := goal
	if hero.nav_index < hero.nav_path.size():
		while hero.nav_index < hero.nav_path.size() - 1 and hero.pos.distance_to(hero.nav_path[hero.nav_index]) < 8.0:
			hero.nav_index += 1
		waypoint = hero.nav_path[hero.nav_index]
	var speed := HERO_SPEED * (1.25 if hero.buff_until > elapsed else 1.0)
	hero.pos = _sweep_move(hero.pos, hero.pos.direction_to(waypoint) * speed * delta)
	return hero

func _shot(pos: Vector2, direction: Vector2, side: int, damage: float, speed: float, distance: float, piercing: bool, tower: bool) -> Dictionary:
	return {"pos": pos, "dir": direction, "side": side, "damage": damage, "speed": speed,
		"remaining": distance, "piercing": piercing, "hits": 0, "hit_ids": [], "tower": tower}

func _update_heroes(delta: float) -> void:
	for i in heroes.size():
		var hero: Dictionary = heroes[i]
		if hero.hp <= 0:
			if elapsed >= hero.dead_until:
				hero.hp = 80.0
				hero.shield = 0.0
				hero.shields = []
				hero.retreating = false
				hero.immune_until = elapsed + 1.0
				hero.q_cd = 0.0
				if i == player_index:
					q_cd = 0.0
			hero.pos = Vector2(160, 320) if hero.side == 0 else Vector2(992, 320)
			hero.nav_path = PackedVector2Array()
			heroes[i] = hero
			continue
		var healing_time := maxf(0.0, elapsed - maxf(elapsed - delta, hero.last_combat + 4.0))
		if healing_time > 0:
			hero.hp = minf(80.0, hero.hp + 4.0 * healing_time)
		hero = _expire_shields(hero)
		if i == player_index:
			heroes[i] = hero
			continue
		if hero.hp <= 24.0:
			hero.retreating = true
		elif hero.hp >= 64.0:
			hero.retreating = false
		var target := _nearest_enemy_hero(hero.pos, hero.side, 9999.0)
		var goal: Vector2
		if hero.retreating:
			goal = Vector2(120, 320) if hero.side == 0 else Vector2(1032, 320)
		else:
			goal = _next_enemy_building(hero.side).pos
			if target >= 0 and hero.pos.distance_to(heroes[target].pos) < 192:
				goal = heroes[target].pos
		if hero.pos.distance_to(goal) > 100 or not _has_line_of_sight(hero.pos, goal):
			hero = _move_ai(hero, goal, delta)
		hero.attack_cd -= delta
		hero.q_cd = maxf(0.0, hero.q_cd - delta)
		if not hero.retreating and hero.attack_cd <= 0:
			var destination := goal
			if hero.pos.distance_to(destination) <= 192 and _has_line_of_sight(hero.pos, destination):
				shots.append(_shot(hero.pos, (destination - hero.pos).normalized(), hero.side, 12.0, 384.0, 192.0, false, false))
				hero.attack_cd = 1.0
				hero.last_combat = elapsed
				hero.immune_until = 0.0
		heroes[i] = hero
		_use_ai_q(i, target)

func _expire_shields(hero: Dictionary) -> Dictionary:
	for i in range(hero.shields.size() - 1, -1, -1):
		if hero.shields[i].expires <= elapsed:
			hero.shields.remove_at(i)
	hero.shield = 0.0
	for shield in hero.shields:
		hero.shield += shield.remaining
	return hero

func _add_shield(index: int, amount: float) -> void:
	var hero: Dictionary = heroes[index]
	hero.shields.append({"remaining": amount, "expires": elapsed + 4.0})
	hero.shield += amount
	heroes[index] = hero

func _use_ai_q(index: int, enemy_index: int) -> void:
	var hero: Dictionary = heroes[index]
	if hero.hp <= 0 or hero.q_cd > 0:
		return
	match hero.hero_class:
		"Atacante":
			if hero.retreating or enemy_index < 0:
				return
			var enemy: Dictionary = heroes[enemy_index]
			if hero.pos.distance_to(enemy.pos) > 256.0 or not _has_line_of_sight(hero.pos, enemy.pos):
				return
			shots.append(_shot(hero.pos, (enemy.pos - hero.pos).normalized(), hero.side, 24.0, 512.0, 256.0, true, false))
			hero.q_cd = 12.0
		"Defensor":
			var target := -1
			var lowest_hp := 64.0
			for ally_index in heroes.size():
				var ally: Dictionary = heroes[ally_index]
				if ally.side != hero.side or ally.hp <= 0 or ally_index == index:
					continue
				if hero.pos.distance_to(ally.pos) <= 160.0 and ally.hp < lowest_hp:
					lowest_hp = ally.hp
					target = ally_index
			if target >= 0:
				_add_shield(target, 20.0)
			elif hero.hp <= 40.0:
				_add_shield(index, 10.0)
			else:
				return
			hero.q_cd = 16.0
		"Soporte":
			if hero.retreating or enemy_index < 0 or hero.pos.distance_to(heroes[enemy_index].pos) > 256.0:
				return
			for ally_index in heroes.size():
				if heroes[ally_index].side == hero.side and heroes[ally_index].hp > 0 and hero.pos.distance_to(heroes[ally_index].pos) <= 96.0:
					heroes[ally_index].buff_until = elapsed + 5.0
			hero.q_cd = 9.0
		_: return
	heroes[index].q_cd = hero.q_cd

func _update_camera() -> void:
	if heroes[player_index].hp > 0:
		camera.position = heroes[player_index].pos
		return
	var closest := -1
	var best := INF
	for i in 5:
		if i == player_index or heroes[i].hp <= 0:
			continue
		var distance: float = heroes[i].pos.distance_squared_to(heroes[player_index].pos)
		if distance < best:
			best = distance
			closest = i
	if closest >= 0:
		camera.position = heroes[closest].pos

func _nearest_enemy_hero(pos: Vector2, side: int, max_distance: float, require_sight: bool = false) -> int:
	var best := -1
	var distance := max_distance
	for i in heroes.size():
		if heroes[i].side == side or heroes[i].hp <= 0:
			continue
		var d: float = pos.distance_to(heroes[i].pos)
		if d < distance and (not require_sight or _has_line_of_sight(pos, heroes[i].pos)):
			distance = d
			best = i
	return best

func _has_line_of_sight(start: Vector2, finish: Vector2) -> bool:
	for rect in _solid_rects():
		if _segment_rect_hit_t(start, finish, rect) >= 0:
			return false
	return true

func _next_enemy_building(side: int) -> Dictionary:
	var enemy := 1 - side
	for tier in 3:
		for building in buildings:
			if building.side == enemy and building.tier == tier and building.hp > 0:
				return building
	return buildings[3 if enemy == 1 else 0]

func _update_shots(delta: float) -> void:
	for i in range(shots.size() - 1, -1, -1):
		var shot: Dictionary = shots[i]
		var start: Vector2 = shot.pos
		var travel: float = minf(shot.speed * delta, shot.remaining)
		shot.pos += shot.dir * travel
		shot.remaining -= travel
		var remove: bool = shot.remaining <= 0
		var contacts: Array[Dictionary] = []
		for rect in _solid_rects():
			var wall_hit := _segment_rect_hit_t(start, shot.pos, rect)
			if wall_hit >= 0:
				contacts.append({"at": wall_hit, "wall": true})
		for j in heroes.size():
			if heroes[j].side == shot.side or heroes[j].hp <= 0 or shot.hit_ids.has(j):
				continue
			var hit := _segment_hit_t(start, shot.pos, heroes[j].pos, 17.0)
			if hit >= 0:
				contacts.append({"at": hit, "hero": j})
		var target: Dictionary = _next_enemy_building(shot.side)
		if target.hp > 0:
			var hit := _segment_hit_t(start, shot.pos, target.pos, 31.0)
			if hit >= 0:
				contacts.append({"at": hit, "building": target})
		contacts.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.at < b.at)
		for contact in contacts:
			if contact.has("wall"):
				remove = true
				break
			elif contact.has("hero"):
				_damage_hero(contact.hero, shot.damage)
				shot.hit_ids.append(contact.hero)
				shot.hits += 1
				if not shot.piercing or shot.hits >= 2:
					remove = true
					break
			else:
				_damage_building(shot.side, contact.building, 12.0 if shot.piercing else shot.damage)
				remove = true
				break
		if remove:
			shots.remove_at(i)
		else:
			shots[i] = shot

func _segment_hit_t(start: Vector2, finish: Vector2, center: Vector2, radius: float) -> float:
	var span := finish - start
	var length_squared := span.length_squared()
	if length_squared <= 0.0001:
		return 0.0 if start.distance_squared_to(center) <= radius * radius else -1.0
	var t := clampf((center - start).dot(span) / length_squared, 0.0, 1.0)
	return t if (start + span * t).distance_squared_to(center) <= radius * radius else -1.0

func _segment_rect_hit_t(start: Vector2, finish: Vector2, rect: Rect2) -> float:
	var direction := finish - start
	var minimum := 0.0
	var maximum := 1.0
	for axis in 2:
		var origin: float = start[axis]
		var step: float = direction[axis]
		var lower: float = rect.position[axis]
		var upper: float = rect.end[axis]
		if absf(step) < 0.0001:
			if origin < lower or origin > upper:
				return -1.0
		else:
			var t1 := (lower - origin) / step
			var t2 := (upper - origin) / step
			minimum = maxf(minimum, minf(t1, t2))
			maximum = minf(maximum, maxf(t1, t2))
			if minimum > maximum:
				return -1.0
	return minimum

func _damage_hero(index: int, damage: float) -> void:
	var hero: Dictionary = heroes[index]
	if hero.immune_until > elapsed:
		return
	hero = _expire_shields(hero)
	hero.last_combat = elapsed
	var remaining_damage := damage
	hero.shields.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.expires < b.expires)
	for shield in hero.shields:
		var absorbed: float = minf(shield.remaining, remaining_damage)
		shield.remaining -= absorbed
		remaining_damage -= absorbed
		if remaining_damage <= 0:
			break
	hero = _expire_shields(hero)
	hero.hp -= remaining_damage
	if hero.hp <= 0:
		hero.hp = 0.0
		hero.dead_until = elapsed + 3.0
	heroes[index] = hero

func _damage_building(attacker_side: int, building: Dictionary, damage: float) -> void:
	var index := buildings.find(building)
	if index < 0 or buildings[index].hp <= 0 or buildings[index].side == attacker_side:
		return
	if _next_enemy_building(attacker_side).tier != buildings[index].tier:
		return
	var real_damage: float = minf(buildings[index].hp, damage)
	buildings[index].hp -= real_damage
	buildings[index].last_hit = elapsed
	effective_damage[attacker_side] += real_damage
	if buildings[index].tier < 2 and buildings[index].hp <= 0:
		_mark_solid_cells(_ruin_cells(buildings[index]))
		_move_heroes_out_of_ruin(buildings[index])
	if buildings[index].tier == 2 and buildings[index].hp <= 0:
		_finish("victoria" if attacker_side == 0 else "derrota")

func _update_buildings(delta: float) -> void:
	for i in buildings.size():
		if buildings[i].tier == 2 and buildings[i].hp > 0:
			var healing_time := maxf(0.0, elapsed - maxf(elapsed - delta, buildings[i].last_hit + 5.0))
			if healing_time > 0:
				buildings[i].hp = minf(400.0, buildings[i].hp + 4.0 * healing_time)

func _towers_fire() -> void:
	for building in buildings:
		if building.tier == 2 or building.hp <= 0:
			continue
		var target := _nearest_enemy_hero(building.pos, building.side, 224.0, true)
		if target >= 0:
			shots.append(_shot(building.pos, (heroes[target].pos - building.pos).normalized(), building.side, 12.0, 384.0, 224.0, false, true))

func _use_player_q() -> void:
	if q_cd > 0 or heroes[player_index].hp <= 0:
		return
	var hero: Dictionary = heroes[player_index]
	match GameState.moba_class:
		"Atacante":
			var direction: Vector2 = (get_global_mouse_position() - hero.pos).normalized()
			if direction.length() == 0: return
			shots.append(_shot(hero.pos, direction, 0, 24.0, 512.0, 256.0, true, false))
			q_cd = 12.0
		"Defensor":
			var target := player_index
			var best := 160.0
			for i in 5:
				if i == player_index or heroes[i].hp <= 0: continue
				var d: float = hero.pos.distance_to(heroes[i].pos)
				if d < best:
					best = d
					target = i
			_add_shield(target, 10.0 if target == player_index else 20.0)
			q_cd = 16.0
		"Soporte":
			for i in 5:
				if hero.pos.distance_to(heroes[i].pos) <= 96:
					heroes[i].buff_until = elapsed + 5.0
			q_cd = 9.0
	if q_cd > 0:
		AudioManager.play_effect("ability")

func _timeout_result() -> String:
	var allies := 0
	var rivals := 0
	for building in buildings:
		if building.tier == 2 or building.hp > 0: continue
		if building.side == 0: rivals += 1
		else: allies += 1
	if allies > rivals: return "victoria"
	if rivals > allies: return "derrota"
	if effective_damage[0] > effective_damage[1]: return "victoria"
	if effective_damage[1] > effective_damage[0]: return "derrota"
	return "empate"

func _finish(result: String) -> void:
	if ended: return
	ended = true
	AudioManager.set_music_paused(true)
	AudioManager.play_effect("result")
	GameState.moba_result = result
	GameState.phase = "result"
	var raw_id := _crypto.generate_random_bytes(16).hex_encode()
	result_event_id = "%s-%s-%s-%s-%s" % [raw_id.substr(0, 8), raw_id.substr(8, 4),
		raw_id.substr(12, 4), raw_id.substr(16, 4), raw_id.substr(20, 12)]
	result_request_id = _crypto.generate_random_bytes(16).hex_encode()
	result_occurred_at = Time.get_datetime_string_from_system(true, true) + "Z"
	result_snapshot = GameState.snapshot()
	result_saved = await SaveManager.save_moba_result_async(result_event_id, result_request_id,
		result_occurred_at, result_snapshot)
	if not is_inside_tree():
		return
	result_panel.get_node("Content/Title").text = "Resultado: " + result if result_saved else "Error al guardar; reintenta"
	result_panel.visible = true
	result_panel.get_node("Content/Continue").grab_focus()

func _return_to_story() -> void:
	if not result_saved:
		result_saved = await SaveManager.save_moba_result_async(result_event_id, result_request_id,
			result_occurred_at, result_snapshot)
	if not result_saved:
		result_panel.get_node("Content/Title").text = "Error al guardar; reintenta"
		return
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, ARENA), Color("24453f"))
	draw_rect(Rect2(0, 226, ARENA.x, 188), Color("54614b"))
	for x in range(0, 1152, 32):
		draw_line(Vector2(x, 0), Vector2(x, 640), Color(1, 1, 1, 0.05))
	for y in range(0, 640, 32):
		draw_line(Vector2(0, y), Vector2(1152, y), Color(1, 1, 1, 0.05))
	for obstacle in STATIC_OBSTACLES:
		var rect := Rect2(Vector2(obstacle.position * TILE_SIZE), Vector2(obstacle.size * TILE_SIZE))
		draw_rect(rect, Color("4d535b"))
		draw_rect(rect.grow(-4.0), Color("70757b"), false, 2.0)
	for building in buildings:
		if building.tier < 2 and building.hp <= 0:
			var ruin := _ruin_cells(building)
			draw_rect(Rect2(Vector2(ruin.position * TILE_SIZE), Vector2(ruin.size * TILE_SIZE)), Color("5d625d"))
			continue
		var color: Color = COLORS[building.side]
		if building.hp <= 0:
			color = Color("5d625d")
		var width := 32 if building.tier == 2 else 24
		draw_rect(Rect2(building.pos - Vector2(width, width), Vector2(width * 2, width * 2)), color)
		if building.hp > 0:
			draw_rect(Rect2(building.pos + Vector2(-25, -width - 12), Vector2(50 * building.hp / building.max_hp, 5)), Color("d6e99f"))
	for hero in heroes:
		if hero.hp <= 0: continue
		_draw_hero_symbol(hero)
		if hero.shield > 0:
			draw_arc(hero.pos, 17, 0, TAU, 32, Color("82ddff"), 3.0)
		if hero.buff_until > elapsed:
			draw_arc(hero.pos, 21, 0, TAU, 32, Color("ffe094"), 2.0)
		if hero.immune_until > elapsed:
			draw_arc(hero.pos, 25, 0, TAU, 32, Color.WHITE, 2.0)
		if hero.name == "Sofi":
			draw_arc(hero.pos, 29, 0, TAU, 32, Color.WHITE, 2.0)
		draw_rect(Rect2(hero.pos + Vector2(-17, -24), Vector2(34 * hero.hp / 80.0, 4)), Color("d6e99f"))
		draw_string(ThemeDB.fallback_font, hero.pos + Vector2(-25, 29), hero.name, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)
	for shot in shots:
		draw_circle(shot.pos, 5, Color("fff0a6") if shot.side == 0 else Color("ffa6b2"))

func _draw_hero_symbol(hero: Dictionary) -> void:
	var position: Vector2 = hero.pos
	var color: Color = COLORS[hero.side]
	match hero.hero_class:
		"Atacante":
			var facing := 1.0 if hero.side == 0 else -1.0
			draw_colored_polygon(PackedVector2Array([
				position + Vector2(-10.0 * facing, -12.0),
				position + Vector2(12.0 * facing, 0),
				position + Vector2(-10.0 * facing, 12.0)
			]), color)
		"Defensor":
			draw_rect(Rect2(position - Vector2(11, 11), Vector2(22, 22)), color)
		"Soporte":
			draw_colored_polygon(PackedVector2Array([
				position + Vector2(0, -13), position + Vector2(13, 0),
				position + Vector2(0, 13), position + Vector2(-13, 0)
			]), color)
		_:
			draw_circle(position, 13, color)
