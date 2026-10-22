extends SceneTree

## Walks through every screen of the real game and saves a PNG of Godot's
## own viewport for each (never the desktop). Must run WITH a window:
##   godot --path . --script res://scripts/tools/Screenshots.gd -- <out_dir>

var out_dir: String = "user://screenshots"
var main


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = args[0]
	DirAccess.make_dir_recursive_absolute(out_dir)
	_run.call_deferred()


func _run() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1280, 800))
	var store = root.get_node("ProgressStore")
	root.get_node("ExerciseDirector")._rng.seed = 7  # same questions every run
	store.set_setting("clock_numbers", 1)
	store.record_attempt("READ_MC", 1, true, 1)
	store.record_attempt("READ_MC", 2, true, 1)

	root.get_node("Speech").force_available = true  # show the 🗣️ badges
	main = load("res://scenes/main/Main.tscn").instantiate()
	root.add_child(main)
	await _shot("01_menu")

	main.show_tier_select()
	await _shot("02_pick_activity", 0.6)

	var ex_mc = load("res://resources/exercises/ex_read_mc.tres")
	var ex_wheel = load("res://resources/exercises/ex_read_free.tres")
	var ex_set = load("res://resources/exercises/ex_set_clock.tres")
	var ex_set_mc = load("res://resources/exercises/ex_set_mc.tres")
	var ex_learn = load("res://resources/exercises/ex_learn.tres")
	var tier1 = load("res://resources/tiers/tier_1_ohclock.tres")
	var tier2 = load("res://resources/tiers/tier_2_half.tres")
	var tier3 = load("res://resources/tiers/tier_3_quarter.tres")
	var tier4 = load("res://resources/tiers/tier_4_five_min.tres")

	main._current_screen._on_activity_picked("READ")
	await _shot("03_pick_difficulty", 0.6)
	main._current_screen._on_activity_picked("LEARN")
	await _shot("03b_pick_lesson", 0.6)

	main._on_exercise_chosen(ex_mc, tier3)
	await _shot("04_mc_question")
	var screen = main._current_screen
	for pair in screen._option_buttons:
		if not pair[0].equals(screen.question.target):
			pair[1].pressed.emit()
			break
	await _shot("05_mc_wrong", 0.45)
	_zoom("05_mc_wrong", "05z_owl_zoom", Rect2i(1080, 590, 180, 190), 3)
	main._on_next_requested()
	main.show_hint()
	await _shot("05a_hint_hour", 0.5)
	main.show_hint()
	await _shot("05a_hint_minute", 0.5)
	screen = main._current_screen
	for pair in screen._option_buttons:
		if pair[0].equals(screen.question.target):
			pair[1].pressed.emit()
			break
	await _shot("05b_mc_correct", 0.3)

	store.set_setting("clock_numbers", 2)
	main._on_exercise_chosen(ex_wheel, tier4)
	await _shot("06_wheel_question")
	main._current_screen._on_check_pressed()
	await _shot("06b_wheel_wrong_shows_answer", 1.0)

	store.set_setting("clock_numbers", 0)
	main._on_exercise_chosen(ex_set, tier3)
	await _shot("07_set_no_numbers")
	main._current_screen._on_check_pressed()
	await _shot("08_set_wrong_shows_answer", 1.6)
	_zoom("08_set_wrong_shows_answer", "08z_hands_zoom", Rect2i(520, 250, 240, 240), 3)
	_zoom("08_set_wrong_shows_answer", "08z_rim_zoom", Rect2i(700, 170, 140, 140), 4)

	store.set_setting("clock_numbers", 1)
	main._on_exercise_chosen(ex_set_mc, tier2)
	await _shot("08c_set_choose", 0.4)
	main.show_hint()
	await _shot("08d_set_choose_hint", 0.4)

	main._on_exercise_chosen(ex_learn, tier1)
	await _shot("08e_learn_step1", 0.6)
	main._current_screen.show_step(1)
	await _shot("08f_learn_short_hand", 1.2)
	main._current_screen.show_step(main._current_screen._steps.size() - 1)
	await _shot("08g_learn_try", 0.6)

	root.get_node("LocaleManager").set_app_locale("nl")
	main._on_exercise_chosen(ex_learn, tier2)
	main._current_screen.show_step(3)
	await _shot("08h_learn_dutch_half", 1.2)
	root.get_node("LocaleManager").set_app_locale("ro")
	main._on_exercise_chosen(ex_mc, tier3)
	await _shot("09_mc_romanian")
	root.get_node("LocaleManager").set_app_locale("en")

	root.get_node("GameState").session_correct = 6
	root.get_node("GameState").session_attempts = 8
	main._show_session_summary()
	await _shot("10_summary", 2.2)

	main.get_node("SafeArea/LocaleSwitcher")._toggle_dialog()
	await _shot("11_locale_dialog")
	main.get_node("SafeArea/NumberModeSwitcher")._toggle_dialog()
	await _shot("11b_numbers_dialog")
	main.get_node("SafeArea/NumberModeSwitcher").close_dialog()
	await _shot("11c_top_bar")
	_zoom("11c_top_bar", "11z_top_bar_zoom", Rect2i(1070, 0, 210, 80), 3)

	var exit_btn = main.get_node("SafeArea/ParentExitButton")
	exit_btn._holding = true
	exit_btn._held = 1.6
	await _shot("12_parent_exit_holding")
	exit_btn._holding = false
	exit_btn._held = 0.0

	# 16:9 monitor: the "expand" aspect widens the logical viewport.
	DisplayServer.window_set_size(Vector2i(1422, 800))
	main.show_tier_select()
	main._current_screen._on_activity_picked("SET")
	await _shot("13_wide_difficulty", 0.6)

	print("screenshots saved to ", out_dir)
	quit()


func _shot(name: String, delay: float = 0.0) -> void:
	for i in 4:
		await process_frame
	if delay > 0.0:
		await create_timer(delay).timeout
	await RenderingServer.frame_post_draw
	var img: Image = root.get_texture().get_image()
	img.save_png(out_dir.path_join(name + ".png"))


## Crops a region of an existing shot and enlarges it with nearest-neighbour
## scaling, so edge quality (jaggies vs. antialiasing) is clearly visible.
func _zoom(src: String, name: String, region: Rect2i, factor: int) -> void:
	var img := Image.load_from_file(out_dir.path_join(src + ".png"))
	var crop := img.get_region(region)
	crop.resize(region.size.x * factor, region.size.y * factor, Image.INTERPOLATE_NEAREST)
	crop.save_png(out_dir.path_join(name + ".png"))
