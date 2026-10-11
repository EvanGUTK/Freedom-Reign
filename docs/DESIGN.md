# Freedom-Reign — design brief

_Owner: chief. Last updated 2026-10-10. Changes to this file are `docs:` commits on `main`; the chief tells every session to `git merge main` after one._

## One line
A 3D third-person action RPG in the Diablo tradition — fight, loot, build, repeat — where real platforming (jumping, ledges, traversal) is part of combat and exploration, not just the walk between rooms.

## Fixed decisions
| | |
|---|---|
| Engine | Godot 4.x (4.7 on the dev machine), GDScript. No C#/.NET toolchain. |
| Platform | PC: Linux and Windows desktop builds. No web, no mobile. |
| Perspective | 3D third-person; camera behind and above the character. Must stay readable in both melee crowds and jumps. |
| Input | Keyboard + mouse and gamepad, both from day one. |
| Players | Single-player first. Networking is not a goal until the vertical slice is fun. |
| Target | 60 fps on mid-range hardware. |
| Art direction | **Dark fantasy, stylized — not realistic.** Bold silhouettes, readable shapes at distance, a restrained palette with deliberate accent colors for threats and loot (serves pillar 3). No photoreal textures or PBR-heavy assets. Audio follows the same rule: atmospheric and distinct, not cinematic-realistic. (Decided 2026-10-10.) |

## Pillars — use these to settle arguments
1. **Every fight has a vertical dimension.** Height, ledges, and jumps matter in combat, not only in traversal.
2. **Loot changes how you play.** Items grant or alter abilities; they are not just bigger numbers.
3. **Readable chaos.** Many enemies on screen, but the player can always see the threat and the ground.

## Not Diablo
"Diablo-like" means the loop above. We do not reuse Diablo's names, classes, items, lore, art, or UI layout.

## Milestone 1 — skeleton (now)
The Godot project opens, a hello scene runs headless, `scripts/check.sh` passes (import + tests), `.gitignore` covers Godot's generated files. Nothing else. This exists so the integrator has something to run before any feature lands.

## Milestone 2 — vertical slice
One arena. Move, jump, one melee attack, one enemy type, one loot drop that changes the attack, one sound effect, one pause menu. Playable start to finish in under two minutes. This is the first build the user plays.

## Open questions — the chief asks the user when a task needs the answer
- Classes vs. classless builds
- Hand-built levels vs. procedural
