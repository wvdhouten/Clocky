extends "res://scenes/ui_components/GlyphButton.gd"

## Top-bar sound toggle. The choice is saved (via SoundFx/ProgressStore).


func _ready() -> void:
	super._ready()
	theme_type_variation = &"TopBarButton"
	pressed.connect(func():
		SoundFx.set_muted(not SoundFx.is_muted())
		_refresh())
	_refresh()


func _refresh() -> void:
	glyph = "🔇" if SoundFx.is_muted() else "🔊"
