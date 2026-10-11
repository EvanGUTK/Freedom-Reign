# Status — paused 2026-10-10, late evening

Read this first when resuming. The chief keeps it current at every pause.

## Where things stand
- `main` is green: Milestone 1 (skeleton) and Milestone 2 (vertical slice) are landed. 177 GUT tests, `scripts/check.sh` PASS.
- The slice is playable: `scripts/play.sh` — WASD, mouse look, Space jump, left-click swing, Esc pause. Five husks, three platforms, first kill drops the Ember Cleaver, HUD, win/lose screens, 13 sounds and a music loop.
- User's verdict after the first playtest: works end to end; "super ugly" and that is fine — **engine first** (recorded in `.claude/rules/preferences.md`).
- All five specialist branches (`engine`, `backend`, `frontend`, `audio`) are fully merged; nothing is in flight. Every window was idle at pause.
- CI is **disabled** (`gh workflow disable check.yml`) because the GitHub account has a billing block. `check.sh` run by the integrator is the only gate; that is enough.

## How to resume
1. Open six BridgeMind CLI windows. In the first, in `~/Projects/BridgeMind/Freedom-Reign`, run `claude` and `/rename chief` (or `claude --name chief`). For the others, `scripts/launch-team.sh cmd` prints the exact line to paste per role (`integrator`, `engine`, `backend`, `frontend`, `audio`).
2. Each window asks to trust its folder once — yes.
3. In the chief window: "read docs/STATUS.md and continue". The chief checks `ListAgents`, then dispatches.
4. Optional, cuts wasted turns in every window: add to `~/.claude/settings.json` after the `"model"` line —
   `"env": { "ECC_DISABLED_HOOKS": "pre:bash:gateguard-fact-force,pre:edit-write:gateguard-fact-force" },`
   and set `"model": "fable"` if Fable 5.1 should be the default again (a `/model opus` in one window changed it).

## Decisions waiting on the user
- **Milestone 3 scope** — proposal below; say "go" or edit it.
- **Ledge rule** — on a 1.5 m platform edge the player is untouchable while still hitting down. Chief's recommendation: husks can hit up within a 2 m vertical gap, and attacks from above do 1.5× damage — height becomes a reward, not immunity. Needs a yes.
- **GitHub billing** (only if CI is ever wanted): Settings → Billing and plans → Payment information (clear the failed charge) and Budgets (Actions not capped at $0). Then `gh workflow enable check.yml`.

## Milestone 3 proposal — engine depth (not started)
1. Movement feel: coyote time, jump buffering, variable jump height, air control, camera collision and smoothing.
2. Combat feel: hit-stop, knockback both ways, enemy hit flash, player i-frames + dodge roll, attack wind-up/recovery.
3. Ledge rule (above).
4. Enemy AI as explicit states (idle/chase/attack/stagger/dead) and a second, ranged enemy type.
5. Data-driven loot table with 4–6 items that change attacks in different ways.
Mostly engine; frontend/audio only pick up new signals; backend idle unless save/load is wanted.

## Open follow-ups
See `docs/BACKLOG.md` (sound-id constants, clean quit during audio, CI generator tests, a test literal).

## Pointers
- Rules: `CLAUDE.md`, `.claude/rules/`. Contracts: `docs/CONTRACTS.md`. Design: `docs/DESIGN.md`. Chief procedures: `.claude/skills/dispatch`, `.claude/skills/capture-feedback`.
- Repo: https://github.com/EvanGUTK/Freedom-Reign (private).
