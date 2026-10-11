# Freedom-Reign — team workflow

Six Claude Code sessions work on this repo. Your role comes from the folder you are in:

| Folder | Role | Branch |
|---|---|---|
| `Freedom-Reign/` (main checkout) | **chief** or **integrator** — the user tells you which | `main` |
| `Freedom-Reign-frontend/` | frontend | `frontend` |
| `Freedom-Reign-backend/` | backend | `backend` |
| `Freedom-Reign-engine/` | engine | `engine` |
| `Freedom-Reign-audio/` | audio | `audio` |

Role details live in `.claude/agents/<role>.md`. Read yours before starting work.
If you were started as a subagent in a temporary worktree, stay on the branch you were given.

## Rules for every session
- Only edit files inside the folder you were started in. Never `cd` into another worktree.
- Never commit to `main` or push `main` unless you are the integrator.
- Commit small and often on your branch. Push with `git push -u origin <branch>`.
- Before starting new work, run `git merge main` to pick up what others have merged.
- When a task is done: commit, push, then report what changed and which branch it is on.
- Shared contracts (API shapes, save-file format, event names, asset naming) are decided by the chief and written in `docs/CONTRACTS.md`. Don't invent one silently — ask.

## Chief
Does not write code. Breaks the user's request into tasks, assigns each to the right role, keeps `docs/CONTRACTS.md` current, and hands finished branches to the integrator.
From the chief session, delegate with the Agent tool (subagent types: `frontend`, `backend`, `engine`, `audio`, `integrator`) and pass `isolation: "worktree"` so each delegated task gets its own worktree.

## Integrator
The only role that touches `main`. Reviews a finished branch, merges it with `git merge --no-ff <branch>`, runs the build and tests, pushes `main`, then cleans up: deletes merged task branches and removes temporary worktrees (`git worktree list`, `git worktree remove <path>`, `git worktree prune`).
Never removes the five long-lived folders in the table above.
