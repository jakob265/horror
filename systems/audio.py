"""
systems/audio.py
----------------
Procedural audio generation for VOID FREQUENCY.

All audio is generated at runtime using Python's wave + struct modules,
written to a temp directory, and loaded by Ursina's Audio class. No
external sound assets are required.

The placeholder comments below describe every sound that would, in a
"real" mix, be a high-quality recorded asset. They are left silent so
the game runs out of the box with zero external files.
"""

import math
import os
import pathlib
import random
import struct
import tempfile
import wave

from ursina import Audio, application, destroy, invoke

SAMPLE_RATE = 22050        # 22 kHz mono is plenty for procedural drones/clicks
BITS = 16
MAX_AMP = 2 ** (BITS - 1) - 1

_AUDIO_CACHE = {}          # path -> Audio instance
_TMP_DIR = None            # lazily created temp directory for generated wavs
_ASSET_FOLDER_BACKUP = None


def _tmp_dir():
    """Return (creating if needed) the temporary directory for generated wav files.

    Also extends Ursina's asset_folder to include it. Ursina's Audio class
    resolves names by globbing application.asset_folder; we need our temp
    folder to be discoverable.
    """
    global _TMP_DIR, _ASSET_FOLDER_BACKUP
    if _TMP_DIR is None:
        _TMP_DIR = tempfile.mkdtemp(prefix="voidfreq_audio_")
        _ASSET_FOLDER_BACKUP = application.asset_folder
        # Ursina expects asset_folder to be a Path-like; point it at our tmp
        # dir so the Audio name lookup finds our generated wav files.
        application.asset_folder = pathlib.Path(_TMP_DIR)
    return _TMP_DIR


