# Neon Ruins enemy roster

Implemented 2026-09-14. Three unique regular enemies per level. The existing five-boss progression follows each wave. Later waves inherit the director's health/damage scaling.

| Level | Enemy | Ability |
| --- | --- | --- |
| 1 | Ruby Beetle | Short-range crystal cone |
| 1 | Neon Jackal | Quick leap toward a locked target |
| 1 | Amber Ram | Long charge with longer windup |
| 2 | Void Spitter | Three-projectile acid fan; keeps distance |
| 2 | Blade Mantis | Circles its target and throws paired blades |
| 2 | Needle Walker | Long windup, fast single needle; retreats at close range |
| 3 | Forge Crab | Wide, short-range pincer sweep |
| 3 | Storm Jelly | Eight-way electrical pulse |
| 3 | Rift Scorpion | Aimed sting plus rear fan |
| 4 | Sword Automaton | Dash with frontal slash |
| 4 | Spore Carrier | Slow, lingering six-way spores |
| 4 | Blood Harpy | Angled dive and feather spread |
| 5 | Ghost Centipede | Rush with four-way spectral projectiles |
| 5 | Prism Golem | Three projectiles along each axis of a rotating cross |
| 5 | Crown Serpent | Frontal venom fan and ten-way crown |

Attacks lock aim during a visible 0.45–0.65 second windup. All projectiles use swept collision and the existing hostile projectile cap. Corpses stop attacking, award rewards once, and remain 0.42 seconds for their death animation.

## Animation implementation

Each creature has six drawn key poses: idle, two walking poses, anticipation, release, collapse. Runtime states: idle, run, windup, attack, hurt and death. Hurt reuses the anticipation pose with a red flash. Death transitions to collapse and fades. This is a compact sprite animation set, not a skeletal rig or eight-direction animation set. Left-facing sprites are mirrored.

## Asset generation record

- Tool: built-in imagegen; no external reference images supplied.
- Atlas: `assets/original_v1/enemy_roster_v2.png` (793 x 1983, RGBA).
- SHA-256: `084DC7D363CD4458B5B17A879227D15B4FD19E406629EB5316BE789DF70C3E1D`.
- Original output: `C:/Users/tuann/.codex/generated_images/01a099e0-6e94-7a30-9c38-29e3b7d9ce5e/exec-c9754c9c-588c-4ff1-ad13-e8b10e0ac28b.png`.
- Raw output preserved unchanged; atlas regions are selected at runtime. Actual row heights differ from requested grid, so explicit row boundaries are used.
- This records generation provenance, not a guarantee of legal clearance or exclusivity.

### Generation prompt

Create a production game sprite atlas PNG with TRUE TRANSPARENT background for an original anime sci-fi top-down mobile survival game Replayborn. No existing franchise characters or logos. EXACT GRID 6 columns x 15 rows, equal cells, output tall high resolution. Each row contains six animation poses of ONE distinct monster, facing right three-quarter view, feet aligned on same baseline, same scale, generous padding no overlap. Columns: idle, walking left legs forward, walking right legs forward, attack anticipation, attack release, collapsing death. No text, grid lines, labels, shadows outside sprite. 15 rows top to bottom: 1 red six-legged crystal beetle; 2 cyan lean cyber jackal; 3 amber armored rhino insect; 4 purple hooded floating alien spitter; 5 lime winged blade mantis; 6 white four-legged needle turret beast; 7 copper heavy crab with massive pincers; 8 blue electric jellyfish; 9 magenta long-tailed scorpion; 10 black and gold biped sword automaton; 11 mint fungal alien with mushroom artillery shell; 12 crimson bat-winged harpy; 13 ivory spectral centipede; 14 violet prism golem with floating hands; 15 dark red crowned armored serpent. Each is anatomically distinct, attractive crisp cel shaded anime game art with strong dark outlines, visible articulated limbs in different walk and attack poses, readable at small size. Exactly 90 isolated sprites total. Transparent background essential, do not paint checkerboard. All cells aligned to uniform 6x15 atlas grid.
