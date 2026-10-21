extends RefCounted

## Façade over the per-locale PhraseStrategy classes. Used both to build
## spoken/subtitle prompts and (reused) to build multiple-choice option
## labels and AnswerMatcher candidates, so phrasing is defined once per
## locale and never duplicated.

const EnPhraseStrategy = preload("res://scripts/speech/EnPhraseStrategy.gd")
const NlPhraseStrategy = preload("res://scripts/speech/NlPhraseStrategy.gd")
const RoPhraseStrategy = preload("res://scripts/speech/RoPhraseStrategy.gd")

static var _strategies: Dictionary = {}


static func _ensure_strategies() -> void:
	if _strategies.is_empty():
		_strategies["en"] = EnPhraseStrategy.new()
		_strategies["nl"] = NlPhraseStrategy.new()
		_strategies["ro"] = RoPhraseStrategy.new()


static func build(tv, locale: String) -> String:
	_ensure_strategies()
	var strategy = _strategies.get(locale, _strategies["en"])
	return strategy.time_to_phrase(tv)


static func supported_locales() -> Array:
	_ensure_strategies()
	return _strategies.keys()
