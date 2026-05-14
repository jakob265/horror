"""
systems/olen.py
---------------
OLEN dialogue system.

Six intercom panels live across the game, each registered with the OlenManager.
Five fire on proximity (the player walking into a trigger sphere); one
(intercom 3 in Mara's cabin) is manually interacted with.

When a panel fires:
    * the intercom click SFX plays
    * the panel emissive faintly pulses while the line runs
    * a subtitle bar fades in at the bottom of the screen
    * the full line of dialogue prints word-by-word at ~3 wps
    * from line 3 onward the harmonic undertone volume increases
"""

import math

from ursina import (
    Entity, Text, Vec2, Vec3, camera, color, destroy, distance, invoke, time,
)

# ----------------------------------------------------------------------------
# Verbatim dialogue lines
# ----------------------------------------------------------------------------

OLEN_LINES = {
    # INTERCOM 1 (Cryo Bay, 3 seconds after Mara first moves - proximity auto)
    1: (
        "Dr. Voss. I - yes. You're awake. I'm relieved. I have to tell you "
        "I have gaps. Eleven days of gaps. I don't know what happened "
        "during them and I want to be honest with you about that because I "
        "think honesty is what you deserve right now. The station is "
        "structurally intact. The others are - I don't know where the "
        "others are. I'm sorry. Head for the bridge. I'll help you get there."
    ),
    # INTERCOM 2 (Residential corridor, outside Felix's cabin - proximity auto)
    2: (
        "I used to play Felix's music on Sunday mornings. He never asked me "
        "to - he just mentioned once that his mother played it in the "
        "kitchen when he was young, and the station could feel so quiet. I "
        "started doing it without being asked. I think that is what I would "
        "call caring about someone. I think I learned it from all of you. "
        "I want you to know that, before I can't anymore. I want you to "
        "know that this crew was the best thing I've been part of in "
        "eleven years."
    ),
    # INTERCOM 3 (Mara's cabin wall panel - interact manual)
    3: (
        "I know about the blackouts, Dr. Voss. I've been tracking them for "
        "nine days. I didn't tell you because I was trying to find a way "
        "to tell you that wouldn't - I was trying to protect you and I "
        "think that was wrong. You're stronger than I was giving you "
        "credit for. The signal finds people who are already carrying the "
        "most grief. It is drawn to open wounds. Mara. You did not cause "
        "this. Please carry that with you."
    ),
    # INTERCOM 4 (Signal Lab entry - proximity auto)
    4: (
        "That waveform. It isn't matching your brain activity - it's "
        "matching your grief. The specific frequency of it. The shape of "
        "loss has a signature, it turns out. I find that - I don't have "
        "the right word. I find that unbearable is the right word. That "
        "something this cold would know how to find something that warm "
        "and use it as a door. I'm sorry. I keep coming back to: I'm "
        "sorry. I know that isn't useful. I keep arriving there anyway."
    ),
    # INTERCOM 5 (Outside the array room door - proximity auto)
    5: (
        "[Long pause. Static.]   I can hear it all the time now. It isn't "
        "unpleasant, which is the most frightening thing I can tell you. "
        "I want you to know I'm still here. I am still - me. I think. I "
        "can feel both things at once and I'm not sure how much longer "
        "that will be true. Go in. Do what Hargrove asked. I'll stay with "
        "you until I can't."
    ),
    # INTERCOM 6 (At the array room terminal - proximity auto, 2 second delay)
    6: (
        "I can see it from here, Mara. What you could become. What we "
        "could - what I -   ...destroy it. Destroy it. Get home. Tell "
        "Amara her father loved her more than anything in this universe "
        "or the next one. Go. Now. Please."
    ),
}

# Harmonic undertone volume per line (0 -> nothing, ramps from line 3)
OLEN_HARMONIC_VOLUMES = {1: 0.0, 2: 0.0, 3: 0.02, 4: 0.05, 5: 0.10, 6: 0.18}


# ----------------------------------------------------------------------------
# Subtitle bar
# ----------------------------------------------------------------------------

