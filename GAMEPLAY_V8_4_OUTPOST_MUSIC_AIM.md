# Satria Gambut V8.4 — Clear Outpost, Original Music & Target-Aligned Actions

**Based on V8.3**, leaving the previously tested branch untouched.

## Fixed: trees entering the outpost
- Screenshot of the old version shows giant trunks/foliage **inside the walk-in station**.
- Root cause: hiding 3×3 cell groups after forest generation did not remove nearby tree overhangs, decorative props, or tree collisions.
- Reserve a wider **x=5–11, y=0–6** outpost buffer *during initial forest generation*, preventing foliage and collider creation in that area.
- Prevent nearby border-forest trees from generating opposite the north outpost.
- Move the tents, log stack, campfire and sign farther from the building and main entrance.
- Keep the furnished station, walk-in doorway, status lamp, mission logic, and player spawn intact.

## Original background music (offline)
- Dedicated **original instrumental themes** are generated procedurally once at startup using PCM oscillators.
- The **main-menu track** is slower and ambient; **gameplay track** has a more energetic motif, bass and gentle pulses.
- Background tracks are deliberately quiet: about **-27 dB menu**, **-32 dB gameplay**, **-39 dB pause**.
- During win/defeat/voluntary evaluation, the calming menu theme plays. The music uses the same overall Master volume as other audio, and **weather / thunder / fire SFX remain louder**.
- No copyrighted music recordings, network dependencies or additional downloadable files are used.
- These are synthetic instrumental cues, not recorded full-band songs; arrangements can be further improved after listening locally.

## Target-aware FPS and TPP tools
- PlayerController resolves the **same targeted grid cell** used by the game and sends its world position to visual controllers every active frame.
- **FPS** held tool gently adjusts its pitch and yaw toward the highlighted cell, on top of existing equip, recoil and animation sways.
- **TPP** arms lean/turn toward the highlighted cell during actions; the held nozzle, shovel or spear points toward its world position.
- **Sekat Api** retains its event-driven swing, and **Tombak Gambut** retains its active injection pose; both should now be more visible.
- The existing water/nozzle particles stay attached to the TPP hand and rotate along with the equipped tool.
- Visual targets never bypass tool range, cell checks or gameplay fire suppression mechanics.

## Must-test scenarios
1. [ ] Import the branch in a **new folder**. Check Godot Editor Output/Debugger for import/parse errors.
2. [ ] Start Level 1, switch to TPP (**V**), walk inside the outpost, and confirm no tree trunk, vine, branch or invisible collider blocks the room or entrance.
3. [ ] Move along interior walls and doorway; check the avatar/camera doesn't clip or get stuck.
4. [ ] Listen to the menu theme before starting. Then enter gameplay and verify the sound changes to a gentle upbeat theme while **rain, wind, water and thunder remain clearly audible**.
5. [ ] Press **Esc**: music should be quieter; resume and verify gameplay music volume returns.
6. [ ] Press **1**, choose a ground cell at different screen angles and click: in both FPS and TPP, sekat tool should swing and visually aim at the cell.
7. [ ] Press **2**, hold left mouse: both FPS water jet and TPP nozzle/hand should aim at different targeted cells.
8. [ ] Press **3**, locate a genuine hotspot/ember, hold left mouse: the spear and arms should follow that cell while the injection bar progresses.
9. [ ] Toggle FPS/TPP mid-mission and verify targeting doesn't change game results. Check camera when near walls.
10. [ ] Test thermal mode, F9 lightning, F10 cinematic, F11 display resize, F12 screenshot, M large map, and V8.1 partial stop/report.
11. [ ] Test all 3 scenarios at low/medium/high quality, and compare audio balance with headphones at a modest listening volume.

### Limitations
- Procedural music is a short repeating original instrumental loop rather than a commercial-grade studio recording.
- Arm/hand targeting is an approximation using simple procedural mesh joints, not skeletal IK or motion capture.
- Outpost forest exclusion is broad to avoid long branches, so the north spawn region may look more open than older builds.
- **Godot executable is unavailable in the authoring environment.** Source review was possible; no local Godot parser or real gameplay verification was performed. This remains a draft until user playtests.
