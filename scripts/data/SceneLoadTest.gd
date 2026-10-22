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
	_try_instantiate("res://scenes/exercises/ReadClockWheel.tscn", func(n):
		n.setup(tier3, q))
	_try_instantiate("res://scenes/exercises/SetTheClock.tscn", func(n):
		n.setup(tier3, q))
	_try_instantiate("res://scenes/exercises/SetClockMultipleChoice.tscn", func(n):
		n.setup(tier3, q))
	_try_instantiate("res://scenes/exercises/LearnLesson.tscn", func(n):
		n.setup(tier3))

	await _check_wheels()
	await _check_set_multiple_choice()
	await _check_back_navigation()
	await _check_safe_area()
	_check_speech_text()
	# From here on, show the 🗣️ buttons so layout checks include them.
	root.get_node("Speech").force_available = true
	await _check_card_speakers()
	await _check_top_bar()
	await _check_hints()
	await _check_lesson()
	await _check_clock_number_setting()
	# Logical viewport sizes under the "expand" stretch aspect: 1280x800 is
	# the design size (16:10), 1422x800 a 16:9 monitor, 1280x960 a 4:3
	# tablet, and 1778x800 a 20:9 phone in landscape.
	for host_size in [Vector2(1280, 800), Vector2(1422, 800), Vector2(1280, 960), Vector2(1778, 800)]:
		for path in ["res://scenes/exercises/ReadClockMultipleChoice.tscn",
				"res://scenes/exercises/ReadClockWheel.tscn",
				"res://scenes/exercises/SetTheClock.tscn",
				"res://scenes/exercises/SetClockMultipleChoice.tscn"]:
			await _check_layout(path, host_size, func(inst):
				inst.setup(tier3, q)
				await process_frame
				inst._report_answer(true)
				if inst.has_node("CheckButton"):
					inst.get_node("CheckButton").visible = false)
		await _check_layout("res://scenes/exercises/LearnLesson.tscn", host_size, func(inst):
			inst.setup(tier3))
		await _check_layout("res://scenes/session/TierSelect.tscn", host_size, func(_inst): pass)
		for activity in ["LEARN", "READ"]:
			await _check_layout("res://scenes/session/TierSelect.tscn", host_size, func(inst):
				inst._on_activity_picked(activity))
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
		"[TopBar]": Rect2(w - 196, 12, 184, 56),
		"[ParentExit]": Rect2(12, 12, 48, 48),
	}
	if inst.has_method("next_hint"):
		rects["[Hint]"] = Rect2(w - 262, h - 86, 56, 56)
	var nodes := {}
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
			nodes[key] = part
			if not screen.encloses(r):
				failures += 1
				print("FAIL %s: %s off-screen %s" % [tag, key, r])
	# 🗣️ badges overhang their element's corner: they may overlap only that
	# element (and what contains it), never anything else or the screen edge.
	var speakers: Array = inst.find_children("Speaker", "Button", true, false).filter(
		func(sp): return sp.is_visible_in_tree())
	for sp in speakers:
		var r: Rect2 = sp.get_global_rect()
		if not screen.encloses(r):
			failures += 1
			print("FAIL %s: 🗣️ of %s off-screen %s" % [tag, sp.get_parent().name, r])
		for key in rects:
			var owner_node = nodes.get(key)
			if owner_node != null and (owner_node == sp.get_parent() or owner_node.is_ancestor_of(sp)):
				continue
			if rects[key].grow(-1).intersects(r.grow(-1)):
				failures += 1
				print("FAIL %s: 🗣️ of %s overlaps %s" % [tag, sp.get_parent().name, key])
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
	print("ok   %s layout checked (%d rects, %d badges)" % [tag, rects.size(), speakers.size()])

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


