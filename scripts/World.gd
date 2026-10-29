extends Node2D
class_name CentinelaWorld

signal interacted(target_id: String)

const SPEED := 152.0
const ROOM := Rect2(30, 56, 708, 338)
const DRAFT_BACKGROUNDS := {
	"draft_d1": preload("res://assets/world/day1_lobby_generated.png"),
	"draft_d2": preload("res://assets/world/day2_school_exterior_generated.png"),
	"draft_d3": preload("res://assets/world/day3_corridor_generated.png"),
	"draft_d4": preload("res://assets/world/day4_courtyard_generated.png")
}
const DAY0_BACKGROUNDS := {
	"bedroom": preload("res://assets/world/day0_bedroom.png"),
	"courtyard": preload("res://assets/world/day0_courtyard.png"),
	"computer": preload("res://assets/world/day0_computer_room.png")
}
const GROUND_TILES := {
	"bedroom": "res://assets/world/tiles/day0_bedroom_floor.png",
	"courtyard": "res://assets/world/tiles/day0_courtyard_paving.png",
	"computer": "res://assets/world/tiles/day0_computer_floor.png",
	"draft_d1": "res://assets/world/tiles/day1_lobby_floor.png",
	"draft_d2": "res://assets/world/tiles/day2_exterior_paving.png",
	"draft_d3": "res://assets/world/tiles/day3_corridor_floor.png",
	"draft_d4": "res://assets/world/tiles/day4_courtyard_paving.png"
}
const CHARACTER_SHEETS := {
	"Sofi": preload("res://assets/characters/sofi_directions.png"),
	"Mateo": preload("res://assets/characters/mateo_directions.png"),
	"Bruno": preload("res://assets/characters/bruno_directions.png"),
	"Camila": preload("res://assets/characters/camila_directions.png"),
	"Sebas": preload("res://assets/characters/sebas_directions.png")
}
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
const SCENE_PROPS := {
	"bedroom": [
		{"sprite": "bed", "rect": Rect2(79, 112, 104, 113)},
		{"sprite": "wardrobe", "rect": Rect2(451, 101, 86, 74)},
		{"sprite": "bookshelf", "rect": Rect2(565, 109, 86, 57)},
		{"sprite": "plant", "rect": Rect2(669, 121, 44, 50)},
		{"sprite": "plant", "rect": Rect2(53, 323, 49, 58)},
		{"sprite": "plant", "rect": Rect2(654, 325, 48, 55)}
	],
	"courtyard": [
		{"sprite": "tree", "rect": Rect2(44, 113, 90, 91)},
		{"sprite": "tree", "rect": Rect2(607, 110, 90, 91)},
		{"sprite": "tree", "rect": Rect2(572, 299, 90, 91)},
		{"sprite": "bench", "rect": Rect2(157, 145, 91, 43)},
		{"sprite": "bench", "rect": Rect2(508, 145, 91, 43)},
		{"sprite": "plant", "rect": Rect2(266, 113, 40, 46)},
		{"sprite": "plant", "rect": Rect2(455, 113, 40, 46)}
	],
	"computer": [
		{"sprite": "bookshelf", "rect": Rect2(93, 117, 104, 67)},
		{"sprite": "plant", "rect": Rect2(610, 133, 51, 58)}
	]
}
const DAY0_BLOCKS := {
	"bedroom": [[30, 56, 708, 52], [86, 123, 91, 94], [238, 124, 80, 39], [455, 112, 78, 55], [569, 118, 78, 47], [680, 151, 24, 20]],
	"courtyard": [[30, 56, 708, 55], [75, 171, 29, 22], [638, 168, 29, 22], [603, 357, 29, 22], [162, 153, 81, 22], [513, 153, 81, 22], [277, 141, 18, 15], [466, 141, 18, 15]],
	"computer": [[30, 56, 708, 62], [97, 129, 96, 51], [343, 155, 78, 43], [626, 161, 20, 25]]
}
const DRAFT_BLOCKS := {
	"draft_d1": [[30, 56, 708, 123], [30, 178, 130, 42], [30, 215, 99, 150], [681, 205, 57, 165]],
	"draft_d2": [[30, 56, 375, 124], [30, 180, 154, 64], [530, 125, 35, 60], [434, 197, 68, 28], [30, 345, 142, 49], [620, 346, 118, 48]],
	"draft_d3": [[30, 56, 708, 117], [30, 342, 122, 52], [626, 342, 112, 52]],
	"draft_d4": [[30, 56, 708, 107], [80, 163, 112, 34], [185, 163, 115, 50], [575, 163, 100, 50], [625, 163, 113, 34], [30, 349, 145, 45], [616, 349, 122, 45]]
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
	scene_key = key
	player_pos = position
	story_targets_active = false
	story_primary_target = ""
	_configure_layers()
	if key == "bedroom":
		objects = {"alarm": Vector2(150, 164), "backpack": Vector2(605, 294),
			"desk": Vector2(278, 146), "photo": Vector2(494, 140), "door": Vector2(698, 230)}
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
	map_sprite.visible = DRAFT_BACKGROUNDS.has(scene_key) or DAY0_BACKGROUNDS.has(scene_key)
	ground_layer.visible = map_sprite.visible
	ground_layer.clear()
	if map_sprite.visible:
		var texture: Texture2D = DRAFT_BACKGROUNDS[scene_key] if DRAFT_BACKGROUNDS.has(scene_key) else DAY0_BACKGROUNDS[scene_key]
		var size: Vector2 = texture.get_size()
		var crop_height: float = minf(size.y, size.x * ROOM.size.y / ROOM.size.x)
		map_sprite.texture = texture
		map_sprite.region_rect = Rect2(Vector2.ZERO, Vector2(size.x, crop_height))
		map_sprite.position = ROOM.position
		map_sprite.scale = Vector2(ROOM.size.x / size.x, ROOM.size.y / crop_height)
		_configure_ground_tiles()
		var blocks: Array = DRAFT_BLOCKS[scene_key] if DRAFT_BLOCKS.has(scene_key) else DAY0_BLOCKS[scene_key]
		for dimensions in blocks:
			_add_obstacle(Rect2(float(dimensions[0]), float(dimensions[1]), float(dimensions[2]), float(dimensions[3])))
		if DRAFT_BLOCKS.has(scene_key):
			for dimensions in blocks:
				if Rect2(float(dimensions[0]), float(dimensions[1]), float(dimensions[2]), float(dimensions[3])).grow(11.0).has_point(player_pos):
					player_pos = Vector2(180, 315)
					break
	else:
		map_sprite.texture = null
		ground_layer.tile_set = null
	player_body.position = player_pos

func _configure_ground_tiles() -> void:
	var tile_texture: Texture2D = load(GROUND_TILES[scene_key]) as Texture2D
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
	for prop in SCENE_PROPS.get(scene_key, []):
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
			_draw_objective_marker(pos + Vector2(0, 31))
			continue
		_draw_object(key, pos, active)
	if scene_key == "courtyard":
		for friend in FRIENDS:
			_draw_character(Vector2(objects.friends) + friend.offset, str(friend.name), "down", true)
	elif scene_key.begins_with("draft_d") and not story_targets_active:
		_draw_character(objects.mateo, "Mateo")
		if scene_key == "draft_d1":
			_draw_character(Vector2(330, 245), "Camila")
			_draw_character(Vector2(260, 250), "Bruno")
			_draw_character(Vector2(400, 250), "Sebas")
	_draw_character(player_pos, "Sofi", player_facing)

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
	for i in range(3):
		draw_rect(Rect2(546, 346 - i * 5, 36 - i * 3, 5), [Color("c19bcf"), Color("e8b0c6"), Color("ebd5ad")][i])

func _draw_story_target(key: String, pos: Vector2, active: bool) -> void:
	var color := Color("f5d479") if active else Color("8ec9c2")
	if key.capitalize() in CHARACTER_SHEETS:
		_draw_character(pos, key.capitalize())
	else:
		draw_rect(Rect2(pos - Vector2(21, 20), Vector2(42, 40)), Color("193448", 0.88), true)
		draw_rect(Rect2(pos - Vector2(21, 20), Vector2(42, 40)), color, false, 2.0)
		if key == "lobby" or key == "pc":
			draw_texture_rect(OBJECT_SPRITES.pc, Rect2(pos - Vector2(17, 17), Vector2(34, 34)), false)
	draw_rect(Rect2(pos + Vector2(-43, -64), Vector2(86, 19)), Color("10192b", 0.9))
	var target_name: String = {"lobby": "Lobby", "tutoria": "Tutoría", "pc": "PC", "salida": "Salida"}.get(key, key.capitalize())
	draw_string(ThemeDB.fallback_font, pos + Vector2(-42, -49), "F · " + target_name, HORIZONTAL_ALIGNMENT_CENTER, 84, 11, color)
	if key == story_primary_target:
		_draw_objective_marker(pos + Vector2(0, 31))

func _draw_draft_caption() -> void:
	var caption: String = str({"draft_d1": "DÍA 1 · LOBBY", "draft_d2": "DÍA 2 · EXTERIOR DEL COLEGIO", "draft_d3": "DÍA 3 · PASILLO", "draft_d4": "DÍA 4 · PATIO"}.get(scene_key, ""))
	if story_targets_active:
		caption = "DÍA %d · %s" % [int(GameState.coral_state.get("day", 1)), {"draft_d1": "LOBBY", "draft_d2": "EXTERIOR", "draft_d3": "PASILLO", "draft_d4": "PATIO"}.get(scene_key, "")]
	draw_rect(Rect2(56, 62, 355, 27), Color("10192b", 0.8))
	draw_string(ThemeDB.fallback_font, Vector2(65, 81), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("fff3df"))

func _draw_objective_marker(pos: Vector2) -> void:
	var marker := Color("f5d479")
	draw_colored_polygon(PackedVector2Array([
		pos + Vector2(-7, -2), pos + Vector2(7, -2), pos + Vector2(0, 9)
	]), Color("10192b"))
	draw_colored_polygon(PackedVector2Array([
		pos + Vector2(-5, 0), pos + Vector2(5, 0), pos + Vector2(0, 6)
	]), marker)

func _draw_object(key: String, pos: Vector2, active: bool) -> void:
	var color := Color("f5d479") if active else Color("8ec9c2")
	if key == objective_target():
		draw_arc(pos, 27, 0, TAU, 24, Color("f5d479"), 2.0)
		_draw_objective_marker(pos + Vector2(0, 32))
	var sprite_size: Vector2 = OBJECT_SIZES[key]
	draw_texture_rect(OBJECT_SPRITES[key], Rect2(pos - sprite_size * 0.5, sprite_size), false)
	if key in ["alarm", "backpack"] and GameState.flags.get(key, false):
		draw_circle(pos + Vector2(19, -14), 7, Color("54b67c"))
		draw_line(pos + Vector2(16, -14), pos + Vector2(19, -11), Color.WHITE, 2.0)
		draw_line(pos + Vector2(19, -11), pos + Vector2(23, -17), Color.WHITE, 2.0)
	draw_rect(Rect2(pos + Vector2(-41, -45), Vector2(82, 18)), Color("10192b", 0.82))
	draw_string(ThemeDB.fallback_font, pos + Vector2(-41, -30), target_label(key),
		HORIZONTAL_ALIGNMENT_CENTER, 82, 12, color)

func _draw_character(pos: Vector2, actor_name: String, facing: String = "down", compact_label: bool = false) -> void:
	var texture: Texture2D = CHARACTER_SHEETS[actor_name]
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
