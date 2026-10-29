extends Control

const BACKGROUNDS := {
	"bedroom": "res://assets/vn/bedroom.png",
	"courtyard": "res://assets/vn/courtyard.png",
	"corridor": "res://assets/vn/corridor.png"
}
const SPRITES := {
	"Sofi": "res://assets/vn/sofi_neutral.png",
	"Sofi_concerned": "res://assets/vn/sofi_concerned.png",
	"Mateo": "res://assets/vn/mateo_neutral.png",
	"Mateo_worried": "res://assets/vn/mateo_worried.png",
	"Mateo_alarmed": "res://assets/vn/mateo_alarmed.png",
	"Camila": "res://assets/vn/camila_neutral.png",
	"Bruno": "res://assets/vn/bruno_neutral.png",
	"Sebas": "res://assets/vn/sebas_neutral.png"
}
const AVATARS := {
	"Kairo": "res://assets/vn/kairo_anonymous.png",
	"Sofi": "res://assets/portraits/sofi_neutral.png",
	"Mateo": "res://assets/portraits/mateo_neutral.png",
	"Camila": "res://assets/portraits/camila_neutral.png",
	"Bruno": "res://assets/portraits/bruno_neutral.png",
	"Sebas": "res://assets/portraits/sebas_neutral.png"
}

func _ready() -> void:
	position = Vector2.ZERO
	size = Vector2(768, 448)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false

func clear_view() -> void:
	visible = false
	for child in get_children():
		remove_child(child)
		child.queue_free()

func _panel(rect: Rect2, fill: Color, border: Color = Color.TRANSPARENT, radius: int = 0) -> Panel:
	var node := Panel.new()
	node.position = rect.position
	node.size = rect.size
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1 if border.a > 0.0 else 0)
	style.set_corner_radius_all(radius)
	node.add_theme_stylebox_override("panel", style)
	add_child(node)
	return node

func _label(text_value: String, rect: Rect2, font_size: int, color: Color = Color("f7f2e8")) -> Label:
	var label := Label.new()
	label.text = text_value
	label.position = rect.position
	label.size = rect.size
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	add_child(label)
	return label

func _picture(path: String, rect: Rect2, dimmed: bool = false) -> TextureRect:
	var picture := TextureRect.new()
	picture.name = "Sprite_" + path.get_file().get_basename()
	picture.texture = load(path) as Texture2D
	picture.position = rect.position
	picture.size = rect.size
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if dimmed:
		picture.modulate = Color(0.65, 0.72, 0.78, 0.88)
	add_child(picture)
	picture.size = rect.size
	return picture

func _button(text_value: String, rect: Rect2, action: Callable, font_size: int = 16) -> Button:
	var button := Button.new()
	button.text = text_value
	button.position = rect.position
	button.size = rect.size
	button.custom_minimum_size = rect.size
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.add_theme_font_size_override("font_size", font_size)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("263a4d")
	normal.border_color = Color("77c9c5")
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(8)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("35646e")
	var focus := normal.duplicate() as StyleBoxFlat
	focus.border_color = Color("f3d789")
	focus.set_border_width_all(2)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_stylebox_override("focus", focus)
	button.pressed.connect(action)
	add_child(button)
	return button

func _choice_list(options: Array, rect: Rect2, font_size: int) -> void:
	var scroll := ScrollContainer.new()
	scroll.position = rect.position
	scroll.size = rect.size
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var list := VBoxContainer.new()
	list.custom_minimum_size.x = rect.size.x - 12
	list.add_theme_constant_override("separation", 5)
	scroll.add_child(list)
	for option in options:
		var button := Button.new()
		button.text = str(option.get("label", ""))
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.custom_minimum_size = Vector2(rect.size.x - 16, 44)
		button.add_theme_font_size_override("font_size", font_size)
		var normal := StyleBoxFlat.new()
		normal.bg_color = Color("284457e8")
		normal.border_color = Color("75bdbb")
		normal.set_border_width_all(1)
		normal.set_corner_radius_all(6)
		normal.set_content_margin_all(8)
		var hover := normal.duplicate() as StyleBoxFlat
		hover.bg_color = Color("38656f")
		button.add_theme_stylebox_override("normal", normal)
		button.add_theme_stylebox_override("hover", hover)
		button.add_theme_stylebox_override("pressed", hover)
		button.pressed.connect(option.action)
		list.add_child(button)
		if option == options[0]:
			button.grab_focus()

