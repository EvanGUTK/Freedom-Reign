#!/usr/bin/env bash
# Launch the six-session Freedom-Reign team, each in its own window.
#
#   scripts/launch-team.sh          one ghostty window per role (your tiling WM arranges them)
#   scripts/launch-team.sh tmux     one tmux session, one tab per role (Ctrl-b 0..5 to switch)
#   scripts/launch-team.sh list     print what would be launched
#
# Every session gets --name <role> so the chief can address it with SendMessage.
# The chief uses your saved default model; the others get the model listed below.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"   # main checkout (chief + integrator)
PARENT="$(dirname "$ROOT")"
NAME="$(basename "$ROOT")"
MODE="${1:-ghostty}"

# role | folder | model ("" = your default) | opening instruction
ROLES=(
  "chief|$ROOT||You are the chief. Read CLAUDE.md. Do not write code. Wait for my instructions."
  "integrator|$ROOT|opus|You are the integrator. Read CLAUDE.md and .claude/agents/integrator.md. Wait until a branch is handed to you."
  "engine|$PARENT/$NAME-engine|opus|You are the engine agent. Read CLAUDE.md and .claude/agents/engine.md. Wait for a task from chief."
  "frontend|$PARENT/$NAME-frontend|sonnet|You are the frontend agent. Read CLAUDE.md and .claude/agents/frontend.md. Wait for a task from chief."
  "backend|$PARENT/$NAME-backend|sonnet|You are the backend agent. Read CLAUDE.md and .claude/agents/backend.md. Wait for a task from chief."
  "audio|$PARENT/$NAME-audio|sonnet|You are the audio agent. Read CLAUDE.md and .claude/agents/audio.md. Wait for a task from chief."
)

for entry in "${ROLES[@]}"; do
  IFS='|' read -r role dir model prompt <<<"$entry"
  if [[ ! -d "$dir" ]]; then
    echo "missing worktree: $dir  (run: git worktree add \"$dir\" $role)" >&2
    exit 1
  fi
done

launch_cmd() {  # prints a shell-escaped `claude ...` command line
  local role="$1" model="$2" prompt="$3"
  local cmd=(claude --name "$role")
  [[ -n "$model" ]] && cmd+=(--model "$model")
  cmd+=("$prompt")
  printf '%q ' "${cmd[@]}"
}

case "$MODE" in
  list)
    for entry in "${ROLES[@]}"; do
      IFS='|' read -r role dir model prompt <<<"$entry"
      printf '%-11s %-45s %s\n' "$role" "$dir" "${model:-default}"
    done
    ;;
  tmux)
    SESSION="freedom"
    if tmux has-session -t "$SESSION" 2>/dev/null; then
      echo "tmux session '$SESSION' already exists — attaching. (tmux kill-session -t $SESSION to reset)" >&2
      exec tmux attach -t "$SESSION"
    fi
    first=1
    for entry in "${ROLES[@]}"; do
      IFS='|' read -r role dir model prompt <<<"$entry"
      cmd="$(launch_cmd "$role" "$model" "$prompt")"
      if (( first )); then
        tmux new-session -d -s "$SESSION" -n "$role" -c "$dir" "$cmd"
        first=0
      else
        tmux new-window -t "$SESSION" -n "$role" -c "$dir" "$cmd"
      fi
    done
    tmux select-window -t "$SESSION:chief"
    exec tmux attach -t "$SESSION"
    ;;
  ghostty)
    command -v ghostty >/dev/null || { echo "ghostty not found; try: $0 tmux" >&2; exit 1; }
    for entry in "${ROLES[@]}"; do
      IFS='|' read -r role dir model prompt <<<"$entry"
      args=(--name "$role")
      [[ -n "$model" ]] && args+=(--model "$model")
      setsid -f ghostty --working-directory="$dir" --title="FR: $role" -e claude "${args[@]}" "$prompt" >/dev/null 2>&1
      sleep 0.4   # let the window manager place each window before the next appears
    done
    echo "launched 6 windows: chief, integrator, engine, frontend, backend, audio"
    ;;
  *)
    echo "usage: $0 [ghostty|tmux|list]" >&2
    exit 2
    ;;
esac
