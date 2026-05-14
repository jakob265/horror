"""
scenes/act3_lab.py
------------------
ACT 3 - RESEARCH DECK & SIGNAL LAB.

The maintenance hatch opens into an access corridor that leads to a large
signal lab.  Banks of monitors all show the same waveform on loop; the
moment Mara enters, every screen simultaneously shifts to an EEG-like
pattern.

In the lab:
    - Note 5 (Yuna's shorthand) on the central workbench
    - Array Access keycard on a side bench
    - Felix's mug, examine-only
    - Felix-Shape crouched on the floor (no reactions)

Off the lab:
    HARGROVE'S OFFICE - papers everywhere, a readable terminal showing the
    calibration log: 'Array resonance at 0.7 Planck units. Unexpected
    harmonic. Flagged for review. Low priority.'  Three months before
    first contact.

OLEN's Intercom 4 fires on lab entry.
"""

import math
import random

from ursina import (
    Entity, Text, Vec3, color, time,
)

from systems.entity import FelixShape
from systems.interaction import make_interactable
from systems import visuals


# ----------------------------------------------------------------------------
# Animated waveform monitor (emissive screen with a sliding sine pattern)
# ----------------------------------------------------------------------------

class _WaveformMonitor(Entity):
    """A wall-mounted lab monitor showing an animated waveform.

    Mode 'sine' - a steady sine, used before player enters the lab.
    Mode 'eeg' - an irregular noisy line, the 'EEG' shift on entry.
    """

    def __init__(self, position, rotation=(0, 0, 0)):
        """Build the monitor body + screen + waveform child entities."""
        super().__init__(model="cube", scale=(1.0, 0.7, 0.08),
                         position=position, rotation=rotation,
                         color=color.rgb(30, 35, 50), collider="box")
        self.screen = Entity(parent=self, model="quad",
                             scale=(0.92, 0.62),
                             position=(0, 0, -0.055),
                             color=color.rgba(15, 25, 55, 255))
        self.mode = "sine"
        self.bars = []
        for i in range(28):
            b = Entity(parent=self.screen, model="quad",
                       scale=(0.025, 0.10),
                       position=(-0.43 + i * 0.031, 0, -0.001),
                       color=color.rgba(120, 220, 240, 255))
            self.bars.append(b)
        self._t = random.uniform(0, 10)

    def set_eeg(self):
        """Switch to the irregular EEG waveform."""
        self.mode = "eeg"
        for b in self.bars:
            b.color = color.rgba(220, 230, 250, 255)

    def update(self):
        """Animate the waveform bars each frame."""
        self._t += time.dt
        if self.mode == "sine":
            for i, b in enumerate(self.bars):
                y = 0.18 * math.sin(self._t * 4.0 + i * 0.5)
                b.position = (b.x, y, b.z)
        else:
            for i, b in enumerate(self.bars):
                y = (0.05 * math.sin(self._t * 8.0 + i)
                     + 0.10 * math.sin(self._t * 3.0 + i * 1.7)
                     + 0.08 * (random.random() - 0.5))
                b.position = (b.x, y, b.z)


# ----------------------------------------------------------------------------
# Scene build
# ----------------------------------------------------------------------------

