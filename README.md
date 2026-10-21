# Clocky

A Godot 4 app that teaches children (4.5+) to read analog clocks, in English, Dutch and Romanian.

## Running

Open the folder in Godot 4.7+ or run:

```
godot --path C:\dev\Clocky
```

## Building an executable

The "Windows Desktop" preset is in `export_presets.cfg`. It builds a single self-contained `Clocky.exe` with the game data embedded, so Godot isn't needed on the target PC. The test, screenshot and debug scripts are left out.

```
godot --headless --path C:\dev\Clocky --export-release "Windows Desktop" build/Clocky.exe
```

This needs the Godot **4.7.2** Windows export templates in `%APPDATA%\Godot\export_templates\4.7.2.stable\`. Install them via the editor's *Editor → Manage Export Templates*. The `build/` folder is git-ignored.

### App icon

`icon.svg` (an owl-clock) is the source. `assets/icon/clocky.ico` is generated from it:

```
godot --headless --path . --script res://scripts/tools/BuildIcon.gd -- [preview_dir]
```

The `.ico` serves as the runtime window/taskbar icon (`windows_native_icon`) and is stamped into the exe at export. Stamping needs [rcedit](https://github.com/electron/rcedit), configured per machine in Godot's editor settings: `export/windows/rcedit` in `%APPDATA%\Godot\editor_settings-4.7.tres`. On this PC it's `%LOCALAPPDATA%\Programs\rcedit\rcedit-x64.exe`. Without rcedit, the export still works, but the exe keeps Godot's default icon.

## Kiosk mode

The app starts fullscreen and stretches to fill the screen. Children can't close it by accident. To exit, **press and hold the round ⏻ button in the top-left corner for 3 seconds** until the ring fills. Alt+F4 also works.

**Multiple monitors:** move the app to the monitor you want (e.g. Win+Shift+→). It re-fits itself to that monitor and opens there from then on. To force a monitor for one launch, run `Clocky.exe --screen 1`; monitors are numbered from 0, with 0 the main one.

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
