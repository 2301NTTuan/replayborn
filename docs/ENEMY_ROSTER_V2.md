# Neon Ruins enemy roster

The playable vertical slice uses five readable base families across all five levels. Each level changes the mix, cadence, elite chance, health scaling, and boss rather than introducing cosmetic duplicates.

| Family | Combat role | Readability cue |
| --- | --- | --- |
| Chaser | Direct pursuit | Pink, steady approach |
| Runner | Fast flanker | Cyan, light silhouette |
| Charger | Telegraph then rush | Amber, heavy silhouette |
| Shooter | Ranged pressure | Purple, keeps distance |
| Orbiter | Curved area denial | Green, circular movement |

Two modifiers can appear in the second half of a level:

- **Armored:** amber outline and substantially increased health.
- **Volatile:** magenta outline, faster movement, and a delayed hazard on death.

Each family uses idle, run, windup, attack, hurt, and death animation states. Attacks telegraph before release. Dead enemies stop attacking, award rewards once, and remain briefly for the death animation.

The five bosses use separate atlases and behaviors: Gate Warden, Vector Hunter, Array Sentinel, Chrono Reaper, and Archive Archon. Closing a Time Circuit creates a boss-specific interrupt or vulnerability window; boss time-lock duration is reduced.

## Asset record

- Retained concept atlas (excluded from release export): `assets/original_v1/enemy_roster_v2.png`.
- SHA-256: `084DC7D363CD4458B5B17A879227D15B4FD19E406629EB5316BE789DF70C3E1D`.
- Generated with the built-in image generator without external reference images.
- This provenance record is not a guarantee of legal clearance or exclusivity.

The atlas also contains unused concept rows. They are deliberately not separate runtime families in this release.
