extends Control

## Reusable analog clock widget. STATIC mode just renders a TimeValue;
## INTERACTIVE mode lets the user drag the hands (touch or mouse), with
## minute-hand snapping driven by `allowed_minutes` and the minute hand
## carrying the hour over on full revolutions, like a real clock.
##
## Exercise scenes should only ever read/write time via set_time()/
## get_current_time() and the signals below - never touch hand rotations
## directly.
##
## Types are explicitly preloaded here (rather than relying on global
## class_name resolution) because headless/direct `godot --path . scene`
## runs don't always have a populated global script class cache.
const TimeValue = preload("res://scripts/clock_logic/TimeValue.gd")
const ClockMath = preload("res://scripts/clock_logic/ClockMath.gd")

enum DisplayMode { STATIC, INTERACTIVE }
enum HandId { NONE, HOUR, MINUTE }
enum NumberMode { NONE, HOURS, HOURS_AND_MINUTES }

const NUMBER_MODE_SETTING := "clock_numbers"
## Hand polygons in AnalogClock.tscn are authored for this radius and
## scaled from it, so hands stay proportional at any clock size.
const DESIGN_RADIUS := 150.0

signal time_changed(new_time: TimeValue)
signal hand_released(final_time: TimeValue)
signal hand_grabbed(which_hand: int)

@export var display_mode: DisplayMode = DisplayMode.STATIC
## Minute values the minute hand is allowed to land on while dragging.
## Empty array = free/exact-minute dragging (Tier 5).
@export var allowed_minutes: Array[int] = [0, 15, 30, 45]
@export var show_debug_label: bool = false
@export var number_mode: NumberMode = NumberMode.HOURS:
	set(value):
		number_mode = value
		_reposition_hands()
		queue_redraw()
## When true, number_mode tracks the player's saved "clock_numbers" setting.
@export var follow_number_setting: bool = true

const FACE_COLOR := Color("fffbea")
const PLATE_COLOR := Color("ffffff")
const RIM_COLOR := Color("ff6b6b")
const RIM_DARK := Color("d94f4f")
const TICK_COLOR := Color("1d2b53")
const MINOR_TICK_COLOR := Color("8a96b3")
## Hour hand and hour numbers share a color, as do the minute hand and
## minute numbers, so children can match each hand to its numbers.
const HOUR_HAND_COLOR := Color("1d2b53")
const MINUTE_HAND_COLOR := Color("1f7fc7")
const CAP_COLOR := Color("ffc93c")

@onready var _hour_hand: Node2D = $HourHand
@onready var _minute_hand: Node2D = $MinuteHand
@onready var _center_pin: Node2D = $CenterPin
@onready var _debug_label: Label = $DebugLabel

var _current_time: TimeValue = TimeValue.new(12, 0)
var _dragging_hand: HandId = HandId.NONE
var _drag_last_raw_angle: float = 0.0
var _drag_accumulated_degrees: float = 0.0
var _drag_start_hour: int = 0


func _ready() -> void:
	_debug_label.visible = show_debug_label
	_build_hand_shapes()
	if follow_number_setting:
		number_mode = int(ProgressStore.get_setting(NUMBER_MODE_SETTING, NumberMode.HOURS))
		ProgressStore.setting_changed.connect(_on_setting_changed)
	_reposition_hands()
	_update_hand_rotations()
	queue_redraw()


## Hands are tapered with rounded tips, built in code at DESIGN_RADIUS
## scale (the nodes are then scaled to the actual face size).
func _build_hand_shapes() -> void:
	var hour_shape: Polygon2D = $HourHand/HourHandShape
	hour_shape.polygon = _hand_polygon(82.0, 9.0, 5.5, 16.0)
	hour_shape.color = HOUR_HAND_COLOR
	var minute_shape: Polygon2D = $MinuteHand/MinuteHandShape
	minute_shape.polygon = _hand_polygon(126.0, 6.0, 3.5, 20.0)
	minute_shape.color = MINUTE_HAND_COLOR
	var cap: Polygon2D = $CenterPin
	cap.polygon = _circle_polygon(11.0)
	cap.color = CAP_COLOR
	# The shapes are SmoothPolygon2D, which redraws its outline on change.
	for poly in [hour_shape, minute_shape, cap]:
		poly.queue_redraw()


func _hand_polygon(length: float, base_half: float, tip_half: float, tail: float) -> PackedVector2Array:
	# Traced once around the outline (no self-crossing, or Godot silently
	# refuses to triangulate and the hand disappears): rounded tail from
	# right to left, up the left edge, over the rounded tip, and the
	# polygon closes back down the right edge.
	var pts := PackedVector2Array()
	for i in range(9):
		var a: float = PI * i / 8.0
		pts.append(Vector2(base_half * cos(a), tail + base_half * sin(a) * 0.6))
	pts.append(Vector2(-tip_half, -length))
	for i in range(1, 8):
		var a: float = PI + PI * i / 8.0
		pts.append(Vector2(0, -length) + Vector2(cos(a), sin(a)) * tip_half)
	pts.append(Vector2(tip_half, -length))
	return pts


