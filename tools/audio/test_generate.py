"""Checks for tools/audio/generate.py: determinism, loudness targets, a seamless music loop.

Run from the repo root: python3 -m unittest discover -s tools/audio
"""

import unittest

import generate

PEAK_TOLERANCE_DB = 0.05
# A loop seam is seamless when the jump from the last sample back to the first
# is no bigger than the largest step between neighbouring samples elsewhere.
SEAM_STEP_MARGIN = 1.0


class SfxTest(unittest.TestCase):
    def test_every_sfx_is_deterministic(self) -> None:
        for sound_id in generate.SFX:
            with self.subTest(sound_id):
                self.assertEqual(generate.render_sfx(sound_id), generate.render_sfx(sound_id))

    def test_every_sfx_peaks_at_the_target(self) -> None:
        for sound_id in generate.SFX:
            with self.subTest(sound_id):
                self.assertAlmostEqual(
                    generate.peak_dbfs(generate.render_sfx(sound_id)),
                    generate.SFX_PEAK_DBFS,
                    delta=PEAK_TOLERANCE_DB,
                )

    def test_sounds_differ_from_each_other(self) -> None:
        rendered = [tuple(generate.render_sfx(sound_id)) for sound_id in generate.SFX]
        self.assertEqual(len(set(rendered)), len(rendered))


class MusicTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.music = generate.render_music()

    def test_music_is_deterministic(self) -> None:
        self.assertEqual(self.music, generate.render_music())

    def test_music_length_is_the_loop_length(self) -> None:
        self.assertEqual(len(self.music), generate.count(generate.MUSIC_LOOP_SECONDS))

    def test_music_peaks_at_the_target(self) -> None:
        self.assertAlmostEqual(generate.peak_dbfs(self.music), generate.MUSIC_PEAK_DBFS, delta=PEAK_TOLERANCE_DB)

    def test_loop_seam_is_no_bigger_than_the_largest_inner_step(self) -> None:
        seam = abs(self.music[0] - self.music[-1])
        largest_step = max(abs(b - a) for a, b in zip(self.music, self.music[1:]))
        self.assertLessEqual(seam, largest_step * SEAM_STEP_MARGIN)


class HelperTest(unittest.TestCase):
    def test_normalised_rejects_silence(self) -> None:
        with self.assertRaises(ValueError):
            generate.normalised([0.0, 0.0], generate.SFX_PEAK_DBFS)

    def test_periodic_freq_has_whole_cycles_per_loop(self) -> None:
        cycles = generate.periodic_freq(73.4) * generate.MUSIC_LOOP_SECONDS
        self.assertAlmostEqual(cycles, round(cycles), places=9)

    def test_add_wrapped_rings_across_the_seam(self) -> None:
        buffer = [0.0] * 10
        generate.add_wrapped(buffer, [1.0] * 4, 8 / generate.SAMPLE_RATE)
        self.assertEqual(buffer, [1.0, 1.0] + [0.0] * 6 + [1.0, 1.0])


if __name__ == "__main__":
    unittest.main()
