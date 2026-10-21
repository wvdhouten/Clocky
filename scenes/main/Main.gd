extends Control

const MainMenuScene = preload("res://scenes/main/MainMenu.tscn")
const TierSelectScene = preload("res://scenes/session/TierSelect.tscn")
const SessionSummaryScene = preload("res://scenes/session/SessionSummary.tscn")

@onready var screen_host: Control = $ScreenHost
@onready var owl: Control = $Owl
@onready var celebration: Control = $Celebration

var _current_screen: Node = null


func _ready() -> void:
	show_main_menu()


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


func show_tier_select() -> void:
	_clear_screen()
	var select = TierSelectScene.instantiate()
	select.exercise_chosen.connect(_on_exercise_chosen)
	select.back_requested.connect(show_main_menu)
	screen_host.add_child(select)
	_current_screen = select


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
	summary.set_stats(stats)
	owl.celebrate()
	celebration.shower()
	SoundFx.play("fanfare")
