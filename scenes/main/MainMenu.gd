extends Control

signal start_pressed()

const TimeValue = preload("res://scripts/clock_logic/TimeValue.gd")
const SpeakButtonScript = preload("res://scenes/ui_components/SpeakButton.gd")

@onready var start_button: Button = $StartButton
@onready var live_clock: Control = $LiveClock

var _breath_tween: Tween


func _ready() -> void:
	start_button.text = tr("START")
	start_button.pressed.connect(func(): start_pressed.emit())
	LocaleManager.locale_changed.connect(func(_l): start_button.text = tr("START"))
	SpeakButtonScript.attach(start_button, func(): return start_button.text)

	# A real, ticking clock showing the actual time right now.
	_show_current_time()
	var timer := Timer.new()
	timer.wait_time = 1.0
	timer.autostart = true
	timer.timeout.connect(_show_current_time)
	add_child(timer)

	# Gentle "breathing" on the Start button invites a tap.
	start_button.pivot_offset = start_button.size / 2.0
	_breath_tween = create_tween().set_loops()
	_breath_tween.tween_property(start_button, "scale", Vector2(1.06, 1.06), 0.9).set_trans(Tween.TRANS_SINE)
	_breath_tween.tween_property(start_button, "scale", Vector2.ONE, 0.9).set_trans(Tween.TRANS_SINE)


func _show_current_time() -> void:
	var now: Dictionary = Time.get_time_dict_from_system()
	live_clock.set_time(TimeValue.new(now["hour"], now["minute"]))
