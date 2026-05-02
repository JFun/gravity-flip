"""Generate placeholder arcade SFX (.wav) using stdlib only.
Run: python3 scripts/dev/gen_sfx.py
Output: assets/sounds/{flip,star,death,level_clear}.wav
Sounds are intentionally simple — swap in real assets later from freesound.org or Kenney packs.
"""
from __future__ import annotations
import math
import struct
import wave
from pathlib import Path

SAMPLE_RATE = 44100
OUT_DIR = Path(__file__).resolve().parents[2] / "assets" / "sounds"


def write_wav(name: str, samples: list[float]) -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    path = OUT_DIR / f"{name}.wav"
    # Clamp + convert to 16-bit PCM
    data = b"".join(struct.pack("<h", max(-32768, min(32767, int(s * 32767)))) for s in samples)
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SAMPLE_RATE)
        w.writeframes(data)
    print(f"wrote {path} ({len(samples)/SAMPLE_RATE*1000:.0f} ms)")


def envelope(i: int, n: int, attack: float = 0.01, release: float = 0.3) -> float:
    """Simple AR envelope. attack/release are fractions of total length."""
    t = i / n
    a = max(0.0001, attack)
    r = max(0.0001, release)
    if t < a:
        return t / a
    if t > 1.0 - r:
        return max(0.0, (1.0 - t) / r)
    return 1.0


def tone(freq: float, dur: float, vol: float = 0.4, harmonic_mix: float = 0.0) -> list[float]:
    n = int(SAMPLE_RATE * dur)
    out = []
    for i in range(n):
        t = i / SAMPLE_RATE
        v = math.sin(2 * math.pi * freq * t)
        if harmonic_mix > 0:
            v += harmonic_mix * math.sin(2 * math.pi * freq * 2 * t)
            v /= 1 + harmonic_mix
        out.append(v * vol * envelope(i, n))
    return out


def chirp(f0: float, f1: float, dur: float, vol: float = 0.4) -> list[float]:
    n = int(SAMPLE_RATE * dur)
    out = []
    phase = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        f = f0 + (f1 - f0) * (t / dur)
        phase += 2 * math.pi * f / SAMPLE_RATE
        out.append(math.sin(phase) * vol * envelope(i, n, attack=0.05, release=0.4))
    return out


def noise_thud(dur: float, vol: float = 0.5) -> list[float]:
    """Low descending tone with a touch of noise — a 'thud'."""
    import random
    rng = random.Random(42)
    n = int(SAMPLE_RATE * dur)
    out = []
    phase = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        f = 180 - 130 * (t / dur)  # 180 → 50 Hz
        phase += 2 * math.pi * f / SAMPLE_RATE
        sine = math.sin(phase)
        n_amp = (rng.random() * 2 - 1) * 0.3
        env = envelope(i, n, attack=0.005, release=0.6)
        out.append((sine + n_amp) * vol * env)
    return out


def arpeggio(freqs: list[float], note_dur: float, vol: float = 0.35) -> list[float]:
    out = []
    for f in freqs:
        out.extend(tone(f, note_dur, vol=vol, harmonic_mix=0.3))
    return out


def main() -> None:
    # Flip: quick rising chirp ~70ms
    write_wav("flip", chirp(280, 520, 0.07, vol=0.35))
    # Star: bright bell-ish ping ~350ms, two-tone
    star_a = tone(880, 0.18, vol=0.32, harmonic_mix=0.5)
    star_b = tone(1320, 0.25, vol=0.22, harmonic_mix=0.5)
    write_wav("star", [a + (star_b[i] if i < len(star_b) else 0) for i, a in enumerate(star_a + [0.0] * max(0, len(star_b) - len(star_a)))])
    # Death: low descending thud ~400ms
    write_wav("death", noise_thud(0.4, vol=0.45))
    # Level clear: ascending arpeggio C-E-G-C ~480ms
    write_wav("level_clear", arpeggio([523, 659, 784, 1047], 0.12, vol=0.32))


if __name__ == "__main__":
    main()
