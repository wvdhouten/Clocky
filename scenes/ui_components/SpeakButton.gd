extends Button

## Small round 🗣️ button that reads a text aloud when tapped (never
## automatically). `source` returns the text at tap time, so it is always
## in the current language. Hides itself when there's no voice for the
## current language, or while `active` is false.

var source: Callable

var active: bool = true:
	set(value):
		active = value
		_refresh()


func _ready() -> void:
	theme_type_variation = &"TopBarButton"
	text = "🗣️"
	add_theme_font_size_override("font_size", 24)
	custom_minimum_size = Vector2(52, 52)
	focus_mode = Control.FOCUS_NONE
	pressed.connect(func():
		if source.is_valid():
			Speech.say(source.call()))
	Speech.voices_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	visible = active and Speech.can_speak()
