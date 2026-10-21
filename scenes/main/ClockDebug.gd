extends Control

const TimeValue = preload("res://scripts/clock_logic/TimeValue.gd")

@onready var _clock: Control = $AnalogClock
@onready var _mode_label: Label = $ModeLabel

var _granularities: Array = [
	{"name": "Tier1 o'clock", "allowed": [0]},
	{"name": "Tier2 half", "allowed": [0, 30]},
	{"name": "Tier3 quarter", "allowed": [0, 15, 30, 45]},
	{"name": "Tier4 five-min", "allowed": [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55]},
	{"name": "Tier5 exact", "allowed": []},
]
var _tier_index: int = 2


func _ready() -> void:
	_clock.display_mode = _clock.DisplayMode.INTERACTIVE
	_clock.show_debug_label = true
	_clock.set_time(TimeValue.new(3, 0))
	_apply_tier()
	_clock.time_changed.connect(_on_time_changed)
	_clock.hand_released.connect(_on_hand_released)


func _apply_tier() -> void:
	var t: Dictionary = _granularities[_tier_index]
	_clock.set_allowed_minutes(t["allowed"])
	_mode_label.text = "%s (press SPACE to cycle) - drag the hands" % t["name"]


func _on_time_changed(new_time: TimeValue) -> void:
	print("time_changed: %s" % new_time.to_digital_string())


func _on_hand_released(final_time: TimeValue) -> void:
	print("hand_released: %s" % final_time.to_digital_string())


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		_tier_index = (_tier_index + 1) % _granularities.size()
		_apply_tier()
