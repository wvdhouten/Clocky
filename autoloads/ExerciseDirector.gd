extends Node

## Orchestrates exercise/tier selection, question generation, and
## scoring. Main.gd drives screen transitions; this autoload only holds
## session state and produces questions.

const QuestionGenerator = preload("res://scripts/data/QuestionGenerator.gd")
const ExerciseDefinitionScript = preload("res://scripts/data/ExerciseDefinition.gd")

const SESSION_LENGTH := 8

var current_exercise_def
var current_tier
var current_question
var _rng := RandomNumberGenerator.new()
var _questions_done: int = 0


func _ready() -> void:
	_rng.randomize()


func start_session(exercise_def, tier) -> void:
	current_exercise_def = exercise_def
	current_tier = tier
	_questions_done = 0
	GameState.reset_session()
	_generate_question()


func _generate_question() -> void:
	current_question = QuestionGenerator.generate(current_tier, _rng)


func record_answer(correct: bool) -> void:
	GameState.session_attempts += 1
	if correct:
		GameState.session_correct += 1
	var type_key: String = ExerciseDefinitionScript.type_key(current_exercise_def.exercise_type)
	ProgressStore.record_attempt(type_key, current_tier.tier_number, correct, current_tier.mastery_threshold)


## Advances to the next question. Returns false when the session is over
## (caller should show the session summary instead of another question).
func advance() -> bool:
	_questions_done += 1
	if _questions_done >= SESSION_LENGTH:
		ProgressStore.record_session(
			current_exercise_def.display_name,
			current_tier.display_name,
			GameState.session_correct,
			GameState.session_attempts
		)
		return false
	_generate_question()
	return true


func get_session_stats() -> Dictionary:
	var type_key: String = ExerciseDefinitionScript.type_key(current_exercise_def.exercise_type) if current_exercise_def else ""
	return {
		"correct": GameState.session_correct,
		"attempts": GameState.session_attempts,
		"exercise_name_key": current_exercise_def.name_key if current_exercise_def else "",
		"tier_name_key": current_tier.name_key if current_tier else "",
		"tier_mastered": ProgressStore.is_tier_mastered(type_key, current_tier.tier_number) if current_tier else false,
		"overall_stars": ProgressStore.get_overall_stars(),
	}
