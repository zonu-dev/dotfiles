---
name: godot-mobile
description: Build, debug, export, install, and verify Godot Android mobile games. Use when working on Godot projects that target Android devices, APK export, touch or drag controls, mobile UI input, adb install, adb logcat, screenshots, or real-device gameplay validation.
---

# Godot Mobile

## Workflow

1. Inspect the project first: `AGENTS.md`, README, `project.godot`, existing scenes/scripts, and `export_presets.cfg`.
2. Match the project's Godot version. Do not silently upgrade project format or export settings.
3. Keep mobile gameplay changes small and testable. Prefer primitives and local/generated materials before adding external assets.
4. Run Godot import and script checks before exporting.
5. Build a debug APK, install it on the connected Android device, launch it, and validate gameplay on-device.
6. Use screenshots, `adb shell input`, and logcat to prove the loop works.

## Touch Input Rules

- Use `_input()` for gameplay touch and drag controls when the scene has full-screen `Control` UI. `_unhandled_input()` can miss events after UI consumes them.
- Set HUD-only controls to `mouse_filter = Control.MOUSE_FILTER_IGNORE`.
- Keep interactive overlays and buttons able to receive input. Do not set an entire retry overlay to ignore if its children must be tappable.
- Verify touch controls with a real device command such as `adb shell input swipe ...`; desktop mouse testing is insufficient.
- After input fixes, re-test Retry or other buttons because mouse filtering changes can break UI taps.

## Android Export Checks

- Confirm the package name, export path, signing mode, architecture, and debug keystore in `export_presets.cfg`.
- Confirm local Android SDK, JDK, and Godot export templates are configured for the active Godot version.
- If `godot` is not on `PATH`, locate the matching binary or install it before changing project files.
- Keep APK/AAB/build output ignored unless the repository explicitly tracks binary artifacts.

## Verification Commands

Adapt paths and package names to the project:

```bash
Godot --headless --path . --editor --quit
Godot --path . --quit-after 3
Godot --headless --path . --export-debug "Android Debug" build/android/app_debug.apk
adb devices
adb install -r build/android/app_debug.apk
adb shell monkey -p <package.name> -c android.intent.category.LAUNCHER 1
adb exec-out screencap -p > /tmp/godot_mobile_screen.png
adb shell input swipe 540 1700 160 1700 500
adb shell input tap 540 1065
```

For logcat, filter by package plus crash terms:

```bash
adb logcat --format=threadtime '*:W' | grep --line-buffered '<package.name>\|Godot\|FATAL\|AndroidRuntime\|ANR'
```

Check specifically for `FATAL EXCEPTION`, `AndroidRuntime`, `ANR`, `SIGSEGV`, `SIGABRT`, script errors, and unexpected `Exception` or `Error` lines.

## Reporting

When Android delivery is part of the task, include:

- APK path and SHA-256
- device serial
- install result
- launch result
- gameplay actions verified on-device
- logcat crash/error result
- any remaining constraints, such as debug-only export or local Godot binary location
