"""
systems/endings.py
------------------
The two endings of VOID FREQUENCY.

Each ending is a sequence of:
    * a transition (cut to black + breaths, or warm fade + rising hum)
    * a stream of white text lines fading in with silences between
    * a title card
    * a "Return to Main Menu" button that fades in 5 seconds later

Both endings are driven by a single Ending coroutine that pre-builds the
overlay and uses invoke() to chain timed steps.
"""

from ursina import (
    Entity, Text, Vec2, application, camera, color, destroy, invoke,
    mouse,
)


# Verbatim ending A text (DESTROY - "Signal Lost"), line by line.
ENDING_A_LINES = [
    "The array is silent.",
    "",
    "OLEN's voice stops mid-sentence.",
    "You don't hear the rest of it.",
    "",
    "You stand in the dark for a long time.",
    "",
    "You find the emergency beacon in the supply cabinet.",
    "You activate it.",
    "In 72 hours, a rescue vessel will arrive.",
    "",
    "You sit down in the corridor outside Felix's cabin.",
    "You don't go inside.",
    "You look at the drawing on the floor through the open door.",
    "You don't move it.",
    "",
    "You think about Eli.",
    "You think about all of it.",
    "You let yourself think about all of it.",
    "",
    "You realize you haven't done that before. Not all the way.",
    "You let yourself.",
    "",
    "When the rescue ship comes, there is a message waiting.",
    "It is from Amara Okafor, age seven.",
    "She wants to know if you knew her dad.",
    "She wants to know if he was happy.",
    "",
    "You write back.",
    "You tell her he was.",
    "You tell her he talked about her every day.",
    "You tell her that he called her his favorite thing in the universe",
    "and that you know for certain he meant it.",
    "",
    "She writes back three words.",
    "'Thank you, Mara.'",
    "",
    "You didn't know she knew your name.",
    "",
    "You realize Felix must have told her.",
    "Some Sunday, on some call, he must have talked about you.",
    "",
    "You let that be real.",
    "You let it matter.",
]

# Verbatim ending B text (LISTEN - "Resonance"), line by line.
ENDING_B_LINES = [
    "You understand now.",
    "",
    "It was never malicious.",
    "It was just a pattern looking for a shape to take.",
    "It found yours.",
    "",
    "The grief.",
    "The guilt.",
    "The door you never closed.",
    "",
    "It walked in.",
    "",
    "You are still here.",
    "You are still - you.",
    "But the edges of you are softer now.",
    "Less separate.",
    "",
    "You think about Eli.",
    "For the first time, it doesn't hurt.",
    "You don't ask yourself if that is mercy or erasure.",
    "You have stopped being able to tell the difference.",
    "",
    "You stand very still.",
    "You face the wall.",
    "",
    "Somewhere in the station, something wakes up.",
    "It finds its way to you.",
    "It stands beside you.",
    "",
    "In the frequency, something that was Felix says your name.",
    "You know it isn't Felix.",
    "You answer anyway.",
    "",
    "The station broadcasts.",
    "Into the dark.",
    "Calling.",
    "Waiting for someone to hear.",
]


