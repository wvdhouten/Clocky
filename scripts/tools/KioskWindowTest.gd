extends SceneTree

## Multi-monitor check for KioskWindow (needs a real display and >= 2
## monitors; skips otherwise). Briefly goes fullscreen on each monitor.
##   godot --path . --script res://scripts/tools/KioskWindowTest.gd

var failures := 0


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	if DisplayServer.get_screen_count() < 2:
		print("SKIP: needs 2 monitors")
		quit(0)
		return
	var kiosk = root.get_node("KioskWindow")
	var main = load("res://scenes/main/Main.tscn").instantiate()
	root.add_child(main)

	for screen in [1, 0]:
		kiosk.move_to_screen(screen)
		await _settle()
		_check_fits(screen, "move_to_screen(%d)" % screen)

	# Reproduce the bug: a fullscreen window shoved onto the other monitor
	# by the OS keeps its old size. The watcher must refit it.
	kiosk.move_to_screen(0)
	await _settle()
	root.mode = Window.MODE_WINDOWED
	root.position = DisplayServer.screen_get_position(1) + Vector2i(40, 40)
	await _settle()
	kiosk._check_screen()
	await _settle()
	_check_fits(1, "refit after OS move to screen 1")

	var saved = root.get_node("ProgressStore").get_setting("kiosk_screen", -1)
	_report(int(saved) == 1, "remembers last screen (saved=%s)" % saved)

	kiosk.move_to_screen(0)
	await _settle()
	print("ALL PASS" if failures == 0 else "%d FAILURE(S)" % failures)
	quit(failures)


func _check_fits(screen: int, label: String) -> void:
	var want_pos := DisplayServer.screen_get_position(screen)
	var want_size := DisplayServer.screen_get_size(screen)
	var ok: bool = root.mode == Window.MODE_FULLSCREEN and root.current_screen == screen \
		and root.size == want_size and root.position == want_pos
	_report(ok, "%s: mode=%d screen=%d pos=%s size=%s (want %s %s)" % [
		label, root.mode, root.current_screen, root.position, root.size, want_pos, want_size])


func _report(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
	print(("ok   " if ok else "FAIL ") + label)


func _settle() -> void:
	for i in 10:
		await process_frame
	await create_timer(0.4).timeout
