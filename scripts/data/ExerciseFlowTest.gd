extends SceneTree

## Headless smoke test driving ExerciseDirector's session logic directly
## (no GUI interaction needed). Run with:
##   godot --headless --script res://scripts/data/ExerciseFlowTest.gd

var failures: int = 0


func _init() -> void:
	await process_frame
	await process_frame

	var director = root.get_node_or_null("ExerciseDirector")
	if director == null:
		push_error("ExerciseDirector autoload not found")
		print("1 FAILURE(S)")
		quit(1)
		return

	var ex_mc = load("res://resources/exercises/ex_read_mc.tres")
	var tier3 = load("res://resources/tiers/tier_3_quarter.tres")

	_check_eq_int("exercise supports 5 tiers", ex_mc.supports_tiers.size(), 5)
	_check_eq_int("tier3 allowed_minutes count", tier3.allowed_minutes.size(), 4)

	director.start_session(ex_mc, tier3)
	_check_true("first question target not null", director.current_question.target != null)
	_check_true("first question has distractors", director.current_question.distractors.size() > 0)

	for d in director.current_question.distractors:
		_check_true("distractor minute is tier3-valid", tier3.allowed_minutes.has(d.minute))
		_check_true("distractor != target", not d.equals(director.current_question.target))

	var questions_seen: int = 1
	director.record_answer(true)
	while director.advance():
		questions_seen += 1
		director.record_answer(questions_seen % 2 == 0)

	_check_eq_int("session length reached", questions_seen, director.SESSION_LENGTH)

	var stats: Dictionary = director.get_session_stats()
	_check_eq_int("attempts recorded", stats["attempts"], director.SESSION_LENGTH)

	# Set the clock (choose) keeps its own progress, and its stars count too.
	var store = root.get_node("ProgressStore")
	var stars_before: int = store.get_overall_stars()
	var ex_set_mc = load("res://resources/exercises/ex_set_mc.tres")
	var set_before: int = int(store.get_tier_stats("SET_MC", 3)["correct"])
	director.start_session(ex_set_mc, tier3)
	director.record_answer(true)
	_check_eq_int("SET_MC progress recorded under its own key", int(store.get_tier_stats("SET_MC", 3)["correct"]), set_before + 1)
	_check_eq_int("SET_MC answers add stars", store.get_overall_stars(), stars_before + 1)

	# Every activity groups its modes, and each mode's scene loads.
	for ex_path in ["ex_learn", "ex_read_mc", "ex_read_free", "ex_set_mc", "ex_set_clock"]:
		var ex = load("res://resources/exercises/%s.tres" % ex_path)
		_check_true("%s has an activity and a scene" % ex_path, not ex.activity.is_empty() and ex.scene != null)

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
