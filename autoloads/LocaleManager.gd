extends Node

## Wraps TranslationServer locale switching and exposes phrase
## generation for the currently active locale. set_app_locale() is the
## single entry point that keeps UI text, spoken/subtitle phrasing, and
## (later) the STT language in sync.

const PhraseBuilder = preload("res://scripts/speech/PhraseBuilder.gd")

signal locale_changed(locale: String)

var current_locale: String = "en"


func _ready() -> void:
	set_app_locale(current_locale)


func set_app_locale(locale: String) -> void:
	if not PhraseBuilder.supported_locales().has(locale):
		locale = "en"
	current_locale = locale
	TranslationServer.set_locale(locale)
	locale_changed.emit(locale)


func phrase_for_time(tv) -> String:
	return PhraseBuilder.build(tv, current_locale)
