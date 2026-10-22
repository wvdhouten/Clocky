extends Control

## Phone-alarm style picker wheel: a vertical list of values that the child
## drags or flings, settling on whichever row stops in the highlighted
## middle band. Long lists wrap around; short ones (fewer than
## WRAP_MIN values) stop at their ends so nothing repeats. Mouse wheel
## steps one row. Drawn in code, like the clock.

signal changed(index: int)

const ROW_H := 62.0
const WRAP_MIN := 5
## Friction for flings, in rows/s lost per second.
const FRICTION := 14.0
const MAX_SPEED := 30.0

var values: Array = []
var editable: bool = true

## Scroll position in rows: row i is centred when _offset == i.
var _offset: float = 0.0
var _velocity: float = 0.0
var _dragging: bool = false
var _drag_last_y: float = 0.0
var _drag_last_time: float = 0.0
var _last_index: int = -1
var _settle: Tween
var _font: Font
var _card: StyleBox
var _band: StyleBoxFlat

var selected_index: int:
	get:
		return _index_at(roundi(_offset))


func _ready() -> void:
	clip_contents = true
	custom_minimum_size = Vector2(120, ROW_H * 3.0 + 16.0)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_font = UiTheme.font(700)
	_card = UiTheme.card_box(Color.WHITE, 22)
	_band = StyleBoxFlat.new()
	_band.bg_color = UiTheme.SUN_LIGHT
	_band.border_color = UiTheme.SUN_DARK
	_band.set_border_width_all(3)
	_band.set_corner_radius_all(16)
	_band.anti_aliasing = true


func set_values(p_values: Array) -> void:
	values = p_values
	_stop()
	_offset = 0.0
	_last_index = selected_index
	queue_redraw()


func selected_value() -> String:
	return "" if values.is_empty() else str(values[selected_index])


## Jumps (or, with `animate`, rolls the short way round) to `index`.
func select(index: int, animate: bool = false) -> void:
	_stop()
	var target: float = float(index)
	if _wraps():
		# Nearest equivalent row, so the wheel rolls the short way.
		var n: float = float(values.size())
		target = _offset + wrapf(float(index) - _offset, -n / 2.0, n / 2.0)
	if animate:
		_settle_to(target, 0.6)
	else:
		_offset = target
		_after_move()


## Scrolls by `rows` (positive = later values) and settles; also used by
## tests to simulate a drag.
func scroll_rows(rows: float) -> void:
	_stop()
	_offset = _clamp_offset(_offset + rows)
	_after_move()
	_settle_to(roundf(_offset), 0.15)


func _wraps() -> bool:
	return values.size() >= WRAP_MIN


func _index_at(row: int) -> int:
	if values.is_empty():
		return 0
	return posmod(row, values.size()) if _wraps() else clampi(row, 0, values.size() - 1)


func _clamp_offset(o: float) -> float:
	if _wraps() or values.is_empty():
		return o
	return clampf(o, 0.0, float(values.size() - 1))


func _stop() -> void:
	_velocity = 0.0
	if _settle:
		_settle.kill()
		_settle = null


func _settle_to(target: float, duration: float) -> void:
	if _settle:
		_settle.kill()
	_settle = create_tween()
	_settle.tween_method(func(v: float):
		_offset = v
		_after_move(), _offset, target, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _after_move() -> void:
	var idx: int = selected_index
	if idx != _last_index:
		_last_index = idx
		SoundFx.play("tick")
		changed.emit(idx)
	queue_redraw()


func _process(delta: float) -> void:
	if _dragging or absf(_velocity) < 0.001:
		return
	_offset = _clamp_offset(_offset + _velocity * delta)
	_velocity = move_toward(_velocity, 0.0, FRICTION * delta)
	_after_move()
	# Slow enough: glide into the nearest row.
	if absf(_velocity) < 2.0:
		_velocity = 0.0
		_settle_to(roundf(_offset), 0.25)


func _gui_input(event: InputEvent) -> void:
	if not editable or values.is_empty():
		return
	if event is InputEventMouseButton and event.pressed and \
			event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		var step: float = 1.0 if event.button_index == MOUSE_BUTTON_WHEEL_DOWN else -1.0
		_stop()
		_settle_to(_clamp_offset(roundf(_offset) + step), 0.15)
		accept_event()
		return
	var pressed_event: bool = event is InputEventScreenTouch or \
		(event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT)
	if pressed_event:
		if event.pressed:
			_stop()
			_dragging = true
			_drag_last_y = event.position.y
			_drag_last_time = Time.get_ticks_msec() / 1000.0
		elif _dragging:
			_dragging = false
			if absf(_velocity) < 2.0:
				_velocity = 0.0
				_settle_to(roundf(_offset), 0.2)
		accept_event()
	elif _dragging and (event is InputEventScreenDrag or event is InputEventMouseMotion):
		var now: float = Time.get_ticks_msec() / 1000.0
		var rows: float = -(event.position.y - _drag_last_y) / ROW_H
		var dt: float = maxf(now - _drag_last_time, 0.001)
		_velocity = clampf(lerpf(_velocity, rows / dt, 0.5), -MAX_SPEED, MAX_SPEED)
		_drag_last_y = event.position.y
		_drag_last_time = now
		_offset = _clamp_offset(_offset + rows)
		_after_move()
		accept_event()


func _draw() -> void:
	draw_style_box(_card, Rect2(Vector2(4, 2), size - Vector2(8, 14)))
	var mid_y: float = (size.y - 10.0) / 2.0
	draw_style_box(_band, Rect2(10, mid_y - ROW_H / 2.0, size.x - 20, ROW_H))
	if values.is_empty():
		return
	var font: Font = _font
	var first: int = floori(_offset) - 2
	for row in range(first, first + 6):
		if not _wraps() and (row < 0 or row >= values.size()):
			continue
		var dist: float = float(row) - _offset
		var y: float = mid_y + dist * ROW_H
		var closeness: float = clampf(1.0 - absf(dist) / 2.0, 0.0, 1.0)
		var font_size: int = int(lerpf(26.0, 44.0, closeness))
		var color := Color(UiTheme.INK, lerpf(0.25, 1.0, closeness))
		var label: String = str(values[_index_at(row)])
		var w: float = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var baseline: float = y + (font.get_ascent(font_size) - font.get_descent(font_size)) / 2.0
		draw_string(font, Vector2((size.x - w) / 2.0, baseline), label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