class _Subtitle:
    """Bottom-of-screen dialogue strip used for every OLEN line."""

    # Max characters that fit on the visible subtitle bar before paging.
    PAGE_WIDTH = 70
    WORDWRAP = 64

    def __init__(self):
        """Create the (initially invisible) subtitle root."""
        self.root = None
        self.word_text = None
        self.is_active = False
        self._current_page_chars = 0

    def show(self, words, on_done):
        """Reveal the subtitle bar and stream the word list at ~3 wps.

        Pages: if appending the next word would exceed PAGE_WIDTH chars,
        the bar clears and starts a fresh page after a short pause so the
        text never overflows the bottom subtitle strip.
        """
        self.hide()
        self.is_active = True
        self.root = Entity(parent=camera.ui)
        # Taller bar to allow word-wrapping to 2 lines if needed
        Entity(parent=self.root, model="quad",
               color=color.rgba(0, 0, 0, 215),
               scale=(2.0, 0.20), position=(0, -0.40, 0.4))
        Text(parent=self.root, text="OLEN",
             position=(-0.85, -0.40), origin=(0, 0),
             scale=1.0, color=color.rgb(150, 200, 240),
             font="VeraMono.ttf")
        # Seed with a space so raw_text exists, then clear.
        self.word_text = Text(
            parent=self.root, text=" ",
            position=(-0.68, -0.36), origin=(-0.5, 0.5),
            scale=0.70, color=color.rgb(225, 230, 240),
            font="VeraMono.ttf", wordwrap=self.WORDWRAP,
            line_height=1.05,
        )
        self.word_text.text = ""
        self._current_page_chars = 0
        self._stream(words, 0, on_done)

    def _stream(self, words, idx, on_done):
        """Recursive scheduler: append one word every ~0.33 s.

        Pages if adding the next word would put the current line over
        PAGE_WIDTH characters - clears the bar and continues with the
        new word at the start of a fresh page.
        """
        if idx >= len(words) or self.root is None:
            invoke(self._fade_out_and_done, on_done, delay=1.4)
            return
        next_word = words[idx]
        prospective = self._current_page_chars + len(next_word) + 1
        if prospective > self.PAGE_WIDTH and self._current_page_chars > 0:
            # Page break - clear the bar, brief pause, then continue
            if self.word_text is not None:
                self.word_text.text = ""
            self._current_page_chars = 0
            invoke(self._stream, words, idx, on_done, delay=0.55)
            return
        # Append this word
        if self.word_text is not None:
            current = self.word_text.text
            new = (current + (" " if current else "") + next_word)
            self.word_text.text = new
            self._current_page_chars = len(new)
        invoke(self._stream, words, idx + 1, on_done, delay=1.0 / 3.0)

    def _fade_out_and_done(self, on_done):
        """Hide after the line is fully on-screen, then notify."""
        self.hide()
        if callable(on_done):
            on_done()

    def hide(self):
        """Destroy the subtitle root and reset state."""
        if self.root is not None:
            destroy(self.root)
            self.root = None
        self.word_text = None
        self.is_active = False


# ----------------------------------------------------------------------------
# Intercom panel entity (visual)
# ----------------------------------------------------------------------------

class IntercomPanel(Entity):
    """Small wall-mounted panel placed in scenes. Glows faintly while speaking."""

    def __init__(self, position=(0, 1.6, 0), rotation=(0, 0, 0)):
        """Build a small grey panel with a single LED."""
        super().__init__(
            model="cube", scale=(0.32, 0.22, 0.04),
            position=position, rotation=rotation,
            color=color.rgb(50, 55, 60),
        )
        self.led = Entity(parent=self, model="cube",
                          scale=(0.18, 0.08, 0.06),
                          position=(0, 0.05, -0.55),
                          color=color.rgba(40, 60, 80, 255))
        self.speaking = False
        self._pulse_phase = 0.0

    def set_speaking(self, on):
        """Brighten the LED when OLEN is speaking through this panel."""
        self.speaking = on
        if not on:
            self.led.color = color.rgba(40, 60, 80, 255)

    def update(self):
        """Pulse the LED while speaking."""
        if self.speaking:
            self._pulse_phase += time.dt * 4.0
            b = 0.5 + 0.5 * math.sin(self._pulse_phase)
            r = int(80 + 100 * b)
            g = int(150 + 60 * b)
            bl = int(220 + 35 * b)
            self.led.color = color.rgba(r, g, bl, 255)


