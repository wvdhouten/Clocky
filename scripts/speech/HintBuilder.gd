extends RefCounted

## Step-by-step hints the owl gives when the child taps ❓. Each hint talks
## about one hand: which number it points at and what that means. Hints
## use digits-and-counting language ("the long hand points at the 6:
## count by fives, 30 minutes"), which works the same in every language
## and matches the digital answers on screen.
##
## A hint is {"key", "args", "hand"}; `hand` is the AnalogClock HandId to
## highlight. text() turns a hint into the current language.

const HAND_HOUR := 1    # AnalogClock.HandId.HOUR
const HAND_MINUTE := 2  # AnalogClock.HandId.MINUTE


## Reading the clock: the short hand gives the hour, then the long hand
## gives the minutes.
static func read_hints(tv) -> Array:
	return [_hour_hint(tv, "HINT_READ_HOUR"), _minute_hint(tv, "HINT_READ_MIN")]


## Setting the clock: where the long hand goes, then the short hand.
static func set_hints(tv) -> Array:
	return [_minute_hint(tv, "HINT_SET_MIN"), _hour_hint(tv, "HINT_SET_HOUR")]


static func text(hint: Dictionary) -> String:
	return TranslationServer.translate(hint["key"]).format(hint["args"])


## Clock-face number for a 0-11 hour (0 is the 12).
static func face_number(hour: int) -> int:
	var h: int = posmod(hour, 12)
	return 12 if h == 0 else h


static func _hour_hint(tv, prefix: String) -> Dictionary:
	var args := {"h": face_number(tv.hour), "h1": face_number(tv.hour + 1)}
	# On the hour the short hand sits right on its number; otherwise it has
	# moved on towards the next one, but the hour hasn't changed yet.
	var key: String = prefix + ("_ON" if tv.minute == 0 else "_BETWEEN")
	return {"key": key, "args": args, "hand": HAND_HOUR}


static func _minute_hint(tv, prefix: String) -> Dictionary:
	var m: int = tv.minute
	var n: int = m / 5
	var ticks: int = m % 5
	var args := {"m": m, "n": 12 if n == 0 else n, "m5": n * 5, "k": ticks}
	var key: String
	if m == 0:
		key = prefix + "_TWELVE"
	elif ticks == 0:
		key = prefix + "_ON"
	elif n == 0:
		key = prefix + "_TICKS_TOP"
	else:
		key = prefix + "_TICKS"
	return {"key": key, "args": args, "hand": HAND_MINUTE}
