extends SceneTree

## Headless test for ProgressStore: drives a real session through
## ExerciseDirector, then verifies the save file survives a reload
## (simulating an app restart).
## Run with: godot --headless --script res://scripts/data/ProgressPersistenceTest.gd

const QuestionGenerator = preload("res://scripts/data/QuestionGenerator.gd")

var failures: int = 0


func _init() -> void:
	await process_frame
	await process_frame

	var director = root.get_node_or_null("ExerciseDirector")
	var store = root.get_node_or_null("ProgressStore")
	if director == null or store == null:
		print("1 FAILURE(S)")
		quit(1)
		return

	# ProgressStore already points at a scratch file under --script; start
	# from a clean slate for a deterministic test.
	if FileAccess.file_exists(store.SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(store.SAVE_PATH))
	store.load_progress()

	var ex_mc = load("res://resources/exercises/ex_read_mc.tres")
	var tier1 = load("res://resources/tiers/tier_1_ohclock.tres")

	director.start_session(ex_mc, tier1)
	# tier1 mastery_threshold is 5 - answer 5 correct in a row to trigger mastery.
	for i in range(5):
		director.record_answer(true)
		director.advance()

	var stats: Dictionary = store.get_tier_stats("READ_MC", 1)
	_check_eq_int("attempts after 5 correct", stats["attempts"], 5)
	_check_eq_int("correct after 5 correct", stats["correct"], 5)
	_check_eq_int("streak after 5 correct", stats["streak"], 5)
	_check_true("tier mastered after streak", bool(stats["mastered"]))
	_check_eq_int("total stars = correct answers so far", store.get_overall_stars(), 5)

	# Simulate an app restart: drop the in-memory schema, reload from disk.
	store.schema = null
	store.load_progress()
	var reloaded: Dictionary = store.get_tier_stats("READ_MC", 1)
	_check_eq_int("attempts survive reload", reloaded["attempts"], 5)
	_check_true("mastery survives reload", bool(reloaded["mastered"]))

	# A wrong answer should reset the streak but keep the attempt/correct counts growing.
	director.start_session(ex_mc, tier1)
	director.record_answer(false)
	var after_miss: Dictionary = store.get_tier_stats("READ_MC", 1)
	_check_eq_int("streak resets on wrong answer", after_miss["streak"], 0)
	_check_eq_int("attempts accumulate across sessions", after_miss["attempts"], 6)
	_check_eq_int("wrong answer adds no star", store.get_overall_stars(), 5)

	if failures == 0:
		print("ALL PASS")
	else:
		print("%d FAILURE(S)" % failures)
	quit(failures)


func _check_eq_int(label: String, actual: int, expected: int) -> void:
	if actual != expected:
		failures += 1
		print("FAIL %s: expected %s, got %s" % [label, expected, actual])
	else:
		print("ok   %s" % label)


func _check_true(label: String, actual: bool) -> void:
	if not actual:
		failures += 1
		print("FAIL %s: expected true" % label)
	else:
		print("ok   %s" % label)
