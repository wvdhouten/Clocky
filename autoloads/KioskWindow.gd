extends Node

## Keeps the fullscreen kiosk window fitted to whichever monitor it is on.
##
## Windows keeps a fullscreen window's old size when it is moved to another
## monitor (e.g. with Win+Shift+Arrow), so on a monitor with a different
## resolution/aspect the game ends up distorted or hanging off the edge.
## We watch for a monitor change, re-apply fullscreen on the new monitor,
## and remember it so the next launch opens there. Godot's own
## `--screen N` command-line option still takes priority when given.

const SCREEN_SETTING := "kiosk_screen"
const POLL_SECONDS := 0.4

var _last_screen: int = -1


func _ready() -> void:
	# Headless runs have no real window, and tool/test scripts manage their
	# own window - leave both alone.
	if DisplayServer.get_name() == "headless" or "--script" in OS.get_cmdline_args() or "-s" in OS.get_cmdline_args():
		return
	# Phones/tablets have one screen and the OS manages fullscreen.
	if OS.has_feature("mobile"):
		return

	var saved: int = int(ProgressStore.get_setting(SCREEN_SETTING, -1))
	var forced_by_cli: bool = "--screen" in OS.get_cmdline_args()
	if not forced_by_cli and saved >= 0 and saved < DisplayServer.get_screen_count():
		move_to_screen(saved)
	_last_screen = get_window().current_screen

	var timer := Timer.new()
	timer.wait_time = POLL_SECONDS
	timer.autostart = true
	timer.timeout.connect(_check_screen)
	add_child(timer)


func _check_screen() -> void:
	var current: int = get_window().current_screen
	if current != _last_screen:
		move_to_screen(current)


## Puts the window fullscreen on `screen`, sized to that monitor, and
## remembers the choice.
func move_to_screen(screen: int) -> void:
	var win: Window = get_window()
	win.mode = Window.MODE_WINDOWED
	win.current_screen = screen
	win.mode = Window.MODE_FULLSCREEN
	_last_screen = screen
	if int(ProgressStore.get_setting(SCREEN_SETTING, -1)) != screen:
		ProgressStore.set_setting(SCREEN_SETTING, screen)
