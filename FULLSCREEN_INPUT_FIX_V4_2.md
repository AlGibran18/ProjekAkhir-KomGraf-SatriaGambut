# Satria Gambut V4.2 — Fullscreen Mouse/Input Fix

## Problem
Godot's embedded game view doesn't support display mode transitions in the same way as a normal game window. After disabling embedding, the user observed a visible fullscreen main menu that would not accept mouse clicks.

## Changes
- The "Fullscreen" option now uses **borderless windowed fullscreen**, filling the physical monitor while preserving ordinary Windows input behavior. This is not exclusive fullscreen.
- Display restoration waits until the main menu controls finish initializing, rather than applying fullscreen during autoload initialization.
- Switching display modes is deferred until the UI input event finishes.
- The game requests focus after mode changes and restores a visible cursor on menu focus.
- Windowed mode returns to a centered window within the usable monitor rectangle.
- Existing saved `user://satria_gambut_display.cfg` preferences remain compatible.

## How to test
1. **Stop** the game in Godot.
2. Turn OFF **Embed Game on Next Play**.
3. Run with F5 and wait until the **separate** game window opens.
4. Move the pointer to the **MULAI SIMULASI** button; verify hover response and click.
5. From the menu, Settings → select Windowed then Fullscreen Borderless; verify clicks still work.
6. Press F11 in the menu, planning, FPS and pause phases; verify transitions keep the cursor usable in menus.
7. Alt+Tab out and back. Verify the app regains focus and buttons work.
8. Restart the app and verify the display preference persists.
9. Test at monitor resolutions 1366×768, 1920×1080 or whichever are accessible.
10. Check Editor > Debugger > Errors and Output for input/focus exceptions.

## If clicks still fail
- Try Alt+Tab to another app then back to the running game.
- Check the Godot embedded game toolbar's **Input** interaction mode (when embedding is enabled). During testing use a **separate game window**, not the embedded viewport.
- Temporarily set the selection to Windowed using F11. If needed, reset the display config in Godot's `user://` project data directory (do not delete your records file).
- Check whether the issue occurs with both mouse and keyboard input. If only mouse fails, inspect overlay Control `mouse_filter` settings.
- An exported Windows build is the best validation of behavior outside the editor debug runner.

**Status:** Code change prepared. Godot runtime testing was not performed in the connector environment.
