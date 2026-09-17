# Replayborn release checklist

## Automated

- [ ] Clean clone imports with Godot 4.7.2.
- [x] Resource validation and all smoke tests pass locally on Godot 4.7.2.
- [x] Stress probe records median/p95/max without leaks or unbounded arrays.
- [x] Accelerated balance probe completes all three weapons in the 8–12 minute target.
- [x] Main scene runs headless without parser/runtime errors.
- [ ] Export presets produce unsigned ARM64 AAB and debug APK with Internet disabled.

## Assets and legal

- [ ] `assets/anime_preview/**` and `assets/replayborn/**` remain excluded from export.
- [ ] Verify CC0 music source/hash and Cascadia Code redistribution license.
- [ ] Conduct external similarity/trademark review for generated `original_v1` art.
- [ ] Keep provenance records and third-party notices with the release archive.

## Manual Android work

- [ ] Test touch release, pause/focus/Back, safe area and portrait ratios on devices.
- [ ] Play complete Pulse/Scatter/Lance runs and tune 8–12 minute balance.
- [ ] Verify sustained frame pacing, heat, memory and audio clipping.
- [ ] Create/manage release keystore outside Git and configure signing locally.
- [ ] Complete Play Console listing, closed test and store compliance forms.
