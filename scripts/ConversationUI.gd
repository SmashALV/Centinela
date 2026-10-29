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

var auto_action: Callable = Callable()
var auto_remaining := 0.0
var auto_duration := 0.0
var view_serial := 0
var auto_guard: Callable = Callable()
var auto_progress: ProgressBar

func reading_seconds(text_value: String) -> float:
	var words: int = text_value.split(" ", false).size()
	var factor: float = {"slow": 1.35, "normal": 1.0, "fast": 0.75}.get(GameState.dialogue_speed, 1.0)
	return maxf(4.0, (1.8 + words / 2.6) * factor)

func arm_auto(action: Callable, text_value: String) -> void:
	if not action.is_valid(): return
	auto_action = action
	auto_duration = reading_seconds(text_value)
	auto_remaining = auto_duration
	auto_progress = ProgressBar.new()
	auto_progress.name = "AutoReadProgress"
	auto_progress.position = Vector2(42, 432)
	auto_progress.size = Vector2(684, 3)
	auto_progress.show_percentage = false
	auto_progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var track := StyleBoxFlat.new()
	track.bg_color = Color("d8bdd9")
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("a477ac")
	auto_progress.add_theme_stylebox_override("background", track)
	auto_progress.add_theme_stylebox_override("fill", fill)
	add_child(auto_progress)

func _process(delta: float) -> void:
	if not visible or not auto_action.is_valid(): return
	if auto_guard.is_valid() and not auto_guard.call(): return
	auto_remaining -= delta
	if is_instance_valid(auto_progress): auto_progress.value = 100.0 * maxf(0.0, auto_remaining) / auto_duration
	if auto_remaining <= 0.0: _run_auto()

func _input(event: InputEvent) -> void:
	if visible and auto_action.is_valid() and event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_ENTER, KEY_KP_ENTER]:
		if auto_guard.is_valid() and not auto_guard.call(): return
		_run_auto()
		get_viewport().set_input_as_handled()

func _run_auto() -> void:
	var action: Callable = auto_action
	var serial: int = view_serial
	auto_action = Callable()
	await action.call()
	# Una escritura fallida conserva la vista: reintentar sin saltarse el guardado.
	if visible and view_serial == serial:
		auto_action = action
		auto_remaining = 3.0

func show_prologue(text_value: String, action: Callable, font_size: int) -> void:
	clear_view()
	visible = true
	for y in range(0, 448, 4):
		_panel(Rect2(0, y, 768, 4), Color("eadbf3").lerp(Color("f9dce7"), float(y) / 448.0))
	for i in range(5):
		var person: String = ["Camila", "Bruno", "Sofi", "Mateo", "Sebas"][i]
		_panel(Rect2(112 + i * 110, 24, 90, 90), Color("fff7fc"), Color("c493bb"), 22)
		_picture(AVATARS[person], Rect2(117 + i * 110, 28, 80, 80))
	_panel(Rect2(30, 132, 708, 291), Color("fff8fbe8"), Color("c493bb"), 20)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(54, 151)
	scroll.size = Vector2(660, 254)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var prose := Label.new()
	prose.name = "PrologueText"
	prose.text = text_value
	prose.custom_minimum_size.x = 635
	prose.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	prose.add_theme_font_size_override("font_size", font_size)
	prose.add_theme_color_override("font_color", Color("44304f"))
	scroll.add_child(prose)
	arm_auto(action, text_value)

func _ready() -> void:
	position = Vector2.ZERO
	size = Vector2(768, 448)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false

