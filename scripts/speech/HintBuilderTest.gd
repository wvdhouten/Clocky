extends SceneTree

## Checks the owl's ❓ hints: which hand each step talks about, the numbers
## it names, and that every template exists in every language.
## Run with: godot --headless --script res://scripts/speech/HintBuilderTest.gd

const HintBuilder = preload("res://scripts/speech/HintBuilder.gd")
const TimeValue = preload("res://scripts/clock_logic/TimeValue.gd")

var failures: int = 0


func _init() -> void:
	await process_frame

	# [hour, minute, expected read keys, expected args subset]
	var cases := [
		[3, 0, ["HINT_READ_HOUR_ON", "HINT_READ_MIN_TWELVE"], {"h": 3}],
		[3, 30, ["HINT_READ_HOUR_BETWEEN", "HINT_READ_MIN_ON"], {"h": 3, "h1": 4, "n": 6, "m": 30}],
		[11, 45, ["HINT_READ_HOUR_BETWEEN", "HINT_READ_MIN_ON"], {"h": 11, "h1": 12, "n": 9, "m": 45}],
		[0, 15, ["HINT_READ_HOUR_BETWEEN", "HINT_READ_MIN_ON"], {"h": 12, "h1": 1, "n": 3}],
		[4, 47, ["HINT_READ_HOUR_BETWEEN", "HINT_READ_MIN_TICKS"], {"h": 4, "n": 9, "m5": 45, "k": 2, "m": 47}],
		[9, 3, ["HINT_READ_HOUR_BETWEEN", "HINT_READ_MIN_TICKS_TOP"], {"h": 9, "k": 3, "m": 3}],
	]
	for c in cases:
		var tv = TimeValue.new(c[0], c[1])
		var hints: Array = HintBuilder.read_hints(tv)
		var keys: Array = hints.map(func(x): return x["key"])
		var args := {}
		for x in hints:
			args.merge(x["args"], true)
		var ok: bool = keys == c[2]
		for k in c[3]:
			ok = ok and args.get(k) == c[3][k]
		_check(ok, "read hints for %s: %s %s" % [tv.to_digital_string(), keys, args])
		_check(hints[0]["hand"] == HintBuilder.HAND_HOUR and hints[1]["hand"] == HintBuilder.HAND_MINUTE,
			"read hints for %s: short hand first, then long hand" % tv.to_digital_string())
		var set_hints: Array = HintBuilder.set_hints(tv)
		_check(set_hints[0]["hand"] == HintBuilder.HAND_MINUTE and set_hints[0]["key"].begins_with("HINT_SET_MIN")
			and set_hints[1]["key"].begins_with("HINT_SET_HOUR"), "set hints for %s: long hand first" % tv.to_digital_string())

	# Every template, in every language, is translated and fully filled in.
	var all_keys := {}
	for h in 12:
		for m in 60:
			for x in HintBuilder.read_hints(TimeValue.new(h, m)) + HintBuilder.set_hints(TimeValue.new(h, m)):
				all_keys[x["key"]] = x
	for locale in ["en", "nl", "ro"]:
		TranslationServer.set_locale(locale)
		var bad: Array = []
		for key in all_keys:
			var t: String = HintBuilder.text(all_keys[key])
			if t == key or t.contains("{"):
				bad.append(key)
		_check(bad.is_empty(), "%s: all %d hint templates translated and filled %s" % [locale, all_keys.size(), bad])
	TranslationServer.set_locale("en")
	_check(HintBuilder.text(HintBuilder.read_hints(TimeValue.new(3, 30))[1]) == "Now the long hand. It points at the 6. Count by fives: 30 minutes.",
		"English long-hand hint for 3:30 reads naturally")

	if failures == 0:
		print("ALL PASS")
	else:
		print("%d FAILURE(S)" % failures)
	quit(failures)


func _check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
	print(("ok   " if ok else "FAIL ") + label)
