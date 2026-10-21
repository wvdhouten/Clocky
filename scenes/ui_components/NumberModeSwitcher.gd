extends Control

## Persistent top-bar button (next to the language flag) for choosing
## which numbers the clock face shows. Saved via ProgressStore so it
## survives restarts; every AnalogClock listens for the change.

const AnalogClockScript = preload("res://scenes/clock/AnalogClock.gd")
const SETTING := "clock_numbers"
const OPTIONS := [
	[AnalogClockScript.NumberMode.NONE, "NUMBERS_NONE"],
	[AnalogClockScript.NumberMode.HOURS, "NUMBERS_HOURS"],
	[AnalogClockScript.NumberMode.HOURS_AND_MINUTES, "NUMBERS_ALL"],
]

@onready var mode_button: Button = $ModeButton
@onready var dialog_panel: Panel = $DialogPanel
@onready var option_list: VBoxContainer = $DialogPanel/OptionList


func _ready() -> void:
	add_to_group("top_bar_dialogs")
	mode_button.pressed.connect(_toggle_dialog)
	dialog_panel.visible = false
	_build_options()
	LocaleManager.locale_changed.connect(func(_l): _build_options())
	ProgressStore.setting_changed.connect(func(key, _v):
		if key == SETTING:
			_build_options())


func close_dialog() -> void:
	dialog_panel.visible = false


func _toggle_dialog() -> void:
	var opening: bool = not dialog_panel.visible
	get_tree().call_group("top_bar_dialogs", "close_dialog")
	dialog_panel.visible = opening


func _current_mode() -> int:
	return int(ProgressStore.get_setting(SETTING, AnalogClockScript.NumberMode.HOURS))


func _build_options() -> void:
	for child in option_list.get_children():
		child.queue_free()
	var current: int = _current_mode()
	for entry in OPTIONS:
		var mode: int = entry[0]
		var btn := Button.new()
		btn.text = tr(entry[1])
		btn.custom_minimum_size = Vector2(210, 50)
		btn.add_theme_font_size_override("font_size", 18)
		btn.toggle_mode = true
		btn.button_pressed = mode == current
		btn.pressed.connect(_on_mode_picked.bind(mode))
		option_list.add_child(btn)


func _on_mode_picked(mode: int) -> void:
	ProgressStore.set_setting(SETTING, mode)
	dialog_panel.visible = false
