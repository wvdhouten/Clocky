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

### Android (APK)

```
godot --headless --path C:\dev\Clocky --export-debug "Android" build/Clocky.apk
```

The APK is about 29 MB and supports Android 7.0+ on 64-bit ARM, which covers all current phones and tablets. It requests no permissions.

**Install on a device** with either method:
- Copy `Clocky.apk` to the device, open it, and allow "Install unknown apps" when asked.
- Or enable USB debugging and run `adb install -r build\Clocky.apk`.

**One-time setup on the build PC** (already done on this machine):
- **Java:** a JDK; 17+ works, 23 is used here.
- **Android SDK** in `%LOCALAPPDATA%\Android\Sdk`, with `platform-tools`, `build-tools;35.0.1` and `platforms;android-35`.
- **Godot 4.7.2 Android export templates.**
- **A debug keystore** at `%APPDATA%\Godot\keystores\debug.keystore` (alias `androiddebugkey`, password `android`).

All of these are registered in Godot's editor settings under `export/android/*`. A Play Store release would additionally need your own release keystore and an AAB (Gradle) build.

**On Android:**
- Back steps back through the app; at the main menu it closes it.
- The ⏻ exit button is hidden.
- "Type the time" uses the number keypad: type `315` for 3:15, and the colon is added automatically.

### App icon

`icon.svg` (an owl-clock) is the source. `assets/icon/clocky.ico` is generated from it:

```
godot --headless --path . --script res://scripts/tools/BuildIcon.gd -- [preview_dir]
```

The `.ico` serves as the runtime window/taskbar icon (`windows_native_icon`) and is stamped into the exe at export. Stamping needs [rcedit](https://github.com/electron/rcedit), configured per machine in Godot's editor settings: `export/windows/rcedit` in `%APPDATA%\Godot\editor_settings-4.7.tres`. On this PC it's `%LOCALAPPDATA%\Programs\rcedit\rcedit-x64.exe`. Without rcedit, the export still works, but the exe keeps Godot's default icon.

## Read aloud

Tap a 🗣️ button to hear a screen's instruction, the feedback after answering, or an activity/difficulty card's name read aloud. Nothing is spoken automatically.

It uses the device's own voices: Windows' built-in voices on PC, and Google's text-to-speech on Android. If a language has no voice installed, its 🗣️ buttons are hidden.
- **Windows:** add voices via Settings → Time & Language → Speech.
- **Android:** Settings → Text-to-speech → install voice data.

The 🔊/🔇 mute button silences speech as well.

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
