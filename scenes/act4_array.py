"""
scenes/act4_array.py
--------------------
ACT 4 - COMMUNICATIONS ARRAY ROOM.

The biggest space in the game. Ceiling barely visible. The central tower
runs floor to ceiling, layered hardware and conduit, pulsing with a deep
slow light. Like breathing. Subtle camera shake - subsonic.

Note 6 (OLEN's maintenance log) on the floor near the entrance.
Note 7 (Mara's torn handwriting) at the base of the tower.

Three monitor stations show the signal's origin data - the array's own
broadcast coordinates, pointing inward.

Hargrove-Shape stands at the tower base, facing it, static.

OLEN speaks at the door (Intercom 5 fires in Act 3, just outside, already
registered there). At the terminal: Intercom 6 fires (proximity, 2 s delay).
Hargrove-Shape turns, waves, walks off after Intercom 6 ends.

THE TERMINAL:
    [DESTROY TRANSMITTER - EMERGENCY DISCHARGE PROTOCOL]
    [LISTEN]
15 seconds idle - LISTEN option pulses slowly.
"""

import math

from ursina import (
    Button, Entity, Text, Vec2, Vec3, camera, color, destroy, invoke,
    mouse, time,
)
from ursina.models.procedural.cylinder import Cylinder

from systems.entity import HargroveShape
from systems.interaction import make_interactable


# ----------------------------------------------------------------------------
# Slow-pulsing tower light (the only major light source in the room)
# ----------------------------------------------------------------------------

class _TowerCore(Entity):
    """Cylindrical core that breathes warm-white -> blue between intensities 0.3-0.7."""

    def __init__(self, position):
        """Build the core entity + a floor light pool."""
        super().__init__(model=Cylinder(resolution=16, radius=0.5, height=1.0),
                         scale=(0.8, 6.0, 0.8),
                         position=position,
                         color=color.rgba(220, 200, 180, 255))
        self._t = 0.0
        self._floor = Entity(model="circle", scale=8.0,
                             rotation=(90, 0, 0),
                             position=(position[0], 0.03, position[2]),
                             color=color.rgba(230, 200, 170, 70))

    def update(self):
        """Slow breathing pulse - 4 second period."""
        self._t += time.dt
        v = 0.5 + 0.5 * math.sin(self._t * (2.0 * math.pi / 4.0))
        # color shift warm white -> slight blue at peak
        r = int(180 + 50 * (1 - v))
        g = int(180 + 25 * (1 - v))
        b = int(150 + 90 * v)
        self.color = color.rgba(r, g, b, 255)
        self._floor.color = color.rgba(r, g, b, int(40 + 60 * v))


# ----------------------------------------------------------------------------
# Subtle camera shake driver
# ----------------------------------------------------------------------------

class _SubsonicShake(Entity):
    """A no-mesh entity that nudges camera each frame with very small noise."""

    def __init__(self):
        """Init shake phase."""
        super().__init__()
        self._t = 0.0
        self._original_pos = None

    def update(self):
        """Apply tiny per-frame camera offset."""
        self._t += time.dt
        # Camera pivot is on the FPC; we shake the camera world position via its z-axis
        try:
            dx = 0.004 * math.sin(self._t * 2.7)
            dz = 0.004 * math.cos(self._t * 3.1)
            camera.shake_amount = 0
            # Lightweight: jiggle the camera local position by a hair
            camera.position = (dx, camera.position[1] if not isinstance(camera.position, tuple) else 0, dz)
        except Exception:
            pass


# ----------------------------------------------------------------------------
# Terminal UI
# ----------------------------------------------------------------------------

