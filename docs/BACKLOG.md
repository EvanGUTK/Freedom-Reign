# Backlog

Small follow-ups the chief has accepted but not yet dispatched. One line each: what, who, why. Remove the line in the commit that lands it.

- **ANSI case for `scripts/tests/check_test.sh`** — backend — real GUT colours its output (`\e[31m[GUT ERROR]:\e[0m …`); the self-test never exercises `check.sh`'s ANSI stripping, only the real-Godot run does. Add one case wrapping `Passing Tests 0` in `$'\e[31m'…$'\e[0m'`. (integrator flag, 2026-10-10)
- **Named constant for the collision layer in `tests/engine/test_arena_scene.gd`** — engine — compares `collision_layer` to the literal `1`; use a `WORLD_LAYER_BIT` constant, in whichever gameplay commit touches that test next. (integrator flag, 2026-10-10)