class EndingPlayer:
    """Drives one of the two endings start-to-finish."""

    def __init__(self, audio, on_return_to_menu):
        """audio: AudioManager. on_return_to_menu: callable invoked on button."""
        self.audio = audio
        self.on_return = on_return_to_menu
        self.root = None
        self._line_entities = []
        self._timer_handles = []
        self.menu_button = None

    # ------------------------------------------------------------------
    # Common utilities
    # ------------------------------------------------------------------

    def _build_backdrop(self, rgba):
        """Cover the screen with a solid color overlay."""
        if self.root is not None:
            destroy(self.root)
        self.root = Entity(parent=camera.ui)
        self.bg = Entity(parent=self.root, model="quad", color=rgba,
                         scale=(2.5, 1.5), position=(0, 0, 0.6))
        mouse.locked = False
        mouse.visible = False

    def _stream_lines(self, lines, start_delay, gap_blank=1.6, gap_line=0.9):
        """Fade in each line of text sequentially."""
        delay = start_delay
        y = 0.42
        line_h = 0.05
        for raw in lines:
            line = raw.strip()
            if line == "":
                delay += gap_blank
                y -= line_h * 0.6
                continue
            current_delay = delay
            current_y = y

            def make_line(_line=line, _y=current_y):
                t = Text(parent=self.root, text=_line,
                         position=(0, _y), origin=(0, 0),
                         scale=0.75,
                         color=color.rgba(230, 230, 235, 0),
                         font="VeraMono.ttf",
                         wordwrap=68)
                self._line_entities.append(t)
                self._fade_in(t)

            invoke(make_line, delay=current_delay)
            delay += gap_line
            y -= line_h
            if y < -0.42:
                y = 0.42
                delay += 0.4
                invoke(self._clear_lines, delay=delay)
                delay += 0.6
        return delay

    def _clear_lines(self):
        """Wipe the on-screen lines so a new group can come in below."""
        for e in self._line_entities:
            try:
                destroy(e)
            except Exception:
                pass
        self._line_entities = []

    def _fade_in(self, text_entity, duration=0.8):
        """Fade a Text entity's alpha from 0 -> 235 over the given duration."""
        steps = 12
        for i in range(steps):
            a = int(235 * (i + 1) / steps)

            def setter(alpha=a, te=text_entity):
                try:
                    te.color = color.rgba(230, 230, 235, alpha)
                except Exception:
                    pass
            invoke(setter, delay=duration * (i + 1) / steps)

    def _title_card(self, subtitle, delay):
        """Show the VOID FREQUENCY title with a small line beneath."""
        def show():
            self._clear_lines()
            Text(parent=self.root, text="VOID FREQUENCY",
                 position=(0, 0.06), origin=(0, 0), scale=2.2,
                 color=color.rgb(230, 230, 240),
                 font="VeraMono.ttf")
            Text(parent=self.root, text=subtitle,
                 position=(0, -0.04), origin=(0, 0), scale=1.0,
                 color=color.rgba(190, 200, 220, 230),
                 font="VeraMono.ttf")
        invoke(show, delay=delay)

    def _menu_button(self, delay):
        """Fade in a 'Return to Main Menu' button."""
        def show():
            self.menu_button = Text(
                parent=self.root, text="[Return to Main Menu]",
                position=(0, -0.30), origin=(0, 0), scale=1.0,
                color=color.rgba(180, 210, 230, 220),
                font="VeraMono.ttf")
            mouse.locked = False
            mouse.visible = True
            self._click_armed = True
        invoke(show, delay=delay)

    # ------------------------------------------------------------------
    # Player input (called by main while ending is active)
    # ------------------------------------------------------------------

    def handle_input(self, key):
        """Return-to-menu trigger: any Enter / E / mouse click after button shows."""
        if self.menu_button is None:
            return
        if key in ("enter", "e", "left mouse down", "space"):
            self._do_return()

    def _do_return(self):
        """Dismiss the ending overlay and fire the return callback."""
        if self.root is not None:
            destroy(self.root)
            self.root = None
        self.menu_button = None
        if callable(self.on_return):
            self.on_return()

    # ------------------------------------------------------------------
    # ENDING A - DESTROY ("Signal Lost")
    # ------------------------------------------------------------------

    def play_ending_a(self):
        """Run Ending A start-to-finish."""
        # Black screen, hum builds then cuts
        self.audio.ramp_ending_hum(target=0.50, seconds=2.0)
        invoke(self.audio.cut_hum, delay=2.1)
        self._build_backdrop(color.rgba(0, 0, 0, 255))
        # SOUND: Three breaths in darkness - distinct voices, used in Ending A
        #         only, plays 1.5 seconds after lights cut, before text begins.
        # Stream the text starting around 4 seconds in
        end_delay = self._stream_lines(ENDING_A_LINES, start_delay=4.0,
                                       gap_blank=1.4, gap_line=1.2)
        # Quiet musical tone after text completes
        invoke(self.audio.ending_tone, delay=end_delay + 0.5)
        # Title card 4 seconds after that
        self._title_card("You came back.", delay=end_delay + 4.5)
        # Menu button 5 seconds after title card
        self._menu_button(delay=end_delay + 9.5)

    # ------------------------------------------------------------------
    # ENDING B - LISTEN ("Resonance")
    # ------------------------------------------------------------------

    def play_ending_b(self):
        """Run Ending B start-to-finish."""
        # The hum grows. The tower's light fills the screen slowly.
        self.audio.ramp_ending_hum(target=0.35, seconds=8.0)
        # Warm white overlay that grows over 4 seconds
        self.root = Entity(parent=camera.ui)
        bg = Entity(parent=self.root, model="quad",
                    color=color.rgba(255, 220, 180, 0),
                    scale=(2.5, 1.5), position=(0, 0, 0.6))
        steps = 30
        for i in range(steps):
            a = int(255 * (i + 1) / steps)

            def setter(alpha=a):
                bg.color = color.rgba(255, 220, 180, alpha)
            invoke(setter, delay=2.0 + i * 0.12)
        self.bg = bg
        # After the warm wash, transition to black for the text
        def to_dark():
            bg.animate("color", color.rgba(0, 0, 0, 255), duration=2.0)
        invoke(to_dark, delay=6.5)
        # Stream text
        end_delay = 9.0
        end_delay = self._stream_lines(ENDING_B_LINES, start_delay=end_delay,
                                       gap_blank=1.4, gap_line=1.1)
        # Hum continues 5 seconds after black, then cuts hard
        invoke(self.audio.cut_hum, delay=end_delay + 5.0)
        # Title card
        self._title_card("Something answered.", delay=end_delay + 5.2)
        # Menu button
        self._menu_button(delay=end_delay + 10.2)
