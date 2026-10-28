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
const TARGET_LABELS := {
	"alarm": "Alarma", "backpack": "Mochila", "desk": "Escritorio",
	"photo": "Foto", "door": "Puerta", "friends": "Grupo",
	"exit": "Salida", "pc": "Computadora", "mateo": "Mateo"
}
const FRIENDS := [
	{"name": "Mateo", "offset": Vector2(-60, 28), "jacket": "2f568c", "skin": "dc9f71", "style": "curly"},
	{"name": "Bruno", "offset": Vector2(-20, 28), "jacket": "87334d", "skin": "c98b61", "style": "glasses"},
	{"name": "Camila", "offset": Vector2(20, 28), "jacket": "d9696a", "skin": "dfa47b", "style": "ponytail"},
	{"name": "Sebas", "offset": Vector2(60, 28), "jacket": "e2ad36", "skin": "e4ae80", "style": "spiky"}
]

var scene_key: String = "bedroom"
var player_pos: Vector2 = Vector2(384, 280)
var enabled: bool = true
var nearby: String = ""
var objects: Dictionary = {}

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

func configure(key: String, position: Vector2) -> void:
	scene_key = key
	player_pos = position
	if key == "bedroom":
		objects = {"alarm": Vector2(150, 164), "backpack": Vector2(605, 294),
			"desk": Vector2(278, 146), "photo": Vector2(494, 140), "door": Vector2(698, 230)}
	elif key == "courtyard":
		objects = {"friends": Vector2(374, 175), "exit": Vector2(690, 227)}
	elif key.begins_with("draft_d"):
		objects = {"mateo": Vector2(520, 225)}
	else:
		objects = {"pc": Vector2(382, 180)}
	queue_redraw()

func _physics_process(delta: float) -> void:
	if not enabled:
		return
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	player_pos += direction * SPEED * delta
	player_pos.x = clampf(player_pos.x, ROOM.position.x + 16, ROOM.end.x - 16)
	var playable_top: float = 185.0 if scene_key.begins_with("draft_d") else ROOM.position.y + 16
	player_pos.y = clampf(player_pos.y, playable_top, ROOM.end.y - 16)
	GameState.player_position = player_pos
	nearby = ""
	var best := 1.0
	for key in objects:
		var reach := 84.0 if key in ["friends", "mateo"] else 49.0
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
	draw_rect(Rect2(Vector2.ZERO, Vector2(768, 448)), Color("14182b"))
	if DRAFT_BACKGROUNDS.has(scene_key):
		var background: Texture2D = DRAFT_BACKGROUNDS[scene_key]
		var source_size: Vector2 = background.get_size()
		var source_height: float = minf(source_size.y, source_size.x * ROOM.size.y / ROOM.size.x)
		draw_texture_rect_region(background, ROOM, Rect2(Vector2.ZERO, Vector2(source_size.x, source_height)))
	else:
		draw_rect(ROOM, floor_color)
		for x in range(30, 738, 32):
			draw_line(Vector2(x, 56), Vector2(x, 394), Color(1, 1, 1, 0.04))
		for y in range(56, 394, 32):
			draw_line(Vector2(30, y), Vector2(738, y), Color(1, 1, 1, 0.04))
	if scene_key == "bedroom":
		draw_rect(Rect2(76, 90, 116, 74), Color("6e5269"))
		draw_rect(Rect2(228, 93, 100, 52), Color("795d51"))
		draw_rect(Rect2(458, 94, 72, 44), Color("92736a"))
	elif scene_key == "courtyard":
		for p in [Vector2(90, 112), Vector2(620, 114), Vector2(560, 325)]:
			draw_circle(p, 33, Color("386b55"))
	elif scene_key.begins_with("draft_d"):
		_draw_draft_caption()
	else:
		draw_rect(Rect2(311, 103, 142, 73), Color("425d77"))
		draw_rect(Rect2(552, 96, 98, 77), Color("8ec9c2"))
		draw_rect(Rect2(557, 101, 88, 67), Color("111b36"))
		draw_line(Vector2(601, 101), Vector2(601, 168), Color("8ec9c2"), 3.0)
	for key in objects:
		var pos: Vector2 = objects[key]
		var active: bool = key == nearby
		if key == "friends":
			var color := Color("f5d479") if active else Color("8ec9c2")
			draw_rect(Rect2(pos + Vector2(-83, -12), Vector2(166, 67)), color, false, 2.0 if active else 1.0)
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
			_draw_character(Vector2(objects.friends) + friend.offset, str(friend.name),
				Color(friend.jacket), Color(friend.skin), str(friend.style))
	elif scene_key.begins_with("draft_d"):
		_draw_character(objects.mateo, "Mateo", Color("2f568c"), Color("dc9f71"), "curly")
		if scene_key == "draft_d1":
			_draw_character(Vector2(330, 245), "Camila", Color("d9696a"), Color("dfa47b"), "ponytail")
			_draw_character(Vector2(260, 250), "Bruno", Color("87334d"), Color("c98b61"), "glasses")
			_draw_character(Vector2(400, 250), "Sebas", Color("e2ad36"), Color("e4ae80"), "spiky")
	_draw_character(player_pos, "Sofi", Color("258999"), Color("e2a477"), "long_hair")

