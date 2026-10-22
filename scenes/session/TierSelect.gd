extends Control

## Two-step picker (activity, then difficulty) built as picture cards: each
## card shows a mini clock with an example time, so children who can't
## read yet can still choose. Mastered difficulties get a trophy badge.
##
## Exercises sharing an `activity` (READ: choose / scroll, SET: choose /
## drag) are one card; the difficulty step shows a toggle between their
## modes, and the last choice per activity is remembered.

signal exercise_chosen(exercise_def, tier)
signal back_requested()

const TimeValue = preload("res://scripts/clock_logic/TimeValue.gd")
const ExerciseDefinitionScript = preload("res://scripts/data/ExerciseDefinition.gd")
const AnalogClockScene = preload("res://scenes/clock/AnalogClock.tscn")
const SpeakButtonScript = preload("res://scenes/ui_components/SpeakButton.gd")

## Every exercise, in toggle order within its activity.
const EXERCISES := [
	preload("res://resources/exercises/ex_learn.tres"),
	preload("res://resources/exercises/ex_read_mc.tres"),
	preload("res://resources/exercises/ex_read_free.tres"),
	preload("res://resources/exercises/ex_set_mc.tres"),
	preload("res://resources/exercises/ex_set_clock.tres"),
]
## Activity cards: name key, example time and a corner icon.
const ACTIVITIES := [
	["LEARN", "ACTIVITY_LEARN", 10, 10, "🦉"],
	["READ", "ACTIVITY_READ", 3, 0, "👀"],
	["SET", "ACTIVITY_SET", 7, 30, "👆"],
]
## Mode shown first time an activity is opened (what each used to be).
const DEFAULT_MODE := {"READ": "READ_MC", "SET": "SET_CLOCK"}
## Example time per tier number, showing what that tier practises. Chosen
## so the two hands are always clearly apart on the small card clocks.
const TIER_EXAMPLE := {1: [3, 0], 2: [10, 30], 3: [9, 15], 4: [2, 40], 5: [4, 47]}

@onready var exercise_row: HBoxContainer = $ExerciseRow
@onready var tier_row: HBoxContainer = $TierRow
@onready var mode_row: HBoxContainer = $ModeRow
@onready var title_label: Label = $TitleLabel
@onready var back_button: Button = $BackButton

## Activity whose difficulties are showing ("" on the activity step).
var _chosen_activity: String = ""


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	SpeakButtonScript.attach(title_label, func(): return title_label.text)
	SpeakButtonScript.attach(back_button, func(): return back_button.text)
	_show_exercise_choices()
	LocaleManager.locale_changed.connect(_on_locale_changed)


func _on_locale_changed(_locale: String) -> void:
	if _chosen_activity.is_empty():
		_show_exercise_choices()
	else:
		_on_activity_picked(_chosen_activity)


func _on_back_pressed() -> void:
	if not _chosen_activity.is_empty():
		_show_exercise_choices()
	else:
		back_requested.emit()


static func exercises_for(activity: String) -> Array:
	return EXERCISES.filter(func(ex): return ex.activity == activity)


## The exercise the child last picked for `activity` (its mode).
func selected_exercise(activity: String):
	var modes: Array = exercises_for(activity)
	var key: String = str(ProgressStore.get_setting("mode_" + activity, DEFAULT_MODE.get(activity, "")))
	for ex in modes:
		if ExerciseDefinitionScript.type_key(ex.exercise_type) == key:
			return ex
	return modes[0]


func _show_exercise_choices() -> void:
	_chosen_activity = ""
	title_label.text = tr("PICK_ACTIVITY")
	back_button.text = "◀  " + tr("BACK")
	tier_row.visible = false
	mode_row.visible = false
	exercise_row.visible = true
	_clear(exercise_row)

	for look in ACTIVITIES:
		var activity: String = look[0]
		var mastered: int = _mastered_count(activity)
		var footer: String = "🏆 %d/5" % mastered if mastered > 0 else ""
		var card := _card(Vector2(260, 290), TimeValue.new(look[2], look[3]), 150, tr(look[1]), look[4], footer)
		card.pressed.connect(_on_activity_picked.bind(activity))
		exercise_row.add_child(card)
		_pop_in(card, exercise_row.get_child_count())


func _on_activity_picked(activity: String) -> void:
	_chosen_activity = activity
	title_label.text = tr("PICK_LESSON" if activity == "LEARN" else "PICK_DIFFICULTY")
	back_button.text = "◀  " + tr("BACK")
	exercise_row.visible = false
	tier_row.visible = true
	_build_mode_toggle(activity)
	_build_tier_cards(activity)


