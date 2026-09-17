# Replayborn architecture

`scripts/main.gd` coordinates run state and delegates focused systems:

- `core/time_circuit.gd`: sampled trail, expiry, intersection, polygon validation, snapshot selection and lightweight drawing.
- `core/circuit_finisher.gd`: data-driven Pulse/Scatter/Lance finisher resolution.
- `core/combat.gd`: capped friendly/hostile projectiles, swept collision, zones and effects.
- `core/director.gd`: resource-driven level, wave, boss and transition progression.
- `core/profile.gd`: schema migration, validation, unlock/meta economy and atomic persistence.
- `player.gd` / `enemy.gd`: actor movement, hurt state, telegraphs and boss circuit reactions.
- `ui/hud.gd` / `ui/menu.gd`: presentation and input forwarding; economy and gameplay decisions remain in profile/game systems.

Gameplay timers advance only in physics processing while state is `PLAYING`. Pause, tutorial and upgrade states therefore cannot record trail or progress combat. Runtime arrays are capped and queued nodes are removed from owner arrays before later access.

Data resources under `data/weapons`, `data/enemies`, `data/upgrades` and `data/levels` define content parameters. User-facing copy is routed through `core/words.gd`.
