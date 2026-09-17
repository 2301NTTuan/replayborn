# Replayborn production handoff

Open `project.godot` with Godot 4.7.2 and press F6/F5. The project opens at the Vietnamese/English menu. Start a Neon Ruins run or use Practice for a five-minute session.

Windows artifact: `exports/windows/Replayborn.exe`

Touch control is invisible and dynamic: touch and drag anywhere inside the arena below the top HUD. No joystick graphic appears.

Normal runs contain five Neon Ruins levels. Each two-minute level ends with a distinct boss; defeating the boss unlocks the next level. Defeating boss five completes the run. Practice mode remains a five-minute fast test without level-boss progression.

The release is intentionally locked to Astria and Neon Ruins. Future character/map data is not presented as selectable runtime content.

The loadout/shop layer uses only gold earned in game. When gold is insufficient it reports that state; no payment option is shown.
Android debug artifact: `exports/android/Replayborn-debug.apk`

Validation:

```text
powershell -ExecutionPolicy Bypass -File tools/validate.ps1
godot --headless --path . --script res://tools/stress_probe.gd
godot --headless --path . --script res://tools/balance_probe.gd
```

The app is offline and has no ads, online services, or purchases. `user://profile.json` stores settings and records, with a `.bak` recovery copy. A release signing keystore and a connected Android device are still required before store submission. Release AAB export uses standard installed Godot templates, not repository-local templates.
