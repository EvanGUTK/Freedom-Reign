#!/usr/bin/env python3
"""Deterministic generator for the slice's sounds (docs/CONTRACTS.md, "Audio").

Standard library only. Every sound is synthesised from sines and seeded noise,
so there is no third-party material. The same script on the same Python gives
the same files. SFX are written as 16-bit mono WAV; the music loop is
synthesised as WAV in a temporary folder and encoded to OGG Vorbis with ffmpeg
using fixed settings.

Usage: python3 tools/audio/generate.py [--out DIR]
"""

import argparse
import math
import random
import subprocess
import tempfile
import wave
import zlib
from pathlib import Path
from typing import Callable

SAMPLE_RATE = 44100
SFX_PEAK_DBFS = -6.0
MUSIC_PEAK_DBFS = -14.0
INT16_MAX = 32767
VORBIS_BITRATE = "96k"
MUSIC_LOOP_SECONDS = 24
MUSIC_ID = "music.arena"
FFMPEG = "ffmpeg"

REPO_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_OUT = REPO_ROOT / "game" / "assets" / "audio"

Samples = list[float]


# --- building blocks ---------------------------------------------------------


def count(seconds: float) -> int:
    return round(seconds * SAMPLE_RATE)


def db_to_linear(db: float) -> float:
    return 10.0 ** (db / 20.0)


def sweep(f_start: float, f_end: float, n: int, harmonics: int = 1) -> Samples:
    """Sine (plus 1/k harmonics) gliding exponentially from f_start to f_end."""
    out = [0.0] * n
    phase = 0.0
    for i in range(n):
        frac = i / max(n - 1, 1)
        freq = f_start * (f_end / f_start) ** frac
        phase += 2.0 * math.pi * freq / SAMPLE_RATE
        out[i] = sum(math.sin(k * phase) / k for k in range(1, harmonics + 1))
    return out


def partials(parts: list[tuple[float, float]], n: int) -> Samples:
    """Sum of fixed-frequency sines given as (frequency_hz, amplitude)."""
    step = 2.0 * math.pi / SAMPLE_RATE
    return [sum(amp * math.sin(step * freq * i) for freq, amp in parts) for i in range(n)]


def noise(rng: random.Random, n: int) -> Samples:
    return [rng.uniform(-1.0, 1.0) for _ in range(n)]


def lowpass(x: Samples, cutoff_hz: float) -> Samples:
    alpha = 1.0 - math.exp(-2.0 * math.pi * cutoff_hz / SAMPLE_RATE)
    out = [0.0] * len(x)
    y = 0.0
    for i, s in enumerate(x):
        y += alpha * (s - y)
        out[i] = y
    return out


def highpass(x: Samples, cutoff_hz: float) -> Samples:
    return [s - low for s, low in zip(x, lowpass(x, cutoff_hz))]


def shaped(n: int, attack_s: float, decay_s: float) -> Samples:
    """Linear attack followed by an exponential decay."""
    out = [0.0] * n
    for i in range(n):
        t = i / SAMPLE_RATE
        rise = min(1.0, t / attack_s) if attack_s > 0 else 1.0
        out[i] = rise * math.exp(-t / decay_s)
    return out


def swell(n: int, peak_fraction: float) -> Samples:
    """Raised-cosine rise to peak_fraction of the length, then a fall to zero."""
    peak = max(1, round(n * peak_fraction))
    out = [0.0] * n
    for i in range(n):
        if i < peak:
            out[i] = 0.5 - 0.5 * math.cos(math.pi * i / peak)
        else:
            out[i] = 0.5 + 0.5 * math.cos(math.pi * (i - peak) / max(n - peak, 1))
    return out


def tremolo(n: int, rate_hz: float, depth: float) -> Samples:
    return [1.0 - depth * 0.5 * (1.0 + math.sin(2.0 * math.pi * rate_hz * i / SAMPLE_RATE)) for i in range(n)]


