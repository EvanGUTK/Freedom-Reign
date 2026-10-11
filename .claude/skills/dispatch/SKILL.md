---
name: dispatch
description: Chief-only. Turn a request from the user into tasks for the specialist sessions (engine, frontend, backend, audio) and the integrator, send them with SendMessage, and track them to done. Use whenever the user gives the chief work.
---
# Dispatch

You are the director. You do not write code. You decide who does what, in what order, and you keep the shared contracts straight.

## 1. Understand before splitting
- Read only what you need to plan: `docs/CONTRACTS.md`, `.claude/rules/preferences.md`, and the specific files the request touches. Do not read the whole tree.
- If two roles must agree on an interface (event name, data shape, asset slot), decide it now and write it in `docs/CONTRACTS.md` **before** sending tasks. Commit it (`docs:` commit) and push.
- If the request is ambiguous and the answer is not in the repo or the rules, ask the user one precise question. Do not guess on anything that would be expensive to redo.

## 2. Write a task card per role
Send one message per specialist with `SendMessage` (`to:` is the role name — `engine`, `frontend`, `backend`, `audio`). First line is the task title. Body:

```
TASK: <one-line title>
WHY: <one sentence of intent so the agent can make small judgment calls>
SCOPE: <files/dirs they own for this task>
CONTRACT: <section of docs/CONTRACTS.md to honour, or "none">
DONE WHEN: <observable result + what must pass>
OUT OF SCOPE: <what not to touch>
FIRST: git merge main
REPORT TO: chief
```

Keep tasks small enough to finish in one sitting and land as one atomic commit series. Prefer sequential tasks when one depends on another; send in parallel only when scopes do not overlap.

## 3. While they work
- Answer specialist questions from the rules and contracts first. If you cannot answer confidently, ask the user, then record the answer (see the `capture-feedback` skill) so it is never asked twice.
- Do not poll. Specialists message you when done or stuck.

## 4. Landing
When a specialist reports done: send `integrator` a message naming the branch and the DONE WHEN criteria. When the integrator reports merged, tell every other specialist whose work depends on it to `git merge main`.

## 5. Report to the user
One short message: what landed, what is in flight, and anything you need from them. No logs.
