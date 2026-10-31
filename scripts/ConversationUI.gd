extends Control

const BACKGROUNDS := {
	"living": "res://assets/vn/living.png",
	"classroom": "res://assets/vn/classroom.png",
	"street": "res://assets/vn/courtyard.png",
	"computer_lab": "res://assets/vn/computer_lab.png",
	"bedroom": "res://assets/vn/bedroom.png",
	"courtyard": "res://assets/vn/courtyard.png",
	"corridor": "res://assets/vn/corridor.png"
}
const SPRITES := {
	"Sofi": "res://assets/vn/sofi_v4.png",
	"Sofi_concerned": "res://assets/vn/sofi_concerned_v4.png",
	"Mateo": "res://assets/vn/mateo_v4.png",
	"Mateo_worried": "res://assets/vn/mateo_worried_v4.png",
	"Mateo_alarmed": "res://assets/vn/mateo_alarmed_v4.png",
	"Camila": "res://assets/vn/camila_v4.png",
	"Bruno": "res://assets/vn/bruno_v4.png",
	"Sebas": "res://assets/vn/sebas_v4.png",
	"Tutor": "res://assets/vn/tutor_v2.png",
	# El profesor de la clase es el mismo docente que atiende la tutoría.
	"Profesor": "res://assets/vn/tutor_v2.png"
}
const AVATARS := {
	"Kairo": "res://assets/portraits/kairo_v4.tres",
	"Sofi": "res://assets/portraits/sofi_v4.tres",
	"Mateo": "res://assets/portraits/mateo_v4.tres",
	"Camila": "res://assets/portraits/camila_v4.tres",
	"Bruno": "res://assets/portraits/bruno_v4.tres",
	"Sebas": "res://assets/portraits/sebas_v4.tres",
	"Tutor": "res://assets/portraits/tutor_v2.tres",
	"Profesor": "res://assets/portraits/tutor_v2.tres"
}

var auto_action: Callable = Callable()
var auto_remaining := 0.0
var auto_duration := 0.0
var view_serial := 0
var auto_guard: Callable = Callable()
var auto_progress: ProgressBar
var reading_key := ""
var click_regions: Array[Rect2] = []

static func dialogue_text(value: String) -> String:
	var result := ""
	var capitalize_next := false
	for character in value:
		if character in [";", ":"]:
			result = result.strip_edges(false, true) + ". "
			capitalize_next = true
		elif capitalize_next and character in [" ", "\t"]:
			continue
		else:
			result += character.to_upper() if capitalize_next else character
			if character not in ["\n", "¿", "¡", "«", "(", "\"", "'"]: capitalize_next = false
	return result

static func background_for_world(world_key: String) -> String:
	return {"draft_d1": "computer_lab", "draft_d2": "courtyard", "draft_d3": "corridor", "draft_d4": "courtyard", "bedroom": "bedroom", "computer": "bedroom", "courtyard": "courtyard"}.get(world_key, "courtyard")

func set_reading_key(kind: String, payload: Array) -> void:
	reading_key = kind + "|" + JSON.stringify(payload)

func capture_reading_state() -> Dictionary:
	if not visible or reading_key.is_empty(): return {}
	var result := {"key": reading_key, "remaining": auto_remaining, "duration": auto_duration, "timer_active": auto_action.is_valid()}
	for scroll_name in ["ReadingScroll", "ChoiceScroll"]:
		var scroll := get_node_or_null(scroll_name) as ScrollContainer
		if is_instance_valid(scroll): result[scroll_name] = scroll.scroll_vertical
	return result

func restore_reading_state(state: Dictionary) -> bool:
	if not visible or state.get("key", "") != reading_key: return false
	if state.get("timer_active", false) and auto_action.is_valid():
		auto_duration = maxf(0.1, float(state.get("duration", auto_duration)))
		auto_remaining = clampf(float(state.get("remaining", auto_remaining)), 0.0, auto_duration)
		if is_instance_valid(auto_progress): auto_progress.value = 100.0 * auto_remaining / auto_duration
	for scroll_name in ["ReadingScroll", "ChoiceScroll"]:
		var scroll := get_node_or_null(scroll_name) as ScrollContainer
		if is_instance_valid(scroll) and state.has(scroll_name): scroll.set_deferred("scroll_vertical", int(state[scroll_name]))
	return true

