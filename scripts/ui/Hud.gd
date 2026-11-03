extends RefCounted
## Barra superior con el objetivo del momento y panel de inventario.
## Se movió desde Main.gd sin cambios de comportamiento (paso 8 de la migración modular).

var main: Node

func build_inventory_panel() -> void:
	# Hijo del HUD: se oculta junto con él en menús y conversaciones.
	main.inventory_panel = PanelContainer.new()
	main.inventory_panel.name = "InventoryPanel"
	main.inventory_panel.position = Vector2(560, 352)
	main.inventory_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color("10192bd9")
	style.border_color = Color("f5d479")
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(5)
	main.inventory_panel.add_theme_stylebox_override("panel", style)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	main.inventory_panel.add_child(row)
	var icon := TextureRect.new()
	icon.texture = main.WorldScript.OBJECT_SPRITES.backpack
	icon.custom_minimum_size = Vector2(26, 26)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(icon)
	main.inventory_label = Label.new()
	main.inventory_label.name = "InventoryText"
	main.inventory_label.add_theme_font_size_override("font_size", 13)
	main.inventory_label.add_theme_color_override("font_color", Color("fff3df"))
	row.add_child(main.inventory_label)
	main.hud.add_child(main.inventory_panel)
	main.inventory_panel.visible = false

func refresh_inventory() -> void:
	if not is_instance_valid(main.inventory_panel): return
	var items: Array = GameState.flags.get("inventory", [])
	main.inventory_panel.visible = not items.is_empty()
	main.inventory_label.text = "Inventario: " + ", ".join(items.map(func(item): return str(item).capitalize()))

func update() -> void:
	refresh_inventory()
	if main.daily.active():
		main.hud.text = "DÍA %d · %s" % [int(main.daily.state().day), main.daily.objective()]
		return
	if GameState.phase == "coral":
		main.hud.text = "DÍA %d · %s" % [int(GameState.coral_state.get("day", 1)), objective_text()]
		return
	if GameState.phase == "preview":
		if GameState.flags.get("draft_exploring", false):
			var day_number: int = int(GameState.preview_scene.substr(1, 1))
			main.hud.text = "DÍA %d · %s" % [day_number, objective_text()]
		else:
			var active_scene: Dictionary = main.preview_catalog.get_scene(GameState.preview_scene)
			main.hud.text = main.legacy.scene_title(active_scene)
		return
	var place: String = {"bedroom": "HABITACIÓN", "courtyard": "PATIO", "computer": "COMPUTADORA", "result": "RESULTADO"}.get(GameState.phase, GameState.phase.to_upper())
	main.hud.text = "DÍA 0 · %s | %s" % [place, objective_text()]

func objective_text() -> String:
	if main.daily.active(): return main.daily.objective()
	match GameState.phase:
		"bedroom":
			if not GameState.flags.get("alarm", false): return "Usa la alarma"
			if not GameState.flags.get("backpack", false): return "Recoge la mochila"
			return "Ve a la puerta"
		"courtyard":
			if not GameState.flags.get("friends", false): return "Acércate al grupo"
			return "Ve a la salida"
		"computer": return "Usa la computadora"
		"result": return "Continúa la historia D1–D4"
		"preview": return "Habla con Mateo" if GameState.flags.get("draft_exploring", false) else "Continúa la conversación"
		"coral": return main.coral_flow.objective(GameState.coral_state)
	return ""
