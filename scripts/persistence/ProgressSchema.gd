extends RefCounted

## Typed accessors over the raw progress dict so nothing outside
## ProgressStore touches raw JSON keys directly. `data` is the parsed
## JSON dictionary (see ProgressStore for the on-disk shape).

const SCHEMA_VERSION := 1

var data: Dictionary


func _init(p_data: Dictionary = {}) -> void:
	data = p_data
	_ensure_shape()


func _ensure_shape() -> void:
	if not data.has("schema_version"):
		data["schema_version"] = SCHEMA_VERSION
	if not data.has("profile_name"):
		data["profile_name"] = "Child"
	if not data.has("locale"):
		data["locale"] = "en"
	if not data.has("exercise_progress"):
		data["exercise_progress"] = {}
	if not data.has("overall_stars"):
		data["overall_stars"] = 0
	if not data.has("session_history"):
		data["session_history"] = []
	if not data.has("settings"):
		data["settings"] = {}


func get_setting(key: String, default_value):
	return data["settings"].get(key, default_value)


func set_setting(key: String, value) -> void:
	data["settings"][key] = value


func _tier_key(tier_number: int) -> String:
	return "tier_%d" % tier_number


func get_tier_stats(exercise_type_key: String, tier_number: int) -> Dictionary:
	var ex_dict: Dictionary = data["exercise_progress"].get(exercise_type_key, {})
	var tkey: String = _tier_key(tier_number)
	if not ex_dict.has(tkey):
		return {"correct": 0, "attempts": 0, "streak": 0, "mastered": false}
	return ex_dict[tkey]


func record_attempt(exercise_type_key: String, tier_number: int, correct: bool, mastery_threshold: int) -> void:
	var ex_progress: Dictionary = data["exercise_progress"]
	if not ex_progress.has(exercise_type_key):
		ex_progress[exercise_type_key] = {}
	var ex_dict: Dictionary = ex_progress[exercise_type_key]
	var tkey: String = _tier_key(tier_number)
	if not ex_dict.has(tkey):
		ex_dict[tkey] = {"correct": 0, "attempts": 0, "streak": 0, "mastered": false}
	var stats: Dictionary = ex_dict[tkey]

	stats["attempts"] = int(stats.get("attempts", 0)) + 1
	if correct:
		stats["correct"] = int(stats.get("correct", 0)) + 1
		stats["streak"] = int(stats.get("streak", 0)) + 1
		if stats["streak"] >= mastery_threshold:
			stats["mastered"] = true
			data["overall_stars"] = int(data.get("overall_stars", 0)) + 1
	else:
		stats["streak"] = 0

	ex_dict[tkey] = stats
	ex_progress[exercise_type_key] = ex_dict
	data["exercise_progress"] = ex_progress
	data["updated_at"] = Time.get_datetime_string_from_system()


func is_tier_mastered(exercise_type_key: String, tier_number: int) -> bool:
	return bool(get_tier_stats(exercise_type_key, tier_number).get("mastered", false))


func record_session(exercise_name: String, tier_name: String, correct: int, attempts: int) -> void:
	var history: Array = data["session_history"]
	history.append({
		"date": Time.get_date_string_from_system(),
		"exercise": exercise_name,
		"tier": tier_name,
		"correct": correct,
		"attempts": attempts,
	})
	if history.size() > 100:
		history = history.slice(history.size() - 100, history.size())
	data["session_history"] = history


func get_overall_stars() -> int:
	return int(data.get("overall_stars", 0))
