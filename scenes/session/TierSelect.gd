extends Control

## Two-step picker (activity, then difficulty) built as picture cards: each
## card shows a mini clock with an example time, so children who can't
## read yet can still choose. Mastered difficulties get a trophy badge.

signal exercise_chosen(exercise_def, tier)
signal back_requested()

const TimeValue = preload("res://scripts/clock_logic/TimeValue.gd")
const ExerciseDefinitionScript = preload("res://scripts/data/ExerciseDefinition.gd")
const AnalogClockScene = preload("res://scenes/clock/AnalogClock.tscn")
const ExReadMc = preload("res://resources/exercises/ex_read_mc.tres")
const ExReadFree = preload("res://resources/exercises/ex_read_free.tres")
const ExSetClock = preload("res://resources/exercises/ex_set_clock.tres")

## Example time shown on each activity card, plus a small badge icon.
const ACTIVITY_LOOK := {
	ExerciseDefinitionScript.ExerciseType.READ_MC: [10, 10, "❓"],
	ExerciseDefinitionScript.ExerciseType.READ_FREE: [3, 0, "⌨️"],
	ExerciseDefinitionScript.ExerciseType.SET_CLOCK: [7, 30, "👆"],
}
## Example time per tier number, showing what that tier practises. Chosen
## so the two hands are always clearly apart on the small card clocks.
const TIER_EXAMPLE := {1: [3, 0], 2: [10, 30], 3: [9, 15], 4: [2, 40], 5: [4, 47]}

@onready var exercise_row: HBoxContainer = $ExerciseRow
@onready var tier_row: HBoxContainer = $TierRow
@onready var title_label: Label = $TitleLabel
@onready var back_button: Button = $BackButton

var _chosen_exercise_def = null


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	_show_exercise_choices()
	LocaleManager.locale_changed.connect(_on_locale_changed)


func _on_locale_changed(_locale: String) -> void:
	if _chosen_exercise_def:
		_on_exercise_picked(_chosen_exercise_def)
	else:
		_show_exercise_choices()


func _on_back_pressed() -> void:
	if _chosen_exercise_def:
		_show_exercise_choices()
	else:
		back_requested.emit()


func _show_exercise_choices() -> void:
	_chosen_exercise_def = null
	title_label.text = tr("PICK_ACTIVITY")
	back_button.text = "◀  " + tr("BACK")
	tier_row.visible = false
	exercise_row.visible = true
	_clear(exercise_row)

	for ex in [ExReadMc, ExReadFree, ExSetClock]:
		var look: Array = ACTIVITY_LOOK[ex.exercise_type]
		var mastered: int = _mastered_count(ex)
		var badge: String = look[2]
		var footer: String = "🏆 %d/%d" % [mastered, ex.supports_tiers.size()] if mastered > 0 else ""
		var card := _card(Vector2(260, 290), TimeValue.new(look[0], look[1]), 160, tr(ex.name_key), badge, footer)
		card.pressed.connect(_on_exercise_picked.bind(ex))
		exercise_row.add_child(card)
		_pop_in(card, exercise_row.get_child_count())


func _on_exercise_picked(ex) -> void:
	_chosen_exercise_def = ex
	title_label.text = tr("PICK_DIFFICULTY")
	back_button.text = "◀  " + tr("BACK")
	exercise_row.visible = false
	tier_row.visible = true
	_clear(tier_row)

	var type_key: String = ExerciseDefinitionScript.type_key(ex.exercise_type)
	for tier in ex.supports_tiers:
		var example: Array = TIER_EXAMPLE.get(tier.tier_number, [3, 0])
		var mastered: bool = ProgressStore.is_tier_mastered(type_key, tier.tier_number)
		var card := _card(Vector2(196, 250), TimeValue.new(example[0], example[1]), 130, tr(tier.name_key), "🏆" if mastered else "", "")
		card.pressed.connect(_on_tier_picked.bind(tier))
		tier_row.add_child(card)
		_pop_in(card, tier_row.get_child_count())


func _on_tier_picked(tier) -> void:
	exercise_chosen.emit(_chosen_exercise_def, tier)


func _mastered_count(ex) -> int:
	var type_key: String = ExerciseDefinitionScript.type_key(ex.exercise_type)
	var n: int = 0
	for tier in ex.supports_tiers:
		if ProgressStore.is_tier_mastered(type_key, tier.tier_number):
			n += 1
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

	if not badge.is_empty():
		var b := Label.new()
		b.text = badge
		b.add_theme_font_size_override("font_size", 34)
		b.position = Vector2(card_size.x - 52, 6)
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
