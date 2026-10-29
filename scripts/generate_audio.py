"""Generate deterministic, replaceable chiptune audio for the prototype."""

from __future__ import annotations

import argparse
import io
import math
import struct
import wave
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "assets" / "audio"
RATE = 22050


def wav_bytes(samples: list[float]) -> bytes:
    output = io.BytesIO()
    with wave.open(output, "wb") as sound:
        sound.setnchannels(1)
        sound.setsampwidth(2)
        sound.setframerate(RATE)
        sound.writeframes(b"".join(struct.pack("<h", max(-32767, min(32767, round(value * 32767)))) for value in samples))
    return output.getvalue()


def note(frequency: float, t: float) -> float:
    return math.sin(math.tau * frequency * t) + 0.18 * math.sin(math.tau * 2 * frequency * t)


def loop(melody: list[float], bass: list[float], beat: float, gain: float) -> bytes:
    duration = beat * len(melody)
    samples = []
    for index in range(round(duration * RATE)):
        t = index / RATE
        step = min(len(melody) - 1, int(t / beat))
        local = t - step * beat
        gate = min(1.0, local / 0.018, (beat - local) / 0.075)
        edge = min(1.0, t / 0.025, (duration - t) / 0.025)
        lead = note(melody[step], local) if melody[step] else 0.0
        low = note(bass[step // 2], t) * 0.36
        samples.append((lead * 0.62 * gate + low) * gain * edge)
    return wav_bytes(samples)


def effect(start_hz: float, end_hz: float, duration: float, gain: float) -> bytes:
    samples = []
    for index in range(round(duration * RATE)):
        t = index / RATE
        fraction = t / duration
        phase = math.tau * (start_hz * t + (end_hz - start_hz) * t * t / (2 * duration))
        envelope = min(1.0, t / 0.005) * (1.0 - fraction) ** 2
        samples.append(math.sin(phase) * gain * envelope)
    return wav_bytes(samples)


def school_bell() -> bytes:
    duration = 1.8
    samples = []
    for index in range(round(duration * RATE)):
        t = index / RATE
        pulse = t % 0.45
        envelope = min(1.0, pulse / 0.006) * math.exp(-8 * pulse)
        fade = min(1.0, (duration - t) / 0.25)
        metallic = sum(math.sin(math.tau * frequency * t) * gain for frequency, gain in
                       [(1480, 0.45), (2105, 0.27), (2985, 0.16), (3890, 0.08)])
        samples.append(metallic * envelope * fade * 0.30)
    return wav_bytes(samples)


def assets() -> dict[str, bytes]:
    return {
        "school_bell.wav": school_bell(),
        "explore_loop.wav": loop(
            [392, 440, 523.25, 440, 349.23, 392, 440, 0,
             392, 440, 523.25, 587.33, 523.25, 440, 392, 0],
            [130.81, 130.81, 174.61, 174.61, 146.83, 146.83, 196, 196], 0.5, 0.15),
        "arena_loop.wav": loop(
            [220, 261.63, 329.63, 261.63, 220, 293.66, 349.23, 293.66,
             246.94, 293.66, 369.99, 293.66, 246.94, 329.63, 392, 329.63],
            [110, 110, 130.81, 130.81, 123.47, 123.47, 146.83, 146.83], 0.375, 0.18),
        "confirm.wav": effect(520, 780, 0.11, 0.27),
        "interact.wav": effect(340, 530, 0.16, 0.27),
        "ability.wav": effect(280, 690, 0.24, 0.30),
        "result.wav": effect(520, 320, 0.34, 0.26),
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="Fail if generated WAVs differ from tracked files")
    args = parser.parse_args()
    OUTPUT.mkdir(parents=True, exist_ok=True)
    for name, data in assets().items():
        path = OUTPUT / name
        if args.check:
            if not path.is_file() or path.read_bytes() != data:
                raise SystemExit(f"Audio diferente: {path}")
        else:
            path.write_bytes(data)
        print(f"PASS {name}: {len(data)} bytes")


if __name__ == "__main__":
    main()