func show_scene(background_key: String, title: String, speaker: String, line: String,
		options: Array, next_action: Callable, next_label: String, sprite_key: String,
		partner_key: String, is_message: bool, font_size: int, caption: String = "",
		header_action: Callable = Callable(), header_button_label: String = "Historial") -> Label:
	clear_view()
	visible = true
	var backdrop: String = BACKGROUNDS.get(background_key, BACKGROUNDS.courtyard)
	var bg := TextureRect.new()
	bg.texture = load(backdrop) as Texture2D
	bg.name = "VNBackground"
	bg.position = Vector2.ZERO
	bg.size = size
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	bg.size = size
	_panel(Rect2(0, 0, 768, 448), Color(0.05, 0.10, 0.18, 0.20))
	if not partner_key.is_empty() and SPRITES.has(partner_key):
		_picture(SPRITES[partner_key], Rect2(32, 22, 310, 350), partner_key != sprite_key)
	if not sprite_key.is_empty() and SPRITES.has(sprite_key):
		_picture(SPRITES[sprite_key], Rect2(410, 14, 320, 360))
	if not caption.is_empty():
		_panel(Rect2(17, 10, 734, 48), Color(0.05, 0.10, 0.18, 0.84), Color("77c9c5"), 7)
		_label(caption, Rect2(29, 18, 708, 34), maxi(12, font_size - 3))
	else:
		_panel(Rect2(17, 10, 440, 31), Color(0.05, 0.10, 0.18, 0.78), Color("77c9c5"), 7)
		_label(title, Rect2(29, 15, 420, 25), maxi(12, font_size - 3))
	if header_action.is_valid():
		_button(header_button_label, Rect2(626, 9, 121, 32), header_action, 13)
	if is_message:
		_panel(Rect2(303, 76, 162, 153), Color(0.09, 0.13, 0.21, 0.94), Color("77c9c5"), 9)
		var avatar_name: String = speaker.get_slice(" (", 0)
		if AVATARS.has(avatar_name):
			_picture(AVATARS[avatar_name], Rect2(325, 83, 118, 118))
		_label("Mensaje de " + avatar_name, Rect2(313, 202, 145, 22), 13)
	var choosing: bool = not options.is_empty()
	var panel_y: int = 209 if choosing else 252
	_panel(Rect2(19, panel_y, 730, 226 if choosing else 183), Color(0.055, 0.10, 0.17, 0.94), Color("7ac6c3"), 13)
	_panel(Rect2(39, panel_y - 18, 173, 31), Color("28626a"), Color("b7e1d8"), 8)
	_label(speaker if not choosing else "SOFI", Rect2(54, panel_y - 14, 150, 26), font_size)
	if choosing:
		_label("¿Qué le respondes?", Rect2(41, panel_y + 22, 674, 28), font_size)
		_choice_list(options, Rect2(40, panel_y + 52, 686, 163), maxi(14, font_size - 2))
		return null
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(42, panel_y + 40)
	scroll.size = Vector2(674, 116)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var text_label := Label.new()
	text_label.text = line
	text_label.custom_minimum_size.x = 652
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.add_theme_font_size_override("font_size", font_size)
	text_label.add_theme_color_override("font_color", Color("f7f2e8"))
	scroll.add_child(text_label)
	if next_action.is_valid():
		_button(next_label, Rect2(606, 399, 122, 32), next_action, maxi(14, font_size - 2)).grab_focus()
	return text_label

