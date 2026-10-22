extends Control

## The owl mascot, drawn entirely in code in a 200x220 design space
## (origin at bottom-centre, y up is negative) and scaled to this
## control's size. Always alive: a gentle bob and natural blinking.
## Reactions: cheer() (hop + wings up + happy eyes), encourage() (head
## tilt + nod, soft eyes), explain() (tilt + small bob, for hints and
## lessons), celebrate() (several hops for the summary).

enum Mood { IDLE, HAPPY, ENCOURAGE }

const BODY := Color("9b6b4a")
const BODY_DARK := Color("7a5236")
const BELLY := Color("f7e6c8")
const FACE := Color("fbefd9")
const BEAK := Color("ff9f1c")
const CHEEK := Color(1.0, 0.55, 0.65, 0.55)
const EYE_WHITE := Color.WHITE
const INK := Color("1d2b53")

var mood: Mood = Mood.IDLE
var _t: float = 0.0
var _hop: float = 0.0
var _tilt: float = 0.0
var _wing: float = 0.0
var _blink: float = 0.0
var _next_blink: float = 2.0
var _tween: Tween
var _mood_timer: SceneTreeTimer


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_t += delta
	_next_blink -= delta
	if _next_blink <= 0.0 and mood != Mood.HAPPY:
		_next_blink = randf_range(2.5, 5.0)
		var b := create_tween()
		b.tween_property(self, "_blink", 1.0, 0.07)
		b.tween_property(self, "_blink", 0.0, 0.09)
	queue_redraw()


func cheer() -> void:
	_react(Mood.HAPPY, 1.8)
	_tween.set_parallel(false)
	for i in 2:
		_tween.tween_property(self, "_hop", -26.0, 0.17).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		_tween.parallel().tween_property(self, "_wing", 1.0, 0.17)
		_tween.tween_property(self, "_hop", 0.0, 0.17).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		_tween.parallel().tween_property(self, "_wing", 0.35, 0.17)
	_tween.tween_property(self, "_wing", 0.0, 0.3)


func encourage() -> void:
	_react(Mood.ENCOURAGE, 1.8)
	_tween.tween_property(self, "_tilt", 0.2, 0.25).set_trans(Tween.TRANS_SINE)
	_tween.tween_property(self, "_tilt", -0.12, 0.35).set_trans(Tween.TRANS_SINE)
	_tween.tween_property(self, "_tilt", 0.0, 0.3).set_trans(Tween.TRANS_SINE)


## A thoughtful head tilt while the owl explains something.
func explain() -> void:
	_react(Mood.IDLE, 1.2)
	_tween.tween_property(self, "_tilt", -0.12, 0.2).set_trans(Tween.TRANS_SINE)
	_tween.tween_property(self, "_hop", -8.0, 0.12).set_trans(Tween.TRANS_SINE)
	_tween.tween_property(self, "_hop", 0.0, 0.12).set_trans(Tween.TRANS_SINE)
	_tween.tween_property(self, "_tilt", 0.0, 0.3).set_trans(Tween.TRANS_SINE)


func celebrate() -> void:
	_react(Mood.HAPPY, 3.2)
	for i in 4:
		_tween.tween_property(self, "_hop", -34.0, 0.18).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		_tween.parallel().tween_property(self, "_wing", 1.0, 0.18)
		_tween.parallel().tween_property(self, "_tilt", 0.12 if i % 2 == 0 else -0.12, 0.18)
		_tween.tween_property(self, "_hop", 0.0, 0.18).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		_tween.parallel().tween_property(self, "_wing", 0.4, 0.18)
	_tween.tween_property(self, "_tilt", 0.0, 0.2)
	_tween.parallel().tween_property(self, "_wing", 0.0, 0.3)


func _react(new_mood: Mood, duration: float) -> void:
	if _tween:
		_tween.kill()
	_hop = 0.0
	_tilt = 0.0
	mood = new_mood
	_tween = create_tween()
	var my_timer := get_tree().create_timer(duration)
	_mood_timer = my_timer
	my_timer.timeout.connect(func():
		# Only the most recent reaction gets to reset the mood.
		if _mood_timer == my_timer:
			mood = Mood.IDLE)


# --- Drawing ---

