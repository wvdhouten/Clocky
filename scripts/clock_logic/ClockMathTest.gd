extends SceneTree

## Standalone headless check for ClockMath/TimeValue.
## Run with: godot --headless --script res://scripts/clock_logic/ClockMathTest.gd

const ClockMath = preload("res://scripts/clock_logic/ClockMath.gd")
const TimeValue = preload("res://scripts/clock_logic/TimeValue.gd")

var failures: int = 0


func _init() -> void:
	_check_eq("hour_angle 12:00", ClockMath.hour_angle_deg(0, 0), 0.0)
	_check_eq("hour_angle 3:00", ClockMath.hour_angle_deg(3, 0), 90.0)
	_check_eq("hour_angle 6:00", ClockMath.hour_angle_deg(6, 0), 180.0)
	_check_eq("hour_angle 3:30 creep", ClockMath.hour_angle_deg(3, 30), 105.0)

	_check_eq("minute_angle :00", ClockMath.minute_angle_deg(0), 0.0)
	_check_eq("minute_angle :15", ClockMath.minute_angle_deg(15), 90.0)
	_check_eq("minute_angle :30", ClockMath.minute_angle_deg(30), 180.0)
	_check_eq("minute_angle :45", ClockMath.minute_angle_deg(45), 270.0)

	_check_eq("vector straight up -> 0", ClockMath.vector_to_clock_angle_deg(Vector2(0, -1)), 0.0)
	_check_eq("vector right -> 90", ClockMath.vector_to_clock_angle_deg(Vector2(1, 0)), 90.0)
	_check_eq("vector down -> 180", ClockMath.vector_to_clock_angle_deg(Vector2(0, 1)), 180.0)
	_check_eq("vector left -> 270", ClockMath.vector_to_clock_angle_deg(Vector2(-1, 0)), 270.0)

	_check_eq_int("snap to quarter, near 0", ClockMath.snap_minute_to_allowed(2.0, [0, 15, 30, 45]), 0)
	_check_eq_int("snap to quarter, near 15", ClockMath.snap_minute_to_allowed(13.0, [0, 15, 30, 45]), 15)
	_check_eq_int("snap wraps near 60->0", ClockMath.snap_minute_to_allowed(58.0, [0, 15, 30, 45]), 0)
	_check_eq_int("snap to five, near 7", ClockMath.snap_minute_to_allowed(7.0, [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55]), 5)

	var tv_a := TimeValue.new(3, 30)
	var tv_b := TimeValue.new(3, 30)
	var tv_c := TimeValue.new(15, 30)  # should normalize to hour 3
	_check_true("TimeValue equals", tv_a.equals(tv_b))
	_check_true("TimeValue normalizes 24h hour", tv_a.equals(tv_c))
	_check_eq_str("digital string 3:30", tv_a.to_digital_string(), "3:30")
	_check_eq_str("digital string 0:05 -> 12:05", TimeValue.new(0, 5).to_digital_string(), "12:05")

	if failures == 0:
		print("ALL PASS")
	else:
		print("%d FAILURE(S)" % failures)
	quit(failures)


func _check_eq(label: String, actual: float, expected: float) -> void:
	if abs(actual - expected) > 0.01:
		failures += 1
		print("FAIL %s: expected %s, got %s" % [label, expected, actual])
	else:
		print("ok   %s" % label)


func _check_eq_int(label: String, actual: int, expected: int) -> void:
	if actual != expected:
		failures += 1
		print("FAIL %s: expected %s, got %s" % [label, expected, actual])
	else:
		print("ok   %s" % label)


func _check_eq_str(label: String, actual: String, expected: String) -> void:
	if actual != expected:
		failures += 1
		print("FAIL %s: expected %s, got %s" % [label, expected, actual])
	else:
		print("ok   %s" % label)


func _check_true(label: String, actual: bool) -> void:
	if not actual:
		failures += 1
		print("FAIL %s: expected true" % label)
	else:
		print("ok   %s" % label)