def mul(a: Samples, b: Samples) -> Samples:
    return [x * y for x, y in zip(a, b)]


def scale(x: Samples, gain: float) -> Samples:
    return [s * gain for s in x]


def mix(*tracks: Samples) -> Samples:
    length = max(len(t) for t in tracks)
    out = [0.0] * length
    for track in tracks:
        for i, s in enumerate(track):
            out[i] += s
    return out


def placed(x: Samples, offset_s: float, total: int) -> Samples:
    out = [0.0] * total
    start = count(offset_s)
    for i, s in enumerate(x):
        if start + i < total:
            out[start + i] = s
    return out


def normalised(x: Samples, peak_dbfs: float) -> Samples:
    peak = max(abs(s) for s in x)
    if peak == 0.0:
        raise ValueError("cannot normalise silence")
    return scale(x, db_to_linear(peak_dbfs) / peak)


def peak_dbfs(x: Samples) -> float:
    return 20.0 * math.log10(max(abs(s) for s in x))


def write_wav(path: Path, x: Samples) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    frames = b"".join(int(round(s * INT16_MAX)).to_bytes(2, "little", signed=True) for s in x)
    with wave.open(str(path), "wb") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(SAMPLE_RATE)
        wav.writeframes(frames)


# --- sound effects -----------------------------------------------------------


def jump(rng: random.Random) -> Samples:
    n = count(0.2)
    body = sweep(240, 480, n, harmonics=2)
    breath = lowpass(noise(rng, n), 3000)
    return mul(mix(scale(body, 0.7), scale(breath, 0.3)), shaped(n, 0.01, 0.07))


def land(rng: random.Random) -> Samples:
    n = count(0.28)
    thud = mul(sweep(110, 42, n), shaped(n, 0.002, 0.09))
    grit = mul(lowpass(noise(rng, n), 600), shaped(n, 0.001, 0.05))
    return mix(thud, scale(grit, 0.6))


def attack_swing(rng: random.Random) -> Samples:
    n = count(0.32)
    air = highpass(lowpass(noise(rng, n), 3500), 500)
    edge = scale(sweep(300, 180, n), 0.15)
    return mul(mix(air, edge), swell(n, 0.35))


def attack_hit(rng: random.Random) -> Samples:
    n = count(0.35)
    crack = mul(highpass(noise(rng, n), 800), shaped(n, 0.001, 0.04))
    thump = mul(sweep(150, 55, n), shaped(n, 0.002, 0.1))
    ring = mul(partials([(523, 0.3), (791, 0.2), (1180, 0.1)], n), shaped(n, 0.001, 0.12))
    return mix(crack, thump, ring)


def player_hurt(rng: random.Random) -> Samples:
    n = count(0.4)
    low = sweep(340, 170, n, harmonics=3)
    detuned = sweep(361, 181, n, harmonics=3)
    grit = lowpass(noise(rng, n), 1500)
    return mul(mix(low, detuned, scale(grit, 0.4)), shaped(n, 0.005, 0.18))


def player_die(rng: random.Random) -> Samples:
    n = count(1.6)
    fall = sweep(220, 48, n, harmonics=2)
    dread = mul(fall, tremolo(n, 7.0, 0.3))
    breath = mul(lowpass(noise(rng, n), 500), shaped(n, 0.05, 0.5))
    return mul(mix(dread, scale(breath, 0.5)), shaped(n, 0.02, 0.6))


def enemy_die(rng: random.Random) -> Samples:
    n = count(0.65)
    growl = sweep(190, 60, n, harmonics=4)
    rasp = lowpass(noise(rng, n), 1200)
    voiced = mul(mix(growl, scale(rasp, 0.5)), tremolo(n, 30.0, 0.5))
    return mul(voiced, shaped(n, 0.005, 0.25))