def build(game):
    """Construct Act 3 geometry."""
    created = []

    # ----- Access corridor (from Act 2 hatch) -----
    # Floor
    created.append(Entity(model="cube", scale=(3, 0.2, 8),
                          position=(0, -0.1, -10),
                          color=color.rgb(55, 60, 70), collider="box"))
    created.append(Entity(model="cube", scale=(3, 0.2, 8),
                          position=(0, 3, -10),
                          color=color.rgb(30, 35, 45)))
    for x in (-1.5, 1.5):
        created.append(Entity(model="cube", scale=(0.2, 3, 8),
                              position=(x, 1.5, -10),
                              color=color.rgb(45, 50, 60), collider="box"))
    # Back cap
    created.append(Entity(model="cube", scale=(3, 3, 0.2),
                          position=(0, 1.5, -14.1),
                          color=color.rgb(40, 50, 60), collider="box"))

    # ----- Signal Lab (16 x 12 room) -----
    lab_center = (0, 0, 0)
    lab_w, lab_d = 16, 12
    created.append(Entity(model="cube", scale=(lab_w, 0.2, lab_d),
                          position=(lab_center[0], -0.1, lab_center[2]),
                          color=color.rgb(130, 140, 150),
                          texture=visuals.make_concrete(),
                          texture_scale=(8, 6),
                          collider="box"))
    created.append(Entity(model="cube", scale=(lab_w, 0.2, lab_d),
                          position=(lab_center[0], 3.5, lab_center[2]),
                          color=color.rgb(80, 90, 105),
                          texture=visuals.make_metal_panel(),
                          texture_scale=(4, 3)))
    # Walls
    # north - with 1.4-wide opening centered at x=-6 for the array door
    array_door_x = -6
    DOOR_W = 1.4
    # Left segment of north wall: from x=-lab_w/2 to array_door_x - DOOR_W/2
    left_w = (array_door_x - DOOR_W / 2) - (-lab_w / 2)
    if left_w > 0:
        created.append(Entity(model="cube", scale=(left_w, 3.5, 0.2),
                              position=(-lab_w / 2 + left_w / 2, 1.75,
                                        lab_d / 2),
                              color=color.rgb(50, 55, 65),
                              texture=visuals.make_metal_panel(),
                              texture_scale=(left_w / 2, 1.75),
                              collider="box"))
    # Right segment: from array_door_x + DOOR_W/2 to lab_w/2
    right_w = lab_w / 2 - (array_door_x + DOOR_W / 2)
    if right_w > 0:
        created.append(Entity(model="cube", scale=(right_w, 3.5, 0.2),
                              position=(array_door_x + DOOR_W / 2
                                        + right_w / 2, 1.75, lab_d / 2),
                              color=color.rgb(50, 55, 65),
                              texture=visuals.make_metal_panel(),
                              texture_scale=(right_w / 2, 1.75),
                              collider="box"))
    # Header above the array door opening
    created.append(Entity(model="cube",
                          scale=(DOOR_W + 0.2, 3.5 - 2.4, 0.2),
                          position=(array_door_x,
                                    2.4 + (3.5 - 2.4) / 2,
                                    lab_d / 2),
                          color=color.rgb(50, 55, 65),
                          collider="box"))
    # south wall with corridor opening (gap centered)
    seg_w = (lab_w - 3) / 2
    for sx in (-(1.5 + seg_w / 2), (1.5 + seg_w / 2)):
        created.append(Entity(model="cube", scale=(seg_w, 3.5, 0.2),
                              position=(sx, 1.75, -lab_d / 2),
                              color=color.rgb(50, 55, 65), collider="box"))
    # east + west - east wall has an opening leading to Hargrove's office (z=2..5)
    # east solid lower portion z=-6..1 and z=5..6
    created.append(Entity(model="cube", scale=(0.2, 3.5, 7),
                          position=(lab_w / 2, 1.75, -2.5),
                          color=color.rgb(50, 55, 65), collider="box"))
    created.append(Entity(model="cube", scale=(0.2, 3.5, 1),
                          position=(lab_w / 2, 1.75, 5.5),
                          color=color.rgb(50, 55, 65), collider="box"))
    # west wall solid
    created.append(Entity(model="cube", scale=(0.2, 3.5, lab_d),
                          position=(-lab_w / 2, 1.75, 0),
                          color=color.rgb(50, 55, 65), collider="box"))

    # Cool blue overhead glow (just visual emissive panels)
    for x in (-5, 0, 5):
        for z in (-4, 0, 4):
            created.append(Entity(model="cube",
                                  scale=(1.2, 0.06, 0.4),
                                  position=(x, 3.35, z),
                                  color=color.rgba(180, 220, 240, 255)))

    # ----- Bank of monitors along north wall -----
    monitors = []
    for x in [-5, -3, -1, 1, 3, 5]:
        m = _WaveformMonitor(position=(x, 1.8, 5.85), rotation=(0, 180, 0))
        monitors.append(m)
        created.append(m)
        game.register_ticker(m.update)

    # Central workbench
    bench = Entity(model="cube", scale=(3.0, 1.0, 1.2),
                   position=(0, 0.5, 0),
                   color=color.rgb(70, 75, 85), collider="box")
    created.append(bench)
    # Note 5 on the bench
    note5 = Entity(model="quad", scale=(0.4, 0.5),
                   rotation=(90, 0, 0),
                   position=(-0.6, 1.02, 0.2),
                   color=color.rgba(230, 220, 200, 255), collider="box")
    make_interactable(note5, "Read lab notebook", "collect_note",
                      note_id="note_5")
    created.append(note5)

    # Side bench - array access keycard + Felix's mug
    side_bench = Entity(model="cube", scale=(2.4, 1.0, 0.9),
                       position=(-6.0, 0.5, 0),
                       color=color.rgb(65, 70, 80), collider="box")
    created.append(side_bench)
    side_label_plate = Entity(model="quad", scale=(1.4, 0.18),
                              position=(-6.0, 1.05, -0.45),
                              rotation=(0, 0, 0),
                              color=color.rgba(255, 240, 180, 250))
    Text(parent=side_label_plate,
         text="ARRAY ACCESS - AUTHORIZED PERSONNEL ONLY",
         position=(0, 0, -0.01), origin=(0, 0), scale=2.4,
         color=color.rgb(40, 40, 40), font="VeraMono.ttf")
    created.append(side_label_plate)

    array_keycard = Entity(model="cube", scale=(0.22, 0.04, 0.13),
                           position=(-6.0, 1.04, 0.0),
                           color=color.rgba(220, 180, 120, 255),
                           collider="box")

    def collect_array_keycard():
        """Take the array keycard - unlocks the array room door (Act 4)."""
        game.state.array_keycard = True
        from ursina import destroy as _d
        _d(array_keycard)
        game.show_examine(
            "ARRAY ACCESS KEYCARD secured.  The way to the array room is open.")
    make_interactable(array_keycard, "Take array keycard", "trigger_event",
                      callback=collect_array_keycard)
    created.append(array_keycard)

    # Felix's mug - examine_only
    felix_mug = Entity(model="cube", scale=(0.18, 0.20, 0.18),
                       position=(-5.0, 1.05, 0.0),
                       color=color.rgb(160, 80, 60), collider="box")
    make_interactable(
        felix_mug, "Look at mug", "examine_only",
        text=("Felix's mug.  'WORLD'S OKAYEST ASTROPHYSICIST' in block "
              "letters.  He won it in a crew bet in month four.  He was "
              "so pleased with himself."),
        duration=5.0)
    created.append(felix_mug)

    # ----- Felix-Shape crouched in the corner of the lab -----
    # Corner: east side near south wall
    felix_corner = FelixShape(
        position=(5.5, 0, -4.5), rotation_y=210,
        crouched=True, audio=game.audio)
    game.shapes.register(felix_corner)
    created.append(felix_corner)

    # ----- Intercom 4 panel near the south doorway -----
    from systems.olen import IntercomPanel
    intercom4 = IntercomPanel(position=(-1.5, 1.7, -5.85),
                              rotation=(0, 0, 0))
    created.append(intercom4)
    game.register_ticker(intercom4.update)
    game.olen.add_proximity_trigger(
        intercom_id=4, position=(0, 1.6, -5.5), panel=intercom4,
        radius=3.5)

    # ----- EEG-shift gate: once player crosses z = -5, switch monitors -----
    lab_state = {"eeg_done": False}

    def maybe_eeg_shift():
        """The moment Mara enters, all monitors flip to the EEG waveform."""
        if lab_state["eeg_done"]:
            return
        if game.player.position.z > -5.5:
            for m in monitors:
                m.set_eeg()
            lab_state["eeg_done"] = True
    game.register_ticker(maybe_eeg_shift)

    # ----- Hargrove's Office (off the east side, z = 2..6) -----
    office_center = (lab_w / 2 + 4, 0, 4)
    ox, _, oz = office_center
    o_w, o_d = 6, 4
    created.append(Entity(model="cube", scale=(o_w, 0.2, o_d),
                          position=(ox, -0.1, oz),
                          color=color.rgb(45, 45, 55), collider="box"))
    created.append(Entity(model="cube", scale=(o_w, 0.2, o_d),
                          position=(ox, 3.0, oz),
                          color=color.rgb(25, 30, 40)))
    # Walls
    # north / south
    for zz in (oz - o_d / 2, oz + o_d / 2):
        created.append(Entity(model="cube", scale=(o_w, 3.0, 0.2),
                              position=(ox, 1.5, zz),
                              color=color.rgb(45, 50, 55), collider="box"))
    # east solid
    created.append(Entity(model="cube", scale=(0.2, 3.0, o_d),
                          position=(ox + o_w / 2, 1.5, oz),
                          color=color.rgb(45, 50, 55), collider="box"))
    # west wall = lab's east wall opening; only build a corner segment at top
    # (the opening through which the player walks; already handled in lab wall)

    # Desk + papers + readable terminal
    h_desk = Entity(model="cube", scale=(1.8, 0.85, 0.9),
                   position=(ox - 0.8, 0.42, oz - 0.5),
                   color=color.rgb(55, 50, 45), collider="box")
    created.append(h_desk)
    # Strewn paper
    for i in range(7):
        pp = (ox - 1.6 + random.uniform(-1.2, 1.2), 0.02,
              oz + random.uniform(-1.5, 1.5))
        rot = random.uniform(0, 90)
        created.append(Entity(model="quad", scale=(0.28, 0.35),
                              rotation=(90, rot, 0),
                              position=pp,
                              color=color.rgba(230, 220, 195, 240),
                              collider="box"))
    # Warm desk lamp (just visual emissive)
    created.append(Entity(model="sphere", scale=0.18,
                          position=(ox + 0.4, 1.10, oz - 0.55),
                          color=color.rgba(255, 220, 140, 255)))
    created.append(Entity(model="circle",
                          scale=2.6,
                          rotation=(90, 0, 0),
                          position=(ox - 0.6, 0.02, oz - 0.4),
                          color=color.rgba(255, 220, 140, 50)))

    # Readable terminal on the desk
    terminal_back = Entity(model="cube", scale=(0.85, 0.55, 0.06),
                          position=(ox - 0.8, 1.10, oz - 0.85),
                          color=color.rgb(30, 30, 35), collider="box")
    created.append(terminal_back)
    term_screen = Entity(model="quad", scale=(0.76, 0.48),
                         position=(ox - 0.8, 1.10, oz - 0.825),
                         color=color.rgba(20, 40, 30, 255), collider="box")
    created.append(term_screen)
    Text(parent=term_screen,
         text="[ ARRAY MAINTENANCE LOG ]\n\nREAD",
         position=(0, 0, -0.01), origin=(0, 0), scale=2.4,
         color=color.rgb(120, 220, 160), font="VeraMono.ttf")
    log_text = (
        "ARRAY MAINTENANCE LOG\n"
        "STATION CRESTFALL-9 / DEEP SPACE ARRAY\n"
        "============================================================\n\n"
        "Entry 0117 - R. HARGROVE\n"
        "Date:  [REDACTED - 3 months prior to 'first contact']\n\n"
        "Array resonance at 0.7 Planck units.\n"
        "Unexpected harmonic.\n"
        "Flagged for review.\n"
        "LOW PRIORITY.\n\n"
        "------------------------------------------------------------\n"
        "    cross-reference:    calibration index 442-K\n"
        "    note (R.H.):        return to this later.\n"
        "------------------------------------------------------------\n\n"
        "Entry 0118 - R. HARGROVE\n"
        "Date:  [REDACTED]\n\n"
        "(no entries logged)\n\n"
        "Entry 0119 - R. HARGROVE\n"
        "Date:  [REDACTED - day of 'first contact']\n\n"
        "*** STANDING WAVE DETECTED ***\n"
        "Coordinates pending.  Signature unknown.\n"
        "REC: full alert.  Convene crew.\n"
        "============================================================\n"
    )
    make_interactable(term_screen, "Read terminal", "read_terminal",
                      title="ARRAY MAINTENANCE LOG", text=log_text)

    # Player spawns at the south end of the corridor (z = -13.5)
    game.player.position = Vec3(0, 1.6, -13.5)
    game.player.fpc.rotation_y = 0

    # Heavy array door - sits in the north-wall opening at x=-6.  When
    # unlocked it slides up into the header.
    array_door = Entity(model="cube",
                        scale=(DOOR_W, 2.4, 0.10),
                        position=(array_door_x, 1.2, lab_d / 2),
                        color=color.rgb(110, 80, 60),
                        texture=visuals.make_metal_panel(),
                        texture_scale=(DOOR_W / 2, 1.2),
                        collider="box")
    created.append(array_door)
    # Label "ARRAY" on a small plate above
    label_plate = Entity(model="cube",
                         scale=(0.6, 0.16, 0.04),
                         position=(array_door_x, 2.5, lab_d / 2 - 0.13),
                         color=color.rgb(220, 200, 160))
    created.append(label_plate)
    Text(parent=label_plate, text="ARRAY",
         position=(0, 0, -0.55), origin=(0, 0), scale=3.5,
         color=color.rgb(30, 30, 35), font="VeraMono.ttf")

    def try_open_array_door():
        """Slide the array door open if the keycard has been collected."""
        if not game.state.array_keycard:
            game.show_examine(
                "Door locked.  ARRAY ACCESS keycard required.")
            return
        if game.state.array_door_open:
            return
        array_door.animate("y", 2.4 + 1.2, duration=0.6)
        # Drop collision and hide once it's clear
        from ursina import invoke as _invoke
        _invoke(setattr, array_door, "collider", None, delay=0.55)
        _invoke(setattr, array_door, "visible", False, delay=0.60)
        game.audio.door()
        game.state.array_door_open = True
    make_interactable(array_door, "Try array door", "trigger_event",
                      callback=try_open_array_door)
    game.state.array_door_open = False

    # Intercom 5 - just outside the array door (proximity)
    intercom5 = IntercomPanel(position=(-4.6, 1.7, lab_d / 2 - 0.15),
                              rotation=(0, 180, 0))
    created.append(intercom5)
    game.register_ticker(intercom5.update)
    game.olen.add_proximity_trigger(
        intercom_id=5, position=(-6, 1.6, lab_d / 2 - 1.2), panel=intercom5,
        radius=3.5)

    # Transition - cross the array door threshold
    def check_transition():
        """Trigger Act 4 transition when player crosses the array door."""
        if game.state.array_door_open:
            pp = game.player.position
            if pp.z > lab_d / 2 + 0.2 and abs(pp.x - array_door_x) < 1.0:
                game.transition_to("act4")
    game.register_ticker(check_transition)

    return created
