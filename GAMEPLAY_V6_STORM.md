# Satria Gambut V6 — Thunderstorm & Wet Ground Polish

This branch extends the user-tested V5 branch and **combines all requested effects in one branch**. Earlier gameplay, window resizing, F11, navigation, weather, score, and missions remain present.

## New features
1. **Branched procedural lightning:** Jagged, branching lightning strokes appear in the upper sky area of the screen during storms. Two short soft blue-white flashes also brighten the scene briefly. The overlay is click-through, so buttons/gameplay remain usable.
2. **Delayed thunder:** A rumbling thunder sound follows each strike after roughly 0.6–2.5 seconds. Thunder is synthesized offline, with different pitch and level each time.
3. **Richer rainfall sound:** A broad rain-noise bed is combined with a second, quieter irregular droplet-impact layer. Both react to the current precipitation level. Existing wind and nearby fire soundscapes remain.
4. **Ground rain impacts:** Small local ground-level particle splashes accompany falling rain near the player. Low/Medium/High quality reduces or increases particle density.
5. **Wet peat:** Rain and water-tool actions already update soil moisture. Wet cells now darken toward a cool tone in the existing MultiMesh terrain material, without additional physics/colliders.
6. **Storm frequency:** Lightning requires meaningful rainfall (at least 4 mm in the simplified game-weather model); strikes have randomized 22–45 second checks and chance scaled by rain. The lighting is intentionally restrained, not an intense full-white flash.

## Preview control
- Press **F9 during FPS gameplay** to trigger one lightning + thunder demonstration immediately. This preview helps testing even if random weather hasn't produced a storm yet.
- The regular lightning is weather-driven; **F9 is an optional test shortcut**, not an extra gameplay weapon.

## Validation
- [ ] Godot import/parse succeeds and Main Menu remains clickable.
- [ ] Start a level and press F9. Confirm a branching bolt and *two brief* flashes appear with minimal UI obstruction.
- [ ] After a short delay, a thunderclap/low rumble plays; test at moderate headset volume.
- [ ] Wait for rainy weather and verify automatic lightning can happen when rain reaches the threshold.
- [ ] Compare normal and heavy rain: audio textures and particle splash intensity should differ.
- [ ] Spray a cell / watch it get wetter after rainfall; verify soil becomes darker while the PFVI heatmap and Thermal mode still work.
- [ ] Confirm particles are fewer on Low and fuller on High graphics presets.
- [ ] Press Escape, resume, complete/fail a mission: rain and storm audio/visuals must not leak into pause/results.
- [ ] Verify F11, native window maximization, and menu mouse clicks still work.
- [ ] Play all 3 missions; wins/defeats, medals, records and sumur water capacity still function.
- [ ] Check Output/Debugger errors and FPS profile on your own laptop.

## Important limitations
- Audio and lightning are procedural approximations, not physically measured or field-recorded thunder/hydrometeorology.
- Lightning does not ignite peat or damage the player; it is a visual/audio environmental effect.
- The rain splashes use a flat ground plane at world Y = 0.15, not collision-driven contact with individual 3D props.
- Lightning is not a photorealistic volumetric sky simulation; the branching bolt is an overlay paired with scene lighting.
- No Godot runtime or Windows frame-rate test was possible in the code-authoring environment; the new version remains a draft until tested locally.
