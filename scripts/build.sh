#!/usr/bin/env bash
# Exports release builds with the presets in game/export_presets.cfg.
#   scripts/build.sh [linux|windows|all]     (default: all)
# Output goes to game/export/<preset>/ (git-ignored). Needs the Godot export
# templates for the running Godot version; if they are missing this fails with
# the install instruction and downloads nothing. Works from any directory.
# Uses $GODOT if set, else `godot` from PATH.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
readonly REPO_ROOT="${SCRIPT_DIR%/*}"
readonly PROJECT_DIR="$REPO_ROOT/game"
readonly GODOT_BIN="${GODOT:-godot}"
readonly TEMPLATES_ROOT="${XDG_DATA_HOME:-$HOME/.local/share}/godot/export_templates"
# Numeric fields, then the status field (stable, rc1, beta2, dev3 ...): the
# folder name Godot uses for export templates. Build metadata after it is ignored.
readonly VERSION_PATTERN='^([0-9]+(\.[0-9]+)*\.[A-Za-z][A-Za-z0-9]*)(\.|$)'
readonly PRESET_LINUX="Linux"
readonly PRESET_WINDOWS="Windows Desktop"
readonly OUTPUT_LINUX="freedom-reign.x86_64"
readonly OUTPUT_WINDOWS="freedom-reign.exe"

fail() {
	echo "FAIL: $1" >&2
	exit 1
}

usage_error() {
	echo "usage: scripts/build.sh [linux|windows|all]" >&2
	exit 2
}

# export_preset PRESET OUTPUT_FILE
export_preset() {
	local preset=$1 output=$2
	local artifact="$PROJECT_DIR/export/$preset/$output"
	echo "exporting '$preset' -> game/export/$preset/$output"
	"$GODOT_BIN" --headless --path "$PROJECT_DIR" --export-release "$preset" ||
		fail "export $preset"
	[[ -s "$artifact" ]] || fail "export $preset: $artifact was not produced"
	echo "built $artifact"
}

target=${1:-all}
case "$target" in
linux | windows | all) ;;
*) usage_error ;;
esac

if ! godot_version="$("$GODOT_BIN" --version 2>/dev/null)"; then
	echo "error: cannot run Godot ('$GODOT_BIN'); set GODOT to a Godot 4.7 binary or put godot on PATH" >&2
	fail "toolchain"
fi

# "4.7.2.stable.arch_linux.ed1daf0bf" -> "4.7.2.stable", "4.8.stable.official.abc" -> "4.8.stable".
if [[ ! "$godot_version" =~ $VERSION_PATTERN ]]; then
	echo "error: cannot read a version from '$GODOT_BIN --version' output: '$godot_version'" >&2
	fail "toolchain"
fi
templates_version="${BASH_REMATCH[1]}"
templates_dir="$TEMPLATES_ROOT/$templates_version"
if [[ ! -d "$templates_dir" ]]; then
	echo "error: Godot export templates $templates_version are not installed (expected in $templates_dir)" >&2
	echo "install: in the Godot editor choose Editor > Manage Export Templates > Download, or unpack Godot_v${templates_version}_export_templates.tpz (from the Godot releases page) into $templates_dir" >&2
	fail "export templates"
fi

if [[ "$target" == linux || "$target" == all ]]; then
	export_preset "$PRESET_LINUX" "$OUTPUT_LINUX"
fi
if [[ "$target" == windows || "$target" == all ]]; then
	export_preset "$PRESET_WINDOWS" "$OUTPUT_WINDOWS"
fi
echo "PASS"
