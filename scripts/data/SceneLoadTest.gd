extends SceneTree

## Instantiates every top-level scene and feeds exercise scenes a real
## question via setup(), to catch @onready node-path mismatches or
## runtime errors that only show up once a scene is actually in the tree.
## Run with: godot --headless --script res://scripts/data/SceneLoadTest.gd

const TierDefScript = preload("res://scripts/data/TierDefinition.gd")
const QuestionGenerator = preload("res://scripts/data/QuestionGenerator.gd")

var failures: int = 0


func _init() -> void:
	await process_frame
	await process_frame

	_try_instantiate("res://scenes/main/MainMenu.tscn")
	_try_instantiate("res://scenes/session/TierSelect.tscn")
	_try_instantiate("res://scenes/session/SessionSummary.tscn", func(n):
		n.set_stats({"correct": 5, "attempts": 8, "exercise_name_key": "EX_READ_MC", "tier_name_key": "TIER_1"}))

	var tier3 = load("res://resources/tiers/tier_3_quarter.tres")
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var q = QuestionGenerator.generate(tier3, rng)

	_try_instantiate("res://scenes/exercises/ReadClockMultipleChoice.tscn", func(n):
		n.setup(tier3, q))
	_try_instantiate("res://scenes/exercises/ReadClockFreeForm.tscn", func(n):
		n.setup(tier3, q))
	_try_instantiate("res://scenes/exercises/SetTheClock.tscn", func(n):
		n.setup(tier3, q))

	_check_free_form_24h_parsing()
	await _check_keypad_input()
	await _check_back_navigation()
	await _check_clock_number_setting()
	# Logical viewport sizes under the "expand" stretch aspect: 1280x800 is
	# the design size (16:10), 1422x800 a 16:9 monitor, 1280x960 a 4:3
	# tablet, and 1778x800 a 20:9 phone in landscape.
	for host_size in [Vector2(1280, 800), Vector2(1422, 800), Vector2(1280, 960), Vector2(1778, 800)]:
		for path in ["res://scenes/exercises/ReadClockMultipleChoice.tscn",
				"res://scenes/exercises/ReadClockFreeForm.tscn",
				"res://scenes/exercises/SetTheClock.tscn"]:
			await _check_layout(path, host_size, func(inst):
				inst.setup(tier3, q)
				await process_frame
				inst._report_answer(true)
				if inst.has_node("CheckButton"):
					inst.get_node("CheckButton").visible = false)
		await _check_layout("res://scenes/session/TierSelect.tscn", host_size, func(_inst): pass)
		var ex_mc = load("res://resources/exercises/ex_read_mc.tres")
		await _check_layout("res://scenes/session/TierSelect.tscn", host_size, func(inst):
			inst._on_exercise_picked(ex_mc))
		await _check_layout("res://scenes/session/SessionSummary.tscn", host_size, func(inst):
			inst.set_stats({"correct": 8, "attempts": 8, "exercise_name_key": "EX_READ_MC",
				"tier_name_key": "TIER_3", "tier_mastered": true, "overall_stars": 3}))
		await _check_layout("res://scenes/main/MainMenu.tscn", host_size, func(_inst): pass)

	if failures == 0:
		print("ALL PASS")
	else:
		print("%d FAILURE(S)" % failures)
	quit(failures)