def loot_drop(rng: random.Random) -> Samples:
    n = count(0.7)
    root = 587.0
    bell = partials([(root, 1.0), (root * 2.76, 0.5), (root * 5.4, 0.25), (root * 8.9, 0.12)], n)
    clink = mul(highpass(noise(rng, n), 4000), shaped(n, 0.001, 0.015))
    return mix(mul(bell, shaped(n, 0.001, 0.25)), scale(clink, 0.4))


def loot_pickup(rng: random.Random) -> Samples:
    del rng  # purely tonal
    n = count(0.45)
    note_n = count(0.3)
    chime = [(1.0, 1.0), (2.01, 0.4), (3.02, 0.15)]

    def note(root: float) -> Samples:
        return mul(partials([(root * r, a) for r, a in chime], note_n), shaped(note_n, 0.002, 0.12))

    return mix(placed(note(659), 0.0, n), placed(note(988), 0.1, n))


def two_tone(first_hz: float, second_hz: float) -> Samples:
    n = count(0.28)
    half = count(0.14)
    first = mul(partials([(first_hz, 1.0)], half), shaped(half, 0.005, 0.07))
    second = mul(partials([(second_hz, 1.0)], half), shaped(half, 0.005, 0.07))
    return mix(placed(first, 0.0, n), placed(second, 0.12, n))


def pause_open(rng: random.Random) -> Samples:
    del rng
    return two_tone(392, 294)


def pause_close(rng: random.Random) -> Samples:
    del rng
    return two_tone(294, 392)


def click(rng: random.Random) -> Samples:
    n = count(0.07)
    tick = mul(partials([(1200, 1.0)], n), shaped(n, 0.001, 0.012))
    snap = mul(highpass(noise(rng, n), 2000), shaped(n, 0.0005, 0.006))
    return mix(tick, scale(snap, 0.4))


# --- music -------------------------------------------------------------------


def periodic_freq(freq: float) -> float:
    """Nearest frequency with a whole number of cycles per loop, so the loop is seamless."""
    return round(freq * MUSIC_LOOP_SECONDS) / MUSIC_LOOP_SECONDS


def add_wrapped(buffer: Samples, event: Samples, offset_s: float) -> None:
    """Add event at offset_s, wrapping past the end so a tail rings across the loop seam."""
    start = count(offset_s)
    length = len(buffer)
    for i, s in enumerate(event):
        buffer[(start + i) % length] += s