## One toggle segment per mode, e.g. [❓ Choose | 🎚️ Scroll].
func _build_mode_toggle(activity: String) -> void:
	_clear(mode_row)
	var modes: Array = exercises_for(activity)
	mode_row.visible = modes.size() > 1
	if modes.size() < 2:
		return
	var selected = selected_exercise(activity)
	var group := ButtonGroup.new()
	for ex in modes:
		var seg := Button.new()
		seg.name = "Mode_" + ExerciseDefinitionScript.type_key(ex.exercise_type)
		seg.text = "%s  %s" % [ex.mode_icon, tr(ex.mode_name_key)]
		seg.custom_minimum_size = Vector2(220, 64)
		seg.toggle_mode = true
		seg.button_group = group
		seg.button_pressed = ex == selected
		seg.pressed.connect(_on_mode_picked.bind(activity, ex))
		mode_row.add_child(seg)
		var label_text: String = tr(ex.mode_name_key)
		SpeakButtonScript.attach(seg, func(): return label_text)


func _on_mode_picked(activity: String, ex) -> void:
	ProgressStore.set_setting("mode_" + activity, ExerciseDefinitionScript.type_key(ex.exercise_type))
	_build_tier_cards(activity)


func _build_tier_cards(activity: String) -> void:
	_clear(tier_row)
	var ex = selected_exercise(activity)
	var type_key: String = ExerciseDefinitionScript.type_key(ex.exercise_type)
	for tier in ex.supports_tiers:
		var example: Array = TIER_EXAMPLE.get(tier.tier_number, [3, 0])
		var badge: String = ""
		if activity == "LEARN":
			badge = "✅" if ProgressStore.get_setting("learn_seen_%d" % tier.tier_number, false) else ""
		elif ProgressStore.is_tier_mastered(type_key, tier.tier_number):
			badge = "🏆"
		var card := _card(Vector2(196, 250), TimeValue.new(example[0], example[1]), 120, tr(tier.name_key), badge, "")
		card.pressed.connect(_on_tier_picked.bind(tier))
		tier_row.add_child(card)
		_pop_in(card, tier_row.get_child_count())


func _on_tier_picked(tier) -> void:
	exercise_chosen.emit(selected_exercise(_chosen_activity), tier)


## Tiers mastered in any of the activity's modes.
func _mastered_count(activity: String) -> int:
	var n: int = 0
	for tier_number in range(1, 6):
		for ex in exercises_for(activity):
			if ProgressStore.is_tier_mastered(ExerciseDefinitionScript.type_key(ex.exercise_type), tier_number):
				n += 1
				break
	return n


## A picture card: mini clock + name, optional corner badge and footer.
## All children ignore the mouse so the whole card acts as one button.
func _card(card_size: Vector2, example: TimeValue, clock_px: int, label_text: String, badge: String, footer: String) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = card_size

	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.offset_top = 14
	box.offset_bottom = -16
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 6)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(box)

	var clock: Control = AnalogClockScene.instantiate()
	clock.follow_number_setting = false
	clock.number_mode = clock.NumberMode.NONE
	clock.custom_minimum_size = Vector2(clock_px, clock_px)
	clock.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	clock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(clock)
	clock.set_time(example)

	var label := Label.new()
	label.text = label_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_font_override("font", UiTheme.font(700))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(label)

	if not footer.is_empty():
		var foot := Label.new()
		foot.text = footer
		foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		foot.add_theme_font_size_override("font_size", 18)
		foot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(foot)

	# 🗣️ badge reads the card's name without selecting it (it's its own
	# button, so the tap doesn't reach the card).
	SpeakButtonScript.attach(btn, func(): return label_text)

	if not badge.is_empty():
		var b := Label.new()
		b.text = badge
		b.add_theme_font_size_override("font_size", 30)
		b.position = Vector2(10, 4)
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(b)
	return btn


func _clear(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()


## Cards pop in one after another.
func _pop_in(card: Control, index: int) -> void:
	card.modulate.a = 0.0
	card.scale = Vector2(0.85, 0.85)
	await get_tree().process_frame
	if not is_instance_valid(card):
		return
	card.pivot_offset = card.size / 2.0
	var tw := card.create_tween().set_parallel()
	tw.tween_property(card, "modulate:a", 1.0, 0.25).set_delay(index * 0.06)
	tw.tween_property(card, "scale", Vector2.ONE, 0.35).set_delay(index * 0.06).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
