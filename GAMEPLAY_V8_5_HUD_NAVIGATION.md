# Satria Gambut V8.5 — Modern Tactical HUD & Smart Navigation

**Base branch:** `fix/outpost-music-targeting-v8-4`. This preserves V8.4 outpost clearance, procedural background music, target-aligned FPS/TPP tools, and all earlier game upgrades.

## New HUD
- Water, weather, hotspot, map and cell-information panels use coordinated tactical styling: rounded corners, restrained highlights, colored borders, subtle drop shadows and legible type.
- Water is cyan, weather amber, active fire orange-red, radar green and cell analysis blue.
- Water bar has a dedicated modern fill/background style.
- MissionDirector card uses the same subdued tactical theme, styled progress bar and shorter labels for objective, climate and supply details.
- Existing UI positions, 1280×720 design baseline, controls, simulation and mission results remain unchanged.

## H navigation — one source of truth
- **H** now cycles `OFF → HOTSPOT → SUMUR AIR → POS PENGAMATAN → OFF`.
- The existing MissionDirector finds the closest relevant destination in the selected category; its hidden-ember rule is retained: underground-only embers are *not* disclosed until Thermal is active.
- The selected cell is sent via `EventBus.navigator_target_changed` to the two presentation components. The radar and floating arrow never independently select different destinations.
- Both small radar and large **M** map show a faint line to the selected goal, a smoothly moving chevron along the route and a pulsing destination ring.
- Radar guidance remains visible even if the on-screen/world arrow is disabled.

## Optional floating direction arrow
- A non-colliding, softly emissive 3D arrow floats below center of the active FPS or TPP camera, points horizontally towards the selected destination and gently bobs.
- Automatically hidden when H is OFF, there is no relevant target, player arrives, game pauses/ends, the M map opens or F10 cinematic mode is active.
- **Main Menu → Pengaturan** and **Esc → Pause** both have `Tampilkan panah panduan di depan pemain (FPS/TPP)` checkbox options.
- Preference is stored in `user://satria_gambut_guide.cfg` and persists between launches.
- H mode determines where to navigate; the checkbox independently determines only whether the floating arrow is shown.

## Test checklist (required before merge)
1. [ ] Download V8.5, import `project.godot`, inspect Godot parser errors.
2. [ ] Start Level 1 in FPS. Confirm modern HUD cards and readable mission panel without clipping at 1280×720.
3. [ ] Press H: hotspot destination appears in both radar and floating indicator. Press H again for a stocked well; again for station; again to turn OFF.
4. [ ] Move toward and away from the destination; check pulse, chevron, and floating arrow face the updated target. Ensure no marker is shown for nonexistent wells.
5. [ ] Press Tab to enable Thermal and verify hidden embers only appear while Thermal mode is active.
6. [ ] Press V to toggle TPP; floating direction arrow should remain near lower camera center without obscuring crosshair or tool spray.
7. [ ] During FPS/TPP gameplay, press Esc and uncheck the front-arrow option. Resume: radar guidance should remain, floating arrow should disappear. Re-check to restore it.
8. [ ] Return to Main Menu settings, change the checkbox, restart the game and confirm persistence.
9. [ ] Press M for expanded tactical map: the new animated guide line/ring should show, while the floating world arrow is hidden.
10. [ ] Press F10 for Cinematic Mode; no mission HUD or floating arrow should appear. Exit cinematic and verify they return appropriately.
11. [ ] Test planning, pause, voluntary stop/evaluation, success and failure transitions, plus F9 lightning, F11 fullscreen and F12 screenshot.
12. [ ] Test all 3 levels in 1280×720 and fullscreen, Low/Medium/High quality. Ensure the original V8.4 music and tool targeting still work.

### Notes and limitations
- The animated line on the radar is a **straight directional indicator**, not obstacle-avoiding pathfinding.
- The optional arrow is simple procedural geometry with camera-relative anchoring; it is not a commercial navigation mesh / GPS solution.
- All UI, map and arrow assets are authored in Godot; no additional downloads or Internet access required.
- No Godot runtime executable is available in this development environment; code-level integration was reviewed but actual parser and visual testing are still required.
