# Satria Gambut V5 — Immersive Environmental Audio

Based on the tested responsive-window branch `fix/auto-responsive-window-v4-3`.

## Features
- Offline, procedural **wind ambience** scales with the current wind speed.
- Offline, procedural **rain ambience** fades in as the weather front produces rain and fades out in dry weather.
- A **positional 3D fire-crackle sound** follows the nearest *surface-burning* cell; it becomes quieter as the player moves farther away.
- Audio immediately stops when leaving FPS gameplay (planning, pause, victory or defeat).
- Existing UI/tool SFX and the global Master volume slider are preserved.
- Each sound is a lightweight, reusable 16-bit mono PCM loop generated once when entering a level. No downloadable audio pack or network is required.
- Gameplay behavior, win/loss conditions, weather probabilities, and save data are unchanged.

## Manual validation in Godot
- [ ] Import without GDScript parser/resource errors.
- [ ] Main menu continues to receive mouse input and responds to window resizing/maximize.
- [ ] Start Level 1: hear light wind, then listen as weather conditions evolve (front updates around every 40 seconds).
- [ ] When rain appears, hear a gradual noise bed; dry weather should be effectively quiet.
- [ ] Walk toward a visible surface fire; hear nearby crackling from its direction. Walk away and confirm volume falls.
- [ ] Extinguish surface flames; crackling should fade, even if underground embers are still detectable via Thermal.
- [ ] Press Escape; all environmental loops should stop while paused, then resume when continuing.
- [ ] Finish or fail a mission; loops stop and existing mission-result sounds continue.
- [ ] Test Level 2 and 3; strong wind should produce greater ambient intensity.
- [ ] Use the Master Volume slider; environment and existing effects should both be controlled.
- [ ] Verify Low/Medium/High presets still render and performance remains acceptable on an integrated-GPU laptop.
- [ ] Check with headphones and speakers at safe listening volume; ensure the generated audio is not overly loud.

## Technical notes
- The crackling comes from the **nearest visible fire only**, not from every hotspot simultaneously, to minimize audio mixing costs.
- Weather sounds are intentionally procedural noise textures, not recorded field ambience. Their tone can be refined with supplied recordings later.
- The first time a level loads, three three-second PCM loops are synthesized; this could add a short one-time main-thread cost. Later frames only update gain/position at ~4Hz.
- 3D sound positioning follows the current Godot listener (camera) and attenuation settings; test with headphones for spatial direction.
- No Godot runtime or real-device sound testing was performed in the code environment. This is a draft until confirmed in the user's editor.
