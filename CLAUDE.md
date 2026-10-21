# Clocky — notes for Claude

Godot 4.7 (GDScript) app that teaches children aged 4.5+ to read analog clocks, in English, Dutch and Romanian. It targets a Windows 11 touch monitor in fullscreen kiosk mode. Most of the audience can't read yet, so the UI is visual and icon-first.

## Product decisions (don't undo without asking)

- **Speech: tap-to-hear text-to-speech only, never speech-to-text.**
  - Speech was first removed as "not the right interface for kids", then text-to-speech came back in a narrower form: it helps non-readers understand labels. Getting children to speak answers was judged not worth it.
  - Nothing is spoken automatically. Small 🗣️ `SpeakButton`s sit beside the screen instructions and the feedback, and in each picker card's top-left corner, where they read the name without selecting the card. The main menu, summary and buttons like Next/Back have none (the user chose prompts and card names only).
  - Uses Godot's built-in TTS via the `Speech` autoload (`DisplayServer.tts_*`, with `audio/general/text_to_speech=true`). That means Windows OneCore voices on PC (English and Dutch are installed here, Romanian isn't) and Google TTS on Android. No plugins or helper programs.
  - If the current language has no voice, the 🗣️ buttons hide. The top-bar mute silences speech too.
  - Speech text goes through `Speech.clean()`, which drops emoji and reads "/" as ", ". Set the Clock and wrong typed answers speak the time naturally via `PhraseBuilder` ("half past three"), while the screen shows digits.
  - The "read the clock" prompts must never speak the target time, because that would give away the answer.
- **Exercises:** read the clock (multiple choice), read the clock (type the time; 12h and 24h both accepted), and set the clock (drag the hands). Each has 5 tiers: o'clock → half → quarter → 5-minute → exact minute.
- **Every wrong answer teaches.** Multiple choice reveals the right answer in green. Set the Clock animates the hands to the target. Typed answers show "Almost! It was 3:15." The feedback is never punishing.
- **Clock numbers setting:** none, hours, or hours + minutes. Numbers sit in rings *outside* the rim, so the hands never cover them. Hour hand and hour numbers are navy; minute hand and minute numbers are blue.
- **Owl mascot**, confetti, and sound effects synthesized in code, with a mute toggle.
- **Kiosk:** starts fullscreen with stretch aspect `expand`. Exit by holding the top-left ⏻ for 3 seconds; Alt+F4 also works.
- **Multi-monitor (`KioskWindow` autoload):** Windows keeps a fullscreen window's old size when it's moved to another monitor. That caused a wrong aspect and a cut-off owl on the user's 2560×1600 + 2880×1620 setup. `KioskWindow` polls for a monitor change, re-applies fullscreen there, and saves the `kiosk_screen` setting so the next launch opens on the same monitor. `--screen N` on the command line overrides it. It does nothing in headless runs and `--script` runs. Test it with `scripts/tools/KioskWindowTest.gd`, which needs a window and 2 monitors and briefly goes fullscreen on each.
- **Android** (preset "Android": arm64 only, `com.wvdhouten.clocky`, no permissions, debug-signed):
  - Back (`NOTIFICATION_WM_GO_BACK_REQUEST`, with `quit_on_go_back=false`) is handled by `Main.go_back()`. Order: open dialog → exercise/summary → picker → menu → quit.
  - `ParentExitButton` and `KioskWindow` are disabled when `OS.has_feature("mobile")`.
  - Type the Time uses the number keypad, with digits auto-formatted to "3:15" by `format_digits()`. It lifts itself above the on-screen keyboard (`keyboard_shift()`).
  - Only query `DisplayServer.virtual_keyboard_get_height()` when `has_feature(FEATURE_VIRTUAL_KEYBOARD)`; otherwise Windows logs a warning every frame.
  - Android requires `import_etc2_astc=true`.
  - The slim-engine idea (a custom Godot build to shrink the 110 MB exe) was dropped as not worth the maintenance.
