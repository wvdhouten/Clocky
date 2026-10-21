class_name TimeValue
extends RefCounted

## Immutable-ish hour/minute pair. Hour is stored 0-11 (12-hour clock face,
## no AM/PM concept needed since Clocky only teaches hand positions).

var hour: int
var minute: int


func _init(p_hour: int = 0, p_minute: int = 0) -> void:
	hour = ((p_hour % 12) + 12) % 12
	minute = ((p_minute % 60) + 60) % 60


func equals(other: TimeValue) -> bool:
	return hour == other.hour and minute == other.minute


func duplicate_value() -> TimeValue:
	return get_script().new(hour, minute)


func to_digital_string() -> String:
	var display_hour: int = hour
	if display_hour == 0:
		display_hour = 12
	return "%d:%02d" % [display_hour, minute]


func _to_string() -> String:
	return to_digital_string()
