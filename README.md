# Replayborn production candidate

Requires Godot 4.7.2, GDScript, Mobile renderer.

## Run

Import project.godot in Godot 4.7.2 and press F6 for the main scene or F5 for the project.
The reference canvas is 1080 x 1920; desktop window is 540 x 960 with preserved aspect ratio.

- WASD: move the green player within the outlined arena.
- Automatic fire targets the closest red enemy.
- Enemies chase the player; contact costs 10 HP with 0.7 seconds between hits.
- Every 15 seconds, the recorded positions and shot times/origins/directions become a blue echo.
- Echoes loop their own recordings and deal the same damage as the player. They do not retarget recorded shots or take damage.
- At four echoes, the next recording replaces the oldest echo.
- R: restart at any time, including after game over.

## Structure

- scenes/main.tscn: main scene, CharacterBody2D player and HUD instance.
- scripts/: arena/combat/recording coordinator, player, enemy and echo behavior.
- ui/: HUD scene and script.
- tests/prototype_smoke.gd: headless behavior checks.

## Verification

With your Godot executable:

```text
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/prototype_smoke.gd
godot --headless --path . --quit-after 180
```

Validated using Godot 4.7.2: project import, all scripts/scenes loaded, main-scene runtime,
input/movement, arena bounds, five recording cycles, four-echo limit, replay fire/loop and game over.
Headless checks do not validate GPU rendering or visual appearance.

No external assets, networking, advertising or purchases are used by gameplay.

## Production work

See docs/PRODUCTION_PLAN.md for scope, milestones and progress. ESC or PAUSE opens the pause menu; RESUME continues and RESTART starts a new run. Losing app focus pauses automatically. Run tests/session_smoke.gd headlessly to verify touch and session controls.

Touch control is now invisible and dynamic: touch and drag anywhere inside the arena below the HUD. No joystick graphic appears and no playfield space is reserved.

The menu separates character and map selection. Each screen uses visual thumbnails: 10 character cards (five archetypes with male/female silhouettes) and 10 map cards showing their palette, motif, and 10-level/10-boss structure.

The meta layer now includes five equipment slots, five rarity tiers, slot shards, shared upgrade cores, gold, missions, free chest cooldowns and paid-with-gold chest variants. Real-money payment is intentionally not connected; the shop marks that integration point for a future provider decision.


The M1 run lasts 5 minutes. Runners enter after 20 seconds; chargers after 60 seconds telegraph before dashing. Every 30 seconds choose fire rate, movement speed or healing. Survive to 05:00 to win. Run tests/run_smoke.gd for progression checks; this test bypasses player damage and is not a balance test.


Pause now includes a short gameplay guide, Mute sound and Reduce effects. These settings currently apply to the current run only. Seven synthesized cues require no external assets. Headless tests verify wiring and cleanup, not perceived audio/visual quality.

