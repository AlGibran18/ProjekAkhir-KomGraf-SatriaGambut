# Satria Gambut V4.1 — Fullscreen / Windowed

## Implemented
- **F11** toggles fullscreen from the menu or while playing.
- **Settings → Mode Tampilan** provides **Windowed (Jendela)** and **Fullscreen (Layar Penuh)**.
- The display preference persists locally in `user://satria_gambut_display.cfg`.
- On return to Windowed, the game uses a centered window of up to 1280×720, limited by the display resolution.
- Existing Godot layout uses `window/stretch/mode="canvas_items"` and `window/stretch/aspect="expand"`, so the game canvas responds to window changes. Fullscreen makes the OS game window fill the display; it does not automatically stretch the menu card to every pixel.

## Important: Embedded debug window
If the game starts inside Godot's embedded Game view or a debug window, the **Godot editor's surrounding black border** is not the game's UI. To verify true OS fullscreen, run the game in a separate window. In the Godot editor, turn off `Embed Game on Next Play` (the embedded-game button, if active) then press F6/F5 or use Project → Run Project. Alternatively run the exported executable.

## Manual QA
- [ ] Import in Godot without parser errors.
- [ ] In main menu: Settings → Fullscreen makes the game window fill the display.
- [ ] Settings → Windowed returns to a centered 1280×720 (or smaller if the screen is smaller).
- [ ] Press F11 in the main menu; verify toggle works.
- [ ] Press F11 during FPS and planning; gameplay inputs remain responsive.
- [ ] Close and reopen the game; the selected display mode persists.
- [ ] At 16:9 and 16:10, check main menu, planning, HUD, and evaluation panels for overlap.
- [ ] If switching Fullscreen doesn't affect embedded debug Game view, disable editor game embedding and re-test in a separate game window.
- [ ] Check Windows display scaling, monitor selection and multiple monitors as needed.

Runtime verification still requires Godot on a Windows device; this change has only been inspected at source level.
