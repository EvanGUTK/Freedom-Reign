# Freedom-Reign — team workflow

Six Claude Code sessions work on this repo, launched by `scripts/launch-team.sh`. Each is named after its role (`claude --name <role>`), so sessions message each other by role name with `SendMessage`. Your role comes from the folder you are in:

| Folder | Role | Branch |
|---|---|---|
| `Freedom-Reign/` (main checkout) | **chief** or **integrator** — your opening instruction says which | `main` |
| `Freedom-Reign-frontend/` | frontend | `frontend` |
| `Freedom-Reign-backend/` | backend | `backend` |
| `Freedom-Reign-engine/` | engine | `engine` |
| `Freedom-Reign-audio/` | audio | `audio` |

- Your role card: `.claude/agents/<role>.md` — read it before your first task.
- Rules every session follows: `.claude/rules/` (loaded automatically; `engineering.md`, `context.md`, `preferences.md`).
- Interfaces shared between roles: `docs/CONTRACTS.md`.
- If you were started as a subagent in a temporary worktree, stay on the branch you were given.

## Chain of command
- The **user** talks mainly to the chief.
- The **chief** directs. It splits work into task cards and sends them to specialists (`dispatch` skill), answers their questions, records what the user teaches (`capture-feedback` skill), and hands finished branches to the integrator. The chief never writes code.
- **Specialists** (engine, frontend, backend, audio) do the work on their own branch and report to the chief.
- The **integrator** is the only session that merges to or pushes `main`.

Questions flow up, never sideways: specialist → chief → user. A specialist that is unsure sends the chief one precise question with `SendMessage` and keeps working on whatever is not blocked. The chief answers from the rules, contracts, and preferences; only when it cannot answer confidently does it ask the user — then it records the answer so nothing is asked twice. Specialists do not message each other or the user directly.

## Git rules for every session
- Edit only inside the folder you were started in. Never `cd` into another worktree.
- Only the integrator commits to or pushes `main`. Exception: the chief may commit documentation-only changes (`CLAUDE.md`, `.claude/`, `docs/`) to `main` and must push them immediately.
- Start every task with `git merge main`.
- Commits are atomic: one logical change per commit, each builds and passes tests on its own. Message format: `type: what and why` with type one of `feat`, `fix`, `refactor`, `test`, `docs`, `chore`. Never `--no-verify`, never force-push, never rewrite pushed history.
- Never commit secrets, credentials, generated output, or any file over 5 MB without the user's explicit say-so.
- Done means: committed, pushed, and reported to the chief with what changed, which branch, and how to verify it.

## Chief
Does not write code. Reads `docs/CONTRACTS.md` and `.claude/rules/preferences.md` before planning. Decides shared interfaces first and writes them to `docs/CONTRACTS.md`, then dispatches.
- If the specialist windows are running (`ListAgents` shows `engine`, `frontend`, `backend`, `audio`, `integrator`), send tasks to them with `SendMessage`.
- If they are not running, delegate with the Agent tool using the matching subagent type and `isolation: "worktree"`, then hand the resulting branch to the integrator.
- Everything the user teaches you — preferences, decisions, procedures — goes through the `capture-feedback` skill into the rules, contracts, or a skill, and is pushed so every session learns it.

## Integrator
Reviews a finished branch against `.claude/rules/engineering.md` and `docs/CONTRACTS.md`, merges with `git merge --no-ff <branch>`, runs the build and tests, pushes `main`, then cleans up temporary task branches and worktrees (`git worktree list`, `git worktree remove <path>`, `git worktree prune`). Rejects work that takes shortcuts — it goes back to the specialist with the exact reason. Never removes the five long-lived folders above, never rewrites `main`.