## Android back: dialogs close first, then exercise -> picker -> menu.
func _check_back_navigation() -> void:
	var main = load("res://scenes/main/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var ex = load("res://resources/exercises/ex_set_clock.tres")
	var tier = load("res://resources/tiers/tier_1_ohclock.tres")
	main._on_exercise_chosen(ex, tier)
	await process_frame
	main.get_node("SafeArea/LocaleSwitcher")._toggle_dialog()
	main.go_back()
	await process_frame
	_check(main._screen_kind == main.Screen.EXERCISE and not main.get_node("SafeArea/LocaleSwitcher").dialog_panel.visible,
		"back closes an open dialog first")
	main.go_back()
	await process_frame
	_check(main._screen_kind == main.Screen.PICKER, "back from exercise -> picker")
	main._current_screen._on_activity_picked("SET")
	main.go_back()
	await process_frame
	_check(main._screen_kind == main.Screen.PICKER and main._current_screen._chosen_activity == "",
		"back from difficulty -> activity picker")
	main.go_back()
	await process_frame
	_check(main._screen_kind == main.Screen.MENU, "back from activity picker -> menu")
	root.remove_child(main)
	main.queue_free()


## Phones with rounded corners: with safe margins applied, every button and
## overlay (top bar, owl, an exercise's Exit button) must sit inside the
## inset, while the sky background still fills the whole screen.
func _check_safe_area() -> void:
	var host := Control.new()
	host.size = Vector2(1778, 800)  # 20:9 phone, e.g. the Xiaomi 17 Ultra
	root.add_child(host)
	var main = load("res://scenes/main/Main.tscn").instantiate()
	host.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await process_frame
	main._on_exercise_chosen(load("res://resources/exercises/ex_read_mc.tres"), load("res://resources/tiers/tier_1_ohclock.tres"))
	main.set_safe_margins(56.0, 10.0)
	for i in 3:
		await process_frame

	var inset := Rect2(56, 10, 1778 - 112, 800 - 20)
	var checked := {
		"Owl": main.get_node("SafeArea/Owl"),
		"MuteButton": main.get_node("SafeArea/MuteButton"),
		"NumberModeButton": main.get_node("SafeArea/NumberModeSwitcher/ModeButton"),
		"FlagButton": main.get_node("SafeArea/LocaleSwitcher/FlagButton"),
		"HintButton": main.get_node("SafeArea/HintButton"),
		"Exercise ExitButton": main._current_screen.get_node("ExitButton"),
		"Exercise PromptLabel": main._current_screen.get_node("PromptLabel"),
	}
	for label in checked:
		var r: Rect2 = checked[label].get_global_rect()
		_check(inset.encloses(r), "safe area keeps %s inside the inset (%s)" % [label, r])
	var sky: Rect2 = main.get_node("SkyBackground").get_global_rect()
	_check(sky.size == Vector2(1778, 800), "sky background still fills the whole screen (%s)" % sky)
	_check(main.get_node("SkyBackground").safe_inset == Vector2(56, 10), "sun moves in by the same safe-area margin")
	root.remove_child(host)
	host.queue_free()


func _check_speech_text() -> void:
	var Speech = root.get_node("Speech")
	for c in [["Correct! ⭐", "Correct!"], ["Tier mastered! 🏆", "Tier mastered!"],
			["Quarter Past/To", "Quarter Past, To"], ["Ieșire", "Ieșire"], ["half vier", "half vier"]]:
		_check(Speech.clean(c[0]) == c[1], "speech text '%s' -> '%s' (got '%s')" % [c[0], c[1], Speech.clean(c[0])])


## The 🗣️ badge on each picker card sits on its top-right corner and stays
## off the mini clock's circle.
func _check_card_speakers() -> void:
	var host := Control.new()
	host.size = Vector2(1280, 800)
	root.add_child(host)
	var inst = load("res://scenes/session/TierSelect.tscn").instantiate()
	host.add_child(inst)
	inst.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for step in ["activity", "difficulty"]:
		if step == "difficulty":
			inst._on_activity_picked("READ")
		for i in 4:
			await process_frame
		var row: Control = inst.tier_row if step == "difficulty" else inst.exercise_row
		var worst := INF
		var ok := true
		for card in row.get_children():
			var speaker: Control = card.get_node("Speaker")
			var clock: Control = card.find_children("*", "Control", true, false).filter(func(n): return n.has_method("set_time"))[0]
			var s_rect: Rect2 = speaker.get_global_rect()
			var c_rect: Rect2 = clock.get_global_rect()
			var radius: float = min(c_rect.size.x, c_rect.size.y) / 2.0
			var nearest := Vector2(clamp(c_rect.get_center().x, s_rect.position.x, s_rect.end.x),
				clamp(c_rect.get_center().y, s_rect.position.y, s_rect.end.y))
			var gap: float = nearest.distance_to(c_rect.get_center()) - radius
			worst = min(worst, gap)
			var corner: Vector2 = Vector2(card.get_global_rect().end.x, card.get_global_rect().position.y)
			ok = ok and speaker.visible and s_rect.has_point(corner) and gap >= 3.0
		_check(ok, "%s cards: 🗣️ visible, on the card's top-right corner, clear of the clock (closest gap %.0f px)" % [step, worst])
	root.remove_child(host)
	host.queue_free()


## Scroll wheels: the minute wheel offers exactly the tier's minutes, short
## lists stop at their ends, long ones wrap, and dialling the right time
## counts as correct.
func _check_wheels() -> void:
	var Wheel = load("res://scenes/exercises/ReadClockWheel.gd")
	var tier_files := ["tier_1_ohclock", "tier_2_half", "tier_3_quarter", "tier_4_five_min", "tier_5_exact_min"]
	var expected := [1, 2, 4, 12, 60]
	for i in 5:
		var t = load("res://resources/tiers/%s.tres" % tier_files[i])
		var mins: Array = Wheel.minutes_for(t)
		_check(mins.size() == expected[i] and mins.all(func(m): return t.allowed_minutes.is_empty() or t.allowed_minutes.has(m)),
			"tier %d minute wheel offers %d values" % [i + 1, expected[i]])

	var host := Control.new()
	host.size = Vector2(1280, 800)
	root.add_child(host)
	var inst = load("res://scenes/exercises/ReadClockWheel.tscn").instantiate()
	host.add_child(inst)
	inst.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await process_frame
	var tier2 = load("res://resources/tiers/tier_2_half.tres")
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var q = QuestionGenerator.generate(tier2, rng)
	inst.setup(tier2, q)
	await process_frame
	_check(not inst.dialled_time().equals(q.target), "wheels don't start on the answer")

	var hw = inst.hour_wheel
	hw.select(10)
	hw.scroll_rows(3.0)
	_check(hw.selected_index == 1, "hour wheel wraps round 11 -> 12 -> 1 -> 2 (got index %d)" % hw.selected_index)
	hw.scroll_rows(0.4)
	await create_timer(0.4).timeout
	_check(hw.selected_index == 1 and is_equal_approx(hw._offset, roundf(hw._offset)), "wheel snaps back to a whole row")
	var mw = inst.minute_wheel
	mw.select(0)
	mw.scroll_rows(-3.0)
	_check(mw.selected_index == 0, "2-value minute wheel stops at its end instead of wrapping")

	hw.select(posmod(q.target.hour - 1, 12))
	mw.select(inst._minutes.find(q.target.minute))
	var got := [null]
	inst.answered.connect(func(c): got[0] = c)
	inst._on_check_pressed()
	_check(got[0] == true, "dialling %s on the wheels is correct" % q.target.to_digital_string())
	root.remove_child(host)
	host.queue_free()


## Set the clock (choose): four clocks, one right; a wrong pick reveals it.
func _check_set_multiple_choice() -> void:
	var inst = load("res://scenes/exercises/SetClockMultipleChoice.tscn").instantiate()
	root.add_child(inst)
	await process_frame
	var tier3 = load("res://resources/tiers/tier_3_quarter.tres")
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var q = QuestionGenerator.generate(tier3, rng)
	inst.setup(tier3, q)
	await process_frame
	var right: Array = inst._option_buttons.filter(func(p): return p[0].equals(q.target))
	_check(inst._option_buttons.size() == 4 and right.size() == 1, "set-the-clock choice shows 4 clocks, one right")
	var wrong: Array = inst._option_buttons.filter(func(p): return not p[0].equals(q.target))
	var got := [null]
	inst.answered.connect(func(c): got[0] = c)
	wrong[0][1].pressed.emit()
	var right_box = right[0][1].get_theme_stylebox("disabled")
	_check(got[0] == false and right_box.bg_color == root.get_node("UiTheme").LEAF, "wrong clock picked -> right one turns green")
	root.remove_child(inst)
	inst.queue_free()


## Top bar: every button the same square size; both dialogs fit their
## options with the same padding and the same option size.
func _check_top_bar() -> void:
	var host := Control.new()
	host.size = Vector2(1280, 800)
	root.add_child(host)
	var main = load("res://scenes/main/Main.tscn").instantiate()
	host.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for i in 3:
		await process_frame
	var sizes: Array = []
	for path in ["SafeArea/MuteButton", "SafeArea/NumberModeSwitcher/ModeButton", "SafeArea/LocaleSwitcher/FlagButton"]:
		sizes.append(main.get_node(path).get_global_rect().size)
	_check(sizes.all(func(sz): return sz == Vector2(56, 56)), "top-bar buttons are all 56x56 (%s)" % [sizes])

	var margins: Array = []
	for path in ["SafeArea/NumberModeSwitcher", "SafeArea/LocaleSwitcher"]:
		var sw = main.get_node(path)
		sw._toggle_dialog()
		for i in 2:
			await process_frame
		var panel: Rect2 = sw.dialog_panel.get_global_rect()
		var list: Rect2 = sw.option_list.get_global_rect()
		var m := [list.position.x - panel.position.x, panel.end.x - list.end.x, list.position.y - panel.position.y, panel.end.y - list.end.y]
		margins.append(m)
		var opt_size: Vector2 = sw.option_list.get_child(0).size
		_check(m.all(func(v): return is_equal_approx(v, m[0])) and opt_size == sw.OPTION_SIZE and Rect2(Vector2.ZERO, host.size).encloses(panel),
			"%s dialog: even padding %s, options %s, on screen" % [path.get_file(), m, opt_size])
		sw.close_dialog()
	_check(margins[0] == margins[1], "both dialogs use the same padding")
	root.remove_child(host)
	host.queue_free()


## ❓ beside the owl: shown during a question, gives hints in the owl's
## bubble while highlighting a hand, and goes away once answered.
func _check_hints() -> void:
	var main = load("res://scenes/main/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main._on_exercise_chosen(load("res://resources/exercises/ex_read_mc.tres"), load("res://resources/tiers/tier_3_quarter.tres"))
	await process_frame
	var hint_button: Button = main.get_node("SafeArea/HintButton")
	var bubble = main.get_node("SafeArea/OwlBubble")
	_check(hint_button.visible and not bubble.visible, "hint button shows during a question, bubble starts hidden")
	main.show_hint()
	var clock = main._current_screen.get_node("AnalogClock")
	_check(bubble.visible and not bubble.label.text.is_empty() and clock._highlight == clock.HandId.HOUR,
		"first hint: bubble talks about the short hand, which glows")
	main.show_hint()
	_check(clock._highlight == clock.HandId.MINUTE, "second hint moves on to the long hand")
	main._current_screen._option_buttons[0][1].pressed.emit()
	_check(not hint_button.visible and not bubble.visible and clock._highlight == clock.HandId.NONE,
		"answering hides the hint button, the bubble and the glow")
	main._on_next_requested()
	_check(hint_button.visible, "hint button comes back for the next question")
	root.remove_child(main)
	main.queue_free()


## Learn: steps show in the owl's bubble, and finishing marks it seen.
func _check_lesson() -> void:
	var store = root.get_node("ProgressStore")
	store.set_setting("learn_seen_2", false)
	var main = load("res://scenes/main/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main._on_exercise_chosen(load("res://resources/exercises/ex_learn.tres"), load("res://resources/tiers/tier_2_half.tres"))
	await process_frame
	var lesson = main._current_screen
	var bubble = main.get_node("SafeArea/OwlBubble")
	_check(main._screen_kind == main.Screen.LEARN and bubble.visible and not bubble.label.text.is_empty()
		and not main.get_node("SafeArea/HintButton").visible, "lesson opens with the owl talking (no hint button)")
	var texts := {}
	var step_count: int = lesson._steps.size()
	for i in step_count:
		texts[bubble.label.text] = true
		_check(not bubble.label.text.begins_with("LEARN_") and not bubble.label.text.contains("{"),
			"lesson step %d text is translated and filled in" % (i + 1))
		lesson._on_next_pressed()
		await process_frame
	_check(texts.size() == step_count, "every lesson step says something different")
	_check(bool(store.get_setting("learn_seen_2", false)), "finishing a lesson marks it seen")
	_check(main._screen_kind == main.Screen.PICKER and not bubble.visible, "Done returns to the picker and closes the bubble")

	main._on_exercise_chosen(load("res://resources/exercises/ex_learn.tres"), load("res://resources/tiers/tier_1_ohclock.tres"))
	await process_frame
	lesson = main._current_screen
	lesson.show_step(lesson._steps.size() - 1)
	lesson.clock.set_time(load("res://scripts/clock_logic/TimeValue.gd").new(4, 0))
	lesson._on_clock_changed(lesson.clock.get_current_time())
	_check(lesson._solved and bubble.label.text.begins_with(TranslationServer.translate("LEARN_TRY_DONE").substr(0, 4)),
		"try step: setting the right time is praised")
	main.go_back()
	await process_frame
	_check(main._screen_kind == main.Screen.PICKER, "back from a lesson -> picker")
	root.remove_child(main)
	main.queue_free()
