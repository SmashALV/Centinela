extends RefCounted
## Piezas comunes de interfaz: paneles, títulos, botones, textos y tamaño de letra.
## Se movió desde Main.gd sin cambios de comportamiento (paso 8 de la migración modular).

var main: Node

func make_label(pos: Vector2, dimensions: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.position = pos
	label.size = dimensions
	label.add_theme_font_size_override("font_size", scaled_text_size(font_size))
	label.add_theme_color_override("font_color", Color("fff3df"))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main.canvas.add_child(label)
	return label

func make_screen_icon(key: String, pos: Vector2, icon_size: int) -> TextureRect:
	var icon := TextureRect.new()
	icon.texture = main.UI_ICONS[key]
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.position = pos
	icon.size = Vector2(icon_size, icon_size)
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main.canvas.add_child(icon)
	return icon

func scaled_text_size(base: int) -> int:
	match GameState.text_size:
		"small": return maxi(12, roundi(base * 0.9))
		"large": return roundi(base * 1.3)
	return base

func refresh_static_fonts() -> void:
	main.hud.add_theme_font_size_override("font_size", scaled_text_size(16))
	main.prompt.add_theme_font_size_override("font_size", scaled_text_size(17))
	main.toast.add_theme_font_size_override("font_size", scaled_text_size(15))

func panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("594060")
	style.border_color = Color("d5a4ca")
	style.set_border_width_all(3)
	style.set_content_margin_all(20)
	return style

func clear_modal() -> void:
	if is_instance_valid(main.desktop_ui): main.desktop_ui.clear_view()
	if is_instance_valid(main.conversation_ui):
		main.conversation_ui.clear_view()
	main.prompt.visible = true
	main.hud.visible = not GameState.code.is_empty()
	main.hud_icon.visible = main.hud.visible
	main.menu_background.visible = false
	main.modal.position = Vector2(70, 38)
	main.modal.custom_minimum_size = Vector2(628, 372)
	main.modal.size = Vector2(628, 372)
	for child in main.modal_box.get_children():
		main.modal_box.remove_child(child)
		child.queue_free()
	main.modal.visible = true
	main.world.enabled = false

func close_modal() -> void:
	if main.modal_kind in ["phone", "objective", "class", "desktop", "discord_history"] and not GameState.ui_modal.is_empty():
		if main.save_in_progress:
			return
		main.save_in_progress = true
		var previous: String = GameState.ui_modal
		GameState.ui_modal = ""
		if not await SaveManager.save_slot_async():
			GameState.ui_modal = previous
			main.save_in_progress = false
			main._toast("No se pudo guardar el cierre; reintenta")
			return
		main.save_in_progress = false
	main.modal_kind = ""
	if is_instance_valid(main.desktop_ui): main.desktop_ui.clear_view()
	main.modal.visible = false
	if is_instance_valid(main.conversation_ui):
		main.conversation_ui.clear_view()
	main.prompt.visible = true
	main.menu_background.visible = false
	main.world.enabled = true
	main.hud.visible = not GameState.code.is_empty()
	main.hud_icon.visible = main.hud.visible

func begin_conversation_presentation() -> void:
	clear_modal()
	main.modal.visible = false
	main.hud.visible = false
	main.hud_icon.visible = false
	main.prompt.visible = false
	main.prompt_icon.visible = false

func modal_text(value: String, size: int = 18) -> void:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.y = 38
	label.add_theme_font_size_override("font_size", scaled_text_size(size))
	label.add_theme_color_override("font_color", Color("fff3df"))
	main.modal_box.add_child(label)

func modal_heading(value: String, icon_key: String, size: int = 23) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	main.modal_box.add_child(row)
	var icon := TextureRect.new()
	icon.texture = main.UI_ICONS[icon_key]
	icon.custom_minimum_size = Vector2(32, 32)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	row.add_child(icon)
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", scaled_text_size(size))
	label.add_theme_color_override("font_color", Color("fff3df"))
	row.add_child(label)

func make_button(value: String, callback: Callable, icon_key: String = "", parent: Control = null) -> Button:
	var button := Button.new()
	button.text = value
	button.custom_minimum_size.y = 34
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if not icon_key.is_empty():
		button.icon = main.UI_ICONS[icon_key]
		button.expand_icon = true
	button.add_theme_font_size_override("font_size", scaled_text_size(16))
	button.pressed.connect(callback)
	if parent == null:
		main.modal_box.add_child(button)
	else:
		parent.add_child(button)
	return button

func content_box() -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(565, 256)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main.modal_box.add_child(scroll)
	var body := VBoxContainer.new()
	body.custom_minimum_size.x = 555
	body.add_theme_constant_override("separation", 10)
	scroll.add_child(body)
	return body

func add_text(parent: Container, value: String, size: int = 16, width: int = 545) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = width
	label.add_theme_font_size_override("font_size", scaled_text_size(size))
	label.add_theme_color_override("font_color", Color("fff3df"))
	parent.add_child(label)
	return label

func add_button(parent: VBoxContainer, value: String, callback: Callable, icon_key: String = "") -> Button:
	var button := Button.new()
	button.text = value
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.custom_minimum_size = Vector2(545, 44)
	if not icon_key.is_empty():
		button.icon = main.UI_ICONS[icon_key]
		button.expand_icon = true
	button.add_theme_font_size_override("font_size", scaled_text_size(16))
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func scene_sprite_key(speaker: String, scene_id: String, choice: String = "") -> String:
	if speaker == "Mateo" and scene_id in ["D4_B1", "D4_B2", "D4_A1", "D4_A2"]: return "Mateo_alarmed"
	if speaker == "Mateo" and scene_id in ["D2_B", "D3_B1", "D3_B2"]: return "Mateo_worried"
	if speaker == "Sofi" and (scene_id.begins_with("D3_") or scene_id.begins_with("D4_")): return "Sofi_concerned"
	if speaker == "Sofi" and scene_id in ["D3_01_A", "D4_01_A", "D4_02_A", "D4_03_A", "F03"]:
		return "Sofi_concerned"
	if speaker == "Mateo":
		if choice == "A" and scene_id in ["D3_01_A", "D4_01_A", "D4_02_A", "D4_03_A"]:
			return "Mateo"
		if scene_id in ["D4_01_A", "F03"]:
			return "Mateo_alarmed"
		if scene_id in ["D2_03_A", "D2_04_A", "D3_01_A", "D4_02_A", "D4_03_A", "F02"]:
			return "Mateo_worried"
	return speaker
