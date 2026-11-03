extends RefCounted
## Catálogo de mapas explorables: fondo, colisiones, piso de baldosas y props de cada lugar.
## Los datos viven en data/maps/maps.json; para añadir un lugar basta con su entrada y su imagen.

const PATH := "res://data/maps/maps.json"
const VERSION := "MAPS_v1"

static var _maps: Dictionary = {}


## Todos los mapas (se leen una sola vez).
static func maps() -> Dictionary:
	if _maps.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		if typeof(parsed) == TYPE_DICTIONARY and parsed.get("version") == VERSION:
			_maps = parsed.get("maps", {})
		else:
			push_error("Catálogo de mapas inválido: " + PATH)
	return _maps


static func has_map(key: String) -> bool:
	return maps().has(key)


## Ruta de la imagen de fondo del mapa.
static func background(key: String) -> String:
	return str(maps().get(key, {}).get("background", ""))


## Atlas de baldosas del piso; vacío si el fondo ya trae el piso pintado.
static func ground_tiles(key: String) -> String:
	return str(maps().get(key, {}).get("ground_tiles", ""))


## Colisiones del mapa como rectángulos del juego.
static func blocks(key: String) -> Array[Rect2]:
	var result: Array[Rect2] = []
	for b in maps().get(key, {}).get("blocks", []):
		result.append(_to_rect(b))
	return result


## Muebles que se dibujan encima del fondo: {"sprite": nombre, "rect": Rect2}.
static func props(key: String) -> Array:
	var result: Array = []
	for prop in maps().get(key, {}).get("props", []):
		result.append({"sprite": str(prop.get("sprite", "")), "rect": _to_rect(prop.get("rect", [0, 0, 0, 0]))})
	return result


## Si el jugador aparece dentro de una colisión, se le aparta (mapas del borrador antiguo).
static func keeps_player_clear(key: String) -> bool:
	return bool(maps().get(key, {}).get("keep_player_clear", false))


## Errores del JSON (vacío si todo está bien). `prop_names` son los sprites que World sabe dibujar.
static func validate(prop_names: Array) -> Array[String]:
	var errors: Array[String] = []
	for key in maps():
		if not ResourceLoader.exists(background(key)): errors.append("Fondo inexistente en " + key)
		var tiles: String = ground_tiles(key)
		if not tiles.is_empty() and not ResourceLoader.exists(tiles): errors.append("Baldosas inexistentes en " + key)
		for b in maps()[key].get("blocks", []):
			if typeof(b) != TYPE_ARRAY or b.size() != 4: errors.append("Colisión inválida en " + key)
		for prop in props(key):
			if prop.sprite not in prop_names: errors.append("Prop desconocido en %s: %s" % [key, prop.sprite])
	return errors


static func _to_rect(values: Array) -> Rect2:
	return Rect2(float(values[0]), float(values[1]), float(values[2]), float(values[3]))
