---
name: capture-feedback
description: Chief-only. Turn what the user says after testing a build — likes, dislikes, preferences, bugs, answers to questions — into a durable rule, contract, skill, or task, then push it to every agent. Use whenever the user gives feedback or answers a question an agent asked.
---
# Capture feedback

The goal is that nothing the user tells you has to be told twice. Every item of feedback goes to exactly one home.

## 1. Classify each item
| Kind | Example | Home |
|---|---|---|
| Preference about how things should feel or be built | "menus should fade, not pop", "no magic numbers" | `.claude/rules/preferences.md` |
| Decision about an interface two roles share | "save files are JSON, versioned" | `docs/CONTRACTS.md` |
| Repeatable procedure worth teaching | "how we add a new enemy type" | new `.claude/skills/<name>/SKILL.md` |
| Something broken | "jump stutters on slopes" | task for the owning role (use `dispatch`) |
| Answer to a question an agent asked | — | the rule or contract it belongs in **and** reply to that agent |

## 2. Write it small
One or two lines: what to do, and why if the why is not obvious. Rules are read by every session on every start, so each line costs context forever — earn it. Merge with an existing line when one already covers the topic instead of adding a near-duplicate.

A new skill needs frontmatter (`name`, `description` saying when to use it) and numbered steps. Keep it under 60 lines.

## 3. Commit and propagate
- `git add` only the files you changed under `.claude/`, `docs/`, or `CLAUDE.md`. Commit message: `docs: <what was learned>`. Push `main`.
- `SendMessage` every specialist (`engine`, `frontend`, `backend`, `audio`) and `integrator`: first line "Rules updated — run `git merge main` before your next task", then the one-line summary of what changed.

## 4. Confirm to the user
Reply with each item and where it now lives, in one line each. If something was too vague to record ("make it better"), say so and ask the one question that would make it recordable.
