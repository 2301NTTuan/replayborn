# Replayborn 0.5.0-alpha.1

Replayborn is an offline, portrait Android action roguelite built with Godot 4.7.2, typed GDScript and the Mobile renderer.

> Your path becomes your weapon.

Move Astria with touch-drag or WASD. Her weapon auto-fires at the nearest valid target. Movement leaves a six-second memory trail; cross an older trail segment to close a Time Circuit. Enemies captured by the polygon are time-locked and the selected weapon triggers its own finisher.

The vertical slice contains Astria, Neon Ruins, five 95-second levels, five bosses, five regular enemy families, Armored/Volatile elites, three main weapons and eighteen in-run upgrades. A normal run targets 8–12 minutes including bosses and transitions; Practice lasts five minutes.

## Run

Open `project.godot` in Godot 4.7.2 and run the project. The flow is Boot → Menu → Tutorial/Game → Result → Menu.

Controls:

- Android: touch and drag anywhere below the HUD; release to stop.
- Windows debug: WASD or arrow keys.
- Android Back / Escape: open Pause. Back cannot dismiss an upgrade choice.

## Validation

```powershell
powershell -ExecutionPolicy Bypass -File tools/validate.ps1 -Godot 'C:\path\to\Godot_v4.7.2-stable_win64_console.exe'
godot --headless --path . --script res://tools/stress_probe.gd
godot --headless --path . --script res://tools/balance_probe.gd
godot --headless --path . --quit-after 300
```

The game has no ads, IAP, payment UI, analytics, accounts, network services or Internet permission. Android release is configured as an unsigned ARM64 AAB; debug is a separate APK preset. Signing material must remain outside Git.
