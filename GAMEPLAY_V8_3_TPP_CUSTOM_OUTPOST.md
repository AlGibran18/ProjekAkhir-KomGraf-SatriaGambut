# Satria Gambut V8.3 — TPP Action, Customization, Radar, Enterable Outpost

Base: `feature/tactical-minimap-third-person-v8-2` (inherits V8.1 stop-and-review, V8 analytics, V7 cinematic, V6 weather, and older improvements).

## Gameplay and player customization

- **TPP [V]** now shows an improved stylized 3D firefighter: rounded head and limbs, helmet and visor, protective vest, reflective strip, gloves, reinforced boots, belt, radio and backpack tank.
- **Spray [2] + hold left mouse:** TPP avatar raises both arms toward the target and emits a visible blue-tinted water jet from the nozzle in-hand, instead of playing the invisible FPS-only water effect.
- **Firebreak [1] + left mouse:** a short digging motion animates the arms; a lightweight burst of soil particles appears when the tool action event is triggered.
- **Peat injection [3] + hold left mouse:** both arms press a visible spear downward/forward, with repeated movement while injection runs. Existing world steam effects remain.
- TPP visuals do **not** change the actual spray range, damage/suppression rate, collision capsule or existing first-person tool behavior.
- A new **KUSTOMISASI PETUGAS [HELM & SERAGAM]** choice appears on the main menu. The pause screen additionally offers **GANTI HELM & SERAGAM**, so the player can change while in a mission.
- Uniform choices: **Merah Rescue, Oranye Satgas, Hijau Rimba, Biru Operasi**. Helmet choices: **Merah Rescue, Kuning Safety, Hitam Taktis, Putih Komando**.
- Appearance is saved locally to `user://satria_gambut_outfit.cfg` and updates instantly on the active avatar through `GameState.outfit_changed`. Cosmetics do not change game stats.

## Updated tactical radar

- The compact map and expanded **[M]** map now add a gently animated scan beam, circular distance-reference rings, rescue-GPS styled corner brackets, and a pulsing distress warning if the protected station is destroyed.
- Existing markers for surface fires, concealed embers under Thermal, wells, direction triangle and protected post are preserved.
- The full tactical map legend identifies the map as a **game simulation**, not real GPS or a street map.

## Enterable firefighter operations post

- An enclosed low-poly field post is built just behind the north-side spawn point, with open walk-through doorway, roof, wall colliders, raised floor, operation desk, supplies, radio, map board, interior light and exterior signage.
- The building has status lighting that changes from green to flashing red when the protected station is damaged.
- Nearby plants and tree colliders inside the walking footprint are hidden so players can actually walk through the interior; the original station's mission logic remains unchanged.
- The building is intentionally simple low-poly geometry; it is not a detailed imported architectural model, interactive door, rest area or inventory system.

## Local playtest checklist

1. [ ] Download the V8.3 branch ZIP and import `project.godot` into Godot 4.x; check Output/Debugger for GDScript parse errors.
2. [ ] Main Menu → **KUSTOMISASI PETUGAS** → change both uniform and helmet; start Level 1; toggle **V** and inspect character colors.
3. [ ] Use **1** to dig a firebreak in TPP: visible short tool motion and small ground dust burst.
4. [ ] Use **2** and hold left mouse to spray an active fire in TPP: water jet appears at nozzle, avatar raises arms and suppression still works.
5. [ ] Use **3** and hold left mouse at an underground ember: visible press motion; injection is tracked and extinguishes as before.
6. [ ] Toggle V back to FPS. First-person held tools, crosshair and water jet still appear normally; no duplicated avatar.
7. [ ] Press Esc → **GANTI HELM & SERAGAM**; save a new appearance, resume, and confirm the TPP avatar updates without resetting the level.
8. [ ] Return to the Main Menu or restart Godot; confirm the selected appearance persists.
9. [ ] Open the regular minimap and **M** large map: scan beam and rings should render without hiding player/fire/well/station markers.
10. [ ] From player spawn, walk south into the new observation post's open doorway (building stands behind the station), inspect table/radio/briefing map, and walk out again.
11. [ ] Walk along interior walls to verify they are solid and that trees or props don't block the entrance.
12. [ ] Trigger station damage (if possible) to check the outpost's status light turns red.
13. [ ] Verify Esc pause, V camera toggle, F9 lightning, F10 cinematic, F11 fullscreen, F12 screenshots, V8.1 stop-and-review, Victory/Defeat, retry and export.
14. [ ] Compare frame times Low/Medium/High and check 1280×720 and 1920×1080.

## Known limitations

- The firefighter model is an improved *procedural stylized* character; full skeletal animation and realistic cloth are not included.
- Digging and injection motions are procedural poses; no imported motion-capture animations.
- TPP water particles are visual-only; simulation suppression remains controlled by existing tool targeting and grid logic.
- The outpost is walk-in with a permanently open entrance; it currently has no interactable inventories or NPCs.
- Radar rings are visual distance references, not surveyed GPS distances.
- Godot and Windows runtime tests cannot be run from the source-authoring environment. Keep this branch as a draft and validate locally.

## File changes

- `simulation/player/firefighter_avatar_3d.gd`
- `simulation/player/player_controller_3d.gd`
- `core/game_state.gd`
- `ui/main_menu/main_menu.gd`
- `ui/pause/pause_menu.gd`, `ui/pause/pause_menu.tscn`
- `ui/hud/hud.gd`
- `environment/props/enterable_outpost_3d.gd` (new)
- `simulation/view/simulation_view_3d.gd`
