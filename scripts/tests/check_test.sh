#!/usr/bin/env bash
# Self-test for scripts/check.sh. Drives it with a stub Godot (no real Godot
# needed) through every pass/fail condition in docs/CONTRACTS.md, asserting the
# exit code and the final output line. Exits 0 only if every case passes.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
readonly CHECK_SH="$SCRIPT_DIR/../check.sh"
readonly EXIT_PASS=0
readonly EXIT_FAIL=1
readonly GUT_CLEAN_OUTPUT='Passing Tests         1'

WORKDIR="$(mktemp -d)"
readonly WORKDIR
readonly STUB="$WORKDIR/godot-stub"
total=0
failures=0

# Remove only what this script created, so no recursive delete is needed.
cleanup() {
	rm -f "$STUB"
	rmdir "$WORKDIR"
}
trap cleanup EXIT

# The stub picks its step from its arguments. When that step equals $STUB_STEP
# it prints $STUB_OUTPUT and exits $STUB_EXIT; every other step succeeds.
write_stub() {
	cat >"$STUB" <<'STUB_EOF'
#!/usr/bin/env bash
step=""
for arg in "$@"; do
	case "$arg" in
	--version) echo "stub 4.7"; exit 0 ;;
	--import) step=import ;;
	--quit-after) step=boot ;;
	*gut_cmdln.gd) step=tests ;;
	esac
done
if [[ -z "$step" ]]; then
	echo "stub: unrecognised arguments: $*" >&2
	exit 99
fi
if [[ "$step" == "${STUB_STEP:-}" ]]; then
	echo "$STUB_OUTPUT"
	exit "$STUB_EXIT"
fi
if [[ "$step" == tests ]]; then
	echo "$STUB_GUT_CLEAN_OUTPUT"
else
	echo "ok"
fi
STUB_EOF
	chmod +x "$STUB"
}

# run_case NAME EXPECTED_EXIT EXPECTED_LAST_LINE STUB_STEP STUB_EXIT STUB_OUTPUT [GODOT]
run_case() {
	local name=$1 want_rc=$2 want_last=$3 stub_step=$4 stub_exit=$5 stub_output=$6
	local godot=${7:-$STUB}
	local out rc=0 last
	total=$((total + 1))
	out="$(env GODOT="$godot" STUB_STEP="$stub_step" STUB_EXIT="$stub_exit" \
		STUB_OUTPUT="$stub_output" STUB_GUT_CLEAN_OUTPUT="$GUT_CLEAN_OUTPUT" \
		"$CHECK_SH" 2>&1)" || rc=$?
	last="$(tail -n 1 <<<"$out")"
	if [[ "$rc" == "$want_rc" && "$last" == "$want_last" ]]; then
		echo "ok     $name (exit $rc, '$last')"
	else
		failures=$((failures + 1))
		echo "NOT OK $name: want exit $want_rc '$want_last', got exit $rc '$last'"
	fi
}

write_stub

run_case "a: all clean" "$EXIT_PASS" "PASS" "" 0 ""
run_case "b: import exits nonzero" "$EXIT_FAIL" "FAIL: import" import 1 "boom"
run_case "c: import prints SCRIPT ERROR" "$EXIT_FAIL" "FAIL: import" import 0 "SCRIPT ERROR: Parse Error"
run_case "d: boot prints ERROR:" "$EXIT_FAIL" "FAIL: boot" boot 0 "ERROR: Failed to load script"
run_case "e: GUT nothing was run" "$EXIT_FAIL" "FAIL: tests" tests 0 "[GUT ERROR]:  Nothing was run."
run_case "f: GUT zero passing tests" "$EXIT_FAIL" "FAIL: tests" tests 0 "Passing Tests         0"
run_case "g: tests exit nonzero" "$EXIT_FAIL" "FAIL: tests" tests 1 "$GUT_CLEAN_OUTPUT"
run_case "h: Godot unrunnable" "$EXIT_FAIL" "FAIL: toolchain" "" 0 "" "$WORKDIR/no-such-godot"

echo "$((total - failures))/$total cases passed"
if ((failures > 0)); then
	exit 1
fi