- **Total stars** = one per correct answer ever (the same stars the summary pops in), computed by `ProgressSchema.get_overall_stars()` from per-tier `correct` counts; there's no stored counter. 🏆 is reserved for mastered levels.
- **Safe area (mobile):** everything except the sky lives in `Main/SafeArea`, inset on phones and tablets by the OS safe area. The minimum is 56 px at the sides and 10 at top and bottom, because rounded corners aren't always reported. The same margin is used on both sides so a 180° flip still fits. The sky's sun moves in by *half* the inset: its disc clears the margin, its rays may reach into it. Desktop has zero inset.
- `PhraseBuilder` (time in words per locale, `scripts/speech/`) produces the spoken time phrases. Its Dutch idioms ("half vier" = 3:30, anchored to the *next* hour) are the riskiest correctness area.
- The user playtests every step and gives concrete UX feedback. A UI change isn't done until it has been verified visually (see Screenshots).

## Layout

- `autoloads/`, in this order:
  - `UiTheme`: builds the Theme in code; also holds the palette constants.
  - `GameState`
  - `ProgressStore`: `user://progress.json` and settings.
  - `SoundFx`: synthesized sounds; every button automatically gets a tap sound.
  - `KioskWindow`: keeps fullscreen fitted to the current monitor and remembers it.
  - `LocaleManager`
  - `Speech`: tap-to-hear text-to-speech.
  - `ExerciseDirector`: sessions and question generation.
- `scenes/main/`:
  - `Main.tscn`: the persistent shell. The sky background is full-screen. Everything else sits inside `SafeArea`: `ScreenHost`, where screens are swapped, plus the overlays that appear on every screen (owl, top bar with mute / 🔢 / flag, parent-exit button, confetti layer).
  - `MainMenu`
  - `ClockDebug`: dev-only and excluded from builds.
- `scenes/clock/AnalogClock`: the reusable clock widget, in STATIC or INTERACTIVE mode. It communicates only through `set_time()`, `get_current_time()`, `animate_to()` and its signals.
- `scenes/exercises/`: all exercises extend `ExerciseBase.gd` by path. Each scene must contain the nodes `PromptLabel`, `FeedbackLabel`, `NextButton` and `ExitButton`.
- `scenes/session/`: `TierSelect` (picture cards with mastery badges) and `SessionSummary`.
- `scenes/ui_components/`: owl, sky, celebration, switchers, the parent-exit button and `SpeakButton`.
- `scripts/`:
  - `clock_logic` (`ClockMath`, `TimeValue`)
  - `data` (tier/exercise Resources, `QuestionGenerator`)
  - `persistence`
  - `speech` (`PhraseBuilder`)
  - `ui` (`FlagTextures`, `SmoothPolygon2D`)
  - `tools` (`Screenshots`)
- `resources/tiers/*.tres` and `resources/exercises/*.tres` are data-driven: add a tier or variant by adding a resource, not by branching code.
- `localization/ui_strings.csv` has the columns `keys,en,nl,ro`. All UI text goes through `tr()`, and screens refresh on `LocaleManager.locale_changed`.

## Commands

The Godot executable (winget install, not on PATH):
`/c/Users/walte/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64.exe`

- **Re-import** after changing the CSV or adding assets: `godot --headless --path . --import`
- **Tests:** `godot --headless --script res://<path>`. Each prints `ALL PASS` or `N FAILURE(S)`.
  - `scripts/clock_logic/ClockMathTest.gd`
  - `scripts/data/ExerciseFlowTest.gd`
  - `scripts/data/SceneLoadTest.gd`: checks scene loading, that the hands are drawable, and the layout at 1280×800, 1422×800 (16:9), 1280×960 (4:3 tablet) and 1778×800 (20:9 phone). The layout check includes overlap against the owl, the top bar and the exit button, plus contrast.
    - It also covers back navigation, keypad input, the keyboard lift, the safe area, speech text cleanup, and that card 🗣️ buttons stay clear of the clocks.
    - `Speech.force_available = true` makes the 🗣️ buttons visible in headless runs.
  - `scripts/data/ProgressPersistenceTest.gd`
  - `scripts/speech/PhraseBuilderTest.gd`
