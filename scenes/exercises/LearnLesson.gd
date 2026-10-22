extends Control

## Learn: the owl explains the clock step by step, one lesson per tier
## topic (see LessonLibrary). The clock beside the owl's bubble shows,
## animates and highlights what each step talks about; "try" steps let
## the child set the clock themselves. No scoring: reaching the last step
## marks the lesson as seen (✅ on the picker).
##
## The bubble itself lives in Main (over the owl), so this screen asks for
## it through `owl_says`.

signal exit_requested()
signal owl_says(text: String, spoken: String)
signal owl_cheers()

const TimeValue = preload("res://scripts/clock_logic/TimeValue.gd")
const LessonLibrary = preload("res://scripts/data/LessonLibrary.gd")
const SpeakButtonScript = preload("res://scenes/ui_components/SpeakButton.gd")

@onready var title_label: Label = $TitleLabel
@onready var clock: Control = $AnalogClock
@onready var prev_button: Button = $PrevButton
@onready var next_button: Button = $NextButton
@onready var exit_button: Button = $ExitButton

var tier
var step_index: int = 0
var _steps: Array = []
var _solved: bool = false


func _ready() -> void:
	prev_button.pressed.connect(func(): show_step(step_index - 1))
	next_button.pressed.connect(_on_next_pressed)
	exit_button.pressed.connect(func():
		Speech.stop()
		exit_requested.emit())
	clock.time_changed.connect(_on_clock_changed)
	SpeakButtonScript.attach(title_label, func(): return title_label.text)
	SpeakButtonScript.attach(next_button, func(): return next_button.text)
	SpeakButtonScript.attach(exit_button, func(): return exit_button.text)
	LocaleManager.locale_changed.connect(func(_l): _refresh_text())
	ProgressStore.setting_changed.connect(func(key, _v):
		if key == clock.NUMBER_MODE_SETTING:
			_apply_number_mode())


func setup(p_tier) -> void:
	tier = p_tier
	_steps = LessonLibrary.steps(tier.tier_number)
	show_step(0)


func show_step(index: int) -> void:
	step_index = clampi(index, 0, _steps.size() - 1)
	var step: Dictionary = _steps[step_index]
	var target = _step_time(step)
	_solved = false
	_apply_number_mode()
	clock.set_highlight(step.get("hand", 0))
	if step.has("try"):
		# The child does it: start the hands well away from the answer.
		clock.display_mode = clock.DisplayMode.INTERACTIVE
		clock.set_allowed_minutes(step["try"])
		clock.set_time(TimeValue.new(target.hour + 6, 0))
	else:
		clock.display_mode = clock.DisplayMode.STATIC
		if not clock.get_current_time().equals(target):
			clock.animate_to(target, 1.0)
	if step_index == _steps.size() - 1:
		ProgressStore.set_setting("learn_seen_%d" % tier.tier_number, true)
	_refresh_text()


func _step_time(step: Dictionary):
	return TimeValue.new(step["time"][0], step["time"][1])


func _apply_number_mode() -> void:
	if _steps.is_empty():
		return
	var step: Dictionary = _steps[step_index]
	clock.number_mode = int(step["numbers"]) if step.has("numbers") \
		else int(ProgressStore.get_setting(clock.NUMBER_MODE_SETTING, clock.NumberMode.HOURS))


func _refresh_text() -> void:
	title_label.text = tr(tier.name_key) if tier else ""
	exit_button.text = tr("EXIT")
	prev_button.disabled = step_index == 0
	var last: bool = step_index == _steps.size() - 1
	next_button.text = tr("DONE") if last else tr("NEXT") + "  ▶"
	if _steps.is_empty():
		return
	var step: Dictionary = _steps[step_index]
	var key: String = "LEARN_TRY_DONE" if _solved else step["key"]
	var target = _step_time(step)
	var phrase: String = LocaleManager.phrase_for_time(target)
	var text: String = tr(key).format({"time": target.to_digital_string(), "phrase": phrase})
	var spoken: String = tr(key).format({"time": phrase, "phrase": phrase})
	owl_says.emit(text, spoken)


func _on_clock_changed(current) -> void:
	var step: Dictionary = _steps[step_index]
	if not step.has("try") or _solved:
		return
	if current.equals(_step_time(step)):
		_solved = true
		clock.display_mode = clock.DisplayMode.STATIC
		clock.set_highlight(0)
		SoundFx.play("chime")
		owl_cheers.emit()
		_refresh_text()


func _on_next_pressed() -> void:
	if step_index >= _steps.size() - 1:
		Speech.stop()
		exit_requested.emit()
	else:
		show_step(step_index + 1)
