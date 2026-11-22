# Satria Gambut V4.3 — Automatic Responsive Window

## Requested behavior
The player should not need to open graphics/display settings to enlarge the game. When the player clicks the **Windows Maximize (□) button** or drags a window edge, the game should automatically reflow the UI to the new window size.

## Changes
- The Godot window remains resizable.
- Existing canvas scaling is preserved (`canvas_items` stretch with `expand` aspect).
- The main menu listens to its `resized` signal and dynamically adapts margins, column spacing, left-card minimum width and logo minimum dimensions.
- Display setup runs **only once per startup** or when the player explicitly selects F11/display setting. It no longer resets the user's window size when returning from gameplay to the menu.
- Optional **F11** / display settings remain available but are no longer needed for normal maximization.
- Existing gameplay, effects, saves, records, and mission logic are unchanged.

## Manual verification
1. Download `fix/auto-responsive-window-v4-3` into a separate folder. Import `project.godot`.
2. Disable **Embed Game on Next Play** in the Godot toolbar, then run the game (F5) as a separate Windows window.
3. In **Windowed**, click Windows **Maximize □** — menu background and panels should expand automatically. Buttons must remain clickable.
4. Click Restore, then drag the window wider and taller; the layout should adapt continuously.
5. Open settings and other modals while maximizing. Confirm all buttons remain clickable.
6. Start a level, maximize, then return to main menu: window must remain maximized instead of being reset to 1280×720.
7. Check 1280×720, 1366×768, 1600×900 and 1920×1080 as available.
8. Optional: press F11 to switch to borderless fullscreen and back; verify input remains responsive.

### Note
If the application starts *already borderless fullscreen* due to an earlier saved preference, press **F11** once to return to standard Windowed mode with the Windows title bar and Maximize button. For normal resize/maximize no settings menu is required.

Godot runtime, visual UI and Windows input verification must be performed locally; no runtime success is asserted by this change.
