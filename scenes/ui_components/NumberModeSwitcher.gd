extends "res://scenes/ui_components/TopBarSwitcher.gd"

## Persistent top-bar button (next to the language flag) for choosing
## which numbers the clock face shows. Saved via ProgressStore so it
## survives restarts; every AnalogClock listens for the change.

const AnalogClockScript = preload("res://scenes/clock/AnalogClock.gd")
const AnalogClockScene = preload("res://scenes/clock/AnalogClock.tscn")
const TimeValue = preload("res://scripts/clock_logic/TimeValue.gd")
const SETTING := "clock_numbers"
const OPTIONS := [
	[AnalogClockScript.NumberMode.NONE, "NUMBERS_NONE"],
	[AnalogClockScript.NumberMode.HOURS, "NUMBERS_HOURS"],
	[AnalogClockScript.NumberMode.HOURS_AND_MINUTES, "NUMBERS_ALL"],
]

@onready var mode_button: Button = $ModeButton


func _ready() -> void:
	super._ready()
	mode_button.pressed.connect(_toggle_dialog)
	_build_options()
	LocaleManager.locale_changed.connect(func(_l): _build_options())
	ProgressStore.setting_changed.connect(func(key, _v):
		if key == SETTING:
			_build_options())


func _current_mode() -> int:
	return int(ProgressStore.get_setting(SETTING, AnalogClockScript.NumberMode.HOURS))


func _build_options() -> void:
	_clear_options()
	var current: int = _current_mode()
	for entry in OPTIONS:
		var mode: int = entry[0]
		# A tiny clock showing exactly what this choice looks like.
		var clock: Control = AnalogClockScene.instantiate()
		clock.follow_number_setting = false
		clock.custom_minimum_size = OPTION_ICON
		_add_option(tr(entry[1]), clock, mode == current, _on_mode_picked.bind(mode))
		clock.number_mode = mode
		clock.set_time(TimeValue.new(10, 10))


func _on_mode_picked(mode: int) -> void:
	ProgressStore.set_setting(SETTING, mode)
	dialog_panel.visible = false
