extends "res://scenes/exercises/ExerciseBase.gd"

const TimeValue = preload("res://scripts/clock_logic/TimeValue.gd")

@onready var clock: Control = $AnalogClock
@onready var check_button: Button = $CheckButton

var _answered_this_question: bool = false


func _ready() -> void:
	super._ready()
	check_button.text = tr("CHECK")
	check_button.pressed.connect(_on_check_pressed)


func _on_setup() -> void:
	_answered_this_question = false
	prompt_label.text = tr("SET_CLOCK_PROMPT").format({"time": question.target.to_digital_string()})
	clock.display_mode = clock.DisplayMode.INTERACTIVE
	clock.set_allowed_minutes(tier.allowed_minutes)
	var start_hour: int = (question.target.hour + 6) % 12
	clock.set_time(TimeValue.new(start_hour, 0))
	check_button.disabled = false
	check_button.visible = true


func _refresh_prompt() -> void:
	prompt_label.text = tr("SET_CLOCK_PROMPT").format({"time": question.target.to_digital_string()})
	check_button.text = tr("CHECK")


func _on_check_pressed() -> void:
	if _answered_this_question:
		return
	_answered_this_question = true
	# Next appears in the same slot, so Check steps aside.
	check_button.visible = false
	var current = clock.get_current_time()
	var correct: bool = current.equals(question.target)
	clock.display_mode = clock.DisplayMode.STATIC
	_report_answer(correct)
	if not correct:
		# Show, don't just tell: sweep the hands to where they should be.
		clock.animate_to(question.target, 1.2)
