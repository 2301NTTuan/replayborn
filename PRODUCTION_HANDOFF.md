# Replayborn production handoff

Open `project.godot` with Godot 4.7.2 and press F6/F5. The project now opens at the Vietnamese/English menu. Select a weapon, start a run, or use Practice for a five-minute session.

Windows artifact: `exports/windows/Replayborn.exe`
Android debug artifact: `exports/android/Replayborn-debug.apk`

Validation:

```text
powershell -ExecutionPolicy Bypass -File tools/validate.ps1
godot --headless --path . --script res://tools/stress_probe.gd
godot --headless --path . --script res://tools/balance_probe.gd
```

The app is offline and has no ads, online services, or purchases. `user://profile.json` stores settings and records, with a `.bak` recovery copy. A release signing keystore and a connected Android device are still required before store submission.
