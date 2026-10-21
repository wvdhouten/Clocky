extends Control

## Persistent top-right flag button, present on every screen (lives in
## Main.tscn, outside the ScreenHost that gets swapped). Clicking it
## opens a small dialog to change the active locale. Flags are drawn in
## code (FlagTextures) because Windows has no flag emoji.

const FlagTextures = preload("res://scripts/ui/FlagTextures.gd")
const LOCALES := [["en", "English"], ["nl", "Nederlands"], ["ro", "Română"]]

@onready var flag_button: Button = $FlagButton
@onready var dialog_panel: Panel = $DialogPanel
@onready var option_list: VBoxContainer = $DialogPanel/OptionList


func _ready() -> void:
	add_to_group("top_bar_dialogs")
	flag_button.text = ""
	flag_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	flag_button.pressed.connect(_toggle_dialog)
	dialog_panel.visible = false
	_build_options()
	LocaleManager.locale_changed.connect(func(_l):
		_refresh_flag()
		_build_options())
	_refresh_flag()


func close_dialog() -> void:
	dialog_panel.visible = false


func _toggle_dialog() -> void:
	var opening: bool = not dialog_panel.visible
	get_tree().call_group("top_bar_dialogs", "close_dialog")
	dialog_panel.visible = opening


func _build_options() -> void:
	for child in option_list.get_children():
		child.queue_free()
	for entry in LOCALES:
		var code: String = entry[0]
		var btn := Button.new()
		btn.text = entry[1]
		btn.icon = FlagTextures.make(code, 36, 24)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.custom_minimum_size = Vector2(190, 50)
		btn.add_theme_font_size_override("font_size", 20)
		btn.add_theme_constant_override("h_separation", 12)
		btn.toggle_mode = true
		btn.button_pressed = code == LocaleManager.current_locale
		btn.pressed.connect(_on_locale_picked.bind(code))
		option_list.add_child(btn)


func _on_locale_picked(code: String) -> void:
	LocaleManager.set_app_locale(code)
	dialog_panel.visible = false


func _refresh_flag() -> void:
	flag_button.icon = FlagTextures.make(LocaleManager.current_locale, 44, 30)