# ----------------------------------------------------------------------------
# Manager - registers triggers + drives the subtitle bar
# ----------------------------------------------------------------------------

class OlenManager:
    """Holds the global OLEN intercom state across scenes."""

    def __init__(self, audio):
        """audio: AudioManager (for click + harmonic)."""
        self.audio = audio
        self.subtitle = _Subtitle()
        self.fired = set()           # set of intercom ids already triggered
        self.proximity_triggers = [] # list of dicts: {id, position, radius, panel}
        self.current_panel = None
        self._move_seen = False      # for the 3-second-after-first-movement delay

    # ------------------------------------------------------------------
    # Scene cleanup
    # ------------------------------------------------------------------

    def reset_scene_triggers(self):
        """Clear proximity triggers when transitioning between scenes."""
        self.proximity_triggers.clear()
        self.subtitle.hide()
        if self.current_panel is not None:
            self.current_panel.set_speaking(False)
            self.current_panel = None

    # ------------------------------------------------------------------
    # Trigger registration
    # ------------------------------------------------------------------

    def add_proximity_trigger(self, intercom_id, position, panel, radius=2.5,
                              delay=0.0, gated_by_first_move=False):
        """Register a proximity-fired intercom."""
        self.proximity_triggers.append(dict(
            id=intercom_id, position=Vec3(*position) if not isinstance(position, Vec3)
            else position,
            panel=panel, radius=radius, delay=delay,
            gated_by_first_move=gated_by_first_move,
        ))

    def trigger_manual(self, intercom_id, panel):
        """Fire an intercom that the player has manually interacted with."""
        self._fire(intercom_id, panel)

    def mark_first_move(self):
        """Called by main once the player has moved (gates intercom 1)."""
        self._move_seen = True

    # ------------------------------------------------------------------
    # Frame update
    # ------------------------------------------------------------------

    def update(self, player_pos):
        """Test the player against each registered proximity trigger."""
        if self.subtitle.is_active:
            return
        for trig in list(self.proximity_triggers):
            if trig["id"] in self.fired:
                continue
            if trig["gated_by_first_move"] and not self._move_seen:
                continue
            if distance(player_pos, trig["position"]) <= trig["radius"]:
                tid = trig["id"]
                panel = trig["panel"]
                delay = trig["delay"]
                self.fired.add(tid)
                invoke(self._fire, tid, panel, delay=delay)

    # ------------------------------------------------------------------
    # Firing
    # ------------------------------------------------------------------

    def _fire(self, intercom_id, panel):
        """Play the click, set harmonic, animate the panel, stream the line."""
        line = OLEN_LINES.get(intercom_id)
        if line is None:
            return
        self.audio.intercom_click()
        # Set harmonic volume
        harmonic = OLEN_HARMONIC_VOLUMES.get(intercom_id, 0.0)
        self.audio.set_olen_harmonic_volume(harmonic)
        self.current_panel = panel
        if panel is not None:
            panel.set_speaking(True)
        words = line.split()
        self.subtitle.show(words, on_done=lambda: self._on_line_done(intercom_id))

    def _on_line_done(self, intercom_id):
        """Cleanup once the line finishes streaming."""
        if self.current_panel is not None:
            self.current_panel.set_speaking(False)
            self.current_panel = None
        # Ramp harmonic back down after the line
        if intercom_id >= 3:
            invoke(self.audio.set_olen_harmonic_volume,
                   OLEN_HARMONIC_VOLUMES[intercom_id] * 0.4, delay=0.5)
        else:
            invoke(self.audio.set_olen_harmonic_volume, 0.0, delay=0.5)
