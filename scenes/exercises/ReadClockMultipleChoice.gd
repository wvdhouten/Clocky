extends "res://scenes/exercises/ExerciseBase.gd"

@onready var clock: Control = $AnalogClock
@onready var options_container: HBoxContainer = $OptionsContainer

var _answered_this_question: bool = false
var _option_buttons: Array = []  # [[TimeValue, Button], ...]


func _on_setup() -> void:
	_answered_this_question = false
	prompt_label.text = tr("READ_MC_PROMPT")
	clock.display_mode = clock.DisplayMode.STATIC
	clock.set_time(question.target)

	for child in options_container.get_children():
		child.queue_free()
	_option_buttons.clear()

	var options: Array = [question.target]
	for d in question.distractors:
		options.append(d)
	options.shuffle()

	for opt in options:
		var btn := Button.new()
		btn.text = opt.to_digital_string()
		btn.custom_minimum_size = Vector2(140, 70)
		btn.add_theme_font_size_override("font_size", 30)
		btn.pressed.connect(_on_option_pressed.bind(opt, btn))
		options_container.add_child(btn)
		_option_buttons.append([opt, btn])


func _refresh_prompt() -> void:
	prompt_label.text = tr("READ_MC_PROMPT")
	# Option labels are digit strings (e.g. "3:15") - no translation needed.


func _on_option_pressed(opt, btn: Button) -> void:
	if _answered_this_question:
		return
	_answered_this_question = true
	var correct: bool = opt.equals(question.target)
	for pair in _option_buttons:
		var b: Button = pair[1]
		b.disabled = true
		if pair[0].equals(question.target):
			# Always reveal the right answer, so a wrong pick still teaches.
			_paint(b, UiTheme.LEAF, UiTheme.LEAF_DARK)
			_pop_in(b)
	if not correct:
		_paint(btn, UiTheme.CORAL, UiTheme.CORAL_DARK)
		_wobble(btn)
	_report_answer(correct)


func _paint(b: Button, fill: Color, edge: Color) -> void:
	b.add_theme_stylebox_override("disabled", UiTheme.button_box(fill, edge))
	b.add_theme_color_override("font_disabled_color", UiTheme.INK)
