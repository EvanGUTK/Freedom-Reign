#!/usr/bin/env bash
# Freedom-Reign team sessions. This script never opens windows: you open CLI
# windows inside BridgeMind yourself and paste the command it prints.
#
#   scripts/launch-team.sh cmd engine        print the command to paste into a window for that role
#   scripts/launch-team.sh cmd               print the command for every role
#   scripts/launch-team.sh list              show roles, folders, models
#   scripts/launch-team.sh tmux [role ...]   inside ONE window: a tmux tab per role (Ctrl-b 0..5)
#
# Every session gets --name <role> so the chief can address it with SendMessage.
# The chief uses your saved default model; the others get the model listed below.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"   # main checkout (chief + integrator)
PARENT="$(dirname "$ROOT")"
NAME="$(basename "$ROOT")"
MODE="${1:-cmd}"
ONLY=("${@:2}")   # optional role filter; empty = all

wanted() {  # wanted <role> → true if no filter or role is in the filter
  (( ${#ONLY[@]} == 0 )) && return 0
  local r; for r in "${ONLY[@]}"; do [[ "$r" == "$1" ]] && return 0; done
  return 1
}

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

paste_cmd() {  # human-readable command line for one role (prompts contain no single quotes)
  local role="$1" model="$2" prompt="$3"
  local cmd="claude --name $role"
  [[ -n "$model" ]] && cmd+=" --model $model"
  printf "%s '%s'" "$cmd" "$prompt"
}

tmux_cmd() {  # fully shell-escaped command line for tmux
  local role="$1" model="$2" prompt="$3"
  local argv=(claude --name "$role")
  [[ -n "$model" ]] && argv+=(--model "$model")
  argv+=("$prompt")
  printf '%q ' "${argv[@]}"
}

case "$MODE" in
  cmd)
    for entry in "${ROLES[@]}"; do
      IFS='|' read -r role dir model prompt <<<"$entry"
      wanted "$role" || continue
      printf '# %s\ncd %s && %s\n\n' "$role" "$dir" "$(paste_cmd "$role" "$model" "$prompt")"
    done
    ;;
  list)
    for entry in "${ROLES[@]}"; do
      IFS='|' read -r role dir model prompt <<<"$entry"
      wanted "$role" || continue
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
      wanted "$role" || continue
      cmd="$(tmux_cmd "$role" "$model" "$prompt")"
      if (( first )); then
        tmux new-session -d -s "$SESSION" -n "$role" -c "$dir" "$cmd"
        first=0
      else
        tmux new-window -t "$SESSION" -n "$role" -c "$dir" "$cmd"
      fi
    done
    tmux select-window -t "$SESSION:chief" 2>/dev/null || true
    exec tmux attach -t "$SESSION"
    ;;
  *)
    echo "usage: $0 [cmd|list|tmux] [role ...]" >&2
    exit 2
    ;;
esac
