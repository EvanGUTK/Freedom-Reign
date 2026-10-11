# Freedom-Reign

Game project built by a team of Claude Code agents. See `CLAUDE.md` for how the team is organized and `docs/CONTRACTS.md` for the interfaces the agents share.

## Playing

`scripts/play.sh` runs the game in a window. It works from any directory, uses the Godot binary in `$GODOT` if set, else `godot` from `PATH`, and exits 1 with a clear message if Godot cannot be run. Extra arguments are passed on to Godot.

## Building

`scripts/build.sh [linux|windows|all]` (default `all`) exports release builds with the `Linux` and `Windows Desktop` presets in `game/export_presets.cfg` to `game/export/<preset>/` (git-ignored): `freedom-reign.x86_64` and `freedom-reign.exe`, each a single file. It needs the Godot export templates matching your Godot version (one-time install: Godot editor → Editor → Manage Export Templates → Download); without them it exits 1 with that instruction and downloads nothing.

## Running checks

`scripts/check.sh` is what "the build is green" means: it runs the import, boot, and GUT test commands from `docs/CONTRACTS.md` in order, prints one line per step, and ends with `PASS`, or stops at the first failing step with `FAIL: <step>` and a nonzero exit. A step fails on a nonzero exit, any `SCRIPT ERROR` or `ERROR:` line, or GUT reporting `Nothing was run` or zero passing tests. It works from any directory and uses the Godot binary in `$GODOT` if set, else `godot` from `PATH`. `scripts/tests/check_test.sh` self-tests it against a stub Godot (no real Godot needed); run it after editing `check.sh`.
