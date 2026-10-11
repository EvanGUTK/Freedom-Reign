# Freedom-Reign — team workflow (every tool)

This file is the single source of truth for how the team works, whatever harness an agent runs in: Claude Code reads it through `CLAUDE.md`; Codex CLI and OpenCode read `AGENTS.md` natively; Antigravity reads it natively or through its rules folder (see "Tool notes"). Claude-only mechanics live in `CLAUDE.md`.

## Roles and folders
Each role runs in its own git worktree on a long-lived branch of the same name. **Your role is the folder you were started in.**

| Folder | Role | Branch | In one line |
|---|---|---|---|
| `Freedom-Reign/` (main checkout) | **chief** or **integrator** — your opening instruction says which | `main` | chief directs and never codes; integrator is the only session that merges |
| `Freedom-Reign-engine/` | engine | `engine` | gameplay, physics, camera, enemies, loot |
| `Freedom-Reign-frontend/` | frontend | `frontend` | HUD, menus, screens — builds what ui-ux specs |
| `Freedom-Reign-backend/` | backend | `backend` | scripts, build, CI, persistence, netcode |
| `Freedom-Reign-audio/` | audio | `audio` | sounds, music, mixer |
| `Freedom-Reign-api-mcp/` | api-mcp | `api-mcp` | external APIs, MCP servers, harness configs, the team bus |
| `Freedom-Reign-artwork/` | artwork | `artwork` | 2D/3D asset creation and import pipeline |
| `Freedom-Reign-ui-ux/` | ui-ux | `ui-ux` | flows, wireframes, usability specs in `docs/ux/` |
| `Freedom-Reign-validator/` | validator | `validator` | acceptance tests and bug reports on merged builds |
| `Freedom-Reign-visuals/` | visuals | `visuals` | shaders, VFX, lighting, post-processing |

- Your role card: `.claude/agents/<role>.md` — plain markdown, read it before your first task (the folder name is a Claude convention; the cards are for everyone).
- Rules every session follows, in every tool: `.claude/rules/engineering.md`, `.claude/rules/context.md`, `.claude/rules/preferences.md`. Claude loads them automatically; every other harness reads all three at session start.
- What we are building and why: `docs/DESIGN.md`. Shared interfaces: `docs/CONTRACTS.md`. Follow-ups: `docs/BACKLOG.md`. Where we stopped and how to resume: `docs/STATUS.md`.

## Chain of command
- The **user** talks mainly to the chief.
- The **chief** directs. It splits work into task cards and sends them to specialists, answers their questions, records what the user teaches (into rules, contracts, or a skill), and hands finished branches to the integrator. The chief never writes code.
- **Specialists** do the work on their own branch and report to the chief.
- The **integrator** is the only session that merges to or pushes `main`. The **validator** checks merged builds against what was asked; it never fixes.

Questions flow up, never sideways: specialist → chief → user. A specialist that is unsure sends the chief one precise question and keeps working on whatever is not blocked. A specialist never stops on a blocker silently: the message to the chief goes out first. The chief answers from the rules, contracts, and preferences; only when it cannot answer confidently does it ask the user — then it records the answer so nothing is asked twice. Specialists do not message each other or the user directly.

## Talking to each other
- Claude Code sessions message each other directly by role name (see `CLAUDE.md`).
- Across tools, every session uses the **team bus** once it exists: `scripts/team.sh send <role> "<subject>"` (body on stdin or as a second argument), `scripts/team.sh inbox` (your unread; role from your folder), `scripts/team.sh ack <id>`, `scripts/team.sh who`. Spec: `docs/CONTRACTS.md` → "Team bus". Until it lands, the user relays.
- Only Claude Code sessions are woken by a message. In every other harness, check your inbox at the start and end of each task, and whenever the user says "check inbox".
- A message carries a task card or a report, never file contents. Work travels by branches: say which branch and commit.

## Git rules for every session
- Edit only inside the folder you were started in. Never `cd` into another worktree.
- Only the integrator commits to or pushes `main`. Exception: the chief may commit documentation-only changes (`AGENTS.md`, `CLAUDE.md`, `.claude/`, `docs/`) to `main` and must push them immediately.
- The chief and the integrator share the main checkout. While a merge request is open (sent to the integrator and not yet reported back), the chief does not commit on `main`; it queues its docs changes and lands them in one commit after the integrator reports.
- Start every task with `git merge main`.
- Commits are atomic: one logical change per commit, each builds and passes tests on its own. Message format: `type: what and why` with type one of `feat`, `fix`, `refactor`, `test`, `docs`, `chore`. Never `--no-verify`, never force-push, never rewrite pushed history.
- Never commit secrets, credentials, generated output, or any file over 5 MB without the user's explicit say-so.
- Done means: committed, pushed, and reported to the chief with what changed, which branch, and how to verify it.
- `scripts/check.sh` is the gate. Green at every commit, not only at the tip.

## Chief
Does not write code. Reads `docs/CONTRACTS.md` and `.claude/rules/preferences.md` before planning. Decides shared interfaces first and writes them to `docs/CONTRACTS.md`, then dispatches one task card per role (format in `.claude/skills/dispatch/SKILL.md`). Everything the user teaches goes into the rules, contracts, or a skill, and is pushed so every session learns it (`.claude/skills/capture-feedback/SKILL.md`).

## Integrator
Reviews a finished branch against `.claude/rules/engineering.md` and `docs/CONTRACTS.md`, merges the pinned commit with `git merge --no-ff <hash>`, runs `scripts/check.sh` (and the self-tests under `scripts/tests/`), pushes `main`, then cleans up temporary task branches and worktrees. Rejects work that takes shortcuts — it goes back to the specialist with the exact reason. Never removes the long-lived folders above, never rewrites `main`.

## Which tool runs which role — starting assignment, change freely
| Role | Harness | Why |
|---|---|---|
| chief, integrator, engine | Claude Code | the chief's skills and cross-session messaging live here; the integrator's review quality and engine's reasoning are the two seats where the strongest model matters most |
| backend, api-mcp | Codex CLI | strong at tooling, servers, protocols, and MCP work |
| frontend, ui-ux, visuals, artwork | Antigravity | multimodal — can look at screenshots and mockups, evaluate or generate images |
| validator | OpenCode | a cheap seat that runs checks and bots and writes reports; any capable model will do |
Any role can run in any harness; the role card and these rules are the same everywhere.

## Tool notes
- **Claude Code**: `CLAUDE.md` imports this file; `.claude/rules/` auto-load; `.claude/agents/` double as subagent types. Start: `claude --name <role>` in the role's folder.
- **Codex CLI**: reads `AGENTS.md`. Start `codex` in the role's folder and open with "You are the <role> agent. Read AGENTS.md, .claude/rules/*.md and .claude/agents/<role>.md, then check your inbox."
- **OpenCode**: reads `AGENTS.md`; project config in `opencode.json` (owned by api-mcp). Same opening line.
- **Antigravity**: api-mcp verifies whether it reads `AGENTS.md` directly or needs a pointer in its rules folder, and adds that pointer if so. Same opening line.
