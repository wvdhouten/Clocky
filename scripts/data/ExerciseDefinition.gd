class_name ExerciseDefinition
extends Resource

## Data describing one exercise type. Stored as .tres resources under
## resources/exercises/. Exercises that share an `activity` are shown as
## one picker card ("Read the Clock"), with a toggle between their modes
## (choose / scroll, choose / drag) on the difficulty step.

## New values are appended so existing .tres files keep their meaning.
enum ExerciseType { READ_MC, READ_FREE, SET_CLOCK, SET_MC, LEARN }

@export var exercise_type: ExerciseType = ExerciseType.READ_MC
@export var display_name: String = "Exercise"
## Translation key (ui_strings.csv) for the player-facing name.
@export var name_key: String = ""
@export var scene: PackedScene
## Array[TierDefinition] in spirit, typed as Array[Resource] to avoid
## depending on global class_name resolution order at load time.
@export var supports_tiers: Array[Resource] = []
@export var uses_speech: bool = false
## Picker card this exercise belongs to: "LEARN", "READ" or "SET".
@export var activity: String = ""
## Translation key and emoji for this exercise's mode on the toggle.
@export var mode_name_key: String = ""
@export var mode_icon: String = ""


static func type_key(t: ExerciseType) -> String:
	match t:
		ExerciseType.READ_MC:
			return "READ_MC"
		ExerciseType.READ_FREE:
			return "READ_FREE"
		ExerciseType.SET_CLOCK:
			return "SET_CLOCK"
		ExerciseType.SET_MC:
			return "SET_MC"
		ExerciseType.LEARN:
			return "LEARN"
	return "UNKNOWN"
