extends Control

signal continue_pressed()

const SpeakButtonScript = preload("res://scenes/ui_components/SpeakButton.gd")

@onready var exercise_label: Label = $Card/VBox/ExerciseLabel
@onready var tier_label: Label = $Card/VBox/TierLabel
@onready var stars_row: HBoxContainer = $Card/VBox/StarsRow
@onready var score_label: Label = $Card/VBox/ScoreLabel
@onready var mastered_label: Label = $Card/VBox/MasteredLabel
@onready var total_label: Label = $Card/VBox/TotalLabel
@onready var continue_button: Button = $Card/VBox/ContinueButton

var _last_stats: Dictionary = {}


func _ready() -> void:
	SpeakButtonScript.attach(exercise_label, func(): return "%s. %s" % [exercise_label.text, tier_label.text])
	SpeakButtonScript.attach(mastered_label, func(): return mastered_label.text)
	SpeakButtonScript.attach(total_label, func(): return total_label.text)
	SpeakButtonScript.attach(continue_button, func(): return continue_button.text)
	continue_button.text = tr("CONTINUE")
	continue_button.pressed.connect(func(): continue_pressed.emit())
	LocaleManager.locale_changed.connect(func(_l):
		continue_button.text = tr("CONTINUE")
		_apply_text())


func set_stats(stats: Dictionary) -> void:
	_last_stats = stats
	_apply_text()
	_build_stars(int(stats.get("correct", 0)), int(stats.get("attempts", 0)))


func _apply_text() -> void:
	var s: Dictionary = _last_stats
	exercise_label.text = tr(s.get("exercise_name_key", ""))
	tier_label.text = tr(s.get("tier_name_key", ""))
	score_label.text = "%d / %d" % [int(s.get("correct", 0)), int(s.get("attempts", 0))]
	mastered_label.visible = bool(s.get("tier_mastered", false))
	mastered_label.text = tr("TIER_MASTERED")
	total_label.text = "⭐ " + tr("TOTAL_STARS").format({"count": int(s.get("overall_stars", 0))})


## One star per question: earned ones pop in one by one with rising
## chimes, missed ones stay as faint outlines (no red, no shaming).
func _build_stars(correct: int, attempts: int) -> void:
	for child in stars_row.get_children():
		child.queue_free()
	var earned: Array[Label] = []
	for i in attempts:
		var star := Label.new()
		star.text = "⭐"
		star.add_theme_font_size_override("font_size", 52)
		if i < correct:
			star.modulate.a = 0.0
			earned.append(star)
		else:
			star.modulate = Color(1, 1, 1, 0.22)
		stars_row.add_child(star)

	await get_tree().process_frame
	for i in earned.size():
		var star: Label = earned[i]
		if not is_instance_valid(star):
			return
		star.pivot_offset = star.size / 2.0
		star.scale = Vector2(0.2, 0.2)
		var tw := create_tween().set_parallel()
		tw.tween_property(star, "modulate:a", 1.0, 0.15)
		tw.tween_property(star, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		SoundFx.play("star", 1.0 + i * 0.06)
		await get_tree().create_timer(0.18).timeout
