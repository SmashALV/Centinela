extends Node2D
class_name CentinelaWorld

const MapCatalog = preload("res://scripts/world/MapCatalog.gd")

signal interacted(target_id: String)
signal departure_finished
signal boundary_reached(edge: String)

const SPEED := 152.0
const ROOM := Rect2(30, 56, 708, 338)
const CHARACTER_SHEETS := {
	"Sofi": preload("res://assets/characters/sofi_directions.png"),
	"Mateo": preload("res://assets/characters/mateo_directions_v4.png"),
	"Bruno": preload("res://assets/characters/bruno_directions.png"),
	"Camila": preload("res://assets/characters/camila_directions_v3.png"),
	"Sebas": preload("res://assets/characters/sebas_directions_v4.png"),
	"Tutor": preload("res://assets/characters/tutor_directions.png")
}
const ACTOR_WALK_SPEED := 68.0
const IDLE_FACINGS := ["down", "left", "down", "right"]
const OBJECT_SPRITES := {
	"alarm": preload("res://assets/objects/alarm.png"),
	"backpack": preload("res://assets/objects/backpack.png"),
	"desk": preload("res://assets/objects/desk.png"),
	"photo": preload("res://assets/objects/photo.png"),
	"door": preload("res://assets/objects/door.png"),
	"exit": preload("res://assets/objects/door.png"),
	"tutoria": preload("res://assets/objects/door.png"),
	"pc": preload("res://assets/objects/pc.png")
}
const OBJECT_SIZES := {
	"alarm": Vector2(46, 38), "backpack": Vector2(52, 52),
	"desk": Vector2(80, 62), "photo": Vector2(48, 44),
	"door": Vector2(70, 78), "exit": Vector2(70, 78), "tutoria": Vector2(55, 62),
	"pc": Vector2(90, 66)
}
const PROP_SPRITES := {
	"bed": preload("res://assets/world/props/bed.png"),
	"wardrobe": preload("res://assets/world/props/wardrobe.png"),
	"bookshelf": preload("res://assets/world/props/bookshelf.png"),
	"tree": preload("res://assets/world/props/tree.png"),
	"bench": preload("res://assets/world/props/bench.png"),
	"plant": preload("res://assets/world/props/plant.png")
}
const TARGET_LABELS := {
	"alarm": "Alarma", "backpack": "Mochila", "desk": "Escritorio",
	"photo": "Foto", "door": "Puerta", "friends": "Grupo",
	"exit": "Salida", "pc": "Computadora", "mateo": "Mateo", "tutoria": "Tutoría",
	"camila": "Camila", "bruno": "Bruno", "sebas": "Sebas", "lobby": "Lobby", "salida": "Salida"
}
const FRIENDS := [
	{"name": "Mateo", "offset": Vector2(-60, 28), "jacket": "2f568c", "skin": "dc9f71", "style": "curly"},
	{"name": "Bruno", "offset": Vector2(-20, 28), "jacket": "87334d", "skin": "c98b61", "style": "glasses"},
	{"name": "Camila", "offset": Vector2(20, 28), "jacket": "d9696a", "skin": "dfa47b", "style": "ponytail"},
	{"name": "Sebas", "offset": Vector2(60, 28), "jacket": "e2ad36", "skin": "e4ae80", "style": "spiky"}
]

var scene_key: String = "bedroom"
var player_pos: Vector2 = Vector2(384, 280)
var player_facing: String = "down"
var enabled: bool = true
var nearby: String = ""
var objects: Dictionary = {}
var map_sprite: Sprite2D
var ground_layer: TileMapLayer
var collision_root: Node2D
var player_body: CharacterBody2D
var story_targets_active := false
var story_primary_target := ""
var departures: Dictionary = {}
var routine_mode := false
var evening_light := false
var edge_routes: Dictionary = {}
var edge_latched := ""
var hide_player := false
var anim_time := 0.0
# Posición visible de cada personaje: camina hacia su objetivo en vez de aparecer de golpe.
var actor_display: Dictionary = {}

