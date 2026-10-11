# Backlog

Small follow-ups the chief has accepted but not yet dispatched. One line each: what, who, why. Remove the line in the commit that lands it.

- **Named constant for the collision layer in `tests/engine/test_arena_scene.gd`** — engine — compares `collision_layer` to the literal `1`; use a `WORLD_LAYER_BIT` constant, in whichever gameplay commit touches that test next. (integrator flag, 2026-10-10)