func _draw() -> void:
	var s: float = min(size.x / 200.0, size.y / 220.0)
	var bob: float = sin(_t * 2.2) * 3.0
	var base := Transform2D(_tilt, Vector2(s, s), 0.0, Vector2(size.x / 2.0, size.y - 4.0 + (bob + _hop) * s))

	# Soft ground shadow shrinks while hopping.
	var shadow_scale: float = 1.0 + _hop / 80.0
	var ground := Transform2D(0.0, Vector2(s, s), 0.0, Vector2(size.x / 2.0, size.y - 4.0))
	_ellipse(ground, Vector2(0, -2), Vector2(58, 8) * shadow_scale, Color(0.11, 0.17, 0.33, 0.18))

	# Feet, wings (behind body), body, belly.
	_ellipse(base, Vector2(-24, -8), Vector2(16, 8), BEAK)
	_ellipse(base, Vector2(24, -8), Vector2(16, 8), BEAK)
	_wing_shape(base, -1.0)
	_wing_shape(base, 1.0)
	_ellipse(base, Vector2(0, -78), Vector2(70, 76), BODY)
	_ellipse(base, Vector2(0, -64), Vector2(48, 54), BELLY)
	draw_set_transform_matrix(base)
	for row in 3:
		for col in 3 - row % 2:
			var x: float = -24.0 + col * 24.0 + (12.0 if row % 2 == 1 else 0.0)
			var y: float = -84.0 + row * 20.0
			draw_arc(Vector2(x, y), 8.0, 0.2, PI - 0.2, 8, Color(BODY_DARK, 0.45), 3.0, true)

	# Head with ear tufts.
	_poly(base, PackedVector2Array([Vector2(-58, -168), Vector2(-48, -212), Vector2(-24, -186)]), BODY_DARK)
	_poly(base, PackedVector2Array([Vector2(58, -168), Vector2(48, -212), Vector2(24, -186)]), BODY_DARK)
	_ellipse(base, Vector2(0, -150), Vector2(64, 52), BODY)
	_ellipse(base, Vector2(-25, -152), Vector2(28, 28), FACE)
	_ellipse(base, Vector2(25, -152), Vector2(28, 28), FACE)
	_ellipse(base, Vector2(-44, -126), Vector2(9, 6), CHEEK)
	_ellipse(base, Vector2(44, -126), Vector2(9, 6), CHEEK)

	_eye(base, Vector2(-25, -152))
	_eye(base, Vector2(25, -152))

	_poly(base, PackedVector2Array([Vector2(-9, -137), Vector2(9, -137), Vector2(0, -119)]), BEAK)
	draw_set_transform_matrix(Transform2D())


func _wing_shape(base: Transform2D, side: float) -> void:
	# Wings pivot at the shoulder; side -1 = left, +1 = right. Positive
	# rotation is clockwise on screen, so the left wing raises with +angle.
	var shoulder := Vector2(58.0 * side, -112.0)
	var angle: float = -side * (0.15 + _wing * 1.9)
	var xf: Transform2D = base * Transform2D(angle, Vector2.ONE, 0.0, shoulder)
	_unit_circle(xf * Transform2D(0.0, Vector2(19, 44), 0.0, Vector2(0, 36)), BODY_DARK)


func _eye(base: Transform2D, center: Vector2) -> void:
	draw_set_transform_matrix(base)
	if mood == Mood.HAPPY:
		# Closed, smiling eyes: an upward arc ("^").
		draw_arc(center + Vector2(0, 6), 13.0, PI + 0.35, TAU - 0.35, 12, INK, 6.0, true)
		return
	var open: float = 1.0 - _blink
	if open < 0.15:
		draw_line(center + Vector2(-14, 0), center + Vector2(14, 0), INK, 5.0, true)
		return
	_ellipse(base, center, Vector2(20, 20 * open), EYE_WHITE)
	# ENCOURAGE: pupils look up toward the child kindly; IDLE: toward the
	# middle of the screen (where the clock is).
	var look := Vector2(0, -5) if mood == Mood.ENCOURAGE else Vector2(-5, -2)
	_ellipse(base, center + look, Vector2(11, 11 * open), INK)
	_ellipse(base, center + look + Vector2(4, -4 * open), Vector2(3.5, 3.5 * open), Color.WHITE)


func _ellipse(base: Transform2D, center: Vector2, radii: Vector2, color: Color) -> void:
	_unit_circle(base * Transform2D(0.0, radii, 0.0, center), color)


## Smooth shapes on the OpenGL renderer: compute the outline in SCREEN
## space, fill it, then trace it with a thin antialiased line. (Drawing a
## radius-1 circle under a big scale transform would stretch the
## antialiasing fringe into a blur.)
func _unit_circle(xf: Transform2D, color: Color) -> void:
	var pts := PackedVector2Array()
	var segments: int = 40
	for i in segments:
		var a: float = TAU * i / segments
		pts.append(xf * Vector2(cos(a), sin(a)))
	_fill_smooth(pts, color)


func _poly(base: Transform2D, local_pts: PackedVector2Array, color: Color) -> void:
	_fill_smooth(base * local_pts, color)


func _fill_smooth(screen_pts: PackedVector2Array, color: Color) -> void:
	draw_set_transform_matrix(Transform2D())
	if screen_pts.size() < 3:
		return
	draw_colored_polygon(screen_pts, color)
	var closed: PackedVector2Array = screen_pts.duplicate()
	closed.append(screen_pts[0])
	draw_polyline(closed, color, 1.2, true)
