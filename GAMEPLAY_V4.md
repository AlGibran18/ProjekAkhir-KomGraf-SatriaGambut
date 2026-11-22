# Satria Gambut V4 — Advanced Fire VFX

Based on the tested V3.1 foliage branch. Experimental: test this branch in Godot before merging into the stable branch.

## What's new

1. **Windborne embers:** GPU particle sparks drift in the direction of the wind and strengthen with fire intensity. Underground-only embers do not emit visible flying sparks.
2. **Fire response to wind:** flame particles lean downwind, independently of gameplay spread chances.
3. **Animated light flicker:** existing fire lights flicker at a small amplitude; the change creates no new OmniLight nodes.
4. **Proximity fire warning:** subtle pulsing reddish screen tint appears when approaching an active surface fire; no player damage or health mechanic is introduced.
5. **Performance presets:** flying embers are disabled in Low; Medium scales them to 75%; High uses full density. Existing caps on dynamic lights remain in place.

## Test in Godot

- [ ] Import project with no GDScript errors, then run the main scene.
- [ ] At Level 1 or 2, approach a surface fire and check a light, subtle red warning tint.
- [ ] Move away from fire and verify the tint disappears.
- [ ] Check that there are flying embers near fire and that their trajectory follows wind.
- [ ] Extinguish surface fire while leaving subsurface heat: flying sparks should stop and Thermal vision should still reveal buried embers.
- [ ] Compare Low / Medium / High presets. Sparks are not emitted in Low, even if smoke and base flames are still visible.
- [ ] Check mission HUD, minimap, tutorial, navigation, rain and foliage still operate.
- [ ] Play all 3 levels and confirm there are no regressions in win/loss conditions.
- [ ] Compare frame time and GPU frame stats with V3.1 on the same machine.

## Important limitations

- Sparks are **visual only** and do not physically ignite distant cells. Cellular Automata remains the authoritative simulation.
- Screen tint indicates proximity, not actual player heat damage.
- This branch was reviewed at source level only. There has been no runtime validation or verified FPS benchmark in the assistant environment.
