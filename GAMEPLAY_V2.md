# Gameplay V2 — Tactical Navigator & Personal Best

This experimental branch builds on `feature/gameplay-enhancement-v1` (do not merge independently into `main`).

## New features
- Press **H** during a mission to cycle the navigation target: nearest visible hotspot → nearest well with water → observation station.
- The mission panel displays a relative direction arrow and straight-line distance in meters.
- Hidden subsurface embers are **not disclosed** by the navigator until Thermal X-Ray mode is active.
- Best mission results are stored locally in Godot's `user://satria_gambut_records.cfg`, independently for each level.
- Results prioritize higher score, then shorter time for tied scores.
- Main menu scenario descriptions show the current personal best; evaluation labels a new record.

## Manual acceptance tests
- [ ] Select each of the 3 levels; check no parser errors.
- [ ] Press H three times during FPS, confirm it cycles hotspot / well / station.
- [ ] Turn thermal OFF; only surface fires are tracked. Turn thermal ON to reveal underground-only threats.
- [ ] Follow arrow and verify direction updates when turning or walking. Confirm distance shrinks as player approaches.
- [ ] Drain a well; tracker no longer selects the empty source.
- [ ] Win a mission and verify NEW RECORD appears, then return to menu and read high score.
- [ ] Relaunch Godot and verify best score persists on the same machine.
- [ ] Retry with a lower score and verify prior best remains unchanged.
- [ ] Confirm the panel does not overlap other HUD areas on 1280×720, 1600×900 and 1920×1080.

## Notes
- Records are **device-local**, not cloud-synced.
- `user://` data is stored separately from the project folder and should not be committed.
- Marker uses straight-line navigation, not collision-aware pathfinding.
- CPU/GPU performance, Godot parser status, and device-level playtesting still require execution in the editor. No test pass is claimed by this change.
