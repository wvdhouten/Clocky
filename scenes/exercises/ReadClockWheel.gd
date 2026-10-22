extends "res://scenes/exercises/ExerciseBase.gd"

## Read the clock, answering with two phone-alarm style wheels (hours and
## minutes) instead of typing. The minute wheel offers only the minutes
## this tier practises (all 60 on the exact-minute tier).

const TimeValue = preload("res://scripts/clock_logic/TimeValue.gd")

@onready var clock: Control = $AnalogClock
@onready var hour_wheel: Control = $Wheels/HourWheel
@onready var minute_wheel: Control = $Wheels/MinuteWheel
@onready var check_button: Button = $CheckButton

var _answered_this_question: bool = false
var _minutes: Array[int] = []


func _ready() -> void:
	super._ready()
	check_button.text = tr("CHECK")
	check_button.pressed.connect(_on_check_pressed)
	_attach_button_speaker(check_button)
	var hours: Array = []
	for h in range(1, 13):
		hours.append(str(h))
	hour_wheel.set_values(hours)


## Minute values on the wheel for `p_tier`.
static func minutes_for(p_tier) -> Array[int]:
	var out: Array[int] = []
	if p_tier.allowed_minutes.is_empty():
		for m in 60:
			out.append(m)
	else:
		for m in p_tier.allowed_minutes:
			out.append(int(m))
	return out


func _on_setup() -> void:
	_answered_this_question = false
	prompt_label.text = tr("READ_WHEEL_PROMPT")
	clock.display_mode = clock.DisplayMode.STATIC
	clock.set_time(question.target)

	_minutes = minutes_for(tier)
	var labels: Array = []
	for m in _minutes:
		labels.append("%02d" % m)
	minute_wheel.set_values(labels)
	# Start well away from the answer, so the child has to look and turn.
	hour_wheel.select(_hour_index(question.target.hour + 6))
	var target_minute: int = max(_minutes.find(question.target.minute), 0)
	minute_wheel.select((target_minute + _minutes.size() / 2) % _minutes.size())
	for wheel in [hour_wheel, minute_wheel]:
		wheel.editable = true
	check_button.disabled = false


func _refresh_prompt() -> void:
	prompt_label.text = tr("READ_WHEEL_PROMPT")
	check_button.text = tr("CHECK")


## Wheel index for a 0-11 clock hour (the wheel runs 1..12).
func _hour_index(hour: int) -> int:
	return posmod(hour - 1, 12)


## The time currently dialled in on the wheels.
func dialled_time():
	return TimeValue.new(hour_wheel.selected_index + 1, _minutes[minute_wheel.selected_index])


func _on_check_pressed() -> void:
	if _answered_this_question:
		return
	_answered_this_question = true
	check_button.disabled = true
	for wheel in [hour_wheel, minute_wheel]:
		wheel.editable = false
	var correct: bool = dialled_time().equals(question.target)
	_report_answer(correct)
	if not correct:
		# Screen shows "3:15"; the voice says it the natural way ("quarter past three").
		var wrong: String = tr("FEEDBACK_WRONG_WAS")
		_set_feedback(wrong.format({"time": question.target.to_digital_string()}),
			wrong.format({"time": LocaleManager.phrase_for_time(question.target)}))
		# Show, don't just tell: roll the wheels to the right answer.
		hour_wheel.select(_hour_index(question.target.hour), true)
		minute_wheel.select(_minutes.find(question.target.minute), true)
