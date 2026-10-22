extends Control

## The owl's speech bubble, above and left of the owl with a tail pointing
## at it. Used for ❓ hints during exercises and for the Learn lessons.
## Nothing is spoken automatically: the 🗣️ badge reads the text on tap.
## Hint bubbles close when tapped; lesson bubbles stay put.

const SpeakButtonScript = preload("res://scenes/ui_components/SpeakButton.gd")
## Panel padding (the badge sits on the panel's corner, outside it).
const PAD := 18

@onready var panel: PanelContainer = $Panel
@onready var label: Label = $Panel/Text

var dismissable: bool = true
var _spoken: String = ""
var _tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := UiTheme.card_box(Color.WHITE, 26)
	box.set_content_margin_all(PAD)
	panel.add_theme_stylebox_override("panel", box)
	var badge: Button = SpeakButtonScript.attach(label, func(): return _spoken)
	# Move the badge from the text's corner out to the bubble's corner.
	badge.offset_left += PAD
	badge.offset_right += PAD
	badge.offset_top -= PAD
	badge.offset_bottom -= PAD
	# ...so the text needs no room of its own beside the badge.
	label.remove_theme_stylebox_override("normal")
	label.add_theme_font_override("font", UiTheme.font(600))
	label.add_theme_color_override("font_color", UiTheme.INK)
	panel.gui_input.connect(func(event: InputEvent):
		if dismissable and event is InputEventMouseButton and event.pressed:
			hide_bubble())
	panel.resized.connect(queue_redraw)
	visible = false


## Shows `text` (spoken as `spoken`, if given) with a little pop.
func say(text: String, spoken: String = "", p_dismissable: bool = true) -> void:
	label.text = text
	_spoken = spoken if not spoken.is_empty() else text
	dismissable = p_dismissable
	# Re-fit to the new text: the panel grows up and left from its corner.
	panel.reset_size()
	panel.offset_left = panel.offset_right - panel.get_combined_minimum_size().x
	panel.offset_top = panel.offset_bottom - panel.get_combined_minimum_size().y
	var was_visible: bool = visible
	visible = true
	if not was_visible:
		panel.pivot_offset = panel.size
		panel.scale = Vector2(0.7, 0.7)
		if _tween:
			_tween.kill()
		_tween = create_tween()
		_tween.tween_property(panel, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	queue_redraw()


func hide_bubble() -> void:
	visible = false


func is_showing() -> bool:
	return visible


func spoken_text() -> String:
	return _spoken


## The tail, drawn under the panel and pointing down-right at the owl.
func _draw() -> void:
	var r: Rect2 = panel.get_rect()
	var corner := Vector2(r.end.x, r.end.y)
	var pts := PackedVector2Array([corner + Vector2(-86, -2), corner + Vector2(-40, -2), corner + Vector2(6, 30)])
	draw_colored_polygon(pts, Color.WHITE)
	var closed: PackedVector2Array = pts.duplicate()
	closed.append(pts[0])
	draw_polyline(closed, Color.WHITE, 1.2, true)
