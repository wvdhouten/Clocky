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

const SpeakButtonScript = preload("res://scenes/ui_components/SpeakButton.gd")

@onready var prompt_label: Label = $PromptLabel
@onready var feedback_label: Label = $FeedbackLabel
@onready var next_button: Button = $NextButton
@onready var exit_button: Button = $ExitButton

var tier
var question
## Tap-to-hear 🗣️ buttons, created in code beside the prompt banner and
## (once answered) beside the feedback text.
var prompt_speaker: Button
var feedback_speaker: Button
var _feedback_speech: String = ""
## The feedback label's designed center/half-width; the label is shrunk to
## its text so the 🗣️ can sit right beside the words.
var _feedback_center_x: float
var _feedback_max_half: float


func _ready() -> void:
	next_button.text = tr("NEXT")
	next_button.pressed.connect(_on_next_pressed)
	next_button.visible = false
	exit_button.text = tr("EXIT")
	exit_button.pressed.connect(func():
		Speech.stop()
		exit_requested.emit())
	LocaleManager.locale_changed.connect(_on_locale_changed)

	prompt_speaker = _make_speaker(prompt_label, func(): return _prompt_speech())
	prompt_speaker.name = "PromptSpeaker"
	var mid: float = (prompt_label.offset_top + prompt_label.offset_bottom) / 2.0
	prompt_speaker.offset_right = prompt_label.offset_left - 12.0
	prompt_speaker.offset_left = prompt_speaker.offset_right - 52.0
	prompt_speaker.offset_top = mid - 26.0
	prompt_speaker.offset_bottom = mid + 26.0

	_feedback_center_x = (feedback_label.offset_left + feedback_label.offset_right) / 2.0
	_feedback_max_half = (feedback_label.offset_right - feedback_label.offset_left) / 2.0
	feedback_speaker = _make_speaker(feedback_label, func(): return _feedback_speech)
	feedback_speaker.name = "FeedbackSpeaker"
	feedback_speaker.active = false


## What the prompt's 🗣️ reads. Subclasses override to speak more naturally
## than the on-screen text (e.g. "half past three" instead of "3:30").
func _prompt_speech() -> String:
	return prompt_label.text


func _make_speaker(beside: Control, source: Callable) -> Button:
	var b: Button = SpeakButtonScript.new()
	b.source = source
	add_child(b)
	# Same horizontal/vertical anchor as the label it belongs to.
	b.anchor_left = beside.anchor_left
	b.anchor_right = beside.anchor_left
	b.anchor_top = beside.anchor_top
	b.anchor_bottom = beside.anchor_top
	return b


## Shows the feedback text, with a 🗣️ right beside the (centered) words.
## `spoken` lets the voice say it more naturally than the screen does.
func _set_feedback(display: String, spoken: String = "") -> void:
	feedback_label.text = display
	_feedback_speech = spoken if not spoken.is_empty() else display
	var font: Font = feedback_label.get_theme_font("font")
	var font_size: int = feedback_label.get_theme_font_size("font_size")
	var text_w: float = font.get_string_size(display, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var half: float = min(text_w / 2.0 + 6.0, _feedback_max_half)
	feedback_label.offset_left = _feedback_center_x - half
	feedback_label.offset_right = _feedback_center_x + half
	var mid: float = (feedback_label.offset_top + feedback_label.offset_bottom) / 2.0
	feedback_speaker.offset_right = _feedback_center_x - half - 8.0
	feedback_speaker.offset_left = feedback_speaker.offset_right - 52.0
	feedback_speaker.offset_top = mid - 26.0
	feedback_speaker.offset_bottom = mid + 26.0
	feedback_speaker.active = not display.is_empty()


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
	_set_feedback("")
	next_button.visible = false
	_on_setup()


func _on_setup() -> void:
	pass  # overridden by subclasses


func _report_answer(correct: bool) -> void:
	_set_feedback(tr("FEEDBACK_CORRECT") if correct else tr("FEEDBACK_WRONG"))
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
