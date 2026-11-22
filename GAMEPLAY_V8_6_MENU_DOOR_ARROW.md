# Satria Gambut V8.6 — Animated Outpost Door, Modern Menu & Triangular Navigation Arrow

## Current implementation — SAFE AUTOMATIC DOOR (replaces all earlier door instructions)

The manual F-key door interaction has been **removed**. The outpost door now opens and closes automatically with safety behavior:

- **Open:** player approaches within 5.0 metres on either side of the doorway, or is inside the outpost
- **Hold open:** player is within 8.0 metres of the doorway **or anywhere inside the building**, including the threshold
- **Close:** only after the player is outside, farther than 8.0 metres, continuously for at least 2.0 seconds
- **Reopen:** if the player returns within the protected safety radius while the door is closing, the closing tween reverses
- **Animation:** a gently eased 1.10-second swing using sine ease-in/out
- **Collision:** solid only when fully shut. The moving leaf has collision disabled during opening and closing; after opening there is no hidden blocker. The closed leaf is physically solid.
- **Prompt:** optional near-door indicator (no F-key request). No manual open/close hotkey remains.

### Updated test checklist
- [ ] Walk toward door in FPS and TPP, wait for automatic opening, enter through the center.
- [ ] Stand still in the threshold and inside the room: door stays open indefinitely.
- [ ] Leave room but remain near the outer doorway: door stays open.
- [ ] Move more than 8m away and wait 2s: door closes smoothly.
- [ ] Try to walk through it fully closed: leaf collision stops the player.
- [ ] Approach while it closes: it immediately reopens and does not strike/push the player.
- [ ] Check no prompt refers to F, and other controls still work.



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


## V8.6 cinematic main menu (latest visual extension)

**Reference:** the user's game-menu screenshot and the newly drafted Satria Gambut cinematic concept. The result is a Godot-native, offline menu, not a direct screenshot overlay.

### Implementation
- New original procedural vector artwork `ui/main_menu/cinematic_peatland_bg.svg`: dusk peat forest, smoky sky, wetland, burning patches, ranger watchtower, rescue-person silhouette, depth layers and vignette.
- New `ui/main_menu/cinematic_main_menu.gd` places the original JPG Satria Gambut logo into a framed focal area, adds a large title and subtitle, and creates cinematic left-side operation buttons with selected/hover styling.
- Right-side `ScenarioIntelCard` reuses the **same real LevelOption and LevelDescLabel scene nodes**, with a preview thumbnail and live weather briefing.
- All seven menu actions are preserved: Start, Select Scenario, Guide/SOP, Wardrobe, Settings, Credits, Quit. Guide/Settings/Credits/Wardrobe retain their previous dialogs and existing callbacks.
- Cinematic menu is placed behind the existing modal backdrop, so settings and guidance screens still open as before.
- The original `assets/textures/satria_gambut_logo.jpg` file is **unchanged**. It is re-presented with a premium spotlight frame and additional title typography.
- UI scales as a 1280×720 reference stage and centers within larger/smaller windows, with a full-viewport illustration background.
- No copyrighted Horizon artwork, logo, or title screen is bundled. This is original Satria Gambut artwork inspired by the general cinematic menu atmosphere.

### Cinematic menu checklist
1. [ ] Import branch into Godot; inspect the debugger for new `CinematicMainMenu` or SVG texture errors.
2. [ ] Start project: see full-screen forest cinematic background; original Satria Gambut logo and prominent game title at top.
3. [ ] All seven operation menu entries appear on the left, first entry highlighted; hover changes selection.
4. [ ] Select scenario from card at right; the level information updates and **Mulai Operasi** launches the level selected.
5. [ ] Open/close Guide/SOP, Settings, Credits and Wardrobe; saved values remain intact.
6. [ ] Verify mouse navigation and keyboard up/down/Enter/Esc; F11 fullscreen continues to work.
7. [ ] Test 1280×720, window maximize, fullscreen and return from simulation to menu.
8. [ ] Ensure SVG artwork imported correctly on Godot 4.7.2 GL Compatibility. If it fails to import on the user's PC, inspect import log and keep the old menu version safe.
9. [ ] Check the latest automatic safe posko door still opens and holds open when the player is in/near the station.

**Runtime status:** Source-level checks passed; Godot editor/runtime tests were not possible in the authoring environment.
