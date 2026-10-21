extends Node

## Tracks the currently active session: which exercise/tier is selected
## and basic session counters. Populated by TierSelect, consumed by
## ExerciseDirector and SessionSummary.

var current_exercise_type: int = -1
var current_tier_number: int = -1
var session_correct: int = 0
var session_attempts: int = 0


func reset_session() -> void:
	session_correct = 0
	session_attempts = 0
