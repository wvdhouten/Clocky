class_name TierDefinition
extends Resource

## Data describing one difficulty tier. Stored as .tres resources under
## resources/tiers/ - adding a new tier is adding a new resource file,
## never a code change.

@export var tier_number: int = 1
@export var display_name: String = "Tier"
## Translation key (ui_strings.csv) for the player-facing name.
@export var name_key: String = ""
## Minute values the clock/question generator may use for this tier.
@export var allowed_minutes: Array[int] = [0]
## Consecutive correct answers needed to consider this tier mastered.
@export var mastery_threshold: int = 5
@export var icon: Texture2D
