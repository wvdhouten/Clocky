extends "res://scenes/exercises/ExerciseBase.gd"

## Set the clock, multiple-choice style: the prompt names a time and the
## child picks which of four clocks shows it. Distractors come from
## QuestionGenerator (swapped hours, neighbouring minutes), so the clocks
## differ in exactly the ways children tend to mix up.

const AnalogClockScene = preload("res://scenes/clock/AnalogClock.tscn")

const CARD_SIZE := Vector2(220, 226)
const CLOCK_PX := 196

@onready var options_container: HBoxContainer = $OptionsContainer

var _answered_this_question: bool = false
var _option_buttons: Array = []  # [[TimeValue, Button], ...]


func _on_setup() -> void:
	_answered_this_question = false
	_refresh_prompt()

	for child in options_container.get_children():
		options_container.remove_child(child)
		child.queue_free()
	_option_buttons.clear()

	var options: Array = [question.target]
	for d in question.distractors:
		options.append(d)
	options.shuffle()

	for opt in options:
		var btn := Button.new()
		btn.custom_minimum_size = CARD_SIZE
		var clock: Control = AnalogClockScene.instantiate()
		clock.mouse_filter = Control.MOUSE_FILTER_IGNORE
		clock.custom_minimum_size = Vector2(CLOCK_PX, CLOCK_PX)
		btn.add_child(clock)
		clock.set_time(opt)
		btn.pressed.connect(_on_option_pressed.bind(opt, btn))
		options_container.add_child(btn)
		# Only in the tree does the scene's own 300 px minimum let go.
		clock.reset_size()
		clock.position = Vector2((CARD_SIZE.x - CLOCK_PX) / 2.0, 8)
		_option_buttons.append([opt, btn])


func _hints_for_question() -> Array:
	return HintBuilder.set_hints(question.target)


func _refresh_prompt() -> void:
	prompt_label.text = tr("SET_MC_PROMPT").format({"time": question.target.to_digital_string()})


## Spoken as "Which clock shows half past three?", not "... 3:30".
func _prompt_speech() -> String:
	return tr("SET_MC_PROMPT").format({"time": LocaleManager.phrase_for_time(question.target)})


func _on_option_pressed(opt, btn: Button) -> void:
	if _answered_this_question:
		return
	_answered_this_question = true
	var correct: bool = opt.equals(question.target)
	for pair in _option_buttons:
		var b: Button = pair[1]
		b.disabled = true
		if pair[0].equals(question.target):
			# Always reveal the right clock, so a wrong pick still teaches.
			_paint(b, UiTheme.LEAF, UiTheme.LEAF_DARK)
			_pop_in(b)
	if not correct:
		_paint(btn, UiTheme.CORAL, UiTheme.CORAL_DARK)
		_wobble(btn)
	_report_answer(correct)


func _paint(b: Button, fill: Color, edge: Color) -> void:
	b.add_theme_stylebox_override("disabled", UiTheme.button_box(fill, edge))
