# Replayborn game design

## Core loop

Astria moves, auto-fires, gathers enemies and draws a temporary memory trail. Crossing an older non-adjacent trail segment closes a Time Circuit. A valid circuit must exceed minimum age, perimeter and area; the captured target list is frozen at closure. The current weapon then performs one deterministic finisher. XP creates paused three-card upgrades. Each level ends with a boss; boss five wins the run.

## Circuit rules

- Trail: 6 seconds, sampled every 12 px, capped at 420 points.
- Closure: segment age 0.9 seconds, perimeter 280 px, area 20,000 px², cooldown 0.45 seconds.
- Small loops are quicker; larger valid loops gain capped area scaling.
- Boss circuit damage and lock duration are reduced, but every boss reacts through vulnerability/stagger state.
- Reduce Effects removes costly smoothing/glow without hiding the trail, snap cue or polygon outline.

## Weapons

- Pulse Blaster: fast single shot; circuit chains between nearby captured targets. Relay adds chains and Overload bursts at the final target.
- Scatter Cannon: slower three-pellet spread; circuit converges damage toward its centroid. Focus strengthens the center and Shrapnel marks finisher kills.
- Rift Lance: slow fast projectile with pierce; circuit damages the perimeter and collapses inward. Resonance adds a reduced second pulse and Collapse rewards edge catches.

## Content

Levels: Signal Gate / Gate Warden; Fractured Lane / Vector Hunter; Static Array / Array Sentinel; Orbit Vault / Chrono Reaper; Replay Core / Archive Archon.

Enemies: Chaser, Runner, Charger, Shooter and Orbiter. Armored elites trade speed for durability and amber outline. Volatile elites move faster, use magenta outline and leave an avoidable delayed hazard on death.

Upgrades: Power, Tempo, Stride, Vitality, Armor, Recovery; Long Memory, Wide Recall, Circuit Power, Time Lock, Safe Closure, Compression; Pulse Relay/Overload, Scatter Focus/Shrapnel, Lance Resonance/Collapse.
