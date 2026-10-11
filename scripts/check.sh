#!/usr/bin/env bash
# Runs the three contract checks from docs/CONTRACTS.md ("Project layout and
# toolchain"), in order, and stops at the first failure:
#   import -> boot -> tests
# A step fails on a nonzero exit, on any "SCRIPT ERROR" or "ERROR:" line in its
# output, and (tests only) when GUT reports "Nothing was run" or zero passing tests.
# Works from any directory. Uses $GODOT if set, else `godot` from PATH.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
readonly REPO_ROOT="${SCRIPT_DIR%/*}"
readonly PROJECT_DIR="$REPO_ROOT/game"
readonly GODOT_BIN="${GODOT:-godot}"
readonly BOOT_QUIT_AFTER_FRAMES=2
readonly ANSI_ESCAPE=$'\033'
readonly ERROR_PATTERN='SCRIPT ERROR|ERROR:'
readonly GUT_NOTHING_RAN_PATTERN='Nothing was run'
readonly GUT_PASSING_PATTERN='^Passing Tests +[1-9][0-9]*$'

fail() {
	echo "FAIL: $1" >&2
	exit 1
}

strip_ansi() {
	sed "s/${ANSI_ESCAPE}\[[0-9;]*m//g"
}

# Validators read a step's cleaned output on stdin. On failure they print the
# reason on stdout and return 1; on success they print nothing and return 0.
no_extra_check() {
	return 0
}

gut_ran_tests() {
	local output
	output="$(cat)"
	if grep -q "$GUT_NOTHING_RAN_PATTERN" <<<"$output"; then
		echo "GUT reported '$GUT_NOTHING_RAN_PATTERN'"
		return 1
	fi
	if ! grep -Eq "$GUT_PASSING_PATTERN" <<<"$output"; then
		echo "GUT reported zero passing tests"
		return 1
	fi
}

# run_step NAME VALIDATOR COMMAND [ARGS...]
run_step() {
	local name=$1 validator=$2
	shift 2
	local raw rc=0 output reason=""
	raw="$("$@" 2>&1)" || rc=$?
	output="$(strip_ansi <<<"$raw")"

	if ((rc != 0)); then
		reason="exit code $rc"
	elif grep -Eq "$ERROR_PATTERN" <<<"$output"; then
		reason="output contains a SCRIPT ERROR or ERROR: line"
	elif ! reason="$("$validator" <<<"$output")"; then
		reason="${reason:-validator $validator failed}"
	else
		reason=""
	fi

	if [[ -n "$reason" ]]; then
		printf '%s\n' "$output" >&2
		echo "step $name: exit $rc ($reason)" >&2
		fail "$name"
	fi
	echo "step $name: exit $rc"
}

if ! "$GODOT_BIN" --version >/dev/null 2>&1; then
	echo "error: cannot run Godot ('$GODOT_BIN'); set GODOT to a Godot 4.7 binary or put godot on PATH" >&2
	fail "toolchain"
fi

run_step import no_extra_check \
	"$GODOT_BIN" --headless --path "$PROJECT_DIR" --import
run_step boot no_extra_check \
	"$GODOT_BIN" --headless --path "$PROJECT_DIR" --quit-after "$BOOT_QUIT_AFTER_FRAMES"
run_step tests gut_ran_tests \
	"$GODOT_BIN" --headless --path "$PROJECT_DIR" -s addons/gut/gut_cmdln.gd \
	-gdir=res://tests -ginclude_subdirs -gexit

echo "PASS"
