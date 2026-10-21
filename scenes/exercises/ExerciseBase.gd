extends Control

## Shared scaffolding every exercise scene extends via
## `extends "res://scenes/exercises/ExerciseBase.gd"` (path-based, not
## class_name-based, so it works even without a populated global script
## class cache). Each exercise .tscn must include a PromptLabel, a
## FeedbackLabel, and a NextButton with those exact node names.
##
## Subclasses override `_on_setup()` to build their question UI, and call
## `_report_answer(correct)` once the player has answered.
##
## Every exercise .tscn must also include an ExitButton so the child (or
## a supervising adult) can always back out of an exercise mid-session.

signal answered(correct: bool)
signal next_requested()
signal exit_requested()

@onready var prompt_label: Label = $PromptLabel
@onready var feedback_label: Label = $FeedbackLabel
@onready var next_button: Button = $NextButton
@onready var exit_button: Button = $ExitButton

var tier
var question


func _ready() -> void:
	next_button.text = tr("NEXT")
	next_button.pressed.connect(_on_next_pressed)
	next_button.visible = false
	exit_button.text = tr("EXIT")
	exit_button.pressed.connect(func(): exit_requested.emit())
	LocaleManager.locale_changed.connect(_on_locale_changed)


## Updates static chrome text (next/exit buttons) when the locale changes
## mid-exercise. Subclasses override _refresh_prompt() to update their
## own prompt/button text without rebuilding the question (which would
## lose answered-state).
func _on_locale_changed(_locale: String) -> void:
	next_button.text = tr("NEXT")
	exit_button.text = tr("EXIT")
	_refresh_prompt()


func _refresh_prompt() -> void:
	pass  # overridden by subclasses


func setup(p_tier, p_question) -> void:
	tier = p_tier
	question = p_question
	feedback_label.text = ""
	next_button.visible = false
	_on_setup()


func _on_setup() -> void:
	pass  # overridden by subclasses


func _report_answer(correct: bool) -> void:
	feedback_label.text = tr("FEEDBACK_CORRECT") if correct else tr("FEEDBACK_WRONG")
	next_button.visible = true
	_pop_in(next_button)
	answered.emit(correct)


## Where the confetti for a correct answer bursts from (screen position).
func celebration_point() -> Vector2:
	return feedback_label.get_global_rect().get_center()


## Small "boing" so new things on screen catch a child's eye.
func _pop_in(control: Control) -> void:
	control.pivot_offset = control.size / 2.0
	control.scale = Vector2(0.6, 0.6)
	var tw := create_tween()
	tw.tween_property(control, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Gentle side-to-side wobble for a wrong pick (never harsh).
func _wobble(control: Control) -> void:
	var start: Vector2 = control.position
	var tw := create_tween()
	for dx in [-10.0, 9.0, -6.0, 4.0, 0.0]:
		tw.tween_property(control, "position:x", start.x + dx, 0.06)


func _on_next_pressed() -> void:
	next_requested.emit()
