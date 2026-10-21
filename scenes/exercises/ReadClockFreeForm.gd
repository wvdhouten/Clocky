extends "res://scenes/exercises/ExerciseBase.gd"

const TimeValue = preload("res://scripts/clock_logic/TimeValue.gd")

@onready var clock: Control = $AnalogClock
@onready var answer_edit: LineEdit = $AnswerEdit
@onready var submit_button: Button = $SubmitButton

var _answered_this_question: bool = false


func _ready() -> void:
	super._ready()
	submit_button.text = tr("SUBMIT")
	submit_button.pressed.connect(_on_submit_pressed)
	answer_edit.text_submitted.connect(func(_t): _on_submit_pressed())


func _on_setup() -> void:
	_answered_this_question = false
	prompt_label.text = tr("READ_FREE_PROMPT")
	clock.display_mode = clock.DisplayMode.STATIC
	clock.set_time(question.target)
	answer_edit.text = ""
	answer_edit.editable = true
	submit_button.disabled = false


func _refresh_prompt() -> void:
	prompt_label.text = tr("READ_FREE_PROMPT")
	submit_button.text = tr("SUBMIT")


func _on_submit_pressed() -> void:
	if _answered_this_question:
		return
	var parsed = _parse_time(answer_edit.text)
	if parsed == null:
		feedback_label.text = tr("FORMAT_HINT")
		return
	_answered_this_question = true
	answer_edit.editable = false
	submit_button.disabled = true
	var correct: bool = parsed.equals(question.target)
	_report_answer(correct)
	if not correct:
		feedback_label.text = tr("FEEDBACK_WRONG_WAS").format({"time": question.target.to_digital_string()})
		_wobble(answer_edit)


func _parse_time(text: String):
	var t: String = text.strip_edges()
	if not t.contains(":"):
		return null
	var parts: PackedStringArray = t.split(":")
	if parts.size() != 2:
		return null
	if not parts[0].is_valid_int() or not parts[1].is_valid_int():
		return null
	var h: int = int(parts[0])
	var m: int = int(parts[1])
	# Accept both 12h ("3:15") and 24h ("15:15") input - the clock face has
	# no AM/PM, so TimeValue normalizes either into the same 0-11 hour.
	if h < 0 or h > 23 or m < 0 or m > 59:
		return null
	return TimeValue.new(h, m)