func _chat_message(list: VBoxContainer, speaker: String, message: String, font_size: int) -> Label:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	list.add_child(row)
	var avatar_path: String = AVATARS.get(speaker.get_slice(" (", 0), "")
	var avatar_frame := PanelContainer.new()
	avatar_frame.custom_minimum_size = Vector2(46, 46)
	var avatar_style := StyleBoxFlat.new()
	avatar_style.bg_color = Color("46566b") if speaker.begins_with("Kairo") else Color("303f54")
	avatar_style.border_color = Color("dec685") if speaker.begins_with("Kairo") else Color("6ca8ab")
	avatar_style.set_border_width_all(1)
	avatar_style.set_corner_radius_all(7)
	avatar_frame.add_theme_stylebox_override("panel", avatar_style)
	row.add_child(avatar_frame)
	var avatar := TextureRect.new()
	avatar.texture = load(avatar_path) as Texture2D if not avatar_path.is_empty() else null
	avatar.custom_minimum_size = Vector2(44, 44)
	avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	avatar.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	avatar_frame.add_child(avatar)
	var text_box := VBoxContainer.new()
	text_box.custom_minimum_size.x = 512
	row.add_child(text_box)
	var name := Label.new()
	name.text = speaker.get_slice(" (", 0)
	name.add_theme_font_size_override("font_size", maxi(13, font_size - 3))
	name.add_theme_color_override("font_color", Color("78d4ca") if name.text == "Sofi" else Color("ead69f") if name.text == "Kairo" else Color("d5dceb"))
	text_box.add_child(name)
	var content := Label.new()
	content.text = message
	content.custom_minimum_size.x = 510
	content.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_theme_font_size_override("font_size", font_size)
	content.add_theme_color_override("font_color", Color("f4f0e9"))
	text_box.add_child(content)
	return content

func show_chat(channel: String, messages: Array, options: Array, next_action: Callable,
		next_label: String, header_action: Callable, font_size: int, system_note: String = "",
		header_button_label: String = "Historial") -> Label:
	clear_view()
	visible = true
	_panel(Rect2(0, 0, 768, 448), Color("252a34"))
	_panel(Rect2(0, 0, 152, 448), Color("181c26")).name = "ChannelSidebar"
	_panel(Rect2(0, 0, 152, 53), Color("111722"))
	_label("LOS CHICOS", Rect2(19, 15, 124, 30), 17)
	_label("CANALES", Rect2(17, 80, 122, 24), 12, Color("9aa8b8"))
	_panel(Rect2(7, 109, 138, 35), Color("354954"), Color("6aaca9"), 6)
	_label("#  " + channel, Rect2(18, 115, 126, 26), 14)
	_label("●  Sofi", Rect2(18, 362, 121, 26), 14, Color("7bcfc4"))
	_panel(Rect2(152, 0, 616, 53), Color("303744"))
	_label("#  " + channel, Rect2(171, 12, 389, 32), 19)
	if header_action.is_valid():
		_button(header_button_label, Rect2(617, 9, 132, 34), header_action, 13)
	var choosing: bool = not options.is_empty()
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(167, 62)
	scroll.size = Vector2(584, 165 if choosing else 311)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var list := VBoxContainer.new()
	list.custom_minimum_size.x = 562
	list.add_theme_constant_override("separation", 13)
	scroll.add_child(list)
	if not system_note.is_empty():
		var note := Label.new()
		note.text = system_note
		note.custom_minimum_size.x = 548
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		note.add_theme_font_size_override("font_size", maxi(12, font_size - 4))
		note.add_theme_color_override("font_color", Color("aebbc7"))
		list.add_child(note)
	var current: Label = null
	for item in messages:
		current = _chat_message(list, str(item.get("speaker", "")), str(item.get("text", "")), font_size)
	scroll.set_deferred("scroll_vertical", 100000)
	if choosing:
		_panel(Rect2(162, 233, 597, 207), Color("1c2330"), Color("6aaca9"), 8)
		_label("RESPONDER COMO SOFI", Rect2(174, 241, 560, 22), 13, Color("a9d8d3"))
		_choice_list(options, Rect2(173, 267, 571, 165), maxi(13, font_size - 3))
	else:
		_panel(Rect2(163, 384, 595, 55), Color("1c2330"), Color("6aaca9"), 8)
		_label("Mensaje en #" + channel, Rect2(178, 400, 391, 29), 14, Color("a7b7c6"))
		if next_action.is_valid():
			_button(next_label, Rect2(615, 391, 132, 40), next_action, maxi(13, font_size - 3)).grab_focus()
	return current
