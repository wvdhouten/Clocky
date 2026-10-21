extends RefCounted

## Dutch time phrasing. Unlike English, Dutch anchors the half hour AND
## the 5-minute increments either side of it to the NEXT hour ("half
## vier" = half past three, anchored to four) - this is the highest-risk
## correctness item in the whole app; a native speaker should review it.
const HOUR_WORDS := ["twaalf", "een", "twee", "drie", "vier", "vijf", "zes",
	"zeven", "acht", "negen", "tien", "elf"]


func time_to_phrase(tv) -> String:
	var h: int = tv.hour
	var m: int = tv.minute
	var next_h: int = (h + 1) % 12
	var hour_word: String = HOUR_WORDS[h]
	var next_hour_word: String = HOUR_WORDS[next_h]

	if m == 0:
		return "%s uur" % hour_word
	elif m == 15:
		return "kwart over %s" % hour_word
	elif m == 30:
		return "half %s" % next_hour_word
	elif m == 45:
		return "kwart voor %s" % next_hour_word
	elif m < 15:
		return "%d over %s" % [m, hour_word]
	elif m < 30:
		return "%d voor half %s" % [30 - m, next_hour_word]
	elif m < 45:
		return "%d over half %s" % [m - 30, next_hour_word]
	else:
		return "%d voor %s" % [60 - m, next_hour_word]
