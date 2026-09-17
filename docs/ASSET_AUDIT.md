# Replayborn asset audit

Audit date: 2026-09-17

## Runtime-used assets

The release runtime contains five base enemy families. They share the crawler atlas with distinct color, scale and movement treatment; each boss uses a separate atlas. `enemy_roster_v2.png` and its additional concept rows are not spawned by the release director.

| Runtime group | Paths | Evidence of use | Provenance status |
| --- | --- | --- | --- |
| Astria player | `assets/original_v1/astria_run_v1.png`, `astria_idle_v1.png`, `astria_sprite_frames.tres` | `ui/menu.gd` and `scripts/visuals/art_bridge.gd` | Generated records are documented in `ASSET_PROVENANCE.md`. |
| Enemy and boss visuals | `assets/original_v1/rift_crawler_run_v1.png`, `assets/original_v1/bosses/boss_*_v2.png` | `scripts/visuals/art_bridge.gd` | Generated records are documented in `ASSET_PROVENANCE.md` and boss/enemy art notes. |
| Projectiles | Procedural drawing in `scripts/visuals/art_bridge.gd` | `draw_projectiles()` | Original code; no third-party bitmap is loaded. |
| Gameplay music loop | `assets/audio/replayborn_tense_future_loop.ogg` | `scripts/sound_bank.gd` | Tense Future Loop by gmason, published on OpenGameArt under CC0: https://opengameart.org/content/tense-future-loop. SHA-256 `6F1C60A9C70EAE16A563B5713897D8A5B0F4FFDC56CEB38811D370732D3876F5`. |

## Retained source/preview material

The following pack-derived groups have no release-runtime reference and are excluded by export presets. They remain in the repository as source/preview material:

- `assets/replayborn/maps/**/floor_tile.png`, `border_tile.png`, and `prop_01.png`–`prop_04.png` (the arena is now drawn by `scripts/visuals/arena_map.gd`).
- `assets/replayborn/vfx/**`.
- `assets/replayborn/upgrades/**`.
- `assets/replayborn/ui/**`.
- `assets/replayborn/weapons/**/emitter.png` and `icon.png`.

The original source archive remains as `REPLAYBORN_ASSET_PACK_V1.zip`. Its SHA-256 is `1F532C1BB1EAFAAAE5D788CB8393B46C978F90471949350207C31345BC0D90FE`. The archive contains metadata but no license or copyright grant. Those files prove contents and repository history, not commercial usage rights.

## Excluded from release

`assets/anime_preview/**`, `assets/replayborn/**`, the unused 15-row roster atlas/data, and retired secondary-upgrade data are excluded by all export presets. They are retained as non-runtime source/preview material. Obsolete character/map thumbnail scripts were removed after dependency search confirmed no references.

The former replay-character scripts and upgrade resource were removed after `rg` confirmed that no scene, resource or runtime script referenced them. Circuit/projectile presentation is procedural; it adds no new third-party bitmap dependency.

## Release gate

The generated `original_v1` files have a recorded generation trail. The font license/upstream binary and generated-art similarity still require owner/legal verification. Pack-derived assets must remain excluded unless a license grant is obtained. No asset is labelled commercially cleared based only on appearance.
