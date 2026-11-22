# Satria Gambut V3 — Living Forest & Weather Immersion

This branch is based on `feature/navigation-records-v2`, which in turn extends Gameplay V1. Do not merge V3 directly to `main` without bringing V1 and V2 changes with it.

## Implemented

- Camera-local GPU rain particles during the ACTIVE_FPS phase.
- Rain amount and direction adapt to the dynamic rainfall and wind parameters.
- Low / Medium / High presets scale rain particle density (18% / 55% / 100% of requested density).
- Up to 80 small foliage groups gently sway with wind; tree bodies and collision shapes do not move.
- Sun lighting gradually darkens with rain and larger active fires; rainy sky produces cooler light.
- Visual-only implementation: weather modelling, mission scoring, player control, fire spread, and saved records remain unchanged.

## Try it

1. Download or switch to `feature/living-forest-v3`.
2. Import `project.godot` into a compatible Godot 4.x editor.
3. Open each scenario and start the FPS phase.
4. Wait for a rainy weather front (weather changes roughly every 40s). Check the rain around the player, plant swaying, and sunlight response.
5. Compare graphical presets. Expect visibly fewer rain particles on Low and more on High.

## Manual validation checklist

- [ ] Import succeeds without GDScript parser errors or missing resources.
- [ ] Main menu, planning overlay, and FPS scene continue to work.
- [ ] Rain appears in the FPS phase when rainfall is above zero; stops in other phases.
- [ ] Rain falls and drifts downwind, following the player without visibly jumping.
- [ ] Low/Medium/High quality settings change rain density.
- [ ] Small plants gently sway; collision trees remain stable.
- [ ] Rain/cloudy conditions gradually adjust sunlight rather than switching abruptly.
- [ ] All three levels remain completable; victory/defeat and scoring are unchanged.
- [ ] Profiler: compare FPS and frame times across three presets on integrated GPU hardware.
- [ ] Verify lighting reset after retry or next level and no misplaced particles in planning scene.

## Performance and limitations

- This is a procedural visual overlay, not simulated volumetric weather or physically accurate precipitation.
- No new audio assets or rain sounds were added.
- There is no benchmark result or verified FPS claim: Godot runtime is not available in the coding environment. These checks must be executed in the user's Godot editor.
- Plant swaying updates a limited number of foliage holders and excludes trees to avoid collider drift.
- The V3 changes are an **experimental draft** until checked on the device.
