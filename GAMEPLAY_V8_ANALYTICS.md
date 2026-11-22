# Satria Gambut V8 — Mission Analytics & After-Action Reports

**Branch:** `feature/mission-analytics-v8`, based on V7. This is an experimental draft; V7 remains unchanged.

## Gameplay enhancements
- Automatically record mission snapshots during FPS play approximately every **5 seconds**, plus the mission's final state.
- Track active hotspots, hidden-only embers, safe/burned peat cells, water consumption, rainfall, wind speed, air temperature, emitted-carbon estimate, and observation station status.
- Track use of firebreaks, completed underground injections, thermal activation and spray-update ticks.
- At the existing **Victory / Defeat** screen, choose **GRAFIK PERKEMBANGAN MISI & EKSPOR DATA** to open an embedded mission analytics panel.
- Graph displays **two independent scale** trends: orange for active hotspots, blue for consumed water. Both share the time axis. Comparing line heights directly is not meaningful, because each series has its own y normalization.
- **SIMPAN CSV + JSON** exports complete snapshot rows and an accompanying summary of the mission to `user://mission_reports`.
- The mechanism does not alter physics, weather, mission success/failure, controls, cinematics, or game performance outside a small 5-second data sample.

## Export formats
- **CSV:** `time_s, hotspots, subsurface_only, burned_cells, safe_cells, water_used_l, wind_kmh, rainfall_mm, temperature_c, carbon_released_t, station_safe`.
- **JSON:** mission result, level, duration, score, medal, safety, water and carbon estimates, tool counts and the maximum observed hotspots.
- File names include level and date/time of mission start; records remain local to the player's computer.
- To access files in Godot, use **Project → Open User Data Folder → mission_reports** or read the absolute path printed to the **Output** panel.

## Testing checklist
- [ ] Import the V8 branch and verify no GDScript parser errors.
- [ ] Complete Level 1 and click the new analytics button on the evaluation screen.
- [ ] Confirm the orange hotspot series begins near the outbreak count and changes after suppression/spread.
- [ ] Verify blue water series increases as water is used; data are only recorded during ACTIVE_FPS.
- [ ] Export both formats; inspect CSV rows in spreadsheet software and JSON in a text editor.
- [ ] On victory and defeat, confirm the correct `result` and final metrics are exported.
- [ ] Open Pause during a mission; verify no false samples or play-time increments are recorded while paused.
- [ ] Retry / next level / return to menu; verify a new run creates fresh telemetry.
- [ ] Check Analytics panel does not block other buttons after closing.
- [ ] Confirm V7 F10/F12 screenshots, V6 lightning F9, F11 responsive window, mouselook and controls still work.
- [ ] Test 1280×720 and 1920×1080 resolutions; inspect chart legibility and panel height.
- [ ] Compare frame time before and after V8; data collection should have small overhead.

## Scientific and usability limitations
- Hotspot-count and carbon metrics reflect **game simulation assumptions** only. These are not measured field data.
- The reported `spray_ticks` count is the count of update events while spraying, **not** the number of distinct mouse clicks.
- Charts show normalized individual series; for precise values use exported CSV.
- Extremely short missions with fewer than two samples display a placeholder rather than a graph.
- Exports are initiated manually at the end of the mission; no network or external permissions are needed.
- **No Godot runtime or Windows verification was possible from the source-editing environment.** Keep the pull request in Draft until local testing succeeds.