## Shows a screen at `host_size` (after `prepare` puts it in the state to
## check), then verifies every visible control is fully on-screen, that no
## two controls overlap, and that nothing sits under the always-present
## overlays from Main.tscn (owl, top-bar buttons, parent-exit button).
## Containers (e.g. card rows) are checked per child card.
func _check_layout(path: String, host_size: Vector2, prepare: Callable) -> void:
	var host := Control.new()
	host.size = host_size
	root.add_child(host)
	var inst = load(path).instantiate()
	host.add_child(inst)
	inst.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await process_frame
	await prepare.call(inst)
	for i in 3:
		await process_frame

	var w: float = host_size.x
	var h: float = host_size.y
	var rects := {
		"[Owl]": Rect2(w - 196, h - 207, 170, 187),
		"[TopBar]": Rect2(w - 228, 12, 216, 50),
		"[ParentExit]": Rect2(12, 12, 48, 48),
	}
	var screen := Rect2(Vector2.ZERO, host_size)
	var tag: String = "%s @%dx%d" % [path.get_file(), host_size.x, host_size.y]
	for child in inst.get_children():
		if not (child is Control and child.is_visible_in_tree()):
			continue
		var parts: Array = child.get_children() if child is BoxContainer else [child]
		for part in parts:
			if not (part is Control and part.is_visible_in_tree()):
				continue
			var key: String = "%s/%s" % [child.name, part.name] if part != child else String(child.name)
			var r: Rect2 = part.get_global_rect()
			rects[key] = r
			if not screen.encloses(r):
				failures += 1
				print("FAIL %s: %s off-screen %s" % [tag, key, r])
	var names: Array = rects.keys()
	for i in names.size():
		for j in range(i + 1, names.size()):
			if names[i].begins_with("[") and names[j].begins_with("["):
				continue
			if rects[names[i]].grow(-1).intersects(rects[names[j]].grow(-1)):
				failures += 1
				print("FAIL %s: %s overlaps %s" % [tag, names[i], names[j]])

	if inst.has_node("FeedbackLabel"):
		var c: Color = inst.get_node("FeedbackLabel").get_theme_color("font_color")
		if c.get_luminance() > 0.3:
			failures += 1
			print("FAIL %s: label text too light (%s)" % [tag, c])
	print("ok   %s layout checked (%d rects)" % [tag, rects.size()])

	root.remove_child(host)
	host.queue_free()


func _check_clock_number_setting() -> void:
	var store = root.get_node("ProgressStore")

	var main_scene: PackedScene = load("res://scenes/main/Main.tscn")
	var main = main_scene.instantiate()
	root.add_child(main)
	await process_frame

	var clock_scene: PackedScene = load("res://scenes/clock/AnalogClock.tscn")
	var clock = clock_scene.instantiate()
	clock.size = Vector2(300, 300)
	root.add_child(clock)
	await process_frame

	# A self-crossing outline makes Godot silently skip drawing the hand.
	for shape_path in ["HourHand/HourHandShape", "MinuteHand/MinuteHandShape", "CenterPin"]:
		var poly: PackedVector2Array = clock.get_node(shape_path).polygon
		if Geometry2D.triangulate_polygon(poly).is_empty():
			failures += 1
			print("FAIL %s polygon cannot be triangulated (would be invisible)" % shape_path)
		else:
			print("ok   %s is drawable" % shape_path)

	for mode in [0, 2, 1]:
		store.set_setting("clock_numbers", mode)
		await process_frame
		if clock.number_mode != mode:
			failures += 1
			print("FAIL clock follows clock_numbers=%d (got %d)" % [mode, clock.number_mode])
		else:
			print("ok   clock follows clock_numbers=%d" % mode)

	# Numbers live outside the rim: the face must shrink whenever numbers
	# are shown, and hands must scale with the FACE (so they never reach
	# into the number rings).
	var face_by_mode := {}
	for mode in [0, 1, 2]:
		store.set_setting("clock_numbers", mode)
		await process_frame
		face_by_mode[mode] = clock._face_radius()
		var expected_scale: float = clock._face_radius() / 150.0
		var actual: float = clock.get_node("HourHand").scale.x
		if abs(actual - expected_scale) > 0.01:
			failures += 1
			print("FAIL mode %d: hand scale %s != face-based %s" % [mode, actual, expected_scale])
	if face_by_mode[0] > face_by_mode[1] and face_by_mode[1] > face_by_mode[2] and is_equal_approx(face_by_mode[0], 150.0):
		print("ok   face shrinks to make room for outside numbers")
	else:
		failures += 1
		print("FAIL face radii by mode: %s" % face_by_mode)

	clock.size = Vector2(400, 400)
	await process_frame
	var s: float = clock.get_node("HourHand").scale.x
	if abs(s - clock._face_radius() / 150.0) > 0.01:
		failures += 1
		print("FAIL hands scale with clock size, got %s" % s)
	else:
		print("ok   hands scale with clock size")

	root.remove_child(clock)
	clock.queue_free()
	root.remove_child(main)
	main.queue_free()


