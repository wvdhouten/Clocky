extends "res://scenes/ui_components/GlyphButton.gd"

## Small round 🗣️ badge that reads a text aloud when tapped (never
## automatically). `source` returns the text at tap time, so it is always
## in the current language. Hides itself when there's no voice for the
## current language, or while `active` is false.
##
## Use attach() to pin one to the top-right corner of a label or button,
## so every element carries the same badge in the same place.

const SIZE := 40.0
## How far the badge's centre sits inside the target's top-right corner.
const INSET := 8.0
## Plain labels get this much room either side of their text, so the badge
## sits beside the words instead of on them.
const LABEL_PAD := 30

var source: Callable

var active: bool = true:
	set(value):
		active = value
		_refresh()


## Adds a badge as a child of `target`, so it follows the target around
## (pop-ins, wobbles, labels that shrink to their text).
static func attach(target: Control, p_source: Callable) -> Button:
	var b: Button = load("res://scenes/ui_components/SpeakButton.gd").new()
	b.name = "Speaker"
	b.source = p_source
	target.add_child(b)
	b.anchor_left = 1.0
	b.anchor_right = 1.0
	b.anchor_top = 0.0
	b.anchor_bottom = 0.0
	b.offset_left = INSET - SIZE
	b.offset_right = INSET
	b.offset_top = -INSET
	b.offset_bottom = SIZE - INSET
	if target is Label and target.theme_type_variation == &"":
		var pad := StyleBoxEmpty.new()
		pad.content_margin_left = LABEL_PAD
		pad.content_margin_right = LABEL_PAD
		target.add_theme_stylebox_override("normal", pad)
	return b


func _ready() -> void:
	super._ready()
	theme_type_variation = &"SpeakBadge"
	glyph = "🗣️"
	glyph_size = 20
	custom_minimum_size = Vector2(SIZE, SIZE)
	pressed.connect(func():
		if source.is_valid():
			Speech.say(source.call()))
	Speech.voices_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	visible = active and Speech.can_speak()
