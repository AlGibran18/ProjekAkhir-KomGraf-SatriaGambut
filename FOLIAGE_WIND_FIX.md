# Satria Gambut V3.1 — Foliage Wind Fix

## Problem fixed
V3 collected only the first 80 grid-cell `PlantHolder` groups, leaving vegetation outside the sampled area still. Each holder may also contain logs, rocks, stumps, or mushrooms, so rotating the whole holder was not appropriate.

## New behavior
- The vegetation spawner explicitly names wind-bendable objects `WindPlant_Fern`, `WindPlant_Broadleaf`, `WindPlant_Bush` and `WindPlant_Grass`.
- The weather controller visits **all** 256 grid cell holders and registers every tagged living plant.
- Each plant gets a unique phase offset so the movement looks more organic.
- The original plant rotation is preserved and the small sway is added on top.
- Plants update at approximately 30 Hz for a reasonable CPU cost.
- Rocks, stumps, logs, mushrooms, trees with colliders, and other structural props are not animated.

## Local verification in Godot
1. Download `fix/foliage-wind-v3-1` and import `project.godot`.
2. Open Level 1, Level 2 and Level 3.
3. Look at plants near the initial player location **and** distant grass/bush areas.
4. Compare wind at 10, 16 and 22 km/h (the levels' initial winds); movement should be subtle at low wind and stronger at high wind.
5. Confirm rock, log, stump, fences and tree trunk collisions remain fixed.
6. Confirm formerly hidden plants remain hidden after building a well or firebreak.
7. Check frame time in Godot Debugger > Profiler. Compare V3 versus V3.1 on the same laptop.
8. Check editor Output and Debugger for parsing errors.

Note: This change has not been executed in a Godot runtime here; manual visual and performance validation is still needed.
