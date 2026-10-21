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
	# Big number keypad on phones/tablets. It has no ":" key, so children
	# type digits ("3", "1", "5") and the colon is filled in for them.
	answer_edit.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER
	answer_edit.max_length = 5
	answer_edit.text_changed.connect(_on_text_changed)


func _on_text_changed(new_text: String) -> void:
	var formatted: String = format_digits(new_text)
	if formatted != new_text:
		answer_edit.text = formatted
		answer_edit.caret_column = formatted.length()


## "315" -> "3:15", "1015" -> "10:15"; 1-2 digits stay as typed (an hour).
static func format_digits(text: String) -> String:
	var digits := ""
	for c in text:
		if c >= "0" and c <= "9":
			digits += c
	digits = digits.substr(0, 4)
	if digits.length() <= 2:
		return digits
	return digits.substr(0, digits.length() - 2) + ":" + digits.substr(digits.length() - 2)


func _process(delta: float) -> void:
	# The on-screen keyboard covers the bottom of the screen; slide this
	# screen up just enough to keep the answer box visible while typing.
	# Only ask on devices that have one: elsewhere (Windows) Godot warns
	# on every call.
	if not DisplayServer.has_feature(DisplayServer.FEATURE_VIRTUAL_KEYBOARD):
		return
	var target: float = -keyboard_shift(DisplayServer.virtual_keyboard_get_height())
	position.y = move_toward(position.y, target, delta * 2400.0)


## How far (in viewport units) to lift the screen so the answer box sits
## above an on-screen keyboard of `keyboard_px` physical pixels.
func keyboard_shift(keyboard_px: float, window_px: float = -1.0) -> float:
	if keyboard_px <= 0.0:
		return 0.0
	# This screen fills the viewport, so its height is the viewport height.
	var vp_height: float = size.y
	var window_height: float = window_px if window_px > 0.0 else max(float(DisplayServer.window_get_size().y), 1.0)
	var keyboard_vp: float = keyboard_px * vp_height / window_height
	var answer_bottom: float = answer_edit.get_global_rect().end.y - position.y
	return max(0.0, answer_bottom + 16.0 - (vp_height - keyboard_vp))


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
		_set_feedback(tr("FORMAT_HINT"))
		return
	_answered_this_question = true
	answer_edit.editable = false
	submit_button.disabled = true
	var correct: bool = parsed.equals(question.target)
	_report_answer(correct)
	if not correct:
		# Screen shows "3:15"; the voice says it the natural way ("quarter past three").
		var wrong: String = tr("FEEDBACK_WRONG_WAS")
		_set_feedback(wrong.format({"time": question.target.to_digital_string()}),
			wrong.format({"time": LocaleManager.phrase_for_time(question.target)}))
		_wobble(answer_edit)


func _parse_time(text: String):
	var t: String = text.strip_edges()
	if not t.contains(":"):
		# Digits only (number keypad): "3" means 3:00, "315" means 3:15.
		if not t.is_valid_int() or t.length() > 4:
			return null
		t = format_digits(t) if t.length() > 2 else t + ":00"
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