func clear_view() -> void:
	view_serial += 1
	auto_action = Callable()
	auto_remaining = 0.0
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
	normal.bg_color = Color("765780")
	normal.border_color = Color("d5a4ca")
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(8)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("916b9c")
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
		normal.bg_color = Color("805c8de8")
		normal.border_color = Color("d5a4ca")
		normal.set_border_width_all(1)
		normal.set_corner_radius_all(6)
		normal.set_content_margin_all(8)
		var hover := normal.duplicate() as StyleBoxFlat
		hover.bg_color = Color("9b71a6")
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
	_panel(Rect2(0, 0, 768, 448), Color(0.40, 0.21, 0.40, 0.14))
	var left_key: String = sprite_key if sprite_key.begins_with("Sofi") else partner_key
	var right_key: String = partner_key if sprite_key.begins_with("Sofi") else sprite_key
	if SPRITES.has(left_key): _picture(SPRITES[left_key], Rect2(32, 22, 310, 350), not speaker.begins_with(left_key.get_slice("_", 0)))
	if SPRITES.has(right_key): _picture(SPRITES[right_key], Rect2(410, 14, 320, 360), not speaker.begins_with(right_key.get_slice("_", 0)))
	if not caption.is_empty():
		_panel(Rect2(17, 10, 734, 48), Color(0.31, 0.19, 0.37, 0.84), Color("d5a4ca"), 7)
		_label(caption, Rect2(29, 18, 708, 34), maxi(12, font_size - 3))
	else:
		_panel(Rect2(17, 10, 440, 31), Color(0.31, 0.19, 0.37, 0.78), Color("d5a4ca"), 7)
		_label(title, Rect2(29, 15, 420, 25), maxi(12, font_size - 3))
	if header_action.is_valid():
		_button(header_button_label, Rect2(626, 9, 121, 32), header_action, 13)
	if is_message:
		_panel(Rect2(303, 76, 162, 153), Color(0.38, 0.25, 0.44, 0.94), Color("d5a4ca"), 9)
		var avatar_name: String = speaker.get_slice(" (", 0)
		if AVATARS.has(avatar_name):
			_picture(AVATARS[avatar_name], Rect2(325, 83, 118, 118))
		_label("Mensaje de " + avatar_name, Rect2(313, 202, 145, 22), 13)
	var choosing: bool = not options.is_empty()
	var panel_y: int = 209 if choosing else 252
	_panel(Rect2(19, panel_y, 730, 226 if choosing else 183), Color("f5e7f3f2"), Color("c493bb"), 13)
	var displayed_speaker: String = "Sofi" if choosing else speaker
	if displayed_speaker not in ["Narrador", ""]:
		var badge_x: int = 303 if is_message else 549 if displayed_speaker.get_slice(" (", 0) == right_key.get_slice("_", 0) else 39
		_panel(Rect2(badge_x, panel_y - 18, 180, 31), Color("865c92"), Color("e9c4db"), 8).name = "SpeakerBadge"
		_label(displayed_speaker, Rect2(badge_x + 12, panel_y - 14, 158, 26), font_size, Color("fff8fc")).name = "SpeakerName"
	if choosing:
		_label("¿Qué le respondes?", Rect2(41, panel_y + 22, 674, 28), font_size, Color("44304f"))
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
	text_label.add_theme_color_override("font_color", Color("44304f"))
	scroll.add_child(text_label)
	if next_action.is_valid(): arm_auto(next_action, line)
	return text_label

func _chat_message(list: VBoxContainer, speaker: String, message: String, font_size: int) -> Label:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	list.add_child(row)
	var avatar_path: String = AVATARS.get(speaker.get_slice(" (", 0), "")
	var avatar_frame := PanelContainer.new()
	avatar_frame.custom_minimum_size = Vector2(46, 46)
	var avatar_style := StyleBoxFlat.new()
	avatar_style.bg_color = Color("7e658a") if speaker.begins_with("Kairo") else Color("715778")
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
	_panel(Rect2(0, 0, 768, 448), Color("46374f"))
	_panel(Rect2(0, 0, 152, 448), Color("34273e")).name = "ChannelSidebar"
	_panel(Rect2(0, 0, 152, 53), Color("2b2035"))
	_label("LOS CHICOS", Rect2(19, 15, 124, 30), 17)
	_label("CANALES", Rect2(17, 80, 122, 24), 12, Color("9aa8b8"))
	_panel(Rect2(7, 109, 138, 35), Color("725a7b"), Color("ba8fbb"), 6)
	_label("#  " + channel, Rect2(18, 115, 126, 26), 14)
	_label("●  Sofi", Rect2(18, 362, 121, 26), 14, Color("7bcfc4"))
	_panel(Rect2(152, 0, 616, 53), Color("594460"))
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
		_panel(Rect2(162, 233, 597, 207), Color("3c2c46"), Color("ba8fbb"), 8)
		_label("RESPONDER COMO SOFI", Rect2(174, 241, 560, 22), 13, Color("a9d8d3"))
		_choice_list(options, Rect2(173, 267, 571, 165), maxi(13, font_size - 3))
	else:
		_panel(Rect2(163, 384, 595, 55), Color("3c2c46"), Color("ba8fbb"), 8)
		_label("Mensaje en #" + channel, Rect2(178, 400, 391, 29), 14, Color("a7b7c6"))
		if next_action.is_valid(): arm_auto(next_action, str(messages[-1].get("text", "")) if not messages.is_empty() else system_note)
	return current

