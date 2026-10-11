# Freedom-Reign

Game project built by a team of Claude Code agents. See `CLAUDE.md` for how the team is organized and `docs/CONTRACTS.md` for the interfaces the agents share.

## Running checks

`scripts/check.sh` is what "the build is green" means: it runs the import, boot, and GUT test commands from `docs/CONTRACTS.md` in order, prints one line per step, and ends with `PASS`, or stops at the first failing step with `FAIL: <step>` and a nonzero exit. A step fails on a nonzero exit, any `SCRIPT ERROR` or `ERROR:` line, or GUT reporting `Nothing was run` or zero passing tests. It works from any directory and uses the Godot binary in `$GODOT` if set, else `godot` from `PATH`. `scripts/tests/check_test.sh` self-tests it against a stub Godot (no real Godot needed); run it after editing `check.sh`.
