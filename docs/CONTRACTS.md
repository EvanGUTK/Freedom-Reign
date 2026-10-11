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
- Git-ignored: `game/.godot/`, `game/export/`, `*.tmp`. Everything else under `game/` is committed, including `.import` sidecar files once assets exist.

## Audio events
_None yet._

## Engine hooks (events, components, asset slots)
_None yet._

## Backend formats and APIs
_None yet._

## Asset naming
_None yet._
