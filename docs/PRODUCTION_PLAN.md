# Replayborn production plan

Updated 2026-09-17. Engine: Godot 4.7.2, GDScript, Mobile renderer.

## Current alpha scope

- One hero: Astria; one arena: Neon Ruins.
- Time Circuit is the core mechanic. No replay clones or multiple playable characters.
- Three main weapons with distinct auto-fire and circuit finishers.
- Five regular enemies, two elite modifiers, five levels and five bosses.
- Eighteen in-run upgrades; four ten-level meta upgrades.
- Offline VI/EN profile schema 2 with migration, atomic save and backup recovery.
- Android-first portrait export, ARM64, Internet permission disabled.

## Milestones

- M0 Audit/baseline: complete; pre-change resource and smoke suite passed.
- M1 Time Circuit: implemented with sampled/expiring trail, exact intersection, polygon validation, target snapshot, cooldown and tests.
- M2 Combat slice: Pulse, Scatter and Lance finishers; five enemies; Armored/Volatile elite behavior; eighteen-upgrade catalog.
- M3 Full run: five 95-second resource-driven waves, five bosses, short transitions, Practice and result statistics.
- M4 Meta/UI: armory, gameplay unlocks, meta upgrades, persisted settings and reset flow.
- M5 Art/audio/polish: procedural projectile/circuit visuals and existing provenance-recorded art/music retained. Physical-device feel and full audio content remain manual polish work.
- M6 Hardening: schema migration, expanded validation, CI, stress/balance tools and export configuration implemented. Device and signing work remains out of scope.

Latest accelerated probe (seeded simulation, not a human playtest): Pulse 10:30, Scatter 10:18 and Lance 10:16; all defeated five bosses. Stress p95 was 9.864 ms with 80 enemies and capped projectile pressure in Windows headless mode.

## Known release gates

Do not call the build production-ready until an Android device confirms touch feel, safe areas, thermals, sustained frame pacing and visual/audio readability. Legal review of generated art similarity and verification of the bundled font license remain release checklist items.
