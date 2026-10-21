extends Node

## Tap-to-hear text-to-speech, using Godot's built-in DisplayServer TTS
## (Windows voices on PC, Android's TTS engine - e.g. Google - on phones).
## Nothing is spoken automatically: 🗣️ buttons call say(). If the current
## language has no installed voice, can_speak() is false and the buttons
## hide. Muting (top bar) silences speech as well as sound effects.

signal voices_changed

const RATE := 0.9   # a little slower, for young listeners
const VOLUME := 100

var _voice_by_locale: Dictionary = {}

## Tests only: pretend a voice exists so 🗣️ buttons show in headless runs.
var force_available: bool = false


func _ready() -> void:
	# Android's TTS engine starts asynchronously, so voices can show up a
	# few seconds after launch. Poll briefly and tell buttons when ready.
	if _tts_supported():
		var tries := [0]
		var timer := Timer.new()
		timer.wait_time = 1.0
		timer.autostart = true
		timer.timeout.connect(func():
			tries[0] += 1
			var had: bool = can_speak()
			_voice_by_locale.clear()
			if can_speak() != had:
				voices_changed.emit()
			if can_speak() or tries[0] >= 15:
				timer.stop())
		add_child(timer)
	LocaleManager.locale_changed.connect(func(_l): voices_changed.emit())


func can_speak() -> bool:
	return force_available or not _voice_for(LocaleManager.current_locale).is_empty()


func say(text: String) -> void:
	if SoundFx.is_muted():
		return
	var voice: String = _voice_for(LocaleManager.current_locale)
	if voice.is_empty():
		return
	DisplayServer.tts_stop()
	DisplayServer.tts_speak(clean(text), voice, VOLUME, 1.0, RATE)


func stop() -> void:
	if _tts_supported():
		DisplayServer.tts_stop()


## Text as it should be heard: no emoji (⭐ 🏆), and "Past/To" read as
## "Past, To" instead of "slash".
static func clean(text: String) -> String:
	var out := ""
	for c in text:
		var code: int = c.unicode_at(0)
		if code >= 0x2190 and code <= 0x2BFF or code >= 0x1F000 or code == 0xFE0F:
			continue
		out += ", " if c == "/" else c
	return out.strip_edges()


func _voice_for(locale: String) -> String:
	if _voice_by_locale.has(locale):
		return _voice_by_locale[locale]
	if not _tts_supported():
		return ""
	var voices: PackedStringArray = DisplayServer.tts_get_voices_for_language(locale)
	var voice: String = voices[0] if voices.size() > 0 else ""
	# Only remember hits: on Android an empty list may just mean "not ready yet".
	if not voice.is_empty():
		_voice_by_locale[locale] = voice
	return voice


func _tts_supported() -> bool:
	return DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH) \
		and ProjectSettings.get_setting("audio/general/text_to_speech", false)
