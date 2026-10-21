class_name ClockMath
extends RefCounted

## Pure, stateless angle<->time math for the analog clock widget.
##
## Convention: "clock angle" is always degrees in [0, 360), where 0 = 12
## o'clock and it increases CLOCKWISE. Node2D hands are assumed to be
## drawn pointing straight up (toward 12) with their pivot at the hand
## base, so `rotation = deg_to_rad(clock_angle)` can be applied directly
## (Godot's 2D rotation is clockwise-positive since the Y axis points down).


static func minute_angle_deg(minute: float) -> float:
	return fposmod(minute * 6.0, 360.0)


static func hour_angle_deg(hour: int, minute: float) -> float:
	return fposmod(float(hour % 12) * 30.0 + minute * 0.5, 360.0)


## Converts a direction vector (pointer position minus clock center, in the
## same y-down screen space the clock is drawn in) into a clock angle.
static func vector_to_clock_angle_deg(vec: Vector2) -> float:
	if vec.length_squared() < 0.0001:
		return 0.0
	var rad: float = atan2(vec.x, -vec.y)
	return fposmod(rad_to_deg(rad), 360.0)


## Nearest raw minute (0.0-59.999) for a given clock angle, with no snapping.
static func angle_to_raw_minute(angle_deg: float) -> float:
	return fposmod(angle_deg / 6.0, 60.0)


## Snaps a raw (possibly fractional) minute value to the nearest value in
## `allowed_minutes` (e.g. [0, 15, 30, 45]), using circular (mod 60) distance
## so that e.g. raw=58 snaps to 0, not 45.
static func snap_minute_to_allowed(raw_minute: float, allowed_minutes: Array) -> int:
	if allowed_minutes.is_empty():
		return int(round(raw_minute)) % 60
	var best_value: int = allowed_minutes[0]
	var best_dist: float = INF
	for candidate in allowed_minutes:
		var diff: float = abs(raw_minute - float(candidate))
		var circular_diff: float = min(diff, 60.0 - diff)
		if circular_diff < best_dist:
			best_dist = circular_diff
			best_value = candidate
	return best_value
