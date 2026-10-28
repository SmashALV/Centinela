extends SceneTree

# Creates four exact 32×32 translucent variants per map. The painted maps remain the backdrop.
const OUTPUT := "res://assets/world/tiles"
const SPECS := [
	{"name": "day0_bedroom_floor.png", "grout": Color(0.62, 0.64, 0.78, 0.18), "detail": Color(0.96, 0.77, 0.62, 0.08), "seed": 10},
	{"name": "day0_courtyard_paving.png", "grout": Color(0.43, 0.54, 0.60, 0.18), "detail": Color(0.99, 0.90, 0.68, 0.08), "seed": 20},
	{"name": "day0_computer_floor.png", "grout": Color(0.52, 0.66, 0.74, 0.17), "detail": Color(0.79, 0.88, 0.90, 0.07), "seed": 30},
	{"name": "day1_lobby_floor.png", "grout": Color(0.62, 0.78, 0.83, 0.24), "detail": Color(0.78, 0.86, 0.88, 0.10), "seed": 101},
	{"name": "day2_exterior_paving.png", "grout": Color(0.30, 0.38, 0.48, 0.19), "detail": Color(0.72, 0.66, 0.56, 0.11), "seed": 202},
	{"name": "day3_corridor_floor.png", "grout": Color(0.51, 0.64, 0.70, 0.23), "detail": Color(0.82, 0.87, 0.87, 0.12), "seed": 303},
	{"name": "day4_courtyard_paving.png", "grout": Color(0.39, 0.48, 0.52, 0.25), "detail": Color(0.96, 0.88, 0.68, 0.10), "seed": 404}
]

func _initialize() -> void:
	var absolute: String = ProjectSettings.globalize_path(OUTPUT)
	if DirAccess.make_dir_recursive_absolute(absolute) != OK:
		printerr("No se pudo crear la carpeta de tiles")
		quit(1)
		return
	for spec in SPECS:
		var image := Image.create(128, 32, false, Image.FORMAT_RGBA8)
		image.fill(Color.TRANSPARENT)
		for variant in 4:
			var offset: int = variant * 32
			var random := RandomNumberGenerator.new()
			random.seed = int(spec.seed) + variant * 97
			for coordinate in 32:
				image.set_pixel(offset + coordinate, 0, spec.grout)
				image.set_pixel(offset, coordinate, spec.grout)
			for point in 16 + variant * 3:
				var px: int = random.randi_range(2, 29)
				var py: int = random.randi_range(2, 29)
				image.set_pixel(offset + px, py, spec.detail)
		var path: String = OUTPUT + "/" + str(spec.name)
		if image.save_png(path) != OK:
			printerr("No se pudo guardar " + path)
			quit(1)
			return
		print("Tile generado: ", path)
	quit()