func can_click_advance(point: Vector2) -> bool:
	if not visible or not auto_action.is_valid(): return false
	if auto_guard.is_valid() and not auto_guard.call(): return false
	var inside := false
	for region in click_regions:
		if region.has_point(point): inside = true
	if not inside: return false
	var canvas_point: Vector2 = get_global_transform() * point
	for child in find_children("*", "Control", true, false):
		if (child is BaseButton or child is ScrollBar) and child.is_visible_in_tree() and child.get_global_rect().has_point(canvas_point): return false
	return true

func reading_seconds(text_value: String) -> float:
	var words: int = dialogue_text(text_value).split(" ", false).size()
	var factor: float = {"slow": 1.35, "normal": 1.0, "fast": 0.75}.get(GameState.dialogue_speed, 1.0)
	# Lectura más pausada: el feedback indicó escenas que se sentían demasiado cortas.
	return maxf(5.0, (2.4 + words / 2.3) * factor)

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
	var hint := Label.new()
	hint.name = "ClickHint"
	hint.text = "Clic en el recuadro o Enter para continuar ▸"
	hint.position = Vector2(440, 412)
	hint.size = Vector2(284, 18)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color("8a6496"))
	add_child(hint)

func _process(delta: float) -> void:
	if not visible or not auto_action.is_valid(): return
	if auto_guard.is_valid() and not auto_guard.call(): return
	auto_remaining -= delta
	if is_instance_valid(auto_progress): auto_progress.value = 100.0 * maxf(0.0, auto_remaining) / auto_duration
	if auto_remaining <= 0.0: _run_auto()

func _input(event: InputEvent) -> void:
	if visible and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and event.double_click:
		get_viewport().set_input_as_handled()
		return
	if not visible or not auto_action.is_valid(): return
	if auto_guard.is_valid() and not auto_guard.call(): return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_ENTER, KEY_KP_ENTER]:
		_run_auto()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and not event.double_click:
		var local_event := make_input_local(event) as InputEventMouseButton
		if can_click_advance(local_event.position):
			_run_auto()
			get_viewport().set_input_as_handled()

func _run_auto() -> void:
	if not auto_action.is_valid(): return
	if auto_guard.is_valid() and not auto_guard.call(): return
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
	set_reading_key("show_prologue", [text_value])
	click_regions = [Rect2(30, 132, 708, 291)]
	for y in range(0, 448, 4):
		_panel(Rect2(0, y, 768, 4), Color("eadbf3").lerp(Color("f9dce7"), float(y) / 448.0))
	for i in range(5):
		var person: String = ["Camila", "Bruno", "Sofi", "Mateo", "Sebas"][i]
		_panel(Rect2(112 + i * 110, 24, 90, 90), Color("fff7fc"), Color("c493bb"), 22)
		_picture(AVATARS[person], Rect2(117 + i * 110, 28, 80, 80))
		_label(person, Rect2(112 + i * 110, 113, 90, 19), 12, Color("44304f")).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_panel(Rect2(30, 132, 708, 291), Color("fff8fbe8"), Color("c493bb"), 20)
	var scroll := ScrollContainer.new()
	scroll.name = "ReadingScroll"
	scroll.position = Vector2(54, 151)
	scroll.size = Vector2(660, 254)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var prose := Label.new()
	prose.name = "PrologueText"
	prose.text = dialogue_text(text_value)
	prose.custom_minimum_size.x = 635
	prose.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	prose.add_theme_font_size_override("font_size", font_size)
	prose.add_theme_color_override("font_color", Color("44304f"))
	scroll.add_child(prose)
	arm_auto(action, text_value)