class TerminalUI:
    """The two-option terminal at the foot of the tower."""

    def __init__(self, game):
        """Save references; UI built when the player interacts."""
        self.game = game
        self.root = None
        self.listen_btn = None
        self.destroy_btn = None
        self._idle_timer = 0.0
        self.opened_at = None
        self.is_open = False
        self.confirm_root = None
        self.confirming_destroy = False
        self.pulse_active = False
        self._pulse_t = 0.0

    def open(self):
        """Open the terminal modal. Disables player input."""
        if self.is_open:
            return
        self.is_open = True
        self.game.set_modal(True)
        mouse.locked = False
        mouse.visible = True
        self.root = Entity(parent=camera.ui)
        Entity(parent=self.root, model="quad",
               color=color.rgba(0, 0, 0, 230),
               scale=(2.2, 1.4), position=(0, 0, 0.5))
        Text(parent=self.root, text="ARRAY CONTROL TERMINAL",
             position=(0, 0.36), origin=(0, 0), scale=1.4,
             color=color.rgb(120, 220, 200), font="VeraMono.ttf")
        Text(parent=self.root,
             text="Select an action.",
             position=(0, 0.27), origin=(0, 0), scale=0.95,
             color=color.rgba(180, 220, 230, 220), font="VeraMono.ttf")

        # Button labels - we use Text + a backing quad each; click handled by
        # checking mouse position on input events. But simpler: use Ursina Button.
        try:
            self.destroy_btn = Button(
                parent=self.root,
                text="[ DESTROY TRANSMITTER - EMERGENCY DISCHARGE PROTOCOL ]",
                position=(0, 0.05), scale=(1.4, 0.10),
                color=color.rgba(80, 30, 30, 255),
                text_color=color.rgb(240, 220, 220),
                on_click=self.choose_destroy,
            )
            self.listen_btn = Button(
                parent=self.root,
                text="[ LISTEN ]",
                position=(0, -0.10), scale=(1.4, 0.10),
                color=color.rgba(30, 60, 80, 255),
                text_color=color.rgb(220, 240, 240),
                on_click=self.choose_listen,
            )
        except Exception:
            # Fallback: Text-only with keyboard shortcuts
            self.destroy_btn = None
            self.listen_btn = None
            Text(parent=self.root,
                 text="[1]  DESTROY TRANSMITTER (EMERGENCY DISCHARGE)",
                 position=(0, 0.05), origin=(0, 0), scale=1.0,
                 color=color.rgb(240, 200, 200), font="VeraMono.ttf")
            Text(parent=self.root,
                 text="[2]  LISTEN",
                 position=(0, -0.10), origin=(0, 0), scale=1.0,
                 color=color.rgb(200, 230, 240), font="VeraMono.ttf")
        Text(parent=self.root,
             text="(15 seconds.  Something is waiting.)",
             position=(0, -0.30), origin=(0, 0), scale=0.85,
             color=color.rgba(160, 180, 200, 200),
             font="VeraMono.ttf")
        self.opened_at = time.time()

    def update(self):
        """Drive the 15-second LISTEN pulse + the optional shake."""
        if not self.is_open or self.opened_at is None:
            return
        elapsed = time.time() - self.opened_at
        if elapsed >= 15.0 and not self.pulse_active:
            self.pulse_active = True
        if self.pulse_active and self.listen_btn is not None:
            self._pulse_t += time.dt
            b = 0.5 + 0.5 * math.sin(self._pulse_t * (2.0 * math.pi / 4.0))
            try:
                r = int(40 + 100 * b)
                g = int(80 + 120 * b)
                bl = int(110 + 130 * b)
                self.listen_btn.color = color.rgba(r, g, bl, 255)
            except Exception:
                pass

    def handle_input(self, key):
        """Allow 1/2 keys as alternate shortcuts."""
        if not self.is_open or self.confirming_destroy:
            return
        if key == "1":
            self.choose_destroy()
        elif key == "2":
            self.choose_listen()

    # --------------------------------------------------------------
    # Choices
    # --------------------------------------------------------------

    def choose_destroy(self):
        """Open the confirmation prompt for DESTROY."""
        if self.confirming_destroy:
            return
        self.confirming_destroy = True
        # Build confirm overlay
        self.confirm_root = Entity(parent=self.root)
        Entity(parent=self.confirm_root, model="quad",
               color=color.rgba(0, 0, 0, 235),
               scale=(2.2, 1.4), position=(0, 0, 0.55))
        Text(parent=self.confirm_root,
             text="This action is irreversible.\nConfirm?",
             position=(0, 0.15), origin=(0, 0), scale=1.2,
             color=color.rgb(240, 200, 200), font="VeraMono.ttf")
        try:
            Button(parent=self.confirm_root, text="[ CONFIRM DESTROY ]",
                   position=(0, -0.05), scale=(1.0, 0.10),
                   color=color.rgba(120, 20, 20, 255),
                   text_color=color.rgb(245, 215, 215),
                   on_click=self.do_destroy)
            Button(parent=self.confirm_root, text="[ Cancel ]",
                   position=(0, -0.20), scale=(1.0, 0.10),
                   color=color.rgba(40, 50, 60, 255),
                   text_color=color.rgb(220, 230, 235),
                   on_click=self.cancel_destroy)
        except Exception:
            Text(parent=self.confirm_root,
                 text="[Y]  CONFIRM     [N]  Cancel",
                 position=(0, -0.05), origin=(0, 0), scale=1.0,
                 color=color.rgb(220, 230, 235), font="VeraMono.ttf")

    def cancel_destroy(self):
        """Back out of the destroy confirmation."""
        if self.confirm_root is not None:
            destroy(self.confirm_root)
            self.confirm_root = None
        self.confirming_destroy = False

    def do_destroy(self):
        """Commit: tear down the terminal UI and start Ending A."""
        if self.root is not None:
            destroy(self.root)
            self.root = None
        self.is_open = False
        self.confirming_destroy = False
        self.game.start_ending("A")

    def choose_listen(self):
        """LISTEN choice -> Ending B."""
        if self.root is not None:
            destroy(self.root)
            self.root = None
        self.is_open = False
        self.game.start_ending("B")


