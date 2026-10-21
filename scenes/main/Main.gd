extends Control

const MainMenuScene = preload("res://scenes/main/MainMenu.tscn")
const TierSelectScene = preload("res://scenes/session/TierSelect.tscn")
const SessionSummaryScene = preload("res://scenes/session/SessionSummary.tscn")

@onready var safe_area: Control = $SafeArea
@onready var screen_host: Control = $SafeArea/ScreenHost
@onready var owl: Control = $SafeArea/Owl
@onready var celebration: Control = $SafeArea/Celebration

enum Screen { MENU, PICKER, EXERCISE, SUMMARY }

## Minimum inset on phones/tablets (viewport units). Rounded screen corners
## aren't always reported in the OS safe area, so we always keep at least
## this much room; the sides get more because that's where corners bite in
## landscape.
const MOBILE_MIN_SIDE := 56.0
const MOBILE_MIN_TOP_BOTTOM := 10.0

var _current_screen: Node = null
var _screen_kind: Screen = Screen.MENU


func _ready() -> void:
	show_main_menu()
	# The hold-to-exit button is for the desktop kiosk; on phones/tablets
	# Android's own app switching (and back at the main menu) covers it.
	if OS.has_feature("mobile"):
		$SafeArea/ParentExitButton.visible = false
		_apply_device_safe_area()
		get_viewport().size_changed.connect(_apply_device_safe_area)


## Keeps all UI (but not the sky background) clear of rounded corners and
## camera cutouts. Uses the larger of left/right (and top/bottom) for both
## sides, so the layout stays correct when the phone is flipped 180 deg.
func _apply_device_safe_area() -> void:
	var window := Vector2(DisplayServer.window_get_size())
	if window.x <= 0.0 or window.y <= 0.0:
		return
	var to_viewport: Vector2 = get_viewport_rect().size / window
	var screen := Vector2(DisplayServer.screen_get_size())
	var safe := Rect2(DisplayServer.get_display_safe_area())
	var side: float = max(safe.position.x, screen.x - safe.end.x) * to_viewport.x
	var top_bottom: float = max(safe.position.y, screen.y - safe.end.y) * to_viewport.y
	set_safe_margins(max(side, MOBILE_MIN_SIDE), max(top_bottom, MOBILE_MIN_TOP_BOTTOM))


func set_safe_margins(side: float, top_bottom: float) -> void:
	safe_area.offset_left = side
	safe_area.offset_right = -side
	safe_area.offset_top = top_bottom
	safe_area.offset_bottom = -top_bottom
	$SkyBackground.safe_inset = Vector2(side, top_bottom)


## Android back gesture/button (quit_on_go_back is off): step back through
## the app instead of instantly quitting, and only leave from the menu.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		go_back()


func go_back() -> void:
	for switcher in get_tree().get_nodes_in_group("top_bar_dialogs"):
		if switcher.dialog_panel.visible:
			get_tree().call_group("top_bar_dialogs", "close_dialog")
			return
	match _screen_kind:
		Screen.MENU:
			get_tree().quit()
		Screen.PICKER:
			_current_screen._on_back_pressed()
		Screen.EXERCISE, Screen.SUMMARY:
			show_tier_select()


func _clear_screen() -> void:
	if _current_screen:
		_current_screen.queue_free()
		_current_screen = null


func show_main_menu() -> void:
	_clear_screen()
	var menu = MainMenuScene.instantiate()
	menu.start_pressed.connect(show_tier_select)
	screen_host.add_child(menu)
	_current_screen = menu
	_screen_kind = Screen.MENU


func show_tier_select() -> void:
	_clear_screen()
	var select = TierSelectScene.instantiate()
	select.exercise_chosen.connect(_on_exercise_chosen)
	select.back_requested.connect(show_main_menu)
	screen_host.add_child(select)
	_current_screen = select
	_screen_kind = Screen.PICKER


func _on_exercise_chosen(exercise_def, tier) -> void:
	ExerciseDirector.start_session(exercise_def, tier)
	_show_exercise_screen(exercise_def)


func _show_exercise_screen(exercise_def) -> void:
	_clear_screen()
	var exercise_screen = exercise_def.scene.instantiate()
	exercise_screen.answered.connect(_on_answered)
	exercise_screen.next_requested.connect(_on_next_requested)
	exercise_screen.exit_requested.connect(show_tier_select)
	screen_host.add_child(exercise_screen)
	_current_screen = exercise_screen
	_screen_kind = Screen.EXERCISE
	exercise_screen.setup(ExerciseDirector.current_tier, ExerciseDirector.current_question)


func _on_answered(correct: bool) -> void:
	ExerciseDirector.record_answer(correct)
	if correct:
		owl.cheer()
		celebration.burst(_current_screen.celebration_point())
		SoundFx.play("chime")
	else:
		owl.encourage()
		SoundFx.play("boop")


func _on_next_requested() -> void:
	var has_more: bool = ExerciseDirector.advance()
	if has_more:
		_current_screen.setup(ExerciseDirector.current_tier, ExerciseDirector.current_question)
	else:
		_show_session_summary()


func _show_session_summary() -> void:
	var stats: Dictionary = ExerciseDirector.get_session_stats()
	_clear_screen()
	var summary = SessionSummaryScene.instantiate()
	summary.continue_pressed.connect(show_tier_select)
	screen_host.add_child(summary)
	_current_screen = summary
	_screen_kind = Screen.SUMMARY
	summary.set_stats(stats)
	owl.celebrate()
	celebration.shower()
	SoundFx.play("fanfare")