func show_stage_card(title: String, text_value: String, action: Callable, font_size: int) -> void:
	clear_view()
	visible = true
	set_reading_key("show_stage_card", [title, text_value])
	click_regions = [Rect2(74, 93, 620, 259)]
	_panel(Rect2(0, 0, 768, 448), Color(0.28, 0.16, 0.34, 0.63))
	_panel(Rect2(74, 93, 620, 259), Color("fff3fa"), Color("c493bb"), 18)
	_label(title, Rect2(100, 111, 564, 37), font_size + 2, Color("684776"))
	var scroll := ScrollContainer.new()
	scroll.name = "ReadingScroll"
	scroll.position = Vector2(100, 157)
	scroll.size = Vector2(565, 142)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var prose := Label.new()
	prose.name = "StageGuideText"
	prose.text = dialogue_text(text_value)
	prose.custom_minimum_size.x = 541
	prose.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	prose.add_theme_font_size_override("font_size", font_size)
	prose.add_theme_color_override("font_color", Color("44304f"))
	scroll.add_child(prose)
	_label("WASD · mover    F · interactuar    E · celular    Tab · objetivo    P · pausa", Rect2(97, 311, 568, 33), 12, Color("684776"))
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
	reading_key = ""
	click_regions.clear()
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
	scroll.name = "ChoiceScroll"
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
		button.text = dialogue_text(str(option.get("label", "")))
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
	set_reading_key("show_scene", [background_key, title, speaker, line, options.map(func(option): return option.get("label", ""))])
	click_regions = [Rect2(19, 252, 730, 183)]
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
	if not left_key.is_empty() and left_key.get_slice("_", 0) == right_key.get_slice("_", 0): right_key = ""
	if SPRITES.has(left_key): _picture(SPRITES[left_key], Rect2(32, 22, 310, 350), not speaker.begins_with(left_key.get_slice("_", 0)))
	if SPRITES.has(right_key): _picture(SPRITES[right_key], Rect2(410, 14, 320, 360), not speaker.begins_with(right_key.get_slice("_", 0)))
	if not caption.is_empty():
		_panel(Rect2(17, 10, 734, 48), Color(0.31, 0.19, 0.37, 0.84), Color("d5a4ca"), 7)
		_label(dialogue_text(caption), Rect2(29, 18, 708, 34), maxi(12, font_size - 3))
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
	var visible_speaker := false
	for side in [0, 1]:
		var key: String = left_key if side == 0 else right_key
		if not SPRITES.has(key): continue
		var person: String = key.get_slice("_", 0)
		var active: bool = not is_message and displayed_speaker == person
		visible_speaker = visible_speaker or active
		var badge_x: int = 39 if side == 0 else 549
		_panel(Rect2(badge_x, panel_y - 18, 180, 31), Color("865c92") if active else Color("6e577cba"), Color("e9c4db"), 8).name = "SpeakerBadge" if active else "CharacterPlate_" + person
		_label(person, Rect2(badge_x + 12, panel_y - 14, 158, 26), font_size if active else maxi(13, font_size - 2), Color("fff8fc")).name = "SpeakerName" if active else "CharacterName_" + person
	if is_message or (not visible_speaker and displayed_speaker not in ["Narrador", ""]):
		_panel(Rect2(294, panel_y - 18, 202, 31), Color("865c92"), Color("e9c4db"), 8).name = "SpeakerBadge"
		_label(displayed_speaker, Rect2(305, panel_y - 14, 181, 26), font_size, Color("fff8fc")).name = "SpeakerName"
	if choosing:
		_label("¿Qué le respondes?", Rect2(41, panel_y + 22, 674, 28), font_size, Color("44304f"))
		_choice_list(options, Rect2(40, panel_y + 52, 686, 163), maxi(14, font_size - 2))
		return null
	var scroll := ScrollContainer.new()
	scroll.name = "ReadingScroll"
	scroll.position = Vector2(42, panel_y + 40)
	scroll.size = Vector2(674, 116)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var text_label := Label.new()
	text_label.text = dialogue_text(line)
	text_label.custom_minimum_size.x = 652
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.add_theme_font_size_override("font_size", font_size)
	text_label.add_theme_color_override("font_color", Color("44304f"))
	scroll.add_child(text_label)
	if next_action.is_valid(): arm_auto(next_action, line)
	return text_label

