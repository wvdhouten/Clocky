extends Button

## Square button showing a single emoji, drawn centred on the glyph itself.
## As plain `text`, an emoji sits high in the button and the emoji font's
## deep descent makes the button taller than its neighbours, so here the
## glyph is drawn by hand and the size is fixed.

@export var glyph: String = "":
	set(value):
		glyph = value
		queue_redraw()
@export var glyph_size: int = 26


func _ready() -> void:
	text = ""
	focus_mode = Control.FOCUS_NONE


func _draw() -> void:
	if glyph.is_empty():
		return
	var font: Font = get_theme_font("font")
	var w: float = font.get_string_size(glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, glyph_size).x
	# Emoji ink spans roughly one em above the baseline.
	var baseline: float = (size.y + glyph_size * 0.84) / 2.0
	draw_string(font, Vector2((size.x - w) / 2.0, baseline), glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, glyph_size, Color.WHITE)
