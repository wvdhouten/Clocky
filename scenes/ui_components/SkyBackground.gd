extends Control

## Shared animated backdrop drawn in code: sky gradient, a slowly turning
## sun, drifting clouds and rolling hills. Lives once in Main.tscn behind
## every screen. Motion is deliberately slow so it never distracts.

const HILL_BACK := Color("8fdc8a")
const HILL_FRONT := Color("6fcf73")
const SUN_COLOR := Color("ffd84d")
const SUN_RAY := Color(1.0, 0.85, 0.3, 0.55)

# (x fraction, y fraction, scale, speed px/s)
const CLOUDS := [
	[0.12, 0.16, 1.0, 6.0],
	[0.46, 0.09, 0.75, 4.0],
	[0.78, 0.20, 1.15, 5.0],
	[0.30, 0.30, 0.6, 3.0],
]

var _time: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	draw_polygon(
		PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, h), Vector2(0, h)]),
		PackedColorArray([UiTheme.SKY_TOP, UiTheme.SKY_TOP, UiTheme.SKY_BOTTOM, UiTheme.SKY_BOTTOM]))

	_draw_sun(Vector2(w * 0.07, h * 0.1), h * 0.065)

	for c in CLOUDS:
		var travel: float = fposmod(c[0] * (w + 300.0) + _time * c[3], w + 300.0) - 150.0
		_draw_cloud(Vector2(travel, h * c[1]), h * 0.05 * c[2])

	_draw_hill(h * 0.86, h * 0.07, 0.8, 1.3, HILL_BACK)
	_draw_hill(h * 0.92, h * 0.05, 1.6, 0.4, HILL_FRONT)


func _draw_sun(center: Vector2, r: float) -> void:
	var spin: float = _time * 0.15
	for i in 12:
		var a: float = spin + i * TAU / 12.0
		var dir := Vector2(cos(a), sin(a))
		draw_line(center + dir * r * 1.25, center + dir * r * 1.7, SUN_RAY, r * 0.18, true)
	draw_circle(center, r, SUN_COLOR, true, -1.0, true)


func _draw_cloud(pos: Vector2, r: float) -> void:
	var c := Color(1, 1, 1, 0.92)
	draw_circle(pos + Vector2(-r * 1.1, r * 0.25), r * 0.75, c, true, -1.0, true)
	draw_circle(pos + Vector2(r * 1.1, r * 0.25), r * 0.8, c, true, -1.0, true)
	draw_circle(pos + Vector2(0, -r * 0.15), r * 1.05, c, true, -1.0, true)
	draw_circle(pos + Vector2(r * 0.4, r * 0.35), r * 0.85, c, true, -1.0, true)
	draw_circle(pos + Vector2(-r * 0.45, r * 0.4), r * 0.8, c, true, -1.0, true)


func _draw_hill(base_y: float, amplitude: float, waves: float, phase: float, color: Color) -> void:
	var pts := PackedVector2Array()
	var steps := 48
	for i in steps + 1:
		var x: float = size.x * i / steps
		var y: float = base_y - amplitude * (0.5 + 0.5 * sin(phase + waves * TAU * i / steps))
		pts.append(Vector2(x, y))
	pts.append(Vector2(size.x, size.y))
	pts.append(Vector2(0, size.y))
	draw_colored_polygon(pts, color)
