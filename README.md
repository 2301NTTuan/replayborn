# Replayborn 0.5.0-alpha.1

Godot 4.7.2 / GDScript / Mobile renderer. This offline Android-first vertical slice ships Astria, Neon Ruins, three weapon data sets, five regular enemy types, two elite tiers, fifteen in-run upgrades, and five bosses.

## Play

Open `project.godot` in Godot 4.7.2 and run the project. Touch-drag below the HUD (or WASD) moves Astria; targeting and firing are automatic. A normal Neon Ruins run has five two-minute levels followed by their bosses, intended to last about 8–12 minutes including combat. Practice remains a five-minute fast test.

Every 900 physics ticks, a self-contained Echo tape is created. Echoes replay movement and recorded projectile settings forever until their HP is depleted. Up to four coexist; creating a fifth safely removes the oldest.

The release has no ads, IAP, online services, or Internet permission. Gold/XP earned in combat stays in RAM and persists at safe boundaries such as finishing a run, returning to menu, or app focus loss. Profiles retain temporary-file, backup, and corrupt-save recovery behavior.

## Validation

```text
powershell -ExecutionPolicy Bypass -File tools/validate.ps1
godot --headless --path . --script res://tools/stress_probe.gd
godot --headless --path . --script res://tools/balance_probe.gd
```

Release exports use Godot's standard installed export templates. Debug APK is for internal testing; Android release output is an unsigned AAB and requires a separately managed keystore.
