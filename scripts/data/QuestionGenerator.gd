extends RefCounted

const TimeValue = preload("res://scripts/clock_logic/TimeValue.gd")

## Plain data holder returned by generate(). Not a Resource - these are
## ephemeral, created fresh per question.
class QuestionData:
	var target
	var distractors: Array = []

	func _init(p_target, p_distractors: Array) -> void:
		target = p_target
		distractors = p_distractors


## Produces a target time plus up to 3 pedagogically meaningful distractor
## times (hour swaps, adjacent-minute confusions) for multiple choice,
## using only minute values allowed by `tier`.
static func generate(tier, rng: RandomNumberGenerator):
	# Empty allowed_minutes means free/exact-minute dragging (Tier 5) -
	# any minute 0-59 is valid, not just a fixed snap set.
	var allowed: Array = tier.allowed_minutes
	var is_free_minute: bool = allowed.is_empty()

	var target_hour: int = rng.randi_range(0, 11)
	var target_minute: int = rng.randi_range(0, 59) if is_free_minute else allowed[rng.randi_range(0, allowed.size() - 1)]
	var target := TimeValue.new(target_hour, target_minute)

	var pool: Array = []
	_add_unique(pool, target, TimeValue.new(target_hour + 1, target_minute))
	_add_unique(pool, target, TimeValue.new(target_hour - 1, target_minute))
	_add_unique(pool, target, TimeValue.new(target_hour + 2, target_minute))

	if is_free_minute:
		_add_unique(pool, target, TimeValue.new(target_hour, target_minute + 5))
		_add_unique(pool, target, TimeValue.new(target_hour, target_minute - 5))
		_add_unique(pool, target, TimeValue.new(target_hour, target_minute + 1))
	elif allowed.size() > 1:
		for m in allowed:
			if m != target_minute:
				_add_unique(pool, target, TimeValue.new(target_hour, m))

	pool.shuffle()
	var distractors: Array = []
	for d in pool:
		if distractors.size() >= 3:
			break
		distractors.append(d)

	return QuestionData.new(target, distractors)


static func _add_unique(pool: Array, target, candidate) -> void:
	if candidate.equals(target):
		return
	for existing in pool:
		if existing.equals(candidate):
			return
	pool.append(candidate)