# Cama del cuarto de Sofi en el mapa nuevo: se resalta completa a la hora de dormir.
const SOFI_BED_RECT := Rect2(62, 100, 186, 123)

func _init() -> void:
	map_sprite = Sprite2D.new()
	map_sprite.name = "PaintedBackground"
	map_sprite.centered = false
	map_sprite.region_enabled = true
	map_sprite.z_index = -2
	add_child(map_sprite)
	ground_layer = TileMapLayer.new()
	ground_layer.name = "GroundTiles"
	ground_layer.z_index = -1
	ground_layer.position = Vector2(32, 64)
	add_child(ground_layer)
	collision_root = Node2D.new()
	collision_root.name = "CollisionBodies"
	add_child(collision_root)
	player_body = CharacterBody2D.new()
	player_body.name = "PlayerBody"
	player_body.collision_layer = 1
	player_body.collision_mask = 2
	var player_shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 10.0
	player_shape.shape = circle
	player_body.add_child(player_shape)
	add_child(player_body)

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	map_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

func configure(key: String, position: Vector2) -> void:
	routine_mode = false
	evening_light = false
	edge_routes.clear()
	edge_latched = ""
	hide_player = false
	departures.clear()
	actor_display.clear()
	scene_key = key
	player_pos = position
	story_targets_active = false
	story_primary_target = ""
	_configure_layers()
	if key == "bedroom":
		objects = {"alarm": Vector2(150, 164), "backpack": Vector2(605, 294),
			"desk": Vector2(278, 146), "photo": Vector2(494, 140), "door": Vector2(698, 230)}
		if GameState.has_item("mochila"): objects.erase("backpack")
	elif key == "courtyard":
		objects = {"friends": Vector2(374, 175), "tutoria": Vector2(139, 306), "exit": Vector2(690, 227)}
	elif key.begins_with("draft_d"):
		objects = {"mateo": Vector2(520, 225)}
	else:
		objects = {"pc": Vector2(382, 180)}
	queue_redraw()

func configure_story_targets(targets: Dictionary, primary: String) -> void:
	story_targets_active = true
	story_primary_target = primary
	objects = targets.duplicate()
	queue_redraw()

func _configure_layers() -> void:
	for body in collision_root.get_children():
		collision_root.remove_child(body)
		body.free()
	# Fondo, piso y colisiones vienen de data/maps/maps.json (paso 6 de la migración modular).
	map_sprite.visible = MapCatalog.has_map(scene_key)
	ground_layer.visible = map_sprite.visible
	ground_layer.clear()
	if map_sprite.visible:
		var texture: Texture2D = load(MapCatalog.background(scene_key))
		var size: Vector2 = texture.get_size()
		var crop_height: float = minf(size.y, size.x * ROOM.size.y / ROOM.size.x)
		map_sprite.texture = texture
		map_sprite.region_rect = Rect2(Vector2.ZERO, Vector2(size.x, crop_height))
		map_sprite.position = ROOM.position
		map_sprite.scale = Vector2(ROOM.size.x / size.x, ROOM.size.y / crop_height)
		_configure_ground_tiles(MapCatalog.ground_tiles(scene_key))
		var blocks: Array[Rect2] = MapCatalog.blocks(scene_key)
		for block in blocks:
			_add_obstacle(block)
		if MapCatalog.keeps_player_clear(scene_key):
			for block in blocks:
				if block.grow(11.0).has_point(player_pos):
					player_pos = Vector2(180, 315)
					break
	else:
		map_sprite.texture = null
		ground_layer.tile_set = null
	player_body.position = player_pos

func _configure_ground_tiles(tile_path: String) -> void:
	# Los mapas nuevos traen el piso pintado; solo los antiguos usan baldosas.
	if tile_path.is_empty():
		ground_layer.visible = false
		return
	var tile_texture: Texture2D = load(tile_path) as Texture2D
	var tiles := TileSet.new()
	tiles.tile_size = Vector2i(32, 32)
	var atlas := TileSetAtlasSource.new()
	atlas.texture = tile_texture
	atlas.texture_region_size = Vector2i(32, 32)
	for variant in 4:
		atlas.create_tile(Vector2i(variant, 0))
	var source_id: int = tiles.add_source(atlas)
	ground_layer.tile_set = tiles
	for x in 22:
		for y in 10:
			ground_layer.set_cell(Vector2i(x, y), source_id, Vector2i((x * 13 + y * 7 + x * y) % 4, 0))

