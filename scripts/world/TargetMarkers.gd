extends RefCounted
## Indicadores de interacción que se dibujan sobre el mapa: flecha amarilla del objetivo,
## halo pulsante, cama resaltada y aviso «Pulsa F». Funciones puras de dibujo: reciben el
## lienzo (`canvas`) y el tiempo de animación, sin guardar estado.

const MARKER_COLOR := Color("ffd84d")
const OUTLINE_COLOR := Color("10192b")


## Flecha amarilla grande que rebota sobre el objetivo actual.
static func draw_objective_marker(canvas: CanvasItem, pos: Vector2, time: float) -> void:
	var p: Vector2 = pos + Vector2(0, -absf(sin(time * 4.0)) * 7.0)
	var outline := PackedVector2Array([p + Vector2(-15, -13), p + Vector2(-6, -13), p + Vector2(-6, -24), p + Vector2(6, -24), p + Vector2(6, -13), p + Vector2(15, -13), p + Vector2(0, 5)])
	canvas.draw_colored_polygon(outline, OUTLINE_COLOR)
	var fill := PackedVector2Array([p + Vector2(-11, -11), p + Vector2(-4, -11), p + Vector2(-4, -21), p + Vector2(4, -21), p + Vector2(4, -11), p + Vector2(11, -11), p + Vector2(0, 1)])
	canvas.draw_colored_polygon(fill, MARKER_COLOR)
	canvas.draw_line(p + Vector2(-2, -19), p + Vector2(-2, -12), Color(1, 1, 1, 0.65), 2.0)


## Halo circular que pulsa alrededor del objetivo principal.
static func draw_glow(canvas: CanvasItem, center: Vector2, time: float) -> void:
	var pulse: float = _pulse(time)
	canvas.draw_circle(center, 24.0 + pulse * 6.0, Color(1.0, 0.85, 0.3, 0.18 + 0.22 * pulse))
	canvas.draw_arc(center, 26.0 + pulse * 6.0, 0, TAU, 32, MARKER_COLOR, 2.5)


## Marco pulsante para objetos grandes, como la cama a la hora de dormir.
static func draw_rect_glow(canvas: CanvasItem, rect: Rect2, time: float) -> void:
	var pulse: float = _pulse(time)
	var grown: Rect2 = rect.grow(4.0 + pulse * 3.0)
	canvas.draw_rect(grown, Color(1.0, 0.85, 0.3, 0.12 + 0.1 * pulse))
	canvas.draw_rect(grown, MARKER_COLOR, false, 3.0)


## Aviso «Pulsa F» cuando el jugador está junto a un objetivo.
static func draw_press_prompt(canvas: CanvasItem, pos: Vector2) -> void:
	canvas.draw_rect(Rect2(pos + Vector2(-34, 0), Vector2(68, 20)), MARKER_COLOR)
	canvas.draw_rect(Rect2(pos + Vector2(-34, 0), Vector2(68, 20)), OUTLINE_COLOR, false, 2.0)
	canvas.draw_string(ThemeDB.fallback_font, pos + Vector2(-34, 15), "Pulsa F", HORIZONTAL_ALIGNMENT_CENTER, 68, 13, OUTLINE_COLOR)


static func _pulse(time: float) -> float:
	return 0.5 + 0.5 * sin(time * 3.2)
