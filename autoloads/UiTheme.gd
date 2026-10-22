extends Node

## Builds the app-wide look in code and applies it to the root window, so
## every screen (and every headless test) inherits it. Palette constants
## are public so drawn elements (clock, background, owl) match the theme.

const FONT_PATH := "res://assets/fonts/Baloo2.ttf"

const INK := Color("1d2b53")
const INK_SOFT := Color("4a5a85")
const SKY_TOP := Color("79c6f6")
const SKY_BOTTOM := Color("e3f5ff")
const SUN := Color("ffc93c")
const SUN_DARK := Color("e09a00")
const SUN_LIGHT := Color("ffe08a")
const LEAF := Color("5cc96b")
const LEAF_DARK := Color("3a9a4a")
const CORAL := Color("ff7b7b")
const CORAL_DARK := Color("d94f4f")
const CLOUD := Color("ffffff")
const MINUTE_BLUE := Color("1f7fc7")
const DISABLED := Color("c9d1de")


func _ready() -> void:
	get_tree().root.theme = build()


static func font(weight: int) -> FontVariation:
	var fv := FontVariation.new()
	fv.base_font = load(FONT_PATH)
	var wght: int = TextServerManager.get_primary_interface().name_to_tag("wght")
	fv.variation_opentype = {wght: weight}
	return fv


static func button_box(fill: Color, edge: Color, pressed := false) -> StyleBoxFlat:
	# A chunky darker bottom edge makes buttons read as "pressable"; when
	# pressed the edge shrinks and the label drops, like a real key.
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = edge
	sb.set_corner_radius_all(22)
	sb.border_width_bottom = 2 if pressed else 7
	sb.content_margin_left = 22
	sb.content_margin_right = 22
	sb.content_margin_top = 12 if pressed else 7
	sb.content_margin_bottom = 7 if pressed else 12
	sb.anti_aliasing = true
	return sb


static func card_box(fill: Color = Color.WHITE, radius := 24) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.set_corner_radius_all(radius)
	sb.shadow_color = Color(INK, 0.18)
	sb.shadow_size = 10
	sb.shadow_offset = Vector2(0, 5)
	sb.set_content_margin_all(14)
	sb.anti_aliasing = true
	return sb


static func build() -> Theme:
	var t := Theme.new()
	var regular := font(500)
	var bold := font(700)
	t.default_font = regular
	t.default_font_size = 24

	t.set_color("font_color", "Label", INK)

	# Buttons: sunny yellow keys with navy text (high contrast for kids).
	t.set_font("font", "Button", bold)
	t.set_font_size("font_size", "Button", 26)
	t.set_stylebox("normal", "Button", button_box(SUN, SUN_DARK))
	t.set_stylebox("hover", "Button", button_box(SUN_LIGHT, SUN_DARK))
	t.set_stylebox("pressed", "Button", button_box(LEAF, LEAF_DARK, true))
	t.set_stylebox("hover_pressed", "Button", button_box(LEAF, LEAF_DARK, true))
	t.set_stylebox("disabled", "Button", button_box(DISABLED, Color("a9b3c4")))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		t.set_color(c, "Button", INK)
	t.set_color("font_disabled_color", "Button", INK_SOFT)

	# Small white round buttons for the always-visible top bar.
	t.set_type_variation("TopBarButton", "Button")
	var top := card_box(Color.WHITE, 18)
	top.set_content_margin_all(0)
	var top_hover := card_box(Color("f0f8ff"), 18)
	top_hover.set_content_margin_all(0)
	t.set_stylebox("normal", "TopBarButton", top)
	t.set_stylebox("hover", "TopBarButton", top_hover)
	t.set_stylebox("pressed", "TopBarButton", top_hover)
	t.set_stylebox("hover_pressed", "TopBarButton", top_hover)

	# Round 🗣️ badge pinned to the top-right corner of labels and buttons.
	t.set_type_variation("SpeakBadge", "Button")
	var badge := card_box(Color.WHITE, 20)
	badge.shadow_size = 6
	badge.shadow_offset = Vector2(0, 3)
	badge.set_content_margin_all(0)
	var badge_hover := badge.duplicate()
	badge_hover.bg_color = Color("f0f8ff")
	t.set_stylebox("normal", "SpeakBadge", badge)
	t.set_stylebox("hover", "SpeakBadge", badge_hover)
	t.set_stylebox("pressed", "SpeakBadge", badge_hover)
	t.set_stylebox("hover_pressed", "SpeakBadge", badge_hover)

	# White rounded banner for prompts and titles, so they stay readable
	# over the sky and drifting clouds.
	t.set_type_variation("BubbleLabel", "Label")
	var bubble := card_box(Color.WHITE, 30)
	bubble.set_content_margin_all(8)
	t.set_stylebox("normal", "BubbleLabel", bubble)
	t.set_font("font", "BubbleLabel", bold)

	t.set_stylebox("panel", "Panel", card_box())
	t.set_stylebox("panel", "PanelContainer", card_box())

	var edit := StyleBoxFlat.new()
	edit.bg_color = Color.WHITE
	edit.border_color = INK
	edit.set_border_width_all(3)
	edit.set_corner_radius_all(16)
	edit.set_content_margin_all(10)
	var edit_focus: StyleBoxFlat = edit.duplicate()
	edit_focus.border_color = MINUTE_BLUE
	t.set_stylebox("normal", "LineEdit", edit)
	t.set_stylebox("focus", "LineEdit", edit_focus)
	t.set_stylebox("read_only", "LineEdit", edit)
	t.set_color("font_color", "LineEdit", INK)
	t.set_color("font_uneditable_color", "LineEdit", INK_SOFT)
	t.set_color("font_placeholder_color", "LineEdit", Color(INK, 0.35))
	t.set_color("caret_color", "LineEdit", INK)
	t.set_font("font", "LineEdit", bold)
	return t
