# Satria Gambut V8.6 — Animated Outpost Door, Modern Menu & Triangular Navigation Arrow

## Door revision — manual interaction (latest V8.6 update)

**This section overrides the earlier automatic-door descriptions below.** The door is now **manual**.

- Approach within **3.8 m** of the outpost door (either side, FPS or TPP).
- On-screen prompt appears: **[F] BUKA PINTU** (closed), **PINTU BERGERAK...** (animating), or **[F] TUTUP PINTU** (open).
- Press **F** to open. Wait approximately **0.85 seconds** for the door to finish swinging; then walk through.
- Press **F** again while nearby to close. The entrance becomes solid again. The door refuses to close while the player is standing across the threshold, avoiding a collision trap.
- **No automatic open/close based on walking proximity.**
- Removed the redundant invisible `ClosedDoorwayGate` collider that could leave the apparently open doorway blocked. Closed-door collision is provided by the door's own `AnimatableBody3D` leaf; its collision shape becomes inactive when the open animation finishes, and reactivates before closing.
- Other hotkeys are unchanged (E still refills wells, H navigation, V FPS/TPP).

### Manual regression test
1. [ ] With the door **closed**, walk into it before pressing F: player must be blocked.
2. [ ] Approach, confirm prompt `[F] BUKA PINTU`, press F: door should swing visibly.
3. [ ] After the animation, walk through the exact center of the opening: **no invisible wall**.
4. [ ] Step back near the entrance while open; press F: door should close and again block entry.
5. [ ] Attempt to close while standing in the threshold: should show a gentle reminder and not push or trap the character.
6. [ ] Try the interaction from both the inside and the outside of the outpost, in FPS and TPP.
7. [ ] Check all previous menu, navigation, audio, and mission mechanics still work.


Base: `feature/modern-hud-smart-navigation-v8-5` (user-confirmed working after the AudioManager typed Array fix).

## 1. Posko: animated opening and closing door
- Replaces the permanently open decorative door panel with an **automated hinged door** at the existing outpost entrance.
- The door has its own **AnimatableBody3D collider** and physically swings inward on a hinge using a 0.85-second cubic ease tween.
- Opens automatically within **4.2 m** of the doorway and closes only after the player has moved **at least 6.3 m away**, avoiding rapid open/close oscillation around one distance.
- Player can enter and exit in FPS and TPP, no new hotkey to remember.
- Existing outpost furniture, safety lamp, layout, other walls and forest exclusion remain unchanged.
- Decorative door latch/stripe and `PINTU OTOMATIS` signage signal the interaction.
- The building has no persistent door-open state across level reloads.

## 2. Menu overhaul — original logo preserved
- **No edits** to `assets/textures/satria_gambut_logo.jpg`, `LogoTexture` path, scene transitions, or existing game settings.
- Dark green/cyan rescue-operations aesthetic, amber accent for title, rounded elevated cards, subtle borders and hover/pressed states on buttons.
- Improved **level scenario card**, mission start action, navigation buttons, compact labels, and responsive spacing at 1280×720 / fullscreen.
- **Guide, Settings and Credits panels** now share a consistent premium style with improved typography, button hierarchy, styled sliders/dropdowns and darker backdrop.
- The existing **outfit wardrobe dialog** receives the new panel and dropdown style as well.
- A small entrance fade makes the main menu feel less static without changing its content.
- Every action still uses the original scene wiring and data.

## 3. True triangular guide arrowhead
- Replaces the old `PrismMesh` with a custom `ArrayMesh` **triangle** at the front of the floating FPS/TPP arrow.
- The arrow keeps the slender shaft, pulsing motion, per-destination color and user-controlled show/hide behavior.
- Navigation mode selection H, map target route and all game logic are unchanged.

## Local playtest
1. [ ] Download and extract V8.6 as a **new folder** (keep working V8.5).
2. [ ] Import `project.godot` using Godot 4.7.2; check debugger for parse errors.
3. [ ] Open main menu and verify the **original Satria Gambut logo** remains unmodified and visible.
4. [ ] Test level selection, Start, Guide, Settings, Credits, Wardrobe and Quit; confirm button hover/focus, modal close and saved settings function.
5. [ ] Test at 1280×720, maximized and fullscreen to catch any clipped buttons/modal text.
6. [ ] Start Level 1, enter FPS/TPP. Walk toward the outpost entrance; the door should smoothly open **before** reaching it.
7. [ ] Walk inside, near the jamb and back outside. The door should stay open while close; it closes once you move clear.
8. [ ] Test whether the rotating door collider blocks, traps or pushes the player. There must be no invisible collision left in the entrance.
9. [ ] Press H to select a navigation goal. The floating guide should have a visible **pointed triangular head**, not a rectangular prism.
10. [ ] Turn off the floating arrow in settings: radar guide remains active. Try FPS, TPP, Pause, large map and Cinematic mode.
11. [ ] Smoke-test music, wind/rain sound, all 3 tools, voluntary stop/evaluation and restart.
12. [ ] Test all 3 levels and confirm camera/Thermal/minimap features remain functional.

## Known limitations
- The automatically opening door uses procedural geometry, not a detailed imported animated model.
- Door proximity checks the single main player node; no NPC door access is implemented.
- The triangle is a flat mesh (double-sided shading), not a 3D extruded sculpted arrowhead.
- Source-level static checks passed, but **Godot editor/parser and Windows gameplay runtime tests are unavailable here**. Keep PR as draft until verified locally.