- **Screenshots** (needs a window, so no `--headless`; it saves only Godot's own viewport, never the desktop):
  `godot --path . --script res://scripts/tools/Screenshots.gd -- <out_dir>`
  It uses a fixed RNG seed and writes zoom crops (`*z_*.png`) for checking edge quality. Look at them with the Read tool.
- **Build:** `godot --headless --path . --export-release "Windows Desktop" build/Clocky.exe`
  This needs the 4.7.2 Windows templates in `%APPDATA%\Godot\export_templates\4.7.2.stable\`; only the x86_64 ones are installed. Smoke-test the build with `build/Clocky.exe --headless --quit-after 300`.
- **Android APK:** `godot --headless --path . --export-debug "Android" build/Clocky.apk`, then inspect it with `aapt2 dump badging` from `%LOCALAPPDATA%\Android\Sdk\build-tools\35.0.1`. The layout tests also cover 4:3 tablets (1280×960) and 20:9 phones (1778×800).
- **Icon:** `icon.svg` is the source (owl-clock). After editing it, regenerate `assets/icon/clocky.ico` and the Android launcher icons (`assets/icon/android/`; the adaptive foreground keeps the art inside the circle-mask safe zone) with `godot --headless --path . --script res://scripts/tools/BuildIcon.gd -- <preview_dir>`.
  - The export stamps the icon into the exe through rcedit (`%LOCALAPPDATA%\Programs\rcedit\rcedit-x64.exe`). It's registered per machine as `export/windows/rcedit` in `%APPDATA%\Godot\editor_settings-4.7.tres`; a backup of the original is in `.bak`.
  - The `.ico` is force-included in the pack (`include_filter`) because `windows_native_icon` loads it at runtime.
  - To check what Windows shows, use PowerShell `[System.Drawing.Icon]::ExtractAssociatedIcon(exe)`.

## Gotchas (each of these caused a real bug)

- **Don't rely on `class_name` across scripts.** The global class cache isn't populated for direct and headless runs. Use `const X = preload("res://...")`, `extends "res://path.gd"`, and loose types for custom Resources (e.g. `Array[Resource]`). A script also mustn't reference its own `class_name`; use `get_script().new()`.
- **In SceneTree scripts (`--script`), autoload names don't resolve at compile time.** Use `root.get_node("ProgressStore")` instead.
- **GDScript lambdas capture locals by value.** Signal completion through an Array or Dictionary, not a captured `bool`.
- **`ProgressStore` switches to `user://progress_test.json` whenever `--script` is on the command line.** Tests used to wipe and pollute the child's real save; never bypass this.
- **Antialiasing on the Compatibility (GLES3) renderer:** 2D MSAA isn't supported, and `Polygon2D.antialiased` does nothing. Antialiased lines do work.
  - Filled shapes: use `SmoothPolygon2D`, which traces a thin antialiased outline.
  - Circles: use `draw_circle(..., true, -1.0, true)`.
  - Never draw a radius-1 circle under a large scale transform: the antialiasing fringe gets stretched into a blur. Compute the outline points on screen instead, as `Owl.gd` does.
- **Polygons must not self-intersect,** or Godot silently draws nothing (this once made the clock hands invisible). `SceneLoadTest` checks that they triangulate.
- **Windows has no flag emoji** (🇬🇧 renders as "GB"). Flags are drawn by `scripts/ui/FlagTextures.gd`.
- **Fonts must cover Romanian ă ș ț.** Baloo 2 does; Fredoka doesn't. Check glyph coverage before switching fonts.
- **Text-format `.tscn`/`.tres` files are edited by hand.** Keep the blank lines between `[node]` sections, and put `layout_mode`/anchors on Control nodes.
- **Button children need `mouse_filter = IGNORE`** so the whole card stays clickable (e.g. the mini clocks on the picker cards).
- **Phone checks over adb** (`%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe`, the user's Xiaomi 17 Ultra):
  - `adb install -r build/Clocky.apk` needs "Install via USB" on in HyperOS developer options.
  - Simulated taps (`input tap`) are blocked unless "USB debugging (Security settings)" is also on, so ask the user to navigate.
  - Only take `screencap` after confirming Clocky is the `topResumedActivity`, so nothing else on their phone gets captured.