func _draw_draft_caption() -> void:
	var caption: String = str({"draft_d1": "DÍA 1 · LOBBY", "draft_d2": "DÍA 2 · EXTERIOR DEL COLEGIO", "draft_d3": "DÍA 3 · PASILLO", "draft_d4": "DÍA 4 · PATIO"}.get(scene_key, ""))
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
	var dark := Color("182a38")
	if key == objective_target():
		draw_arc(pos, 27, 0, TAU, 24, Color("f5d479"), 2.0)
		_draw_objective_marker(pos + Vector2(0, 32))
	match key:
		"alarm":
			draw_rect(Rect2(pos + Vector2(-14, -10), Vector2(28, 21)), color)
			draw_rect(Rect2(pos + Vector2(-10, -6), Vector2(20, 13)), dark)
			draw_circle(pos + Vector2(-11, -13), 4, color)
			draw_circle(pos + Vector2(11, -13), 4, color)
			draw_string(ThemeDB.fallback_font, pos + Vector2(-8, 4), "7:00", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.WHITE)
		"backpack":
			draw_arc(pos + Vector2(0, -8), 8, PI, TAU, 12, color, 3.0)
			draw_rect(Rect2(pos + Vector2(-13, -10), Vector2(26, 25)), color)
			draw_rect(Rect2(pos + Vector2(-9, 4), Vector2(18, 8)), dark)
		"desk":
			draw_rect(Rect2(pos + Vector2(-18, -5), Vector2(36, 7)), color)
			draw_rect(Rect2(pos + Vector2(-15, 2), Vector2(4, 15)), color)
			draw_rect(Rect2(pos + Vector2(11, 2), Vector2(4, 15)), color)
			draw_rect(Rect2(pos + Vector2(-9, -14), Vector2(17, 9)), dark)
		"photo":
			draw_rect(Rect2(pos + Vector2(-14, -13), Vector2(28, 26)), color)
			draw_rect(Rect2(pos + Vector2(-10, -9), Vector2(20, 18)), dark)
			draw_circle(pos + Vector2(5, -4), 3, color)
			draw_line(pos + Vector2(-9, 8), pos + Vector2(-2, 0), color, 2.0)
			draw_line(pos + Vector2(-2, 0), pos + Vector2(9, 8), color, 2.0)
		"door", "exit":
			draw_rect(Rect2(pos + Vector2(-13, -18), Vector2(26, 35)), color)
			draw_rect(Rect2(pos + Vector2(-9, -14), Vector2(18, 29)), dark)
			draw_circle(pos + Vector2(5, 2), 2, color)
		"pc":
			draw_rect(Rect2(pos + Vector2(-18, -16), Vector2(36, 25)), color)
			draw_rect(Rect2(pos + Vector2(-14, -12), Vector2(28, 17)), dark)
			draw_rect(Rect2(pos + Vector2(-2, 9), Vector2(4, 7)), color)
			draw_line(pos + Vector2(-12, 17), pos + Vector2(12, 17), color, 3.0)
	if key in ["alarm", "backpack"] and GameState.flags.get(key, false):
		draw_circle(pos + Vector2(19, -14), 7, Color("54b67c"))
		draw_line(pos + Vector2(16, -14), pos + Vector2(19, -11), Color.WHITE, 2.0)
		draw_line(pos + Vector2(19, -11), pos + Vector2(23, -17), Color.WHITE, 2.0)
	draw_string(ThemeDB.fallback_font, pos + Vector2(-41, -30), target_label(key),
		HORIZONTAL_ALIGNMENT_CENTER, 82, 12, color)

func _draw_character(pos: Vector2, actor_name: String, jacket: Color, skin: Color, style: String) -> void:
	var hair := Color("302b38")
	draw_circle(pos + Vector2(0, 11), 13, Color(0, 0, 0, 0.26))
	draw_rect(Rect2(pos + Vector2(-10, 1), Vector2(20, 16)), jacket)
	draw_rect(Rect2(pos + Vector2(-3, 3), Vector2(6, 12)), Color("e8e2d6"))
	if style == "ponytail":
		draw_circle(pos + Vector2(11, -11), 6, hair)
	elif style == "long_hair":
		draw_circle(pos + Vector2(-8, -3), 6, hair)
		draw_circle(pos + Vector2(8, -3), 6, hair)
	draw_circle(pos + Vector2(0, -7), 9, hair)
	draw_circle(pos + Vector2(0, -5), 7, skin)
	match style:
		"curly":
			for dx in [-6.0, 0.0, 6.0]:
				draw_circle(pos + Vector2(dx, -12), 3, hair)
		"glasses":
			draw_rect(Rect2(pos + Vector2(-6, -8), Vector2(5, 4)), Color.WHITE, false, 1.0)
			draw_rect(Rect2(pos + Vector2(1, -8), Vector2(5, 4)), Color.WHITE, false, 1.0)
			draw_line(pos + Vector2(-1, -6), pos + Vector2(1, -6), Color.WHITE, 1.0)
		"ponytail":
			draw_arc(pos + Vector2(0, -8), 8, PI, TAU, 8, hair, 3.0)
		"spiky":
			draw_colored_polygon(PackedVector2Array([
			pos + Vector2(-8, -11), pos + Vector2(-6, -18), pos + Vector2(-2, -13),
			pos + Vector2(2, -19), pos + Vector2(5, -13), pos + Vector2(9, -16),
			pos + Vector2(8, -9)
		]), hair)
		"long_hair":
			draw_arc(pos + Vector2(0, -5), 8, PI, TAU, 8, hair, 3.0)
	draw_rect(Rect2(pos + Vector2(-24, -37), Vector2(70, 17)), Color("10192b", 0.78))
	draw_string(ThemeDB.fallback_font, pos + Vector2(-19, -23), actor_name,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)
