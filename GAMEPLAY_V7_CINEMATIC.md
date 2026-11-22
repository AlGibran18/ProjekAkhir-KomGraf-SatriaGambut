# Satria Gambut V7 — Cinematic Mode & Gameplay Screenshots

V7 builds on the user-tested **V6 storm / wet terrain** branch and retains all its missions, weather, sound, lightning, F11/window resizing, controls and records.

## Added
- **F10** while playing FPS: toggle **Cinematic Mode**, hiding the normal HUD, tactical mission panel, crosshair, danger tint and the held tool model so that the environment can be appreciated without interface clutter.
- **WASD, mouse look, sprint and jump remain available** to move the camera into an attractive composition. Water/dig/injection actions are temporarily disabled to avoid accidentally editing the world when composing a shot.
- **F12** while playing FPS: save a **clean PNG screenshot** of the current game frame. Works from either normal or cinematic view; UI is hidden for the captured frame.
- Screenshots are written to `user://screenshots/satria_gambut_YYYY-MM-DD_HH-MM-SS_<id>.png`; a message is sent to the Godot Output console and to the game toast/overlay.
- The screenshot folder is created if missing. Capturing does not require cloud services or extra third-party tools.
- **Esc / exiting the FPS phase** restores the original HUD and held tool visibility so Pause, Evaluation and Main Menu continue working.

## Testing in Godot
1. Download V7 and open `project.godot`. Confirm there are **no GDScript parse errors**.
2. Launch Level 1 and enter FPS gameplay.
3. Press **F10**. Both HUD and hand-held equipment should vanish while the forest, effects and camera remain visible.
4. Move using WASD and mouse. Click the mouse while in cinematic view; no firebreak/water should be used.
5. Press **F12** during rain, fire, or lightning (press **F9** first to preview a strike). Check the notification and screenshot folder.
6. Press **F10** again. HUD and tools should come back. Check normal water spray and injection still work.
7. Press **Esc** from cinematic view; on resuming the game, normal HUD must be restored.
8. Test Pause, Victory, Defeat, Retry, Next Level, and return-to-menu; menus must remain clickable.
9. Use **F11** / Windows Maximize in both modes. Confirm screenshots capture the current display size.
10. Test all 3 scenarios, with Low, Medium and High quality and a headset if available.

### Where to find screenshots
In Godot Editor select **Project → Open User Data Folder** and open the `screenshots` subfolder. Alternatively read the exact saved absolute path in Godot's **Output** panel.

### Limitations
- This is a **clean-view screenshot mode**, not a separate flying/free camera, scene recorder, video encoder or offline photo gallery.
- The world simulation continues running in Cinematic Mode, including fire spread and weather; it is not a paused photograph editor.
- The screenshot file will reflect the game's current render resolution (not automatically upscaled to 4K).
- This code is ready for local testing but no Windows/Godot runtime test has been performed in the authoring environment. Keep the Pull Request in Draft until verified.
