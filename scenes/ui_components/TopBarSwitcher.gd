extends Control

## Shared behaviour for the top-bar buttons that open a small options
## dialog (language, clock numbers): one dialog open at a time, and every
## dialog uses the same option buttons, so the two look and space alike.
## The dialog is a PanelContainer that sizes itself to its options and
## grows leftwards from under its own button.

const OPTION_SIZE := Vector2(290, 64)
## Room on the left of each option for its picture (flag, mini clock).
const OPTION_ICON := Vector2(44, 44)

@onready var dialog_panel: Control = $DialogPanel
@onready var option_list: VBoxContainer = $DialogPanel/OptionList


func _ready() -> void:
	add_to_group("top_bar_dialogs")
	dialog_panel.visible = false


func close_dialog() -> void:
	dialog_panel.visible = false


func _toggle_dialog() -> void:
	var opening: bool = not dialog_panel.visible
	get_tree().call_group("top_bar_dialogs", "close_dialog")
	dialog_panel.visible = opening


func _clear_options() -> void:
	for child in option_list.get_children():
		option_list.remove_child(child)
		child.queue_free()


## An option button with `picture` (any Control) in a fixed slot on the
## left, then the text. Selected options show as pressed.
func _add_option(label: String, picture: Control, selected: bool, on_pick: Callable) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.custom_minimum_size = OPTION_SIZE
	btn.add_theme_font_size_override("font_size", 20)
	btn.add_theme_constant_override("h_separation", 12)
	# A transparent placeholder icon reserves the picture's slot, so text
	# starts at the same x in every dialog.
	var spacer := Image.create(int(OPTION_ICON.x), int(OPTION_ICON.y), false, Image.FORMAT_RGBA8)
	btn.icon = ImageTexture.create_from_image(spacer)
	btn.toggle_mode = true
	btn.button_pressed = selected
	btn.pressed.connect(on_pick)
	option_list.add_child(btn)
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(picture)
	# In the tree, so a scene's own (larger) minimum size has let go.
	picture.reset_size()
	# Left content margin of the theme's button box, centred vertically.
	picture.position = Vector2(22, (OPTION_SIZE.y - picture.size.y) / 2.0 - 2.0)
	return btn