func _check_free_form_24h_parsing() -> void:
	var scene: PackedScene = load("res://scenes/exercises/ReadClockFreeForm.tscn")
	var inst = scene.instantiate()
	root.add_child(inst)
	await process_frame

	var cases := [
		["3:15", 3, 15, true],
		["15:15", 3, 15, true],
		["0:05", 0, 5, true],
		["12:00", 0, 0, true],
		["24:00", 0, 0, false],
		["nonsense", 0, 0, false],
		["315", 3, 15, true],
		["1530", 3, 30, true],
		["3", 3, 0, true],
		["12", 0, 0, true],
		["99", 0, 0, false],
		["12345", 0, 0, false],
	]
	for c in cases:
		var parsed = inst._parse_time(c[0])
		var expect_ok: bool = c[3]
		if expect_ok:
			if parsed == null or parsed.hour != c[1] or parsed.minute != c[2]:
				failures += 1
				print("FAIL parse '%s': expected %d:%02d" % [c[0], c[1], c[2]])
			else:
				print("ok   parse '%s' -> %d:%02d" % [c[0], c[1], c[2]])
		else:
			if parsed != null:
				failures += 1
				print("FAIL parse '%s': expected rejection, got %s" % [c[0], parsed.to_digital_string()])
			else:
				print("ok   parse '%s' rejected" % c[0])

	root.remove_child(inst)
	inst.queue_free()


func _try_instantiate(path: String, after: Callable = Callable()) -> void:
	var scene: PackedScene = load(path)
	if scene == null:
		failures += 1
		print("FAIL load %s" % path)
		return
	var inst = scene.instantiate()
	root.add_child(inst)
	await process_frame
	if after.is_valid():
		after.call(inst)
		await process_frame
	root.remove_child(inst)
	inst.queue_free()
	print("ok   instantiated %s" % path)

func _check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
	print(("ok   " if ok else "FAIL ") + label)


## Number keypad on Android has no ":" - digits are auto-formatted, and the
## screen lifts so an on-screen keyboard never covers the answer box.
func _check_keypad_input() -> void:
	var FreeForm = load("res://scenes/exercises/ReadClockFreeForm.gd")
	for c in [["3", "3"], ["31", "31"], ["315", "3:15"], ["1015", "10:15"], ["3:15", "3:15"], ["10155", "10:15"], ["a3b1c5", "3:15"]]:
		_check(FreeForm.format_digits(c[0]) == c[1], "format_digits('%s') -> '%s' (got '%s')" % [c[0], c[1], FreeForm.format_digits(c[0])])

	var host := Control.new()
	host.size = Vector2(1280, 800)
	root.add_child(host)
	var inst = load("res://scenes/exercises/ReadClockFreeForm.tscn").instantiate()
	host.add_child(inst)
	inst.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await process_frame
	var tier = load("res://resources/tiers/tier_3_quarter.tres")
	var rng := RandomNumberGenerator.new()
	inst.setup(tier, QuestionGenerator.generate(tier, rng))
	await process_frame
	var vp_h: float = inst.size.y
	_check(inst.keyboard_shift(0.0, vp_h) == 0.0, "no keyboard -> no shift")
	var kb: float = vp_h * 0.42  # a typical landscape tablet keyboard
	var shift: float = inst.keyboard_shift(kb, vp_h)
	var answer_bottom: float = inst.answer_edit.get_global_rect().end.y
	_check(shift > 0.0 and answer_bottom - shift <= vp_h - kb, "keyboard lift keeps answer box visible (shift %.0f)" % shift)
	root.remove_child(host)
	host.queue_free()


## Android back: dialogs close first, then exercise -> picker -> menu.
func _check_back_navigation() -> void:
	var main = load("res://scenes/main/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var ex = load("res://resources/exercises/ex_set_clock.tres")
	var tier = load("res://resources/tiers/tier_1_ohclock.tres")
	main._on_exercise_chosen(ex, tier)
	await process_frame
	main.get_node("LocaleSwitcher")._toggle_dialog()
	main.go_back()
	await process_frame
	_check(main._screen_kind == main.Screen.EXERCISE and not main.get_node("LocaleSwitcher").dialog_panel.visible,
		"back closes an open dialog first")
	main.go_back()
	await process_frame
	_check(main._screen_kind == main.Screen.PICKER, "back from exercise -> picker")
	main._current_screen._on_exercise_picked(ex)
	main.go_back()
	await process_frame
	_check(main._screen_kind == main.Screen.PICKER and main._current_screen._chosen_exercise_def == null,
		"back from difficulty -> activity picker")
	main.go_back()
	await process_frame
	_check(main._screen_kind == main.Screen.MENU, "back from activity picker -> menu")
	root.remove_child(main)
	main.queue_free()