# ----------------------------------------------------------------------------
# Scene build
# ----------------------------------------------------------------------------

def build(game):
    """Construct Act 4 geometry."""
    created = []

    # Vast room - 30 x 30, ceiling at y=18 (barely visible)
    rw, rd, rh = 30, 30, 18
    floor = Entity(model="plane", scale=(rw, 1, rd),
                   position=(0, 0, 0),
                   color=color.rgb(20, 22, 28), collider="box")
    created.append(floor)
    # No ceiling light - just a high cube to seal it
    ceil = Entity(model="cube", scale=(rw, 0.2, rd),
                  position=(0, rh, 0),
                  color=color.rgb(8, 8, 12))
    created.append(ceil)
    # Walls
    for x, z, sx, sz in [(-rw / 2, 0, 0.2, rd), (rw / 2, 0, 0.2, rd),
                         (0, -rd / 2, rw, 0.2), (0, rd / 2, rw, 0.2)]:
        created.append(Entity(model="cube", scale=(sx, rh, sz),
                              position=(x, rh / 2, z),
                              color=color.rgb(20, 22, 28), collider="box"))

    # Central tower
    tower_pos = (0, 9, 4)
    tower_outer = Entity(model=Cylinder(resolution=24, radius=0.5, height=1.0),
                         scale=(1.6, rh, 1.6),
                         position=(tower_pos[0], rh / 2,
                                   tower_pos[2]),
                         color=color.rgb(40, 45, 55),
                         collider="box")
    created.append(tower_outer)
    tower_core = _TowerCore(position=(tower_pos[0], rh / 2, tower_pos[2]))
    created.append(tower_core)
    game.register_ticker(tower_core.update)
    # Conduit cubes around the tower
    for ang in range(0, 360, 30):
        rad = 1.85
        x = tower_pos[0] + math.cos(math.radians(ang)) * rad
        z = tower_pos[2] + math.sin(math.radians(ang)) * rad
        h = 4.0 + (ang % 70) / 70.0 * 6.0
        created.append(Entity(model="cube", scale=(0.30, h, 0.30),
                              position=(x, h / 2, z),
                              color=color.rgb(30, 35, 45),
                              collider="box"))

    # Subsonic shake (per-frame nudge of camera position)
    shake = _SubsonicShake()
    created.append(shake)
    game.register_ticker(shake.update)

    # Note 6 - OLEN's maintenance log, on the floor near the entrance
    note6 = Entity(model="quad", scale=(0.4, 0.5),
                   rotation=(90, 0, 0),
                   position=(0, 0.03, -12),
                   color=color.rgba(230, 220, 200, 255), collider="box")
    make_interactable(note6, "Read maintenance log", "collect_note",
                      note_id="note_6")
    created.append(note6)

    # Note 7 - Mara's torn paper, at the base of the tower
    note7 = Entity(model="quad", scale=(0.35, 0.45),
                   rotation=(90, 0, 0),
                   position=(tower_pos[0] + 1.6, 0.03, tower_pos[2] - 0.8),
                   color=color.rgba(220, 210, 195, 255), collider="box")
    make_interactable(note7, "Read torn paper", "collect_note",
                      note_id="note_7")
    created.append(note7)

    # Three monitor stations (signal origin - the array's own coords)
    for ang_deg in (-45, 0, 45):
        ang = math.radians(ang_deg)
        sx = tower_pos[0] + math.sin(ang) * 7
        sz = tower_pos[2] + math.cos(ang) * 7 + 3
        stand = Entity(model="cube", scale=(1.2, 0.9, 0.5),
                       position=(sx, 0.45, sz),
                       color=color.rgb(35, 40, 50), collider="box")
        created.append(stand)
        screen = Entity(model="quad", scale=(1.0, 0.6),
                        rotation=(0, ang_deg, 0),
                        position=(sx, 1.10, sz - 0.26),
                        color=color.rgba(60, 130, 180, 255))
        created.append(screen)
        Text(parent=screen,
             text=("SIGNAL ORIGIN\n"
                   "BEARING: 000.000\n"
                   "DIST:    0.000 m\n"
                   "(SELF)"),
             position=(0, 0, -0.01), origin=(0, 0), scale=2.4,
             color=color.rgb(15, 20, 40), font="VeraMono.ttf")

    # Hargrove-Shape at the base of the tower
    hargrove = HargroveShape(
        position=(tower_pos[0], 0, tower_pos[2] + 1.6),
        rotation_y=180, audio=game.audio)
    game.shapes.register(hargrove)
    created.append(hargrove)
    game.state.hargrove_shape = hargrove

    # Terminal pedestal in front of the tower (player-facing south)
    term_pedestal = Entity(model="cube", scale=(0.9, 1.1, 0.6),
                           position=(tower_pos[0], 0.55,
                                     tower_pos[2] - 2.2),
                           color=color.rgb(50, 60, 75), collider="box")
    created.append(term_pedestal)
    term_screen = Entity(model="quad", scale=(0.75, 0.45),
                         rotation=(35, 0, 0),
                         position=(tower_pos[0], 1.15,
                                   tower_pos[2] - 2.45),
                         color=color.rgba(40, 130, 110, 255), collider="box")
    created.append(term_screen)
    Text(parent=term_screen,
         text="[ ARRAY CONTROL ]\n  USE TERMINAL",
         position=(0, 0, -0.01), origin=(0, 0), scale=2.5,
         color=color.rgb(15, 50, 35), font="VeraMono.ttf")

    # Create the TerminalUI and gate it behind the Intercom 6 sequence
    terminal_ui = TerminalUI(game)
    game.state.terminal_ui = terminal_ui

    def open_terminal():
        """Player interacts with the terminal pedestal."""
        terminal_ui.open()
    make_interactable(term_screen, "Use terminal", "trigger_event",
                      callback=open_terminal)

    # Per-frame: drive the terminal pulse + check intercom 6 trigger
    game.register_ticker(terminal_ui.update)

    # Intercom 6 - proximity to the terminal, 2 second delay, fires once.
    # When it FINISHES, Hargrove-Shape does its farewell + the terminal lights up.
    from systems.olen import IntercomPanel
    intercom6_panel = IntercomPanel(position=(tower_pos[0], 1.7,
                                              tower_pos[2] - 2.95),
                                    rotation=(0, 0, 0))
    created.append(intercom6_panel)
    game.register_ticker(intercom6_panel.update)
    # Wrap the OlenManager registration so we can run a callback when 6 fires.
    state = {"hargrove_started": False, "act4_sting_played": False}

    def maybe_hargrove_wave():
        """After Intercom 6 has fully played, trigger Hargrove's farewell."""
        if state["hargrove_started"]:
            return
        # Wait for Intercom 6 to have fired AND the subtitle to be done
        if 6 in game.olen.fired and not game.olen.subtitle.is_active:
            state["hargrove_started"] = True
            hargrove.farewell()
    game.register_ticker(maybe_hargrove_wave)

    game.olen.add_proximity_trigger(
        intercom_id=6,
        position=(tower_pos[0], 1.6, tower_pos[2] - 2.6),
        panel=intercom6_panel,
        radius=2.2, delay=2.0)

    # Play the Shape sting once on entering Act 4
    def play_entry_sting():
        """Single sting when player enters this scene."""
        if state["act4_sting_played"]:
            return
        state["act4_sting_played"] = True
        game.audio.shape_sting()
    invoke(play_entry_sting, delay=0.4)

    # Player spawn just inside the array door (came from Act 3 lab north door)
    game.player.position = Vec3(0, 1.6, -12.5)
    game.player.fpc.rotation_y = 0

    return created
