extends RefCounted

## English time phrasing. Hour index 0 = 12 o'clock.
const HOUR_WORDS := ["twelve", "one", "two", "three", "four", "five", "six",
	"seven", "eight", "nine", "ten", "eleven"]


func time_to_phrase(tv) -> String:
	var h: int = tv.hour
	var m: int = tv.minute
	var next_h: int = (h + 1) % 12

	if m == 0:
		return "%s o'clock" % HOUR_WORDS[h]
	elif m == 30:
		return "half past %s" % HOUR_WORDS[h]
	elif m == 15:
		return "quarter past %s" % HOUR_WORDS[h]
	elif m == 45:
		return "quarter to %s" % HOUR_WORDS[next_h]
	elif m < 30:
		return "%d past %s" % [m, HOUR_WORDS[h]]
	else:
		return "%d to %s" % [60 - m, HOUR_WORDS[next_h]]
