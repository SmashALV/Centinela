extends Node2D
class_name CentinelaWorld

signal interacted(target_id: String)

const SPEED := 152.0
const ROOM := Rect2(30, 56, 708, 338)
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

func configure(key: String, position: Vector2) -> void:
	scene_key = key
	player_pos = position
	if key == "bedroom":
		objects = {"alarm": Vector2(150, 164), "backpack": Vector2(605, 294),
			"desk": Vector2(278, 146), "photo": Vector2(494, 140), "door": Vector2(698, 230)}
	elif key == "courtyard":
		objects = {"friends": Vector2(374, 175), "exit": Vector2(690, 227)}
	else:
		objects = {"pc": Vector2(382, 180)}
	queue_redraw()

func _physics_process(delta: float) -> void:
	if not enabled:
		return
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	player_pos += direction * SPEED * delta
	player_pos.x = clampf(player_pos.x, ROOM.position.x + 16, ROOM.end.x - 16)
	player_pos.y = clampf(player_pos.y, ROOM.position.y + 16, ROOM.end.y - 16)
	GameState.player_position = player_pos
	nearby = ""
	var best := 1.0
	for key in objects:
		var reach := 84.0 if key == "friends" else 49.0
		var distance: float = player_pos.distance_to(objects[key]) / reach
		if distance < best:
			best = distance
			nearby = key
	queue_redraw()

func interact() -> void:
	if enabled and not nearby.is_empty():
		interacted.emit(nearby)

func _draw() -> void:
	var floor_color := Color("312d49") if scene_key == "bedroom" else Color("21453f")
	draw_rect(Rect2(Vector2.ZERO, Vector2(768, 448)), Color("14182b"))
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
	else:
		draw_rect(Rect2(311, 103, 142, 73), Color("425d77"))
	for key in objects:
		var pos: Vector2 = objects[key]
		var active: bool = key == nearby
		if key == "friends":
			var color := Color("f5d479") if active else Color("8ec9c2")
			draw_rect(Rect2(pos + Vector2(-83, -12), Vector2(166, 67)), color, false, 2.0 if active else 1.0)
			draw_string(ThemeDB.fallback_font, pos + Vector2(-31, -23), "F · Grupo", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, color)
			continue
		draw_circle(pos, 18 if active else 14, Color("f5d479") if active else Color("8ec9c2"))
		draw_string(ThemeDB.fallback_font, pos + Vector2(-25, -23), key, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)
	if scene_key == "courtyard":
		for friend in FRIENDS:
			_draw_character(Vector2(objects.friends) + friend.offset, str(friend.name),
				Color(friend.jacket), Color(friend.skin), str(friend.style))
	_draw_character(player_pos, "Sofi", Color("258999"), Color("e2a477"), "long_hair")

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
	draw_string(ThemeDB.fallback_font, pos + Vector2(-19, -23), actor_name,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)
