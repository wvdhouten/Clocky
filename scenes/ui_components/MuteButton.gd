extends Button

## Top-bar sound toggle. The choice is saved (via SoundFx/ProgressStore).


func _ready() -> void:
	theme_type_variation = &"TopBarButton"
	add_theme_font_size_override("font_size", 26)
	pressed.connect(func():
		SoundFx.set_muted(not SoundFx.is_muted())
		_refresh())
	_refresh()


func _refresh() -> void:
	text = "🔇" if SoundFx.is_muted() else "🔊"