def arena_music(rng: random.Random) -> Samples:
    n = count(MUSIC_LOOP_SECONDS)
    step = 2.0 * math.pi / SAMPLE_RATE

    # Drone: D minor root, fifth, minor third and a sub, each breathing slowly.
    drone_parts = [(36.7, 0.6, 3), (73.4, 1.0, 4), (110.0, 0.5, 5), (174.6, 0.3, 6)]
    drone = [0.0] * n
    for freq, amp, lfo_cycles in drone_parts:
        f = periodic_freq(freq)
        for i in range(n):
            breathe = 0.75 + 0.25 * math.sin(2.0 * math.pi * lfo_cycles * i / n)
            drone[i] += amp * breathe * math.sin(step * f * i)

    # Wind: periodic sines at random loop-aligned frequencies, so it needs no crossfade.
    wind = [0.0] * n
    for _ in range(10):
        f = periodic_freq(rng.uniform(180.0, 700.0))
        phase = rng.uniform(0.0, 2.0 * math.pi)
        lfo_cycles = rng.randint(1, 6)
        lfo_phase = rng.uniform(0.0, 2.0 * math.pi)
        for i in range(n):
            gust = 0.5 + 0.5 * math.sin(2.0 * math.pi * lfo_cycles * i / n + lfo_phase)
            wind[i] += gust * math.sin(step * f * i + phase)

    # Heartbeat: one low thump every three seconds.
    beat_n = count(0.5)
    beat = mul(sweep(70, 40, beat_n), shaped(beat_n, 0.005, 0.12))
    heart = [0.0] * n
    for k in range(MUSIC_LOOP_SECONDS // 3):
        add_wrapped(heart, beat, k * 3.0)

    # Sparse bells in D minor pentatonic; tails wrap across the seam.
    bell_n = count(2.5)
    bells = [0.0] * n
    for when, root in [(2.0, 293.7), (7.5, 349.2), (11.0, 440.0), (17.5, 261.6), (21.0, 392.0)]:
        bell = partials([(root, 1.0), (root * 2.76, 0.4), (root * 5.4, 0.15)], bell_n)
        add_wrapped(bells, mul(bell, shaped(bell_n, 0.003, 0.6)), when)

    return mix(scale(drone, 0.5), scale(wind, 0.06), scale(heart, 0.5), scale(bells, 0.15))


# --- catalog and output ------------------------------------------------------

# id -> (output path relative to the audio folder, synthesiser)
SFX: dict[str, tuple[str, Callable[[random.Random], Samples]]] = {
    "sfx.jump": ("sfx/jump.wav", jump),
    "sfx.land": ("sfx/land.wav", land),
    "sfx.attack_swing": ("sfx/attack_swing.wav", attack_swing),
    "sfx.attack_hit": ("sfx/attack_hit.wav", attack_hit),
    "sfx.player_hurt": ("sfx/player_hurt.wav", player_hurt),
    "sfx.player_die": ("sfx/player_die.wav", player_die),
    "sfx.enemy_die": ("sfx/enemy_die.wav", enemy_die),
    "sfx.loot_drop": ("sfx/loot_drop.wav", loot_drop),
    "sfx.loot_pickup": ("sfx/loot_pickup.wav", loot_pickup),
    "ui.pause_open": ("ui/pause_open.wav", pause_open),
    "ui.pause_close": ("ui/pause_close.wav", pause_close),
    "ui.click": ("ui/click.wav", click),
}
MUSIC_PATH = "music/arena.ogg"


def rng_for(sound_id: str) -> random.Random:
    """Stable per-sound seed (crc32, not hash(), which is salted per process)."""
    return random.Random(zlib.crc32(sound_id.encode()))


def render_sfx(sound_id: str) -> Samples:
    _, synth = SFX[sound_id]
    return normalised(synth(rng_for(sound_id)), SFX_PEAK_DBFS)


def render_music() -> Samples:
    return normalised(arena_music(rng_for(MUSIC_ID)), MUSIC_PEAK_DBFS)


def encode_ogg(wav_path: Path, ogg_path: Path) -> None:
    ogg_path.parent.mkdir(parents=True, exist_ok=True)
    command = [
        FFMPEG, "-y", "-v", "error", "-i", str(wav_path),
        "-ac", "1", "-ar", str(SAMPLE_RATE),
        "-c:a", "libvorbis", "-b:a", VORBIS_BITRATE,
        "-map_metadata", "-1", "-fflags", "+bitexact", "-flags:a", "+bitexact",
        str(ogg_path),
    ]  # fmt: skip
    try:
        subprocess.run(command, check=True, capture_output=True, text=True)
    except FileNotFoundError as error:
        raise SystemExit(f"error: '{FFMPEG}' not found; it encodes the music loop to OGG Vorbis") from error
    except subprocess.CalledProcessError as error:
        raise SystemExit(f"error: ffmpeg failed encoding {wav_path}:\n{error.stderr}") from error


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--out", type=Path, default=DEFAULT_OUT, help="audio folder (default: game/assets/audio)")
    out = parser.parse_args().out

    for sound_id, (relative, _) in SFX.items():
        write_wav(out / relative, render_sfx(sound_id))
        print(f"wrote {relative}")

    with tempfile.TemporaryDirectory() as scratch:
        music_wav = Path(scratch) / "arena.wav"
        write_wav(music_wav, render_music())
        encode_ogg(music_wav, out / MUSIC_PATH)
    print(f"wrote {MUSIC_PATH}")


if __name__ == "__main__":
    main()
