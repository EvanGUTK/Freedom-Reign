# Shared contracts

Anything two agents both depend on gets written here by the chief before either builds against it. Keep entries short and dated.

## Project layout and toolchain (2026-10-10, Milestone 1)
- The Godot project lives in `game/` (`game/project.godot`). Repo root keeps `docs/`, `scripts/`, `.claude/`. Nothing Godot-related outside `game/` except `.gitignore` entries and `scripts/check.sh`.
- Godot **4.7**, GDScript only, renderer Forward+. `project.godot` declares `config/features=PackedStringArray("4.7", "Forward Plus")`.
- Main scene: `res://scenes/main.tscn`. Folder layout inside `game/`: `scenes/`, `scripts/`, `assets/audio/`, `assets/models/`, `assets/textures/`, `tests/`, `addons/`.
- Tests: **GUT 9.x** vendored at `game/addons/gut/` (pin the release tag in the commit that adds it). Test files live in `game/tests/`, named `test_*.gd`, extending `GutTest`.
- Commands every check runs, from the repo root — these are what `scripts/check.sh` calls and what the integrator runs before merging:
  1. import: `godot --headless --path game --import`
  2. boot the main scene: `godot --headless --path game --quit-after 2`
  3. tests: `godot --headless --path game -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit`
  Each must exit 0, and the combined output must contain no `SCRIPT ERROR` or `ERROR:` lines.