func _add_obstacle(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 2
	body.collision_mask = 0
	body.position = rect.get_center()
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	body.add_child(shape)
	collision_root.add_child(body)

func _physics_process(delta: float) -> void:
	if not enabled:
		player_body.velocity = Vector2.ZERO
		return
	anim_time += delta
	_update_departures(delta)
	_update_actor_walks(delta)
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction != Vector2.ZERO:
		if absf(direction.x) > absf(direction.y):
			player_facing = "right" if direction.x > 0.0 else "left"
		else:
			player_facing = "down" if direction.y > 0.0 else "up"
	if is_inside_tree():
		player_body.velocity = direction * SPEED
		player_body.move_and_slide()
		player_pos = player_body.position
	else:
		player_pos += direction * SPEED * delta
	player_pos.x = clampf(player_pos.x, ROOM.position.x + 16, ROOM.end.x - 16)
	var playable_top: float = 185.0 if scene_key.begins_with("draft_d") else 124.0
	player_pos.y = clampf(player_pos.y, playable_top, ROOM.end.y - 16)
	player_body.position = player_pos
	GameState.player_position = player_pos
	if routine_mode: check_boundary(direction)
	nearby = ""
	var best := 1.0
	for key in objects:
		var reach := 84.0 if key in ["friends", "mateo", "camila", "bruno", "sebas"] else 64.0 if story_targets_active else 49.0
		var distance: float = player_pos.distance_to(objects[key]) / reach
		if distance < best:
			best = distance
			nearby = key
	queue_redraw()

func interact() -> void:
	if enabled and not nearby.is_empty():
		interacted.emit(nearby)

func check_boundary(direction: Vector2) -> void:
	var edge := ""
	var top: float = 185.0 if scene_key.begins_with("draft_d") else 124.0
	if player_pos.x <= 49 and direction.x < 0: edge = "left"
	elif player_pos.x >= 719 and direction.x > 0: edge = "right"
	elif player_pos.y <= top + 3 and direction.y < 0: edge = "up"
	elif player_pos.y >= 375 and direction.y > 0: edge = "down"
	if edge.is_empty():
		if player_pos.x > 68 and player_pos.x < 700 and player_pos.y > top + 22 and player_pos.y < 355: edge_latched = ""
		return
	if edge_routes.has(edge) and edge_latched != edge:
		edge_latched = edge
		boundary_reached.emit(edge)

func target_label(key: String) -> String:
	return str(TARGET_LABELS.get(key, key))

func objective_target() -> String:
	if story_targets_active:
		return story_primary_target
	match scene_key:
		"bedroom":
			if not GameState.flags.get("alarm", false): return "alarm"
			if not GameState.flags.get("backpack", false): return "backpack"
			return "door"
		"courtyard":
			return "exit" if GameState.flags.get("friends", false) else "friends"
		"computer":
			return "pc"
		"draft_d1", "draft_d2", "draft_d3", "draft_d4":
			return "mateo"
	return ""

func _draw() -> void:
	var floor_color := Color("21453f")
	if scene_key == "bedroom":
		floor_color = Color("312d49")
	elif scene_key == "computer":
		floor_color = Color("253148")
	elif scene_key == "draft_d1":
		floor_color = Color("30465e")
	elif scene_key == "draft_d3":
		floor_color = Color("3d4256")
	elif scene_key == "draft_d4":
		floor_color = Color("31524a")
	if map_sprite.visible:
		draw_rect(Rect2(0, 0, 768, ROOM.position.y), Color("4c365b"))
		draw_rect(Rect2(0, ROOM.end.y, 768, 448 - ROOM.end.y), Color("4c365b"))
		draw_rect(Rect2(0, ROOM.position.y, ROOM.position.x, ROOM.size.y), Color("4c365b"))
		draw_rect(Rect2(ROOM.end.x, ROOM.position.y, 768 - ROOM.end.x, ROOM.size.y), Color("4c365b"))
	else:
		draw_rect(Rect2(Vector2.ZERO, Vector2(768, 448)), Color("4c365b"))
		draw_rect(ROOM, floor_color)
		for x in range(30, 738, 32):
			draw_line(Vector2(x, 56), Vector2(x, 394), Color(1, 1, 1, 0.04))
		for y in range(56, 394, 32):
			draw_line(Vector2(30, y), Vector2(738, y), Color(1, 1, 1, 0.04))
	if scene_key.begins_with("draft_d"):
		_draw_draft_caption()
	if scene_key == "bedroom": _draw_bedroom_decor()
	for prop in MapCatalog.props(scene_key):
		draw_texture_rect(PROP_SPRITES[prop.sprite], prop.rect, false)
	for key in objects:
		var pos: Vector2 = objects[key]
		var active: bool = key == nearby
		if story_targets_active:
			_draw_story_target(key, pos, active)
			continue
		if key == "friends":
			var color := Color("f5d479") if active else Color("8ec9c2")
			draw_rect(Rect2(pos + Vector2(-83, -12), Vector2(166, 67)), color, false, 2.0 if active else 1.0)
			draw_rect(Rect2(pos + Vector2(-43, -38), Vector2(86, 20)), Color("10192b", 0.84))
			draw_string(ThemeDB.fallback_font, pos + Vector2(-31, -23), "F · Grupo", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, color)
			if key == objective_target():
				_draw_objective_marker(pos + Vector2(0, -50))
			continue
		if key == "mateo":
			var mateo_color := Color("f5d479") if active else Color("8ec9c2")
			draw_arc(pos, 29, 0, TAU, 24, Color("10192b"), 5.0)
			draw_arc(pos, 28, 0, TAU, 24, mateo_color, 2.0)
			draw_rect(Rect2(pos + Vector2(-44, -69), Vector2(90, 22)), Color("10192b", 0.87))
			draw_string(ThemeDB.fallback_font, pos + Vector2(-39, -53), "F · Mateo", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, mateo_color)
			_draw_objective_marker(pos + Vector2(0, -72))
			continue
		_draw_object(key, pos, active)
	if scene_key == "courtyard":
		if not GameState.flags.get("friends", false):
			for friend in FRIENDS:
				var idle_pos: Vector2 = Vector2(374, 175) + friend.offset
				_draw_character(idle_pos, str(friend.name), _idle_facing(str(friend.name), idle_pos), true, true)
		else:
			for person in departures:
				_draw_character(departures[person].position, person, str(departures[person].facing), true, true, true)
	elif scene_key.begins_with("draft_d") and not story_targets_active:
		_draw_character(objects.mateo, "Mateo", _idle_facing("mateo", objects.mateo), false, true)
		if scene_key == "draft_d1":
			for extra in [["Camila", Vector2(330, 245)], ["Bruno", Vector2(260, 250)], ["Sebas", Vector2(400, 250)]]:
				_draw_character(extra[1], extra[0], _idle_facing(extra[0], extra[1]), false, true)
	if not hide_player: _draw_character(player_pos, "Sofi", player_facing)
	if routine_mode:
		if scene_key == "school" and objects.has("friends"):
			for friend in FRIENDS:
				var idle_pos: Vector2 = Vector2(objects.friends) + friend.offset
				_draw_character(idle_pos, str(friend.name), _idle_facing(str(friend.name), idle_pos), true, true)
		if scene_key == "school":
			for person in departures: _draw_character(departures[person].position, person, str(departures[person].facing), true, true, true)
		# El mapa nocturno del cuarto ya trae su propia luz: no se tiñe.
		if evening_light and scene_key != "sofi_room_night":
			draw_rect(ROOM, Color(0.94, 0.38, 0.23, 0.20) if scene_key in ["school", "street"] else Color(0.24, 0.12, 0.38, 0.15))
		for edge in edge_routes:
			var pos: Vector2 = {"left": Vector2(36, 285), "right": Vector2(663, 285), "up": Vector2(340, 125), "down": Vector2(340, 380)}[edge]
			var arrow: String = {"left": "< ", "right": "> ", "up": "^ ", "down": "v "}[edge]
			draw_string(ThemeDB.fallback_font, pos, arrow + str(edge_routes[edge]), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("fff3df"))

func begin_departures() -> void:
	if scene_key not in ["courtyard", "school"] or not departures.is_empty(): return
	objects.erase("friends")
	var exits: Array = [Vector2(47, 290), Vector2(720, 230), Vector2(180, 389), Vector2(550, 389)]
	exits.shuffle()
	for i in FRIENDS.size():
		var friend: Dictionary = FRIENDS[i]
		var endpoint: Vector2 = exits[i]
		departures[str(friend.name)] = {"position": Vector2(374, 245 if routine_mode else 175) + friend.offset, "path": [Vector2(314 + i * 40, 260 + i * 8), Vector2(endpoint.x, 285), endpoint], "step": 0, "speed": randf_range(52.0, 72.0), "facing": "down"}
	queue_redraw()

func _update_departures(delta: float) -> void:
	if departures.is_empty(): return
	for person in departures.keys():
		var walk: Dictionary = departures[person]
		var target: Vector2 = walk.path[int(walk.step)]
		var direction: Vector2 = target - Vector2(walk.position)
		walk.facing = ("right" if direction.x > 0 else "left") if absf(direction.x) > absf(direction.y) else ("down" if direction.y > 0 else "up")
		walk.position = Vector2(walk.position).move_toward(target, float(walk.speed) * delta)
		if Vector2(walk.position).distance_to(target) < 0.5:
			walk.step = int(walk.step) + 1
			if int(walk.step) >= walk.path.size(): departures.erase(person)
	if departures.is_empty(): departure_finished.emit()

func _draw_bedroom_decor() -> void:
	draw_rect(ROOM, Color(0.80, 0.48, 0.71, 0.14))
	var rug := StyleBoxFlat.new()
	rug.bg_color = Color("c496bd")
	rug.border_color = Color("f1cde0")
	rug.set_border_width_all(4)
	rug.set_corner_radius_all(40)
	draw_style_box(rug, Rect2(236, 223, 300, 131))
	draw_arc(Vector2(386, 287), 43, 0, TAU, 40, Color("e6bfd8"), 3)
	for x in range(254, 522, 14):
		draw_line(Vector2(x, 353), Vector2(x, 362), Color("e8c2db"), 2)
	# Guirnalda y recuerdos: decoración de suelo/pared, sin bloquear el paso.
	for x in range(224, 660, 32):
		var y: float = 96 + sin(float(x) * 0.017) * 5
		draw_circle(Vector2(x, y), 5, Color(1.0, 0.76, 0.83, 0.14))
		draw_circle(Vector2(x, y), 2, Color("ffe4bd"))
	for i in range(3):
		var pos := Vector2(338 + i * 30, 138)
		draw_rect(Rect2(pos, Vector2(22, 27)), Color("e8bfd4"))
		draw_rect(Rect2(pos + Vector2(3, 3), Vector2(16, 16)), Color("a88ac3"))
		draw_circle(pos + Vector2(11, 11), 4, Color("ffdfbf"))
	# Tocador con espejo, zapatero y televisor: muebles fuera de las rutas principales.
	draw_rect(Rect2(46, 257, 60, 36), Color("a67c9e"))
	draw_rect(Rect2(50, 261, 52, 13), Color("d8adcb"))
	draw_circle(Vector2(77, 280), 2, Color("f9d9ba"))
	draw_rect(Rect2(54, 212, 44, 42), Color("e6bbd5"))
	draw_rect(Rect2(58, 216, 36, 34), Color("a9cad5"))
	draw_line(Vector2(60, 246), Vector2(88, 218), Color("e0f0ee"), 2)
	for i in range(3):
		draw_rect(Rect2(50 + i * 12, 248, 6, 9), [Color("f0c0d5"), Color("ae8ac6"), Color("e7d1a1")][i])
	draw_rect(Rect2(148, 354, 64, 32), Color("9c748f"))
	for i in range(2):
		draw_rect(Rect2(152, 357 + i * 13, 56, 9), Color("65465d"))
		for j in range(3): _draw_shoe(Vector2(160 + j * 18, 363 + i * 13))
	draw_rect(Rect2(552, 369, 76, 20), Color("a37b95"))
	draw_rect(Rect2(558, 329, 64, 37), Color("392e48"))
	draw_rect(Rect2(562, 333, 56, 29), Color("af95bf"))
	draw_line(Vector2(583, 366), Vector2(594, 366), Color("392e48"), 3)

func _draw_shoe(pos: Vector2) -> void:
	draw_rect(Rect2(pos - Vector2(5, 3), Vector2(11, 5)), Color("e7c8d8"))

func _draw_story_target(key: String, pos: Vector2, active: bool) -> void:
	var color := Color("f5d479") if active else Color("8ec9c2")
	var is_character: bool = key.capitalize() in CHARACTER_SHEETS
	var target_pos: Vector2 = pos
	if is_character: pos = actor_display.get(key, target_pos)
	# Un solo aro por objetivo: el halo del objetivo principal sustituye al aro simple y sigue al personaje.
	if key == story_primary_target:
		_draw_target_glow(pos, key)
	elif routine_mode and key in ["friends", "meal", "lesson"]:
		draw_arc(pos, 20, 0, TAU, 24, color, 2)
	if is_character:
		var walking: bool = pos.distance_to(target_pos) > 1.0
		_draw_character(pos, key.capitalize(), _walk_facing(pos, target_pos) if walking else _idle_facing(key, pos), false, true, walking)
	elif key == "tutoria":
		# El tutor espera junto a la puerta de tutoría.
		if scene_key != "tutor_office": draw_texture_rect(OBJECT_SPRITES.tutoria, Rect2(pos + Vector2(-62, -40), Vector2(48, 54)), false)
		_draw_character(pos, "Tutor", _idle_facing("tutor", pos), false, true)
	elif routine_mode and scene_key.begins_with("sofi_room") and key in ["bed", "pc", "photo"]:
		pass  # Cama, escritorio y fotos ya están pintados en el mapa.
	elif routine_mode and key in ["bed", "photo", "backpack"]:
		if key != "bed": draw_texture_rect(OBJECT_SPRITES[key], Rect2(pos - Vector2(23, 23), Vector2(46, 46)), false)
	elif routine_mode and key in ["friends", "meal", "lesson"]:
		pass
	else:
		draw_rect(Rect2(pos - Vector2(21, 20), Vector2(42, 40)), Color("193448", 0.88), true)
		draw_rect(Rect2(pos - Vector2(21, 20), Vector2(42, 40)), color, false, 2.0)
		if key == "lobby" or key == "pc":
			draw_texture_rect(OBJECT_SPRITES.pc, Rect2(pos - Vector2(17, 17), Vector2(34, 34)), false)
	draw_rect(Rect2(pos + Vector2(-43, -64), Vector2(86, 19)), Color("10192b", 0.9))
	var target_name: String = {"lobby": "Lobby", "tutoria": "Tutor", "pc": "PC", "salida": "Salida", "friends": "Grupo", "bed": "Dormir", "meal": "Comer", "lesson": "Clase", "photo": "Foto", "backpack": "Mochila"}.get(key, key.capitalize())
	draw_string(ThemeDB.fallback_font, pos + Vector2(-42, -49), "F · " + target_name, HORIZONTAL_ALIGNMENT_CENTER, 84, 11, color)
	if key == story_primary_target:
		var bed_marker: Vector2 = Vector2(155, 92) if scene_key.begins_with("sofi_room") else Vector2(131, 104)
		_draw_objective_marker(bed_marker if key == "bed" else pos + Vector2(0, -70))
	if active:
		_draw_press_prompt(pos + Vector2(0, 30))

func _draw_draft_caption() -> void:
	var caption: String = str({"draft_d1": "DÍA 1 · LOBBY", "draft_d2": "DÍA 2 · EXTERIOR DEL COLEGIO", "draft_d3": "DÍA 3 · PASILLO", "draft_d4": "DÍA 4 · PATIO"}.get(scene_key, ""))
	if story_targets_active:
		caption = "DÍA %d · %s" % [int(GameState.coral_state.get("day", 1)), {"draft_d1": "LOBBY", "draft_d2": "EXTERIOR", "draft_d3": "PASILLO", "draft_d4": "PATIO"}.get(scene_key, "")]
	draw_rect(Rect2(56, 62, 355, 27), Color("10192b", 0.8))
	draw_string(ThemeDB.fallback_font, Vector2(65, 81), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("fff3df"))

func _draw_objective_marker(pos: Vector2) -> void:
	# Flecha amarilla grande que rebota sobre el objetivo actual.
	var marker := Color("ffd84d")
	var p: Vector2 = pos + Vector2(0, -absf(sin(anim_time * 4.0)) * 7.0)
	var outline := PackedVector2Array([p + Vector2(-15, -13), p + Vector2(-6, -13), p + Vector2(-6, -24), p + Vector2(6, -24), p + Vector2(6, -13), p + Vector2(15, -13), p + Vector2(0, 5)])
	draw_colored_polygon(outline, Color("10192b"))
	var fill := PackedVector2Array([p + Vector2(-11, -11), p + Vector2(-4, -11), p + Vector2(-4, -21), p + Vector2(4, -21), p + Vector2(4, -11), p + Vector2(11, -11), p + Vector2(0, 1)])
	draw_colored_polygon(fill, marker)
	draw_line(p + Vector2(-2, -19), p + Vector2(-2, -12), Color(1, 1, 1, 0.65), 2.0)

func _draw_target_glow(pos: Vector2, key: String) -> void:
	var pulse: float = 0.5 + 0.5 * sin(anim_time * 3.2)
	if key == "bed":
		# La cama es grande: se resalta todo el mueble y no solo un punto.
		var bed_rect := (SOFI_BED_RECT if scene_key.begins_with("sofi_room") else Rect2(79, 112, 104, 113)).grow(4.0 + pulse * 3.0)
		draw_rect(bed_rect, Color(1.0, 0.85, 0.3, 0.12 + 0.1 * pulse))
		draw_rect(bed_rect, Color("ffd84d"), false, 3.0)
		return
	# En personajes el halo rodea los pies; en objetos, el centro.
	var center: Vector2 = pos + (Vector2(0, 12) if key.capitalize() in CHARACTER_SHEETS or key == "tutoria" else Vector2.ZERO)
	draw_circle(center, 24.0 + pulse * 6.0, Color(1.0, 0.85, 0.3, 0.18 + 0.22 * pulse))
	draw_arc(center, 26.0 + pulse * 6.0, 0, TAU, 32, Color("ffd84d"), 2.5)

func _draw_press_prompt(pos: Vector2) -> void:
	draw_rect(Rect2(pos + Vector2(-34, 0), Vector2(68, 20)), Color("ffd84d"))
	draw_rect(Rect2(pos + Vector2(-34, 0), Vector2(68, 20)), Color("10192b"), false, 2.0)
	draw_string(ThemeDB.fallback_font, pos + Vector2(-34, 15), "Pulsa F", HORIZONTAL_ALIGNMENT_CENTER, 68, 13, Color("10192b"))

func _draw_object(key: String, pos: Vector2, active: bool) -> void:
	var color := Color("f5d479") if active else Color("8ec9c2")
	if key == objective_target():
		_draw_target_glow(pos, key)
		_draw_objective_marker(pos + Vector2(0, -50))
	var sprite_size: Vector2 = OBJECT_SIZES[key]
	draw_texture_rect(OBJECT_SPRITES[key], Rect2(pos - sprite_size * 0.5, sprite_size), false)
	if key in ["alarm", "backpack"] and GameState.flags.get(key, false):
		draw_circle(pos + Vector2(19, -14), 7, Color("54b67c"))
		draw_line(pos + Vector2(16, -14), pos + Vector2(19, -11), Color.WHITE, 2.0)
		draw_line(pos + Vector2(19, -11), pos + Vector2(23, -17), Color.WHITE, 2.0)
	draw_rect(Rect2(pos + Vector2(-41, -45), Vector2(82, 18)), Color("10192b", 0.82))
	draw_string(ThemeDB.fallback_font, pos + Vector2(-41, -30), target_label(key),
		HORIZONTAL_ALIGNMENT_CENTER, 82, 12, color)

func _idle_facing(key: String, pos: Vector2) -> String:
	# Mira a Sofi si está cerca; si no, cambia de postura cada pocos segundos.
	if pos.distance_to(player_pos) < 110.0:
		return _walk_facing(pos, player_pos)
	return IDLE_FACINGS[int(anim_time / 2.6 + _phase(key) * 4.0) % IDLE_FACINGS.size()]

func _walk_facing(from: Vector2, to: Vector2) -> String:
	var d: Vector2 = to - from
	return ("right" if d.x > 0 else "left") if absf(d.x) > absf(d.y) else ("down" if d.y > 0 else "up")

func _phase(actor_name: String) -> float:
	return float(absi(hash(actor_name.to_lower())) % 1000) / 1000.0

func _update_actor_walks(delta: float) -> void:
	if not story_targets_active: return
	for key in objects:
		if not key.capitalize() in CHARACTER_SHEETS: continue
		var target: Vector2 = objects[key]
		if not actor_display.has(key):
			actor_display[key] = target
			continue
		actor_display[key] = Vector2(actor_display[key]).move_toward(target, ACTOR_WALK_SPEED * delta)

func _draw_character(pos: Vector2, actor_name: String, facing: String = "down", compact_label: bool = false, animated := false, walking := false) -> void:
	var texture: Texture2D = CHARACTER_SHEETS[actor_name]
	if walking:
		# Pasos: pequeño rebote y balanceo al caminar.
		pos += Vector2(sin(anim_time * 11.0) * 1.2, -absf(sin(anim_time * 11.0)) * 3.0)
	elif animated:
		var phase: float = _phase(actor_name)
		pos.y += sin(anim_time * 2.3 + phase * TAU) * 1.4
		var cycle: float = fmod(anim_time + phase * 7.0, 7.0)
		if cycle < 0.45:
			# Saltito ocasional para que el grupo no parezca de estatuas.
			pos.y -= sin(cycle / 0.45 * PI) * 9.0
	var half: Vector2 = texture.get_size() * 0.5
	var cell := Vector2.ZERO
	match facing:
		"up": cell = Vector2(1, 0)
		"left": cell = Vector2(0, 1)
		"right": cell = Vector2(1, 1)
	draw_circle(pos + Vector2(0, 13), 11, Color(0, 0, 0, 0.22))
	draw_texture_rect_region(texture, Rect2(pos + Vector2(-23, -25), Vector2(46, 46)),
		Rect2(cell * half, half))
	if compact_label:
		draw_rect(Rect2(pos + Vector2(-22, -47), Vector2(44, 15)), Color("10192b", 0.78))
		draw_string(ThemeDB.fallback_font, pos + Vector2(-22, -35), actor_name,
			HORIZONTAL_ALIGNMENT_CENTER, 44, 9, Color.WHITE)
	elif scene_key == "courtyard" and actor_name == "Sofi":
		draw_rect(Rect2(pos + Vector2(-23, 21), Vector2(46, 15)), Color("10192b", 0.78))
		draw_string(ThemeDB.fallback_font, pos + Vector2(-23, 33), actor_name,
			HORIZONTAL_ALIGNMENT_CENTER, 46, 10, Color.WHITE)
	else:
		draw_rect(Rect2(pos + Vector2(-24, -47), Vector2(70, 17)), Color("10192b", 0.78))
		draw_string(ThemeDB.fallback_font, pos + Vector2(-19, -33), actor_name,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)
