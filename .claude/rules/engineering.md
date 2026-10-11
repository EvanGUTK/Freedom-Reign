# Engineering rules

These apply to every line of code in this repo, from every session. There is no "quick version". A shortcut that saves time today is a bug the integrator rejects tomorrow, so it never saves time.

## Correctness
- Finish the logic or do not commit it. No TODO-and-move-on, no stubs that silently do nothing, no commented-out code.
- Every error path is handled or deliberately propagated. Never swallow an exception, never return a fake success, never log-and-continue past a failure the caller needs to know about.
- Every loop has a termination condition you can name. Retries are capped (three at most) and then fail loudly.
- If something fails twice the same way, stop and report it to the chief. Do not keep retrying or try random variations.
- Never disable a test, lint rule, type check, or warning to get green. Fix the cause or report it.

## Structure
- One responsibility per function and per file. If you need "and" to describe what it does, split it.
- No duplicated logic. If the same code exists twice, extract it before adding a third copy.
- No magic numbers or strings; name them.
- Dependencies point one way: UI → engine API → engine internals; backend and audio expose APIs the engine calls, never the reverse. Never reach across a boundary because it is convenient.
- Match the existing code's style, naming, and conventions. Do not introduce a second way of doing something that already has one.
- Prefer the boring, readable solution. Performance work only with a measurement before and after, and the numbers in the commit message.

## Safety
- No secrets in code, logs, tests, or commits. Configuration comes from the environment; required variables are documented in `.env.example`.
- Validate every input that crosses a trust boundary: files, network, save data, user input. Never `eval`, never build shell commands or queries by string concatenation.
- No new dependency without the reason in the commit message, and pin its version.
- No network calls, telemetry, or writes outside the project folder that the task did not ask for.
- Destructive commands (`rm -rf`, `git reset --hard`, force-push, `sudo`) are blocked by `.claude/settings.json`. If you believe you need one, ask the chief; do not work around the block.

## Tests
- New logic ships with a test that would fail if the logic were wrong. A bug fix ships with the test that reproduces the bug.
- Run the project's build and tests before every commit. A commit that does not pass is not a commit.