- Git-ignored: `game/.godot/`, `game/export/`, `*.tmp`. Everything else under `game/` is committed, including `.import` sidecars next to assets and the `*.gd.uid` sidecars Godot 4.7 generates next to scripts (Godot's guidance is to version them; never delete or hand-edit one).
- Empty contract folders hold a `.gitkeep`; delete it in the same commit that adds the folder's first real file.
- `scripts/check.sh` must also fail when GUT reports `Nothing was run` — zero tests passing is a failure, not a pass.

## Audio events
_None yet._

## Engine hooks (events, components, asset slots)
_None yet._

## Backend formats and APIs
_None yet._

## Asset naming
_None yet._

## Milestone 2 — vertical slice (2026-10-10)
One arena, playable start to finish in under two minutes: move, jump, one melee attack, one enemy type, one loot drop that changes the attack, sound, pause menu, win and lose screens. Dark fantasy, stylized (`docs/DESIGN.md`).

### Ownership — who may edit what
A merge conflict between two roles is a process failure, not a git problem. If you need a change in a file you do not own, ask the chief.

| Path | Owner | Notes |
|---|---|---|
| `game/project.godot` | engine | input actions, autoloads, physics layers all land in the foundation commit; no one else edits this file |
| `game/scenes/main.tscn`, `game/scenes/arena/`, `game/scenes/player/`, `game/scenes/enemies/`, `game/scenes/loot/` | engine | |
| `game/scripts/**` except `scripts/ui/` and `scripts/audio/` | engine | includes `scripts/events.gd` and `scripts/data/` |
| `game/data/**` (`.tres` instances) | engine | |
| `game/scenes/ui/**`, `game/scripts/ui/**` | frontend | engine's foundation creates `scenes/ui/ui_root.tscn` (a bare `CanvasLayer`) and instances it in `main.tscn`; after that frontend owns it and never touches `main.tscn` |
| `game/scenes/audio/**`, `game/scripts/audio/**`, `game/assets/audio/**` | audio | engine's foundation creates the minimal `scripts/audio/audio_manager.gd` registered as autoload; after that audio owns it |
| `scripts/**`, `.github/**`, `game/export_presets.cfg` | backend | |
| `game/tests/<role>/` | that role | `tests/engine/`, `tests/ui/`, `tests/audio/`; the existing `tests/test_smoke.gd` stays engine's |

### Input actions (engine foundation, in `project.godot`)
`move_forward` W / left stick up · `move_back` S / down · `move_left` A / left · `move_right` D / right · `jump` Space / gamepad A · `attack` left mouse / gamepad X · `pause` Escape / Start. Camera look uses relative mouse motion and the right stick inside the player camera; no action needed.

### Autoloads (engine foundation, registered in this order)
1. `Events` → `res://scripts/events.gd` — the signal bus. Gameplay emits; UI and audio connect. Nobody calls into a UI or audio node from gameplay, and UI/audio never call gameplay nodes. This is the dependency boundary from `engineering.md`.
2. `AudioManager` → `res://scripts/audio/audio_manager.gd`.
- An autoload is registered in the same commit that creates its script, never earlier — every commit must boot.
- `AudioManager.registry: Dictionary[StringName, AudioStream]` is the id→stream map audio fills. `AudioManager.error_reporter: Callable` defaults to `push_error`; tests inject a recorder so an expected unknown-id report never prints a real `ERROR:` line (which would fail `check.sh`). Keep both when you replace the file.

### `Events` signals — exact names and arguments; adding one is a contract change via the chief
- `player_health_changed(current: int, maximum: int)`
- `player_jumped()` · `player_landed()`
- `player_attacked(attack: AttackData)` — the swing started
- `player_hit_enemy(enemy: Node3D, damage: int)`
- `player_hurt(damage: int)` · `player_died()`
- `attack_changed(attack: AttackData)` — emitted once at spawn and on every loot pickup
- `enemy_died(enemy: Node3D)`
- `loot_dropped(item: ItemData, world_position: Vector3)` · `loot_picked_up(item: ItemData)`
- `arena_cleared()` — the last enemy died
- `game_paused(is_paused: bool)` — emitted by the pause menu (frontend). Gameplay honours `get_tree().paused` through `process_mode`; it never polls this signal.

### Data types (engine; Resources with `class_name`)
- `AttackData`: `id: StringName`, `display_name: String`, `damage: int`, `cooldown_seconds: float`, `reach_meters: float`, `arc_degrees: float`
- `ItemData`: `id: StringName`, `display_name: String`, `grants_attack: AttackData`
- Slice instances in `game/data/`: attack `rusted_blade` (damage 10, cooldown 0.6, reach 1.8, arc 90) is the starting attack; item `ember_cleaver` grants attack `ember_cleaver` (damage 25, cooldown 1.0, reach 2.2, arc 120). Placeholder names, ours.

### Gameplay numbers (engine; exported vars with these defaults)
Player: health 100, walk 6 m/s, jump height 2.2 m, gravity 24 m/s², third-person camera behind and above. Enemy `husk`: health 30, speed 3.5 m/s, contact damage 10 once per 1.0 s while within 1.5 m, walks straight at the player, no pathfinding. The first husk killed drops `ember_cleaver`; pickup is by touch. Arena: 30×30 m floor, three platforms at 1.5 / 3 / 4.5 m reachable by jumping, five husks at fixed spawn markers, enemies in group `enemies`. Win = `arena_cleared`; lose = `player_died`.

### UI (frontend) — everything under `scenes/ui/ui_root.tscn`
- HUD: health bar from `player_health_changed`; current attack name from `attack_changed`; enemies remaining = size of group `enemies` at ready, minus one per `enemy_died`.
- Pause menu: on `pause` action toggle `get_tree().paused`, emit `game_paused`, show Resume / Quit; `process_mode = PROCESS_MODE_ALWAYS`.
- End screen: `arena_cleared` → "Arena cleared" + Restart; `player_died` → "You died" + Restart. Restart unpauses and calls `get_tree().reload_current_scene()`.
- One `Theme` resource at `scenes/ui/theme.tres`; no per-control style overrides. Keyboard, mouse, and gamepad all navigate menus.

### Audio — `AudioManager` API and sound IDs
- `AudioManager.play_sfx(id: StringName, world_position: Vector3 = Vector3.INF)` — `INF` means non-positional. `AudioManager.play_music(id: StringName)`, `AudioManager.stop_music()`.
- AudioManager connects to `Events` itself and chooses what to play; gameplay never calls `play_sfx`. UI may call `play_sfx` for its own clicks.
- Required IDs, each mapped to a stream under `assets/audio/`: `sfx.jump`, `sfx.land`, `sfx.attack_swing`, `sfx.attack_hit`, `sfx.player_hurt`, `sfx.player_die`, `sfx.enemy_die`, `sfx.loot_drop`, `sfx.loot_pickup`, `ui.pause_open`, `ui.pause_close`, `ui.click`, `music.arena`.
- An unknown id is a `push_error` (so tests and `check.sh` catch it), never silence.
- Buses: `Master` → `Music`, `SFX`, `UI`. Formats: `.wav` for SFX, `.ogg` for music. Any single file ≤ 2 MB, all slice audio ≤ 10 MB. Sources: generated by a committed script under `tools/audio/`, or CC0 with every source listed in `assets/audio/SOURCES.md`. Nothing that is not CC0.

### Tooling (backend)
- `scripts/play.sh` runs the game windowed (`godot --path game`).
- `game/export_presets.cfg` with `Linux` and `Windows Desktop` presets exporting to `game/export/<preset>/`; `scripts/build.sh [linux|windows|all]` runs the headless export and, if export templates are missing, fails with the one-line install instruction.
- `.github/workflows/check.yml` runs `scripts/check.sh` and `scripts/tests/check_test.sh` on every push and pull request with Godot 4.7.2 headless.

### Order of landing
1. **engine foundation**: project settings, `Events`, data types and instances, minimal `AudioManager`, `ui_root.tscn` instanced in `main.tscn`, spawn markers. → integrator → every role runs `git merge main`.
2. **in parallel**: engine gameplay · frontend UI · audio sounds · backend tooling (backend may start now; it depends on nothing above).
3. The chief hands the build to the user.
