# Visual & Combat Overhaul progress

Updated: 2026-09-17. This document records implemented work only; Android/iOS device export and testing remain out of scope for this pass.

## Phase 0 — baseline

- [x] Audited Git, project configuration, scenes, gameplay resources, assets, tests, and CI.
- [x] Confirmed `main` is clean and matches `origin/main` at `4d48ecf` before this overhaul.
- [x] Confirmed the project contains 15 named regular-enemy resources and five boss resources.
- [x] Re-run full validation after the completed roster/combat slice.

## Phase 1 — enemy roster and level identity

- [x] Replace fragile enemy-array indices with stable resource IDs.
- [x] Add all 15 regular families to the runtime catalog and distribute them across five levels.
- [x] Give each level an explicit map theme/resource and roster validation.
- [x] Validate unique IDs, all roster use, and no bosses in regular pools.

## Phase 2 — player and gun feel

- [x] Chrono Shift, cooldown UI, invulnerability, perfect dodge, Temporal Cut.
- [x] Target stickiness, recoil, impact, knockback, and audio/VFX feedback.

## Phase 3 — circuit, combo, and Overdrive

- [x] Three-state Circuit Sequence with impact-timed damage.
- [x] Chrono Combo and Overdrive.

## Phase 4 — map, HUD, and UI

- [x] Per-level visual motifs and level-specific palette presentation.
- [x] Combat HUD: Chrono Shift, Combo/Overdrive, and live boss-health bar.
- [x] Run report: max combo and total damage dealt.
- [x] Upgrade archetype presentation: Offense, Circuit, Survival, Weapon; color and stack progress.

## Phase 5 — rewards, bosses, and audio

- [x] Boss relic/evolution pickup loop with three rotating run modifiers and result reporting.
- [x] Boss alert audio and impact/knockback polish.

## Phase 6 — hardening

- [x] Expanded automated validation, in-run debug overlay, and benchmark probe (`tools/stress_probe.gd`).
- [x] Asset provenance manifest reviewed and retained in `docs/ASSET_PROVENANCE.md`.

## Files changed in this pass

- `scripts/data/catalog.gd`, `scripts/data/level_data.gd`, and all five level resources: stable enemy and map IDs.
- `data/enemies/*.tres`, `scripts/data/enemy_data.gd`: fifteen runtime enemy families with explicit behavior metadata.
- `scripts/player.gd`, `scripts/main.gd`, `scripts/core/time_circuit.gd`, `scripts/core/combat.gd`, `scripts/core/circuit_finisher.gd`, `scripts/sound_bank.gd`: Chrono Shift, Temporal Cut, perfect dodge, combo, and Overdrive.
- `ui/hud.gd`, `scripts/core/words.gd`, `project.godot`: Shift button, combat meters, localization, and Space binding.
- `tests/enemy_roster_smoke.gd`, `tests/chrono_shift_smoke.gd`, validation scripts and CI workflow: roster and Shift contracts.

## Latest tests

- Baseline before the overhaul: `tools/validate.ps1` passed in the preceding vertical-slice delivery.
- Godot editor parse/import: PASS after the Chrono Shift/UI work.
- Full local validation: PASS — resource validation (142 files), Time Circuit, Circuit Finisher, Chrono Shift, prototype, session, tutorial, run, roster, effect lifecycle, HUD layout, and menu flow smoke tests.
- Final polish regression: Godot parse/import plus prototype, Circuit Finisher, Chrono Shift, and session smoke tests PASS.

## Known constraints

- Generated art and Cascadia Code license provenance still require human/legal release review; no asset is marked commercially cleared by this document.
- APK export, device testing, signing, and store submission are intentionally not run.
