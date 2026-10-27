extends RefCounted
class_name DisplayGuard

const MIN_WIDTH := 768
const MIN_HEIGHT := 448
const RESIZE_MESSAGE := "Amplía la ventana del navegador o activa la pantalla completa para continuar jugando"

static func window_size() -> Vector2i:
	if DisplayServer.get_name() == "headless":
		return Vector2i(1152, 672)
	if OS.has_feature("web"):
		var raw: Variant = JavaScriptBridge.eval("JSON.stringify([window.innerWidth,window.innerHeight])")
		if typeof(raw) == TYPE_STRING:
			var values: Variant = JSON.parse_string(raw)
			if typeof(values) == TYPE_ARRAY and values.size() == 2:
				return Vector2i(int(values[0]), int(values[1]))
	return DisplayServer.window_get_size()

static func too_small(size: Vector2i) -> bool:
	return size.x < MIN_WIDTH or size.y < MIN_HEIGHT

static func make_overlay(owner: Node) -> CanvasLayer:
	var layer := CanvasLayer.new()
	layer.layer = 20
	layer.visible = false
	owner.add_child(layer)
	var veil := ColorRect.new()
	veil.color = Color(0.02, 0.06, 0.09, 0.94)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(veil)
	var panel := PanelContainer.new()
	panel.position = Vector2(76, 120)
	panel.custom_minimum_size = Vector2(616, 190)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("132730")
	style.border_color = Color("78bdbb")
	style.set_border_width_all(3)
	style.set_content_margin_all(22)
	panel.add_theme_stylebox_override("panel", style)
	layer.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	var title := Label.new()
	title.text = "VENTANA INSUFICIENTE"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color("78cbb8"))
	box.add_child(title)
	var message := Label.new()
	message.text = RESIZE_MESSAGE
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.custom_minimum_size.x = 560
	message.add_theme_font_size_override("font_size", 20)
	message.add_theme_color_override("font_color", Color("fff3df"))
	box.add_child(message)
	return layer