def _write_wav(name, samples):
    """Write a list of float samples in [-1, 1] to a 16-bit mono wav and return its path."""
    path = os.path.join(_tmp_dir(), name + ".wav")
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(BITS // 8)
        w.setframerate(SAMPLE_RATE)
        frames = bytearray()
        for s in samples:
            v = max(-1.0, min(1.0, s))
            frames += struct.pack("<h", int(v * MAX_AMP))
        w.writeframes(bytes(frames))
    return path


# ----------------------------------------------------------------------------
# Waveform generators
# ----------------------------------------------------------------------------

def _gen_sine(freq, duration, amp=0.5):
    """Pure sine, length = duration seconds."""
    n = int(duration * SAMPLE_RATE)
    return [amp * math.sin(2.0 * math.pi * freq * i / SAMPLE_RATE) for i in range(n)]


def _gen_warble(freq, duration, lfo_hz=0.4, lfo_depth=6.0, amp=0.5):
    """Sine with slow FM warble - used for the signal proximity tone."""
    n = int(duration * SAMPLE_RATE)
    out = []
    phase = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        cur_freq = freq + lfo_depth * math.sin(2.0 * math.pi * lfo_hz * t)
        phase += 2.0 * math.pi * cur_freq / SAMPLE_RATE
        out.append(amp * math.sin(phase))
    return out


def _gen_square(freq, duration, amp=0.5):
    """Hard-edged square wave - used for the intercom click."""
    n = int(duration * SAMPLE_RATE)
    period = SAMPLE_RATE / freq
    return [amp if (i % period) < (period / 2) else -amp for i in range(n)]


def _gen_noise(duration, amp=0.5):
    """White noise burst."""
    n = int(duration * SAMPLE_RATE)
    return [amp * (random.random() * 2 - 1) for _ in range(n)]


def _apply_fade(samples, fade_in=0.0, fade_out=0.0):
    """Linear fade in/out applied in-place; returns the samples for chaining."""
    n = len(samples)
    fi = int(fade_in * SAMPLE_RATE)
    fo = int(fade_out * SAMPLE_RATE)
    for i in range(min(fi, n)):
        samples[i] *= i / fi
    for i in range(min(fo, n)):
        samples[n - 1 - i] *= i / fo
    return samples


def _mix(*streams):
    """Sum-mix a set of equal-length sample lists, clamped to [-1, 1]."""
    length = max(len(s) for s in streams)
    out = [0.0] * length
    for s in streams:
        for i, v in enumerate(s):
            out[i] += v
    return [max(-1.0, min(1.0, v)) for v in out]


# ----------------------------------------------------------------------------
# Pre-baked audio assets (generated once at startup)
# ----------------------------------------------------------------------------

_PATHS = {}


def _bake_all():
    """Pre-generate every wav file used by the game."""
    # STATION HUM - 38 Hz sine, 4 second loop. (Continuous from launch, vol 0.12)
    hum = _gen_sine(38.0, 4.0, amp=0.85)
    _apply_fade(hum, fade_in=0.4, fade_out=0.4)
    _PATHS["station_hum"] = _write_wav("station_hum", hum)

    # SIGNAL TONE - 440 Hz with 0.4 Hz LFO warble. (Shape proximity, max vol 0.08)
    sig = _gen_warble(440.0, 3.0, lfo_hz=0.4, lfo_depth=6.0, amp=0.8)
    _apply_fade(sig, fade_in=0.2, fade_out=0.2)
    _PATHS["signal_tone"] = _write_wav("signal_tone", sig)

    # SIGNAL TONE + HARMONIC - same with +2 semitones harmonic, used for OLEN from intercom 3+
    base = _gen_warble(440.0, 3.0, lfo_hz=0.4, lfo_depth=6.0, amp=0.55)
    harm = _gen_warble(440.0 * (2 ** (2 / 12)), 3.0, lfo_hz=0.4, lfo_depth=4.0, amp=0.55)
    mix = _mix(base, harm)
    _apply_fade(mix, fade_in=0.2, fade_out=0.2)
    _PATHS["signal_tone_harm"] = _write_wav("signal_tone_harm", mix)

    # INTERCOM CLICK - 800 Hz square, 0.06 s, vol 0.4
    click = _gen_square(800.0, 0.06, amp=0.4)
    _apply_fade(click, fade_in=0.005, fade_out=0.02)
    _PATHS["intercom_click"] = _write_wav("intercom_click", click)

    # NOTE CHIME - 880 Hz sine, 0.4 s with gentle fade
    chime = _gen_sine(880.0, 0.4, amp=0.55)
    _apply_fade(chime, fade_in=0.005, fade_out=0.35)
    _PATHS["note_chime"] = _write_wav("note_chime", chime)

    # SHAPE STING - broadband noise burst, 0.3 s sharp attack
    sting = _gen_noise(0.3, amp=0.65)
    _apply_fade(sting, fade_in=0.002, fade_out=0.28)
    _PATHS["shape_sting"] = _write_wav("shape_sting", sting)

    # KEYPAD ACCEPT BEEP - clean 1200 Hz, 0.15 s
    ok = _gen_sine(1200.0, 0.15, amp=0.5)
    _apply_fade(ok, fade_in=0.005, fade_out=0.08)
    _PATHS["keypad_accept"] = _write_wav("keypad_accept", ok)

    # KEYPAD REJECT BUZZ - low 220 Hz, 0.25 s
    bad = _gen_square(220.0, 0.25, amp=0.45)
    _apply_fade(bad, fade_in=0.005, fade_out=0.12)
    _PATHS["keypad_reject"] = _write_wav("keypad_reject", bad)

    # DOOR OPEN/CLOSE - soft pneumatic hiss = filtered noise burst, 0.5 s
    door = _gen_noise(0.5, amp=0.25)
    _apply_fade(door, fade_in=0.05, fade_out=0.4)
    _PATHS["door"] = _write_wav("door", door)

    # SCRAPE - low rumbly noise for move_object
    scrape = _gen_noise(0.6, amp=0.3)
    # add a low rumble underneath
    rumble = _gen_sine(70.0, 0.6, amp=0.4)
    scrape = _mix(scrape, rumble)
    _apply_fade(scrape, fade_in=0.05, fade_out=0.3)
    _PATHS["scrape"] = _write_wav("scrape", scrape)

    # ENDING TONE - single quiet musical tone (E3 + B3, unresolved fifth-ish), 4 s
    e = _gen_sine(164.81, 4.0, amp=0.35)
    b = _gen_sine(246.94, 4.0, amp=0.30)
    end_tone = _mix(e, b)
    _apply_fade(end_tone, fade_in=0.8, fade_out=1.2)
    _PATHS["ending_tone"] = _write_wav("ending_tone", end_tone)


# ----------------------------------------------------------------------------
# Playback manager
# ----------------------------------------------------------------------------

class AudioManager:
    """Owns the persistent station hum and exposes one-shot SFX playback."""

    def __init__(self):
        """Bake all sounds and start the station hum loop."""
        _bake_all()
        # Ursina Audio takes a name (no path, no extension) and globs through
        # application.asset_folder, which _bake_all() points at our tmp dir.
        # STATION HUM - looping at 0.12 volume from launch
        self.station_hum = Audio("station_hum", loop=True, autoplay=True,
                                 volume=0.12)
        # SIGNAL TONE - looping at 0 volume; modulated per-frame by Shape proximity
        self.signal_tone = Audio("signal_tone", loop=True, autoplay=True,
                                 volume=0.0)
        # SIGNAL TONE WITH HARMONIC - layered for OLEN intercoms 3 -> 6
        self.signal_tone_harm = Audio("signal_tone_harm", loop=True,
                                      autoplay=True, volume=0.0)

    def set_signal_proximity_volume(self, v):
        """Live-update the floating signal warble. v in [0, 0.08]."""
        self.signal_tone.volume = max(0.0, min(0.08, v))

    def set_olen_harmonic_volume(self, v):
        """Set the harmonic undertone volume played beneath OLEN lines."""
        self.signal_tone_harm.volume = max(0.0, min(0.25, v))

    # -- One-shot SFX ---------------------------------------------------------

    def _one_shot(self, key, volume=1.0):
        """Fire and forget - create an Audio instance, destroy when done."""
        if key not in _PATHS:
            return None
        a = Audio(key, autoplay=True, loop=False, volume=volume)
        # Schedule destruction a hair after natural duration
        try:
            dur = max(0.5, a.length + 0.2)
        except Exception:
            dur = 1.0
        invoke(destroy, a, delay=dur)
        return a

    def intercom_click(self):
        """Play the sharp click that precedes every OLEN line."""
        return self._one_shot("intercom_click", volume=0.4)

    def note_chime(self):
        """Soft chime played on note pickup."""
        return self._one_shot("note_chime", volume=0.45)

    def shape_sting(self):
        """Broadband noise burst played on Felix trigger / Hargrove wave / Act 4 entry."""
        return self._one_shot("shape_sting", volume=0.6)

    def keypad_accept(self):
        """Short clean 1200 Hz beep on correct keypad code."""
        return self._one_shot("keypad_accept", volume=0.55)

    def keypad_reject(self):
        """Low buzz on wrong keypad code."""
        return self._one_shot("keypad_reject", volume=0.5)

    def door(self):
        """Soft pneumatic hiss for door open/close."""
        return self._one_shot("door", volume=0.5)

    def scrape(self):
        """Soft scrape rumble for moving heavy objects."""
        return self._one_shot("scrape", volume=0.55)

    def ending_tone(self):
        """Single unresolved musical tone used at the end of Ending A."""
        return self._one_shot("ending_tone", volume=0.55)

    # -- Hum control for endings ---------------------------------------------

    def ramp_ending_hum(self, target=0.35, seconds=8.0):
        """Linearly ramp the station hum volume to `target` over `seconds`."""
        from ursina import application

        start = self.station_hum.volume
        steps = max(1, int(seconds * 30))
        for i in range(steps):
            frac = (i + 1) / steps

            def setter(f=frac):
                self.station_hum.volume = start + (target - start) * f
            invoke(setter, delay=(i + 1) * (seconds / steps))

    def cut_hum(self):
        """Hard stop on the station hum."""
        self.station_hum.volume = 0.0
        self.signal_tone.volume = 0.0
        self.signal_tone_harm.volume = 0.0


# ----------------------------------------------------------------------------
# Silent placeholders (deliberately not played - documented hooks)
# ----------------------------------------------------------------------------
#
# SOUND: Felix's voice saying "Amara" - soft, slightly distorted, as if
#         heard through water. Drop mono .wav here. (Felix-Shape trigger)
#
# SOUND: Footstep on metal - hollow clank, short. (player footstep, metal floor)
# SOUND: Footstep on grating - lighter, tinny. (player footstep, grating floor)
#
# SOUND: Cryo pod hiss - steam burst, 1.2 seconds. (Act 1 intro)
#
# SOUND: Distant metallic groan - positional, from ceiling vent position,
#         plays every 45-90 seconds on random timer.
#
# SOUND: Slow breathing - very quiet, positional, from welded pod in Act 1.
#
# SOUND: Door open/close - soft pneumatic hiss. (handled procedurally above)
#
# SOUND: Keypad accept beep - short, clean, 1200 Hz. (handled procedurally above)
# SOUND: Keypad reject buzz - short, low, 220 Hz.  (handled procedurally above)
#
# SOUND: Three breaths in darkness - distinct voices, used in Ending A only,
#         plays 1.5 seconds after lights cut, before text begins.
#
# Drop AudioStreamPlayer wav assets at the documented hooks above and the
# game will pick them up automatically.
