# Satria Gambut — Gameplay Enhancement (Experimental)

Branch: `feature/gameplay-enhancement-v1`. This is an experimental set of gameplay changes, **not yet validated in Godot runtime**. Please do not merge into `main` until the verification below succeeds.

## Implemented
- Mission panel showing active hotspots, protection status, mission progress, weather, and remaining water reserves.
- Tutorial prompts for spray, thermal vision, firebreak, and peat injection.
- Victory scoring (0–100) with bronze / silver / gold medals and an added end-screen summary.
- Dynamic weather fronts every 40 seconds in the active phase, adjusting wind, temperature, rainfall, per-cell PFVI, moisture, and spread probability.
- Finite water reserves for each well, gradual hydration of nearby cells, and consumption through both tank refills and soil hydration.
- Station protection objective at grid coordinate (8,1); station destruction causes defeat.
- Visible minimap station marker and surface hotspot outlines, underground hotspot outlines only in thermal mode.
- More responsive fire/smoke lighting, intensity-scaled particles, wind-tilted smoke, rain-tinted fog, and emergency notifications.
- Headless smoke test script and CPU tick benchmark over all 3 levels.

## How to test locally
1. Switch to the feature branch (`git fetch origin && git switch feature/gameplay-enhancement-v1`), or download ZIP of the branch from GitHub.
2. Open `project.godot` with the configured Godot 4.x version, let assets import, press F5.
3. Run smoke tests in a terminal with the Godot executable:

```powershell
& "C:\path\to\Godot_v4.x-stable_win64_console.exe" --headless --path . --script res://tests/gameplay_smoke_test.gd
```

4. Record the number of PASS/FAIL messages and benchmark timings for all 3 levels. The script does **not** measure rendered FPS.
5. Check manual acceptance cases below and record evidence before merging.

## Manual acceptance checklist
- [ ] Launch main menu and select all three levels; transitions Planning -> FPS -> Victory -> next level/retry work.
- [ ] Mission panel appears only in FPS. No HUD or pause overlap on 1280x720 and 1920x1080.
- [ ] Tutorial steps advance when each matching tool is used; thermal toggle works both via Tab and HUD.
- [ ] Weather changes after 40 seconds of active play and warnings, fog, HUD, and fire spread respond.
- [ ] Place / remove wells in Planning; confirm per-well reserve is finite and no infinite refills.
- [ ] Rescue the observation station by suppressing surrounding fires; deliberately ignite its grid cell to confirm defeat.
- [ ] Clear all surface and underground hotspots; inspect score and medal after victory.
- [ ] Check minimap hotspot markers with thermal mode on/off; smoke and flame graphics on Low, Medium, High.
- [ ] Test at least one integrated-GPU laptop. Record FPS, VRAM, CPU, draw calls, and memory using Godot Debugger/Profiler.
- [ ] Check no parser errors, invalid node paths, missing assets, or invalid signal arguments in Godot Output.

## Known limitations
- The tutorial reports steps, but currently does not pause gameplay or spawn guaranteed safe practice hotspots.
- The progress bar measures relative active hotspot count against starting count; newly spreading fires can reduce progress. It is an **active-threat progress indicator**, not a cumulative percentage of fire extinguished.
- Mission scoring is game-design heuristic and carbon risk values are simplified, not a validated real-world scientific assessment.
- Station protection uses a specific grid cell, not collision of an independently destructible 3D station prop.
- Weather fronts are random; benchmark results are variable until deterministic random seeds are introduced.
- Smoke tests validate simulation invariants, not GPU rendering or actual laptop performance.