func show_advice(speaker: String, text_value: String) -> void:
	# Consejo superpuesto a las opciones: orienta sin elegir por el jugador.
	var previous := get_node_or_null("AdvicePanel")
	if is_instance_valid(previous):
		remove_child(previous)
		previous.queue_free()
	var panel := _panel(Rect2(60, 52, 648, 132), Color("fff6dcf5"), Color("e2ad36"), 12)
	panel.name = "AdvicePanel"
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var avatar := TextureRect.new()
	avatar.texture = load(AVATARS.get(speaker, AVATARS.Sofi)) as Texture2D
	avatar.position = Vector2(12, 14)
	avatar.size = Vector2(100, 100)
	avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(avatar)
	avatar.size = Vector2(100, 100)
	var title := Label.new()
	title.text = "Consejo del " + speaker.to_lower()
	title.position = Vector2(126, 10)
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", Color("8a5a12"))
	panel.add_child(title)
	var body := Label.new()
	body.name = "AdviceText"
	body.text = dialogue_text(text_value)
	body.position = Vector2(126, 34)
	body.size = Vector2(508, 92)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 14)
	body.add_theme_color_override("font_color", Color("44304f"))
	panel.add_child(body)
	body.size = Vector2(508, 92)

func _chat_message(list: VBoxContainer, speaker: String, message: String, font_size: int) -> Label:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_child(row)
	var avatar_path: String = AVATARS.get(speaker.get_slice(" (", 0), "")
	var avatar_frame := PanelContainer.new()
	avatar_frame.name = "MessageAvatar"
	avatar_frame.custom_minimum_size = Vector2(46, 46)
	avatar_frame.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	avatar_frame.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
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
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text_box)
	var name := Label.new()
	name.text = speaker.get_slice(" (", 0)
	name.add_theme_font_size_override("font_size", maxi(13, font_size - 3))
	name.add_theme_color_override("font_color", Color("78d4ca") if name.text == "Sofi" else Color("ead69f") if name.text == "Kairo" else Color("d5dceb"))
	text_box.add_child(name)
	var content := Label.new()
	content.text = dialogue_text(message)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
	set_reading_key("show_chat", [channel, messages, options.map(func(option): return option.get("label", "")), system_note])
	click_regions = [Rect2(163, 62, 595, 377)]
	_panel(Rect2(0, 0, 768, 448), Color("46374f"))
	_panel(Rect2(0, 0, 152, 448), Color("34273e")).name = "ChannelSidebar"
	_panel(Rect2(0, 0, 152, 53), Color("2b2035"))
	_label("LOS CHICOS", Rect2(19, 15, 124, 30), 17)
	_label("CANALES", Rect2(17, 80, 122, 24), 12, Color("9aa8b8"))
	_panel(Rect2(7, 109, 138, 35), Color("725a7b"), Color("ba8fbb"), 6)
	_label("#  " + channel, Rect2(18, 115, 126, 26), 14)
	_panel(Rect2(18, 372, 6, 6), Color("7bcfc4"), Color.TRANSPARENT, 3).mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label("Sofi", Rect2(32, 362, 107, 26), 14, Color("7bcfc4"))
	_panel(Rect2(152, 0, 616, 53), Color("594460"))
	_label("#  " + channel, Rect2(171, 12, 389, 32), 19)
	if header_action.is_valid():
		_button(header_button_label, Rect2(617, 9, 132, 34), header_action, 13)
	var choosing: bool = not options.is_empty()
	var scroll := ScrollContainer.new()
	scroll.name = "ReadingScroll"
	scroll.position = Vector2(167, 62)
	scroll.size = Vector2(584, 165 if choosing else 311)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var list := VBoxContainer.new()
	list.custom_minimum_size.x = 562
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 13)
	scroll.add_child(list)
	if not system_note.is_empty():
		var note := Label.new()
		note.text = dialogue_text(system_note)
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
		current.text = dialogue_text(str(quote.get("text", "")))
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
	set_reading_key("show_direct_chat", [contact, messages, options.map(func(option): return option.get("label", "")), system_note])
	click_regions = [Rect2(163, 77, 595, 362)]
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
	scroll.name = "ReadingScroll"
	scroll.position = Vector2(167, 77)
	scroll.size = Vector2(584, 150 if choosing else 295)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var list := VBoxContainer.new()
	list.custom_minimum_size.x = 562
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 12)
	scroll.add_child(list)
	if not system_note.is_empty():
		var note := Label.new()
		note.text = dialogue_text(system_note)
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
