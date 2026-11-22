# Satria Gambut V8.2 — Tactical Radar & FPS / TPP Camera

This branch builds on V8.1 voluntary-stop evaluation and retains V1–V8 features.

## Camera modes
- Press **V** during active FPS gameplay to toggle between first-person (FPS/FPP) and third-person (TPP).
- TPP uses a **SpringArm3D** with a camera placed about 4.3 m behind the character. It retracts near world geometry to reduce clipping.
- The player's body is shown as a **lightweight, procedurally assembled firefighter avatar**, with helmet, reflective strip, backpack and basic walking/sprinting limb swing. It is a placeholder stylized avatar, not a fully rigged animation or imported human character.
- The original physical `CharacterBody3D` and FPS ray remain in place; tool targeting in TPP uses the screen center against the ground plane, limited to the player's original 8m action reach.
- First-person tools are hidden in TPP and restored when switching back. Cinematic F10 also respects TPP tool visibility.
- Press Esc to pause as before; V toggles only during the active gameplay phase.

## Tactical map and modern minimap
- Minimap now has an atmospheric dark green tactical theme, subtle surveyed grid lines, a facing-direction triangle, rings for the active hotspots, water sources, and protected observation station.
- **M** opens a full-size live tactical view. **M** or **Esc** closes it.
- Surface hotspots show in both modes; underground-only embers stay hidden until Thermal mode is active.
- The player's actions and movement stop while the large map is open to prevent accidental spraying or digging. Simulation weather / fire continues in the background.
- This is a forest survey map inspired by modern game HUDs, not a copy of any particular game asset or real street map.

## Testing checklist
- [ ] Import project in Godot 4.x; no parser errors in `FirefighterAvatar3D`, `PlayerController3D`, `HUD`, `CinematicCapture`.
- [ ] Start Level 1, press V several times. Observe FPS ↔ TPP with visible firefighter avatar and camera collision against nearby tree.
- [ ] Move WASD, sprint and jump in TPP; verify model follows player body, head pitch follows mouse and camera does not pass freely through large physical objects.
- [ ] Try spray, firebreak and peat injection from both FPS and TPP. TPP uses the center reticle and maximum 8m target distance; check accuracy.
- [ ] Switch TPP → F10 Cinematic → F10 exit → FPS; hand-held tools should appear only in FPS.
- [ ] Verify F12 screenshot from both perspectives.
- [ ] Watch the radar update as hotspots spread; station and sumur marks stay distinct.
- [ ] Press M to open full tactical map; press M or Esc to close. Ensure player cannot walk or use water while viewing the expanded map.
- [ ] Confirm first-person cursor returns after closing map. Press Esc again and pause menu should still open.
- [ ] Verify pause, abandon/evaluate, Victory/Defeat, analytics export, F9 storm preview, F11 fullscreen and Windows resize.
- [ ] Compare Low / Medium / High graphics on all three levels and test 1280×720 and 1920×1080.
- [ ] Record actual Godot FPS and any script errors before merging to main.

## Known limitations
- The firefighter avatar is made of primitive meshes; for a polished release it should be replaced with a rigged character and animations.
- The TPP crosshair aims at the ground plane and remains constrained to an ~8-meter interaction range; it is not a bullet/weapon ballistic or full over-shoulder cover system.
- The map is a flat tactical visualization of existing 16x16 cells, not a road network, terrain GPS map, or rotating satellite map.
- Map open does not pause the underlying fire simulation.
- Code has been added to the branch, but Godot runtime testing must be performed locally before treating V8.2 as stable.
