#!/usr/bin/env bash
# Self-test for scripts/build.sh and scripts/play.sh. Copies both into a temp
# repo tree and drives them with a stub Godot, a temp XDG_DATA_HOME and a temp
# game/ folder, so no real Godot, export templates or repo files are touched.
# Exits 0 only if every case passes.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
readonly SCRIPTS_UNDER_TEST="$SCRIPT_DIR/.."
readonly EXIT_PASS=0
readonly EXIT_FAIL=1
readonly EXIT_USAGE=2
readonly STUB_VERSION='4.7.2.stable.test.0000000'
readonly TEMPLATES_VERSION='4.7.2.stable'
readonly PRESET_LINUX='Linux'
readonly PRESET_WINDOWS='Windows Desktop'
readonly ARTIFACT_LINUX='freedom-reign.x86_64'
readonly ARTIFACT_WINDOWS='freedom-reign.exe'

WORKDIR="$(mktemp -d)"
readonly WORKDIR
readonly REPO="$WORKDIR/repo"
readonly STUB="$WORKDIR/godot-stub"
readonly STUB_LOG="$WORKDIR/stub.log"
readonly XDG="$WORKDIR/xdg"
readonly TEMPLATES_DIR="$XDG/godot/export_templates/$TEMPLATES_VERSION"
total=0
failures=0

# Everything this script creates lives under the mktemp dir, so one bounded
# delete on every exit path removes it without a recursive rm.
cleanup() {
	find "$WORKDIR" -delete
}
trap cleanup EXIT

# The stub reports $STUB_VERSION for --version. For --export-release PRESET it
# logs "export:PRESET" and, when STUB_MODE is "create", writes that preset's
# artifact under the project given by --path. Any other call logs its arguments.
write_stub() {
	cat >"$STUB" <<'STUB_EOF'
#!/usr/bin/env bash
project="" preset=""
for ((i = 1; i <= $#; i++)); do
	case "${!i}" in
	--version) echo "$STUB_VERSION"; exit 0 ;;
	--path) j=$((i + 1)); project="${!j}" ;;
	--export-release) j=$((i + 1)); preset="${!j}" ;;
	esac
done
if [[ -z "$preset" ]]; then
	echo "$*" >>"$STUB_LOG"
	exit 0
fi
echo "export:$preset" >>"$STUB_LOG"
if [[ "${STUB_MODE:-}" == create ]]; then
	case "$preset" in
	"$STUB_PRESET_LINUX") artifact="$STUB_ARTIFACT_LINUX" ;;
	"$STUB_PRESET_WINDOWS") artifact="$STUB_ARTIFACT_WINDOWS" ;;
	*) echo "stub: unknown preset $preset" >&2; exit 99 ;;
	esac
	mkdir -p "$project/export/$preset"
	echo built >"$project/export/$preset/$artifact"
fi
STUB_EOF
	chmod +x "$STUB"
}

setup_repo() {
	mkdir -p "$REPO/scripts" "$REPO/game" "$XDG"
	cp "$SCRIPTS_UNDER_TEST/build.sh" "$SCRIPTS_UNDER_TEST/play.sh" "$REPO/scripts/"
}

with_templates() {
	mkdir -p "$TEMPLATES_DIR"
}

without_templates() {
	find "$XDG" -mindepth 1 -delete
}

# Clears artifacts and the stub's call log so each case starts clean.
reset_state() {
	rm -f "$STUB_LOG"
	find "$REPO/game" -mindepth 1 -delete
}

report() {
	local name=$1 ok=$2 detail=$3
	if [[ "$ok" == yes ]]; then
		echo "ok     $name ($detail)"
	else
		failures=$((failures + 1))
		echo "NOT OK $name: $detail"
	fi
}

