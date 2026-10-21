extends SceneTree

## Prints generated time phrases for every tier's minute pattern, in all
## three locales, for manual/native-speaker review - and checks the CSV
## translation import is wired up correctly.
## Run with: godot --headless --script res://scripts/speech/PhraseBuilderTest.gd

const TimeValue = preload("res://scripts/clock_logic/TimeValue.gd")
const PhraseBuilder = preload("res://scripts/speech/PhraseBuilder.gd")

var failures: int = 0

# One representative time per tier's minute pattern, hour 3 (-> next hour 4)
# so the Dutch/Romanian "to the next hour" anchoring is exercised.
var sample_minutes := [0, 15, 30, 45, 5, 10, 20, 25, 35, 40, 50, 55, 17]


func _init() -> void:
	await process_frame
	await process_frame

	print("--- Generated phrases (hour=3) ---")
	for locale in ["en", "nl", "ro"]:
		print("[%s]" % locale)
		for m in sample_minutes:
			var tv = TimeValue.new(3, m)
			var phrase: String = PhraseBuilder.build(tv, locale)
			print("  %s -> %s" % [tv.to_digital_string(), phrase])

	# Spot-check the idiom-critical cases explicitly, not just print them.
	_check_eq("nl half past anchors to next hour", PhraseBuilder.build(TimeValue.new(3, 30), "nl"), "half vier")
	_check_eq("nl quarter to anchors to next hour", PhraseBuilder.build(TimeValue.new(3, 45), "nl"), "kwart voor vier")
	_check_eq("nl quarter past anchors to current hour", PhraseBuilder.build(TimeValue.new(3, 15), "nl"), "kwart over drie")
	_check_eq("nl 25 past = 5 before half past next", PhraseBuilder.build(TimeValue.new(3, 25), "nl"), "5 voor half vier")
	_check_eq("ro half past anchors to current hour", PhraseBuilder.build(TimeValue.new(3, 30), "ro"), "trei și jumătate")
	_check_eq("ro quarter to anchors to next hour", PhraseBuilder.build(TimeValue.new(3, 45), "ro"), "patru fără un sfert")
	_check_eq("en half past", PhraseBuilder.build(TimeValue.new(3, 30), "en"), "half past three")
	_check_eq("en quarter to", PhraseBuilder.build(TimeValue.new(3, 45), "en"), "quarter to four")

	# CSV translation sanity check.
	TranslationServer.set_locale("nl")
	var nl_text: String = tr("PICK_ACTIVITY")
	_check_eq("nl translation loaded", nl_text, "Kies een activiteit")
	TranslationServer.set_locale("ro")
	var ro_text: String = tr("PICK_ACTIVITY")
	_check_eq("ro translation loaded", ro_text, "Alege o activitate")
	TranslationServer.set_locale("en")

	if failures == 0:
		print("ALL PASS")
	else:
		print("%d FAILURE(S)" % failures)
	quit(failures)


func _check_eq(label: String, actual: String, expected: String) -> void:
	if actual != expected:
		failures += 1
		print("FAIL %s: expected '%s', got '%s'" % [label, expected, actual])
	else:
		print("ok   %s" % label)