func _circle_polygon(radius: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(48):
		var a: float = TAU * i / 48.0
		pts.append(Vector2(cos(a), sin(a)) * radius)
	return pts


func _on_setting_changed(key: String, value) -> void:
	if key == NUMBER_MODE_SETTING:
		number_mode = int(value)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_reposition_hands()
		queue_redraw()


func _reposition_hands() -> void:
	var center: Vector2 = size / 2.0
	if _hour_hand:
		var s: float = max(_face_radius(), 1.0) / DESIGN_RADIUS
		for node in [_hour_hand, _minute_hand, _center_pin]:
			node.position = center
			node.scale = Vector2(s, s)


func set_time(tv: TimeValue) -> void:
	_current_time = tv.duplicate_value()
	_update_hand_rotations()


## Sweeps the hands to `tv` along the shorter way round, like a real clock
## being wound, so children can watch how the hands get there.
func animate_to(tv: TimeValue, duration: float) -> void:
	var from_total: int = _current_time.hour * 60 + _current_time.minute
	var to_total: int = tv.hour * 60 + tv.minute
	var diff: int = posmod(to_total - from_total + 360, 720) - 360
	var tw := create_tween()
	tw.tween_method(func(v: float):
		var m: int = posmod(int(round(v)), 720)
		_current_time = TimeValue.new(m / 60, m % 60)
		_update_hand_rotations(),
		float(from_total), float(from_total + diff), duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func get_current_time() -> TimeValue:
	return _current_time.duplicate_value()


func set_allowed_minutes(minutes: Array) -> void:
	var typed: Array[int] = []
	for m in minutes:
		typed.append(int(m))
	allowed_minutes = typed


func _update_hand_rotations() -> void:
	if not _hour_hand:
		return
	_hour_hand.rotation = deg_to_rad(ClockMath.hour_angle_deg(_current_time.hour, _current_time.minute))
	_minute_hand.rotation = deg_to_rad(ClockMath.minute_angle_deg(_current_time.minute))
	if _debug_label:
		_debug_label.text = _current_time.to_digital_string()


## Outer radius of the whole widget (face plus any number rings).
func _radius() -> float:
	return min(size.x, size.y) / 2.0


## The numbers sit in rings OUTSIDE the rim so the hands (which never
## reach past the rim) can't cover them; the face shrinks to make room.
## Hours go in the inner ring and minutes in the outer ring, mirroring
## the short hour hand and the long minute hand.
const FACE_FRACTION := {
	NumberMode.NONE: 1.0,
	NumberMode.HOURS: 0.80,
	NumberMode.HOURS_AND_MINUTES: 0.70,
}


func _face_radius() -> float:
	return _radius() * FACE_FRACTION[number_mode]


func _draw() -> void:
	var center: Vector2 = size / 2.0
	var outer_r: float = _radius()
	var r: float = _face_radius()
	if r < 1.0:
		return
	# White plate behind the number rings so the numbers stay readable on
	# any background (e.g. blue minute numbers on the blue sky).
	if number_mode != NumberMode.NONE:
		draw_circle(center + Vector2(0, outer_r * 0.03), outer_r, Color(0.11, 0.17, 0.33, 0.15), true, -1.0, true)
		draw_circle(center, outer_r, PLATE_COLOR, true, -1.0, true)
	else:
		draw_circle(center + Vector2(0, r * 0.04), r, Color(0.11, 0.17, 0.33, 0.15), true, -1.0, true)

	# Chunky colored rim with a darker inner edge, then the cream face.
	draw_circle(center, r, RIM_COLOR, true, -1.0, true)
	draw_circle(center, r * 0.93, RIM_DARK, true, -1.0, true)
	draw_circle(center, r * 0.91, FACE_COLOR, true, -1.0, true)

	for i in range(60):
		var dir: Vector2 = _clock_dir(i * 6.0)
		var outer: Vector2 = center + dir * r * 0.86
		if i % 5 == 0:
			var inner_len: float = 0.72 if i % 15 == 0 else 0.76
			draw_line(center + dir * r * inner_len, outer, TICK_COLOR, max(2.5, r * 0.028), true)
		else:
			draw_line(center + dir * r * 0.81, outer, MINOR_TICK_COLOR, max(1.0, r * 0.009), true)

	if number_mode == NumberMode.NONE:
		return

	var font: Font = get_theme_default_font()
	var show_minutes: bool = number_mode == NumberMode.HOURS_AND_MINUTES

	# Ring positions/sizes are fractions of the OUTER radius so they fill
	# the band between the rim and the widget edge. Hours are always the
	# larger, darker numbers.
	var hour_ring: float = 0.80 if show_minutes else 0.905
	var hour_size: int = int(outer_r * (0.13 if show_minutes else 0.15))
	for i in range(12):
		var hour_label: String = str(12 if i == 0 else i)
		_draw_centered_text(font, hour_label, center + _clock_dir(i * 30.0) * outer_r * hour_ring, hour_size, HOUR_HAND_COLOR)

	if show_minutes:
		var minute_size: int = int(outer_r * 0.07)
		for i in range(12):
			var label: String = "%02d" % (i * 5)
			_draw_centered_text(font, label, center + _clock_dir(i * 30.0) * outer_r * 0.94, minute_size, MINUTE_HAND_COLOR)


func _draw_centered_text(font: Font, text: String, pos: Vector2, font_size: int, color: Color) -> void:
	var w: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var baseline_offset: float = (font.get_ascent(font_size) - font.get_descent(font_size)) / 2.0
	draw_string(font, pos + Vector2(-w / 2.0, baseline_offset), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _clock_dir(clock_angle_deg: float) -> Vector2:
	var rad: float = deg_to_rad(clock_angle_deg)
	return Vector2(sin(rad), -cos(rad))


# --- Input handling (INTERACTIVE mode only) ---

func _gui_input(event: InputEvent) -> void:
	if display_mode != DisplayMode.INTERACTIVE:
		return

	if event is InputEventScreenTouch or event is InputEventMouseButton:
		var pressed: bool = event.pressed if event is InputEventScreenTouch else (event as InputEventMouseButton).pressed
		if pressed:
			_try_start_drag(event.position)
		else:
			_end_drag()
	elif event is InputEventScreenDrag or event is InputEventMouseMotion:
		if _dragging_hand != HandId.NONE:
			_update_drag(event.position)


func _try_start_drag(local_pos: Vector2) -> void:
	var center: Vector2 = size / 2.0
	var vec: Vector2 = local_pos - center
	var dist: float = vec.length()
	var r: float = _face_radius()
	var press_angle: float = ClockMath.vector_to_clock_angle_deg(vec)

	var minute_hand_angle: float = ClockMath.minute_angle_deg(_current_time.minute)
	var hour_hand_angle: float = ClockMath.hour_angle_deg(_current_time.hour, _current_time.minute)

	var dist_to_minute_angle: float = _angular_distance(press_angle, minute_hand_angle)
	var dist_to_hour_angle: float = _angular_distance(press_angle, hour_hand_angle)

	var in_minute_band: bool = dist > r * 0.35 and dist < r * 1.05 and dist_to_minute_angle < 20.0
	var in_hour_band: bool = dist > r * 0.1 and dist < r * 0.85 and dist_to_hour_angle < 20.0

	if in_minute_band:
		_start_drag(HandId.MINUTE, minute_hand_angle)
	elif in_hour_band:
		_start_drag(HandId.HOUR, hour_hand_angle)


func _angular_distance(a: float, b: float) -> float:
	var diff: float = abs(a - b)
	return min(diff, 360.0 - diff)


func _start_drag(hand: HandId, start_angle: float) -> void:
	_dragging_hand = hand
	_drag_last_raw_angle = start_angle
	_drag_accumulated_degrees = 0.0
	_drag_start_hour = _current_time.hour
	hand_grabbed.emit(hand)


func _update_drag(local_pos: Vector2) -> void:
	var center: Vector2 = size / 2.0
	var vec: Vector2 = local_pos - center
	var new_angle: float = ClockMath.vector_to_clock_angle_deg(vec)

	if _dragging_hand == HandId.MINUTE:
		var delta: float = wrapf(new_angle - _drag_last_raw_angle, -180.0, 180.0)
		_drag_accumulated_degrees += delta
		_drag_last_raw_angle = new_angle

		var raw_minute: float = ClockMath.angle_to_raw_minute(new_angle)
		var snapped_minute: int = ClockMath.snap_minute_to_allowed(raw_minute, allowed_minutes)
		var hour_carry: int = int(_drag_accumulated_degrees / 360.0)
		var new_hour: int = ((_drag_start_hour + hour_carry) % 12 + 12) % 12

		_apply_dragged_time(TimeValue.new(new_hour, snapped_minute))

	elif _dragging_hand == HandId.HOUR:
		var raw_hour_steps: float = new_angle / 30.0
		var new_hour: int = int(round(raw_hour_steps)) % 12
		_apply_dragged_time(TimeValue.new(new_hour, _current_time.minute))


## Only real changes (a new snap position) update, notify and tick, so a
## hand held still doesn't spam time_changed or the tick sound.
func _apply_dragged_time(tv: TimeValue) -> void:
	if tv.equals(_current_time):
		return
	_current_time = tv
	_update_hand_rotations()
	time_changed.emit(_current_time.duplicate_value())
	SoundFx.play("tick")


func _end_drag() -> void:
	if _dragging_hand == HandId.NONE:
		return
	_dragging_hand = HandId.NONE
	hand_released.emit(_current_time.duplicate_value())