# run_build_case NAME WANT_RC WANT_TEXT WANT_CALLS STUB_MODE GODOT [ARGS...]
# WANT_TEXT must appear in the output; WANT_CALLS is the exact comma-joined list
# of presets the stub was asked to export ("" = none).
run_build_case() {
	local name=$1 want_rc=$2 want_text=$3 want_calls=$4 stub_mode=$5 godot=$6
	shift 6
	local out rc=0 calls=""
	total=$((total + 1))
	reset_state
	out="$(env GODOT="$godot" XDG_DATA_HOME="$XDG" STUB_MODE="$stub_mode" \
		STUB_VERSION="$STUB_VERSION" STUB_LOG="$STUB_LOG" \
		STUB_PRESET_LINUX="$PRESET_LINUX" STUB_ARTIFACT_LINUX="$ARTIFACT_LINUX" \
		STUB_PRESET_WINDOWS="$PRESET_WINDOWS" STUB_ARTIFACT_WINDOWS="$ARTIFACT_WINDOWS" \
		"$REPO/scripts/build.sh" "$@" 2>&1)" || rc=$?
	if [[ -f "$STUB_LOG" ]]; then
		calls="$(sed 's/^export://' "$STUB_LOG" | paste -sd, -)"
	fi
	if [[ "$rc" == "$want_rc" && "$out" == *"$want_text"* && "$calls" == "$want_calls" ]]; then
		report "$name" yes "exit $rc, exports '$calls'"
	else
		report "$name" no "want exit $want_rc with '$want_text' and exports '$want_calls'; got exit $rc, exports '$calls', output: $out"
	fi
}

# play.sh must start Godot on the repo's game/ folder and pass extra arguments on.
run_play_case() {
	local name=$1 want_rc=$2 want_log=$3 godot=$4
	shift 4
	local out rc=0 log=""
	total=$((total + 1))
	reset_state
	out="$(env GODOT="$godot" STUB_VERSION="$STUB_VERSION" STUB_LOG="$STUB_LOG" \
		"$REPO/scripts/play.sh" "$@" 2>&1)" || rc=$?
	if [[ -f "$STUB_LOG" ]]; then
		log="$(cat "$STUB_LOG")"
	fi
	if [[ "$rc" == "$want_rc" && "$log" == "$want_log" ]]; then
		report "$name" yes "exit $rc, godot args '$log'"
	else
		report "$name" no "want exit $want_rc and godot args '$want_log'; got exit $rc, args '$log', output: $out"
	fi
}

write_stub
setup_repo

without_templates
run_build_case "a: templates missing" "$EXIT_FAIL" "FAIL: export templates" "" "" "$STUB"
run_build_case "a2: missing templates give install instruction" "$EXIT_FAIL" "Manage Export Templates" "" "" "$STUB"
with_templates
run_build_case "b: bad target" "$EXIT_USAGE" "usage: scripts/build.sh [linux|windows|all]" "" "" "$STUB" bogus
run_build_case "c: Godot missing" "$EXIT_FAIL" "FAIL: toolchain" "" "" "$WORKDIR/no-such-godot"
run_build_case "d1: export linux" "$EXIT_PASS" "PASS" "$PRESET_LINUX" create "$STUB" linux
run_build_case "d2: export windows" "$EXIT_PASS" "PASS" "$PRESET_WINDOWS" create "$STUB" windows
run_build_case "d3: export all (default)" "$EXIT_PASS" "PASS" "$PRESET_LINUX,$PRESET_WINDOWS" create "$STUB"
run_build_case "e: export produces no artifact" "$EXIT_FAIL" "$ARTIFACT_LINUX was not produced" "$PRESET_LINUX" "" "$STUB" linux

run_play_case "f: play.sh passes --path and extra args" "$EXIT_PASS" "--path $REPO/game --windowed" "$STUB" --windowed
run_play_case "g: play.sh Godot missing" "$EXIT_FAIL" "" "$WORKDIR/no-such-godot"

echo "$((total - failures))/$total cases passed"
if ((failures > 0)); then
	exit 1
fi
