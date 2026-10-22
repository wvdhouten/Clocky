extends RefCounted

## The owl's lessons, one per tier topic. Each step is the owl's text (a
## ui_strings.csv key) plus what the clock does meanwhile:
##   time      [hour, minute] shown (animated to, if the clock was elsewhere)
##   hand      hand to highlight: 0 none, 1 short (hour), 2 long (minute)
##   numbers   optional forced number mode (2 = hours and minutes)
##   try       optional: the child sets the clock to `time` themselves,
##             with the minute hand snapping to `try` (allowed minutes)
## Texts may use {time} (digits, e.g. 3:30) and {phrase} (in words, e.g.
## "half past three"); both are spoken as words.

const NONE := 0
const SHORT := 1
const LONG := 2

const LESSONS := {
	1: [
		{"key": "LEARN_1_1", "time": [10, 10], "hand": NONE},
		{"key": "LEARN_1_2", "time": [3, 0], "hand": SHORT},
		{"key": "LEARN_1_3", "time": [3, 0], "hand": LONG},
		{"key": "LEARN_1_4", "time": [3, 0], "hand": LONG},
		{"key": "LEARN_1_5", "time": [3, 0], "hand": SHORT},
		{"key": "LEARN_1_6", "time": [7, 0], "hand": SHORT},
		{"key": "LEARN_1_7", "time": [4, 0], "hand": SHORT, "try": [0]},
	],
	2: [
		{"key": "LEARN_2_1", "time": [3, 0], "hand": LONG},
		{"key": "LEARN_2_2", "time": [3, 30], "hand": LONG},
		{"key": "LEARN_2_3", "time": [3, 30], "hand": SHORT},
		{"key": "LEARN_2_4", "time": [3, 30], "hand": NONE},
		{"key": "LEARN_2_5", "time": [8, 30], "hand": NONE, "try": [0, 30]},
	],
	3: [
		{"key": "LEARN_3_1", "time": [3, 15], "hand": LONG},
		{"key": "LEARN_3_2", "time": [3, 15], "hand": NONE},
		{"key": "LEARN_3_3", "time": [3, 45], "hand": LONG},
		{"key": "LEARN_3_4", "time": [3, 45], "hand": SHORT},
		{"key": "LEARN_3_5", "time": [6, 15], "hand": NONE, "try": [0, 15, 30, 45]},
	],
	4: [
		{"key": "LEARN_4_1", "time": [2, 0], "hand": LONG, "numbers": 2},
		{"key": "LEARN_4_2", "time": [2, 10], "hand": LONG, "numbers": 2},
		{"key": "LEARN_4_3", "time": [2, 40], "hand": LONG, "numbers": 2},
		{"key": "LEARN_4_4", "time": [5, 25], "hand": NONE, "numbers": 2,
			"try": [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55]},
	],
	5: [
		{"key": "LEARN_5_1", "time": [4, 0], "hand": LONG, "numbers": 2},
		{"key": "LEARN_5_2", "time": [4, 12], "hand": LONG, "numbers": 2},
		{"key": "LEARN_5_3", "time": [4, 12], "hand": NONE, "numbers": 2},
		{"key": "LEARN_5_4", "time": [9, 37], "hand": NONE, "numbers": 2, "try": []},
	],
}


static func steps(tier_number: int) -> Array:
	return LESSONS.get(tier_number, LESSONS[1])
