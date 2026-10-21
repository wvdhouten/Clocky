# Clocky

A Godot 4 app that teaches children (4.5+) to read analog clocks, in English, Dutch and Romanian.

## Running

Open the folder in Godot 4.7+ or run:

```
godot --path C:\dev\Clocky
```

## Kiosk mode

The app starts fullscreen and stretches to fill the screen. Children can't close it by accident. To exit, **press and hold the round ⏻ button in the top-left corner for 3 seconds** until the ring fills. Alt+F4 also works.

## Screenshots

`scripts/tools/Screenshots.gd` walks through every screen and saves a PNG of the game's own window (not the desktop). It needs a window, so don't pass `--headless`:

```
godot --path . --script res://scripts/tools/Screenshots.gd -- C:/some/output/folder
```

## Tests

Headless test scripts can be run with `godot --headless --script res://<path>`:

- `scripts/clock_logic/ClockMathTest.gd`
- `scripts/data/ExerciseFlowTest.gd`
- `scripts/data/SceneLoadTest.gd`
- `scripts/data/ProgressPersistenceTest.gd`
- `scripts/speech/PhraseBuilderTest.gd`

Under `--script`, `ProgressStore` automatically uses `user://progress_test.json`, so tests never touch the real save.
