extends Node2D
class_name CentinelaWorld

signal interacted(target_id: String)

const SPEED := 152.0
const ROOM := Rect2(30, 56, 708, 338)

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
	var best := 49.0
	for key in objects:
		var distance: float = player_pos.distance_to(objects[key])
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
		draw_circle(pos, 18 if active else 14, Color("f5d479") if active else Color("8ec9c2"))
		draw_string(ThemeDB.fallback_font, pos + Vector2(-25, -23), key, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)
	if scene_key == "courtyard":
		for offset in [Vector2(-42, 18), Vector2(0, 18), Vector2(42, 18), Vector2(84, 18)]:
			draw_circle(Vector2(objects.friends) + offset, 10, Color("d9a6af"))
	draw_circle(player_pos, 13, Color("f4b17d"))
	draw_circle(player_pos + Vector2(0, -5), 7, Color("3a2c48"))
	draw_string(ThemeDB.fallback_font, player_pos + Vector2(-13, -21), "Sofi", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
