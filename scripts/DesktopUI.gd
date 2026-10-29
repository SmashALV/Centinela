extends Control

var owner_main: Node

func clear_view() -> void:
	visible = false
	for child in get_children():
		remove_child(child)
		child.queue_free()

func _label(value: String, rect: Rect2, font_size: int, color := Color("fff7ff")) -> Label:
	var label := Label.new()
	label.text = value
	label.position = rect.position
	label.size = rect.size
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", owner_main._scaled_text_size(font_size))
	label.add_theme_color_override("font_color", color)
	add_child(label)
	return label

func _panel(rect: Rect2, color: Color, radius := 14) -> Panel:
	var panel := Panel.new()
	panel.position = rect.position
	panel.size = rect.size
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	return panel

func _app(title: String, icon: String, position_value: Vector2, action: Callable, decorative := false) -> Button:
	var button := Button.new()
	button.name = "App_" + title
	button.text = title
	button.position = position_value
	button.size = Vector2(112, 101)
	button.icon = load("res://assets/ui/desktop/" + icon + ".svg")
	button.expand_icon = true
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	button.add_theme_constant_override("icon_max_width", 43)
	button.add_theme_font_size_override("font_size", owner_main._scaled_text_size(14))
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var style := StyleBoxFlat.new()
	style.bg_color = Color("392c59", 0.64)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(8)
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("disabled", style)
	button.add_theme_color_override("font_disabled_color", Color("fff7ff"))
	button.add_theme_color_override("icon_disabled_color", Color.WHITE)
	var hover := style.duplicate() as StyleBoxFlat
	hover.bg_color = Color("715788", 0.9)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("focus", hover)
	button.disabled = decorative
	button.tooltip_text = "Acceso decorativo" if decorative else "Abrir " + title
	if action.is_valid(): button.pressed.connect(action)
	add_child(button)
	return button

func show_desktop(main: Node) -> void:
	clear_view()
	owner_main = main
	visible = true
	var wallpaper := TextureRect.new()
	wallpaper.name = "Wallpaper"
	wallpaper.texture = load("res://assets/ui/sofi_wallpaper.png")
	wallpaper.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	wallpaper.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	wallpaper.size = Vector2(768, 448)
	add_child(wallpaper)
	_panel(Rect2(0, 0, 768, 39), Color("30233d", 0.86), 0)
	var school_pc: bool = main.daily.active() and main.daily.state().place == "computer"
	_label("Sala de cómputo · Sesión de Sofi" if school_pc else "Sofi · Mi espacio", Rect2(22, 9, 490, 26), 17)
	var time_value: String = "20:15" if main.daily.active() and main.daily.is_evening() else "07:10"
	_label(time_value, Rect2(670, 9, 80, 26), 16).horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var discord := _app("Discord", "discord", Vector2(23, 60), main._open_desktop_chat)
	var play := _app("Arena 5v5", "arena", Vector2(151, 60), main._show_class)
	play.disabled = not main.daily.can_play() if main.daily.active() else not GameState.flags.get("d0_chat_done", false)
	play.tooltip_text = "Revisa Discord después de cenar" if play.disabled else "Primero en lograr 5 bajas · máximo 60 segundos"
	_app("Mis archivos", "files", Vector2(23, 178), Callable(), true)
	_app("Fotos", "photos", Vector2(151, 178), Callable(), true)
	_app("Música", "music", Vector2(23, 296), Callable(), true)
	_app("Papelera", "bin", Vector2(151, 296), Callable(), true)
	_panel(Rect2(413, 80, 320, 280), Color("f8eaf5", 0.94))
	_label("Un rato para mí", Rect2(434, 100, 277, 45), 23, Color("654575"))
	_label("Tarea lista. Algo de música.\nY una partida con mis amigos.", Rect2(434, 147, 277, 120), 18, Color("654575"))
	var privacy := Button.new()
	privacy.name = "Privacy"
	privacy.text = "Privacidad revisada" if GameState.flags.get("d0_profile_private", false) else "Revisar mi privacidad"
	if main.daily.active() and int(main.daily.state().day) == 4: privacy.text = "Bloqueo y privacidad"
	privacy.position = Vector2(434, 292)
	privacy.size = Vector2(277, 48)
	privacy.add_theme_font_size_override("font_size", owner_main._scaled_text_size(15))
	privacy.pressed.connect(func():
		if main.daily.active() and int(main.daily.state().day) == 4: main._coral_begin_scene("I_LIMIT")
		else: main._inspect_profile())
	add_child(privacy)
	_panel(Rect2(294, 400, 452, 40), Color("30233d", 0.94))
	_label("Discord  ·  Arena 5v5", Rect2(310, 410, 230, 24), 14)
	var close := Button.new()
	close.name = "CloseDesktop"
	close.text = "Apagar pantalla"
	close.position = Vector2(558, 404)
	close.size = Vector2(177, 33)
	close.add_theme_font_size_override("font_size", owner_main._scaled_text_size(13))
	close.pressed.connect(main._close_modal)
	add_child(close)
	discord.grab_focus()
