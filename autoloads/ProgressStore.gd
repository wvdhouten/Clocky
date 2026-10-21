extends Node

## Loads/saves user://progress.json. Missing or corrupt file just starts
## a fresh profile - never crashes. Single local child profile, no
## accounts/backend.

const ProgressSchema = preload("res://scripts/persistence/ProgressSchema.gd")
var SAVE_PATH := "user://progress.json"

var schema  # ProgressSchema


func _ready() -> void:
	# Headless test scripts (`godot --script ...`) drive real sessions through
	# ExerciseDirector; never let them read or write the child's real save.
	if "--script" in OS.get_cmdline_args() or "-s" in OS.get_cmdline_args():
		SAVE_PATH = "user://progress_test.json"
	load_progress()


func load_progress() -> void:
	var data: Dictionary = {}
	if FileAccess.file_exists(SAVE_PATH):
		var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
		if f:
			var text: String = f.get_as_text()
			f.close()
			var parsed = JSON.parse_string(text)
			if typeof(parsed) == TYPE_DICTIONARY:
				data = parsed
			else:
				push_warning("progress.json was corrupt/unreadable - starting a fresh profile")
	schema = ProgressSchema.new(data)


func save_progress() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(schema.data, "\t"))
		f.close()


func record_attempt(exercise_type_key: String, tier_number: int, correct: bool, mastery_threshold: int) -> void:
	schema.record_attempt(exercise_type_key, tier_number, correct, mastery_threshold)
	save_progress()


func record_session(exercise_name: String, tier_name: String, correct: int, attempts: int) -> void:
	schema.record_session(exercise_name, tier_name, correct, attempts)
	save_progress()


func get_tier_stats(exercise_type_key: String, tier_number: int) -> Dictionary:
	return schema.get_tier_stats(exercise_type_key, tier_number)


func is_tier_mastered(exercise_type_key: String, tier_number: int) -> bool:
	return schema.is_tier_mastered(exercise_type_key, tier_number)


func get_overall_stars() -> int:
	return schema.get_overall_stars()


signal setting_changed(key: String, value)


func get_setting(key: String, default_value):
	return schema.get_setting(key, default_value)


func set_setting(key: String, value) -> void:
	schema.set_setting(key, value)
	save_progress()
	setting_changed.emit(key, value)
