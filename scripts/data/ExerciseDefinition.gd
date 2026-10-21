class_name ExerciseDefinition
extends Resource

## Data describing one exercise type. Stored as .tres resources under
## resources/exercises/.

enum ExerciseType { READ_MC, READ_FREE, SET_CLOCK }

@export var exercise_type: ExerciseType = ExerciseType.READ_MC
@export var display_name: String = "Exercise"
## Translation key (ui_strings.csv) for the player-facing name.
@export var name_key: String = ""
@export var scene: PackedScene
## Array[TierDefinition] in spirit, typed as Array[Resource] to avoid
## depending on global class_name resolution order at load time.
@export var supports_tiers: Array[Resource] = []
@export var uses_speech: bool = false


static func type_key(t: ExerciseType) -> String:
	match t:
		ExerciseType.READ_MC:
			return "READ_MC"
		ExerciseType.READ_FREE:
			return "READ_FREE"
		ExerciseType.SET_CLOCK:
			return "SET_CLOCK"
	return "UNKNOWN"
