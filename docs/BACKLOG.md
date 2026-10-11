# Backlog

Small follow-ups the chief has accepted but not yet dispatched. One line each: what, who, why. Remove the line in the commit that lands it.

- **Wall-height literal in `tests/engine/test_arena_scene.gd`** — engine — asserts wall height > 4.5 as a literal; reuse `PLATFORM_TOP_HEIGHTS.back()`. Next commit that touches the test. (integrator flag, 2026-10-10)
- **Sound ids as named constants** — audio — `AudioEventRouter` repeats the contract id strings that `SoundCatalog` holds as keys; expose constants on SoundCatalog and use them in the router so the contract string lives once. (integrator flag, 2026-10-10)
- **Clean quit while audio plays** — audio — with a real audio driver, closing the window mid-music probably prints Godot's two leak lines; handle `NOTIFICATION_WM_CLOSE_REQUEST` (stop, await a frame, quit). Verify first by closing the game during music. (audio flag, 2026-10-10)
- **CI runs the sound generator's unit tests** — backend — add `python3 -I -m unittest discover -s tools/audio` as a step in `.github/workflows/check.yml`; stdlib only, no Godot needed. (chief, 2026-10-10)
