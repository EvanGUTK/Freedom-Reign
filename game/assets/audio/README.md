# Audio assets

Dark fantasy, stylized: low, dry, slightly dissonant, readable at a glance. Hits
are short and bassy, danger is a falling pitch, loot is a bell.

## Naming scheme

A sound id is `<category>.<name>` in snake_case and maps to one file:

| Id prefix | Folder | Format | Bus |
|---|---|---|---|
| `sfx.` | `sfx/` | `.wav` | `SFX` |
| `ui.` | `ui/` | `.wav` | `UI` |
| `music.` | `music/` | `.ogg` | `Music` |

`sfx.attack_hit` is `sfx/attack_hit.wav`; `music.arena` is `music/arena.ogg`.
Every id and its path is listed in `game/scripts/audio/sound_catalog.gd`; adding
a sound means adding the id there, to `docs/CONTRACTS.md`, and to
`tools/audio/generate.py`.

## Formats and size

- SFX and UI: WAV, 44.1 kHz, 16-bit, mono (a mono source is what `AudioStreamPlayer3D` positions).
- Music: OGG Vorbis, 44.1 kHz, mono, 96 kbit/s, looped by `AudioManager`.
- One file at most 2 MB, all slice audio at most 10 MB. A test enforces both.

## Loudness targets

| Kind | Peak target |
|---|---|
| SFX and UI | −6 dBFS |
| Music | −14 dBFS |

The generator normalises every sound to its target; `tools/audio/test_generate.py`
checks it. Bus volumes stay at 0 dB.

## Regenerating

`python3 tools/audio/generate.py` rewrites every file here (standard library
plus `ffmpeg` for the OGG encode). It is deterministic: fixed seeds per id,
fixed encoder settings. Run the checks with
`python3 -m unittest discover -s tools/audio`. See `SOURCES.md` for provenance.
