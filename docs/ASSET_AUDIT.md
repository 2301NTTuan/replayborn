# Replayborn asset audit

Audit date: 2026-09-13

## Runtime-used assets

2026-09-14: Neon Ruins now uses `assets/original_v1/enemy_roster_v2.png` for its 15 regular enemy types. Generation prompt, hash and runtime animation details are recorded in `ENEMY_ROSTER_V2.md`. Existing crawler art remains for legacy enemy definitions; boss art is unchanged.

| Runtime group | Paths | Evidence of use | Provenance status |
| --- | --- | --- | --- |
| Astria player and Echo | `assets/original_v1/astria_run_v1.png`, `astria_idle_v1.png`, `astria_sprite_frames.tres` | `ui/menu.gd` and `scripts/visuals/art_bridge.gd` | Generated records are documented in `ASSET_PROVENANCE.md`. |
| Enemy and boss visuals | `assets/original_v1/rift_crawler_run_v1.png`, `archive_colossus_run_v1.png` | `scripts/visuals/art_bridge.gd:get_anime_enemy_frames()` | Generated records are documented in `ASSET_PROVENANCE.md`. |
| Projectiles | Procedural drawing in `scripts/visuals/art_bridge.gd` | `draw_projectiles()` | Original code; no third-party bitmap is loaded. |
| Gameplay music loop | `assets/audio/replayborn_tense_future_loop.ogg` | `scripts/sound_bank.gd` | Tense Future Loop by gmason, published on OpenGameArt under CC0: https://opengameart.org/content/tense-future-loop. SHA-256 `6F1C60A9C70EAE16A563B5713897D8A5B0F4FFDC56CEB38811D370732D3876F5`. |

## Removed as unused

The following files had no remaining runtime reference after the procedural arena renderer was installed and were removed from the project:

- `assets/replayborn/maps/**/floor_tile.png`, `border_tile.png`, and `prop_01.png`–`prop_04.png` (the arena is now drawn by `scripts/visuals/arena_map.gd`).
- `assets/replayborn/vfx/**`.
- `assets/replayborn/upgrades/**`.
- `assets/replayborn/ui/**`.
- `assets/replayborn/weapons/**/emitter.png` and `icon.png`.

The original source archive remains as `REPLAYBORN_ASSET_PACK_V1.zip`. Its SHA-256 is `1F532C1BB1EAFAAAE5D788CB8393B46C978F90471949350207C31345BC0D90FE`. The archive contains `ASSET_MANIFEST.json`, `PACK_STATS.json`, and `HUONG_DAN_TICH_HOP.md`, but no license or copyright grant. Those files prove the pack's contents and origin in this repository; they do not prove commercial usage rights.

## Excluded from release

`assets/anime_preview/**` and `assets/replayborn/**` are excluded by both export presets. They are retained as non-runtime source/preview material, not deleted, because no deletion audit was authorized. Existing thumbnail scripts are no longer preloaded by the release menu.

## Release gate

The generated `original_v1` files have a recorded generation trail. The remaining pack-derived assets must receive a license grant from their creator or be replaced with newly generated/procedural assets before commercial release. No asset is labelled commercially cleared based only on appearance.
