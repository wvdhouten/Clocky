extends Control

## Hold-to-exit button for the fullscreen kiosk: a quick tap does nothing
## (so children can't close the app by accident); holding for HOLD_TIME
## fills a ring and then quits. Releasing early cancels.

const HOLD_TIME := 3.0

var _held: float = 0.0
var _holding: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		_holding = event.pressed
		if not _holding:
			_held = 0.0
		accept_event()


func _process(delta: float) -> void:
	if _holding:
		_held += delta
		if _held >= HOLD_TIME:
			get_tree().quit()
	queue_redraw()


func progress() -> float:
	return clamp(_held / HOLD_TIME, 0.0, 1.0)


func _draw() -> void:
	var c: Vector2 = size / 2.0
	var r: float = min(size.x, size.y) / 2.0 - 3.0
	# Deliberately low-key: kids shouldn't find it interesting.
	var alpha: float = 0.35 if not _holding else 0.95
	draw_circle(c, r, Color(1, 1, 1, alpha * 0.8), true, -1.0, true)
	var ink := Color(UiTheme.INK, alpha)
	# Power symbol: an open ring with a vertical bar.
	draw_arc(c, r * 0.45, -PI / 2.0 + 0.6, 1.5 * PI - 0.6, 24, ink, 3.0, true)
	draw_line(c + Vector2(0, -r * 0.62), c + Vector2(0, -r * 0.1), ink, 3.0, true)
	if _holding:
		draw_arc(c, r, -PI / 2.0, -PI / 2.0 + TAU * progress(), 48, UiTheme.CORAL, 5.0, true)
