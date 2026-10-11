@AGENTS.md

# Claude Code specifics
- Sessions are named by role (`claude --name <role>` or `/rename <role>`). `ListAgents` shows which Claude windows are up; `SendMessage` to a role name delivers to that window and wakes it. Roles running in other harnesses are not in that list — reach them through the team bus (`scripts/team.sh`, see `AGENTS.md` → "Talking to each other").
- `.claude/rules/*.md` load automatically. `.claude/agents/*.md` are also subagent types: if a role's window is not running, the chief may delegate with the Agent tool and `isolation: "worktree"`, then hand the resulting branch to the integrator.
- Chief procedures are skills: `dispatch`, `capture-feedback`.
- If you were started as a subagent in a temporary worktree, stay on the branch you were given.
