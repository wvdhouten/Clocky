extends "res://scenes/ui_components/TopBarSwitcher.gd"

## Persistent top-right flag button, present on every screen (lives in
## Main.tscn, outside the ScreenHost that gets swapped). Clicking it
## opens a small dialog to change the active locale. Flags are drawn in
## code (FlagTextures) because Windows has no flag emoji.

const FlagTextures = preload("res://scripts/ui/FlagTextures.gd")
const LOCALES := [["en", "English"], ["nl", "Nederlands"], ["ro", "Română"]]

@onready var flag_button: Button = $FlagButton


func _ready() -> void:
	super._ready()
	flag_button.text = ""
	flag_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	flag_button.pressed.connect(_toggle_dialog)
	_build_options()
	LocaleManager.locale_changed.connect(func(_l):
		_refresh_flag()
		_build_options())
	_refresh_flag()


func _build_options() -> void:
	_clear_options()
	for entry in LOCALES:
		var code: String = entry[0]
		var flag := TextureRect.new()
		flag.texture = FlagTextures.make(code, 40, 27)
		flag.size = Vector2(40, 27)
		_add_option(entry[1], flag, code == LocaleManager.current_locale, _on_locale_picked.bind(code))


func _on_locale_picked(code: String) -> void:
	LocaleManager.set_app_locale(code)
	dialog_panel.visible = false


func _refresh_flag() -> void:
	flag_button.icon = FlagTextures.make(LocaleManager.current_locale, 40, 27)