func _shared_excerpt(list: VBoxContainer, quotes: Array, font_size: int) -> Label:
	var card := PanelContainer.new()
	card.custom_minimum_size.x = 544
	var style := StyleBoxFlat.new()
	style.bg_color = Color("3b2948")
	style.border_color = Color("72a6b7")
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(10)
	card.add_theme_stylebox_override("panel", style)
	list.add_child(card)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 5)
	card.add_child(content)
	var heading := Label.new()
	heading.text = "CHAT CON KAIRO · compartido por Mateo"
	heading.add_theme_font_size_override("font_size", maxi(12, font_size - 3))
	heading.add_theme_color_override("font_color", Color("9dcdd3"))
	content.add_child(heading)
	var current: Label = heading
	for quote in quotes:
		var sender := Label.new()
		sender.text = str(quote.get("speaker", "")).get_slice(" (", 0)
		sender.add_theme_font_size_override("font_size", maxi(12, font_size - 3))
		sender.add_theme_color_override("font_color", Color("ead69f") if sender.text == "Kairo" else Color("cbd7e7"))
		content.add_child(sender)
		current = Label.new()
		current.text = str(quote.get("text", ""))
		current.custom_minimum_size.x = 518
		current.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		current.add_theme_font_size_override("font_size", font_size)
		current.add_theme_color_override("font_color", Color("f4f0e9"))
		content.add_child(current)
	return current

func show_direct_chat(contact: String, messages: Array, options: Array, next_action: Callable,
		next_label: String, font_size: int, system_note: String = "") -> Label:
	clear_view()
	visible = true
	_panel(Rect2(0, 0, 768, 448), Color("46374f"))
	_panel(Rect2(0, 0, 152, 448), Color("34273e")).name = "DirectSidebar"
	_panel(Rect2(0, 0, 152, 53), Color("2b2035"))
	_label("SOFI", Rect2(19, 15, 124, 30), 17)
	_label("MENSAJES DIRECTOS", Rect2(12, 80, 137, 25), 11, Color("9aa8b8"))
	_panel(Rect2(7, 109, 138, 40), Color("725a7b"), Color("ba8fbb"), 6)
	_label(contact, Rect2(20, 118, 125, 27), 15)
	_label("Sofi", Rect2(20, 362, 121, 26), 14, Color("7bcfc4"))
	_panel(Rect2(152, 0, 616, 69), Color("594460"))
	if AVATARS.has(contact):
		_picture(AVATARS[contact], Rect2(167, 8, 43, 43))
	_label(contact, Rect2(218, 8, 360, 28), 18)
	var has_shared_excerpt: bool = false
	for item in messages:
		if "(mensaje)" in str(item.get("speaker", "")):
			has_shared_excerpt = true
			break
	var header_note: String = "Privado con " + contact + " · captura de Kairo compartida" if has_shared_excerpt else "Mensaje directo entre Sofi y " + contact
	_label(header_note, Rect2(218, 37, 520, 22), 12, Color("abb9c8"))
	var choosing: bool = not options.is_empty()
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(167, 77)
	scroll.size = Vector2(584, 150 if choosing else 295)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var list := VBoxContainer.new()
	list.custom_minimum_size.x = 562
	list.add_theme_constant_override("separation", 12)
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
	var quotes: Array = []
	for item in messages:
		var speaker: String = str(item.get("speaker", ""))
		if "(mensaje)" in speaker:
			quotes.append(item)
			continue
		if not quotes.is_empty():
			current = _shared_excerpt(list, quotes, font_size)
			quotes = []
		current = _chat_message(list, speaker, str(item.get("text", "")), font_size)
	if not quotes.is_empty():
		current = _shared_excerpt(list, quotes, font_size)
	scroll.set_deferred("scroll_vertical", 100000)
	if choosing:
		_panel(Rect2(162, 233, 597, 207), Color("3c2c46"), Color("ba8fbb"), 8)
		_label("RESPONDER A " + contact.to_upper(), Rect2(174, 241, 560, 22), 13, Color("a9d8d3"))
		_choice_list(options, Rect2(173, 267, 571, 165), maxi(13, font_size - 3))
	else:
		_panel(Rect2(163, 384, 595, 55), Color("3c2c46"), Color("ba8fbb"), 8)
		_label("Mensaje a " + contact, Rect2(178, 400, 391, 29), 14, Color("a7b7c6"))
		if next_action.is_valid(): arm_auto(next_action, str(messages[-1].get("text", "")) if not messages.is_empty() else system_note)
	return current
