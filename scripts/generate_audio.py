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
    """Timbre escolar eléctrico: parciales metálicos con badajo rápido (~18 Hz)."""
    duration = 2.6
    samples = []
    for index in range(round(duration * RATE)):
        t = index / RATE
        clapper = 0.55 + 0.45 * math.sin(math.tau * 18 * t) ** 2
        attack = min(1.0, t / 0.02)
        fade = min(1.0, (duration - t) / 0.45)
        metallic = sum(math.sin(math.tau * frequency * t) * gain for frequency, gain in
                       [(1480, 0.45), (2105, 0.27), (2985, 0.16), (3890, 0.08)])
        samples.append(metallic * clapper * attack * fade * 0.28)
    return wav_bytes(samples)


def tones(notes: list[tuple[float, float, float]], duration: float, gain: float, decay: float) -> bytes:
    """Notas (inicio, frecuencia, peso) con caída exponencial suave."""
    samples = []
    for index in range(round(duration * RATE)):
        t = index / RATE
        value = 0.0
        for start, frequency, weight in notes:
            local = t - start
            if local < 0:
                continue
            envelope = min(1.0, local / 0.006) * math.exp(-decay * local)
            value += note(frequency, local) * envelope * weight
        fade = min(1.0, (duration - t) / 0.05)
        samples.append(value * gain * fade)
    return wav_bytes(samples)


def door() -> bytes:
    """Puerta: golpe grave corto seguido de un leve chirrido."""
    duration = 0.42
    samples = []
    for index in range(round(duration * RATE)):
        t = index / RATE
        thump = math.sin(math.tau * (95 - 40 * t) * t) * math.exp(-18 * t)
        creak = math.sin(math.tau * (620 + 260 * t) * t) * max(0.0, 1 - abs(t - 0.2) / 0.12) * 0.25
        samples.append((thump + creak) * 0.42)
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
        "pickup.wav": tones([(0.0, 523.25, 1.0), (0.07, 659.25, 0.9), (0.14, 783.99, 0.8)], 0.42, 0.22, 9.0),
        "door.wav": door(),
        "notification.wav": tones([(0.0, 880, 1.0), (0.12, 1318.5, 0.85)], 0.5, 0.2, 8.0),
        "sleep.wav": tones([(0.0, 783.99, 0.8), (0.35, 659.25, 0.7), (0.7, 523.25, 0.7), (1.05, 392, 0.8)], 2.4, 0.16, 2.2),
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
