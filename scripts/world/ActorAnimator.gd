extends RefCounted
## Animación de los personajes del mapa: respiración, saltito ocasional, cambio de postura,
## caminata hacia un nuevo lugar y despedidas. Guarda el estado de la animación; el dibujo
## lo hace World con los desplazamientos que calcula este módulo.

const WALK_SPEED := 68.0
const IDLE_FACINGS := ["down", "left", "down", "right"]
const DEPARTURE_EXITS := [Vector2(47, 290), Vector2(720, 230), Vector2(180, 389), Vector2(550, 389)]

## Tiempo de animación acumulado (segundos).
var time := 0.0
## Posición visible de cada personaje: camina hacia su objetivo en vez de aparecer de golpe.
var display: Dictionary = {}
## Amigos que se van caminando: nombre → {position, path, step, speed, facing}.
var departures: Dictionary = {}


func reset() -> void:
	display.clear()
	departures.clear()


## Hacia dónde mira un personaje quieto: a Sofi si está cerca; si no, cambia cada pocos segundos.
func idle_facing(key: String, pos: Vector2, player_pos: Vector2) -> String:
	if pos.distance_to(player_pos) < 110.0:
		return walk_facing(pos, player_pos)
	return IDLE_FACINGS[int(time / 2.6 + phase(key) * 4.0) % IDLE_FACINGS.size()]


## Dirección de la vista al caminar de un punto a otro.
static func walk_facing(from: Vector2, to: Vector2) -> String:
	var d: Vector2 = to - from
	return ("right" if d.x > 0 else "left") if absf(d.x) > absf(d.y) else ("down" if d.y > 0 else "up")


## Desfase propio de cada personaje para que no se muevan todos a la vez.
static func phase(actor_name: String) -> float:
	return float(absi(hash(actor_name.to_lower())) % 1000) / 1000.0


## Desplazamiento del dibujo: pasos al caminar; respiración y saltito al estar quieto.
func pose_offset(actor_name: String, animated: bool, walking: bool) -> Vector2:
	if walking:
		return Vector2(sin(time * 11.0) * 1.2, -absf(sin(time * 11.0)) * 3.0)
	if not animated:
		return Vector2.ZERO
	var p: float = phase(actor_name)
	var offset := Vector2(0, sin(time * 2.3 + p * TAU) * 1.4)
	var cycle: float = fmod(time + p * 7.0, 7.0)
	if cycle < 0.45:
		# Saltito ocasional para que el grupo no parezca de estatuas.
		offset.y -= sin(cycle / 0.45 * PI) * 9.0
	return offset


## Acerca la posición visible de cada personaje a su objetivo actual.
func update_walks(delta: float, objects: Dictionary, character_names: Array) -> void:
	for key in objects:
		if not key.capitalize() in character_names: continue
		var target: Vector2 = objects[key]
		if not display.has(key):
			display[key] = target
			continue
		display[key] = Vector2(display[key]).move_toward(target, WALK_SPEED * delta)


## Prepara la despedida: cada amigo sale hacia una salida distinta a su propia velocidad.
func start_departures(friends: Array, center: Vector2) -> void:
	var exits: Array = DEPARTURE_EXITS.duplicate()
	exits.shuffle()
	for i in friends.size():
		var friend: Dictionary = friends[i]
		var endpoint: Vector2 = exits[i]
		departures[str(friend.name)] = {"position": center + friend.offset, "path": [Vector2(314 + i * 40, 260 + i * 8), Vector2(endpoint.x, 285), endpoint], "step": 0, "speed": randf_range(52.0, 72.0), "facing": "down"}


## Avanza las despedidas. Devuelve true cuando el último amigo acaba de salir.
func update_departures(delta: float) -> bool:
	if departures.is_empty(): return false
	for person in departures.keys():
		var walk: Dictionary = departures[person]
		var target: Vector2 = walk.path[int(walk.step)]
		walk.facing = walk_facing(Vector2(walk.position), target)
		walk.position = Vector2(walk.position).move_toward(target, float(walk.speed) * delta)
		if Vector2(walk.position).distance_to(target) < 0.5:
			walk.step = int(walk.step) + 1
			if int(walk.step) >= walk.path.size(): departures.erase(person)
	return departures.is_empty()
