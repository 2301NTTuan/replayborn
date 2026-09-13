# Replayborn production handoff

Open `project.godot` with Godot 4.7.2 and press F6/F5. The project now opens at the Vietnamese/English menu. Select a weapon, start a run, or use Practice for a five-minute session.

Windows artifact: `exports/windows/Replayborn.exe`

Touch control is invisible and dynamic: touch and drag anywhere inside the arena below the top HUD. No joystick graphic appears.

Normal runs contain 10 selected-map levels. Each level spawns its map-specific enemy order and ends with a scaled boss; defeating the boss unlocks the next level. Defeating level 10 completes the map. Practice mode remains a five-minute fast test without the level-boss progression.

Character and map selection are separate menu screens with visual thumbnail cards. The current selection is persisted in the profile.

The loadout/shop layer has five slots (shirt, pants, shoes, armor, weapon), five rarities (Common, Rare, Legendary, Mythic, Ancient), per-slot shards, shared upgrade cores, gold, mission rewards and daily free chest cooldowns. Chest purchases currently use in-game gold; payment gateway integration remains intentionally unimplemented pending provider/store requirements.
Android debug artifact: `exports/android/Replayborn-debug.apk`

Validation:

```text
powershell -ExecutionPolicy Bypass -File tools/validate.ps1
godot --headless --path . --script res://tools/stress_probe.gd
godot --headless --path . --script res://tools/balance_probe.gd
```

The app is offline and has no ads, online services, or purchases. `user://profile.json` stores settings and records, with a `.bak` recovery copy. A release signing keystore and a connected Android device are still required before store submission.
