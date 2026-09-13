# Replayborn asset provenance

## Original V1 gameplay art

These assets were generated on 2026-09-13 for Replayborn using the built-in OpenAI image-generation tool. No source image, artist, game, franchise, logo, or character reference was supplied to the generation tool.

| Asset | Internal design | Source record | Constraints used |
| --- | --- | --- | --- |
| `assets/original_v1/astria_run_v1.png` | Astria, urban-techwear echo runner | `exec-175a0bf5-beda-4cb2-ac60-80125d126840.png` | No franchise/artist imitation; no white hair, staff, fantasy armor, gold filigree, logos, or known-character likeness. |
| `assets/original_v1/astria_idle_v1.png` | Astria, relaxed idle loop | `exec-0998064d-9cab-4655-b735-ad5c5b46693c.png` | Generated from the original Astria run sheet only; standing idle pose with no franchise or artist imitation. The output's baked checkerboard matte was removed through a deterministic border-connected transparency pass; no character pixels or design elements were added. |
| `assets/original_v1/rift_crawler_run_v1.png` | Rift Crawler, four-legged salvage machine | `exec-9f91beba-f570-476d-b067-536d5e833e96.png` | Non-humanoid machinery; no existing creature, franchise, or logo reference. |
| `assets/original_v1/archive_colossus_run_v1.png` | Archive Colossus, autonomous archive machine | `exec-6028ed48-283b-4906-957b-4d0232c2d4af.png` | Non-humanoid machinery; no existing character, franchise, artist, or logo reference. |

## Review status

The old `assets/anime_preview` collection is retired. Its resource definitions have been removed and it is not referenced by runtime code, so it must not ship. This collection is a recorded original-generation source for the current prototype. Before commercial release, conduct an external trademark and visual-similarity review for each finalized asset, retain the original generated files and this manifest, and obtain legal advice for the intended markets.
