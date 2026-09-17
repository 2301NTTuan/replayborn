# Replayborn production handoff

Current version: `0.5.0-alpha.1`. Open with Godot 4.7.2. The release slice is Astria in Neon Ruins only.

Core gameplay is Time Circuit: movement records a short sampled trail, crossing an old non-adjacent segment creates a validated polygon, captured enemies are snapshotted and time-locked, then Pulse/Scatter/Lance performs its data-driven finisher. The former multi-character replay mechanic and its files are removed.

Normal mode has five resource-driven levels and five bosses. Practice is a five-minute mechanics session. Profile schema 2 stores settings, currency, four meta upgrades, weapon unlocks and statistics with atomic temp-file writes and backup recovery. Legacy schema 1 profiles migrate on load.

Run validation:

```powershell
powershell -ExecutionPolicy Bypass -File tools/validate.ps1 -Godot 'C:\path\to\Godot_v4.7.2-stable_win64_console.exe'
```

Manual work still required before release: Android device touch/performance playtest, balance tuning from real runs, release keystore/signing, store listing and Play Console upload. Do not commit APK/AAB/EXE, `.godot`, keystores or secrets.
