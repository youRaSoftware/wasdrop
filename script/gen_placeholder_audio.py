#!/usr/bin/env python3
"""Generate placeholder audio for WasDrop into core/resources/audio/.

Pure-stdlib synthesis (no numpy): short SFX as 44.1 kHz mono WAV and a
~21 s seamless music loop rendered at 22.05 kHz and converted to AAC (.m4a)
with the macOS `afconvert` tool. Everything here is generated, so it carries
no license; replace with real assets when they exist (keep the file names —
core/lib/services/audio_service.dart refers to them).

    python3 script/gen_placeholder_audio.py
"""
import math
import os
import random
import struct
import subprocess
import wave

SR = 44100
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'core', 'resources', 'audio')


def write_wav(name, samples, sr=SR, peak_target=0.89):
    os.makedirs(OUT, exist_ok=True)
    peak = max(1e-9, max(abs(s) for s in samples))
    gain = peak_target / peak
    frames = struct.pack('<%dh' % len(samples), *[int(max(-1.0, min(1.0, s * gain)) * 32767) for s in samples])
    path = os.path.join(OUT, name)
    with wave.open(path, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(sr)
        w.writeframes(frames)
    print('  %-22s %6.2f s  %6d KB' % (name, len(samples) / sr, os.path.getsize(path) // 1024))
    return path


def silence(dur, sr=SR):
    return [0.0] * int(dur * sr)


def add(buf, samples, at, sr=SR, wrap=False):
    start = int(at * sr)
    n = len(buf)
    for i, s in enumerate(samples):
        j = start + i
        if j >= n:
            if not wrap:
                break
            j %= n
        buf[j] += s


def tri(x):
    return 2.0 * abs(2.0 * (x - math.floor(x + 0.5))) - 1.0


def note(freq, dur, sr=SR, decay=5.0, attack=0.004, harmonics=((1, 1.0),), wave_fn=math.sin, freq_end=None):
    n = int(dur * sr)
    out = []
    phase = 0.0
    for i in range(n):
        t = i / sr
        f = freq if freq_end is None else freq + (freq_end - freq) * (i / max(1, n - 1))
        phase += f / sr
        env = math.exp(-decay * t / dur)
        if t < attack:
            env *= t / attack
        s = 0.0
        for k, amp in harmonics:
            arg = 2 * math.pi * phase * k
            s += amp * (math.sin(arg) if wave_fn is math.sin else wave_fn(phase * k))
        out.append(s * env)
    return out


def noise_burst(dur, sr=SR, decay=30.0, seed=1):
    rnd = random.Random(seed)
    n = int(dur * sr)
    out = []
    lp = 0.0
    for i in range(n):
        t = i / sr
        white = rnd.uniform(-1, 1)
        lp += 0.35 * (white - lp)  # soften
        out.append(lp * math.exp(-decay * t / dur))
    return out


def sfx():
    print('SFX:')
    # Tap: tiny bright tick.
    buf = silence(0.06)
    add(buf, [s * 0.8 for s in note(1900, 0.05, decay=9)], 0)
    add(buf, [s * 0.25 for s in noise_burst(0.006, decay=8)], 0)
    write_wav('sfx_tap.wav', buf)

    # Drop: soft low thud.
    buf = silence(0.18)
    add(buf, note(170, 0.16, decay=7, freq_end=80), 0)
    add(buf, [s * 0.35 for s in noise_burst(0.014, decay=10, seed=2)], 0)
    write_wav('sfx_drop.wav', buf)

    # Merge 1..11: pop + ding, pitch rises with tier (whole-tone steps).
    for tier in range(1, 12):
        f0 = 523.25 * 2 ** ((tier - 1) * 2 / 12)
        buf = silence(0.32)
        add(buf, [s * 0.5 for s in note(f0 / 2, 0.05, decay=4, freq_end=f0)], 0)
        add(buf, note(f0, 0.26, decay=6, attack=0.006, harmonics=((1, 1.0), (2, 0.45), (3, 0.18))), 0.03)
        write_wav('sfx_merge_%02d.wav' % tier, buf)

    # Game over: three descending notes.
    buf = silence(0.75)
    for i, f in enumerate((659.25, 523.25, 392.0)):
        add(buf, [s * 0.9 for s in note(f, 0.28, decay=4, wave_fn=tri)], i * 0.2)
    write_wav('sfx_game_over.wav', buf)

    # New record: ascending arpeggio + chord.
    buf = silence(0.95)
    for i, f in enumerate((523.25, 659.25, 783.99, 1046.5)):
        add(buf, [s * 0.7 for s in note(f, 0.16, decay=4, harmonics=((1, 1.0), (2, 0.35)))], i * 0.11)
    for f in (523.25, 659.25, 783.99):
        add(buf, [s * 0.45 for s in note(f * 2, 0.45, decay=3.5, harmonics=((1, 1.0), (2, 0.3)))], 0.46)
    write_wav('sfx_record.wav', buf)


def music():
    print('Music loop:')
    sr = 22050
    bpm = 92
    beat = 60.0 / bpm
    bar = 4 * beat
    bars = 8
    total = int(round(bars * bar * sr))
    buf = [0.0] * total

    # I – vi – IV – V, warm register: (bass, pad notes)
    chords = [
        (130.81, (261.63, 329.63, 392.00)),  # C
        (110.00, (220.00, 261.63, 329.63)),  # Am
        (174.61, (261.63, 349.23, 440.00)),  # F
        (196.00, (246.94, 293.66, 392.00)),  # G
    ]
    # Arpeggio patterns (index into pad notes one octave up, None = rest).
    patterns = [
        (0, 2, 1, 2, None, 1, 2, None),
        (0, 1, 2, None, 1, 2, 0, None),
    ]

    for b in range(bars):
        bass_f, pad = chords[b % 4]
        t0 = b * bar
        # Bass: soft sine, whole bar.
        add(buf, [s * 0.38 for s in note(bass_f, bar, sr=sr, decay=1.3, attack=0.02, harmonics=((1, 1.0), (2, 0.15)))], t0, sr=sr, wrap=True)
        # Pad: detuned sine pairs, slow attack.
        for f in pad:
            for det in (1.0, 1.0035):
                add(buf, [s * 0.075 for s in note(f * det, bar * 1.05, sr=sr, decay=0.9, attack=0.25)], t0, sr=sr, wrap=True)
        # Arpeggio: 8th notes.
        pattern = patterns[b % 2]
        for k, idx in enumerate(pattern):
            if idx is None:
                continue
            f = pad[idx] * 2
            vel = 0.24 if k % 2 == 0 else 0.17
            add(buf, [s * vel for s in note(f, beat * 0.9, sr=sr, decay=4.5, attack=0.006, harmonics=((1, 1.0), (2, 0.2)))], t0 + k * beat / 2, sr=sr, wrap=True)
        # Soft shaker on 8ths, accents on beats 2 and 4.
        for k in range(8):
            accent = k in (2, 6)
            add(buf, [s * (0.06 if accent else 0.03) for s in noise_burst(0.03, sr=sr, decay=18, seed=100 + b * 8 + k)], t0 + k * beat / 2, sr=sr, wrap=True)

    # Gentle one-pole low-pass for warmth.
    alpha = 1 - math.exp(-2 * math.pi * 3200 / sr)
    lp = 0.0
    for i in range(total):
        lp += alpha * (buf[i] - lp)
        buf[i] = lp

    wav = write_wav('music_loop.wav', buf, sr=sr, peak_target=0.8)
    m4a = os.path.join(OUT, 'music_loop.m4a')
    subprocess.run(['afconvert', '-f', 'm4af', '-d', 'aac', wav, m4a], check=True)
    os.remove(wav)
    print('  %-22s %6.2f s  %6d KB' % ('music_loop.m4a', total / sr, os.path.getsize(m4a) // 1024))


if __name__ == '__main__':
    sfx()
    music()
    with open(os.path.join(OUT, 'README.md'), 'w') as f:
        f.write('# Audio (placeholders)\n\nGenerated by `script/gen_placeholder_audio.py` — synthesized, no license attached. '
                'Replace with real assets keeping the file names (see `core/lib/services/audio_service.dart`).\n\n'
                '- `sfx_tap.wav` — button press\n- `sfx_drop.wav` — ball dropped\n- `sfx_merge_01..11.wav` — merge, pitch rises with the resulting tier\n'
                '- `sfx_game_over.wav`, `sfx_record.wav`\n- `music_loop.m4a` — ~21 s seamless loop (AAC; iOS has no OGG)\n')
    print('done →', os.path.abspath(OUT))
