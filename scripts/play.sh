#!/usr/bin/env bash
# Runs the game windowed. Works from any directory.
# Uses $GODOT if set, else `godot` from PATH. Extra arguments go to Godot.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
readonly REPO_ROOT="${SCRIPT_DIR%/*}"
readonly PROJECT_DIR="$REPO_ROOT/game"
readonly GODOT_BIN="${GODOT:-godot}"

if ! "$GODOT_BIN" --version >/dev/null 2>&1; then
	echo "error: cannot run Godot ('$GODOT_BIN'); set GODOT to a Godot 4.7 binary or put godot on PATH" >&2
	exit 1
fi

exec "$GODOT_BIN" --path "$PROJECT_DIR" "$@"
