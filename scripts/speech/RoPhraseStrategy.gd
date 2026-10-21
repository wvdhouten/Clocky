extends RefCounted

## Romanian time phrasing. "Past" phrases anchor to the current hour
## ("și" = and), "to" phrases anchor to the next hour ("fără" = without).
const HOUR_WORDS := ["douăsprezece", "una", "două", "trei", "patru", "cinci",
	"șase", "șapte", "opt", "nouă", "zece", "unsprezece"]


func time_to_phrase(tv) -> String:
	var h: int = tv.hour
	var m: int = tv.minute
	var next_h: int = (h + 1) % 12
	var hour_word: String = HOUR_WORDS[h]
	var next_hour_word: String = HOUR_WORDS[next_h]

	if m == 0:
		return "ora %s fix" % hour_word
	elif m == 15:
		return "%s și un sfert" % hour_word
	elif m == 30:
		return "%s și jumătate" % hour_word
	elif m == 45:
		return "%s fără un sfert" % next_hour_word
	elif m < 30:
		return "%s și %d minute" % [hour_word, m]
	else:
		return "%s fără %d minute" % [next_hour_word, 60 - m]
