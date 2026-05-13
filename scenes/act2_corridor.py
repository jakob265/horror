"""
scenes/act2_corridor.py
-----------------------
ACT 2 - RESIDENTIAL CORRIDOR & CREW QUARTERS.

A curved corridor with four cabin doors:
    OKAFOR    (Felix)  - open, Note 2, monitor, Amara drawing, Felix-Shape at viewport
    PARK      (Yuna)   - door has Note 3 taped to it; Shape conditional on note pickup
    HARGROVE  (Raymond)- locked, code 4301 (Day 34 from Felix's journal, reversed)
    VOSS      (Mara)   - open; her things; Eli photo; mirror with 'YOU STARTED IT';
                         Intercom 3 manual on wall.

Maintenance hatch at corridor end. Code 7741 scratched on wall (flashlight only).
Felix-Shape stands beside the hatch, faces the wall; steps aside when door opens.
Intercom 2 fires on proximity outside Felix's cabin.
"""

import random

from ursina import (
    Entity, Text, Vec3, color, destroy, time,
)

from systems.entity import FelixShape, YunaShape
from systems.interaction import make_interactable
from systems.olen import IntercomPanel
from systems import visuals


# ----------------------------------------------------------------------------
# Helpers
# ----------------------------------------------------------------------------

class _FlickerPanel(Entity):
    """Cool-white ceiling panel that flickers fast (interval 1-4 s)."""

    def __init__(self, position, steady=False):
        """steady=True means it doesn't flicker (just dim cool white)."""
        super().__init__(model="cube", scale=(1.4, 0.06, 0.5),
                         position=position,
                         color=color.rgba(200, 220, 230, 255))
        self.steady = steady
        self._timer = random.uniform(1.0, 4.0)
        self._dim = False
        self._pool = Entity(model="quad",
                            scale=(2.4, 2.4),
                            rotation=(90, 0, 0),
                            position=(position[0], 0.05, position[2]),
                            color=color.rgba(180, 200, 220, 35))

    def update(self):
        """Flicker behavior; steady panels skip update entirely."""
        if self.steady:
            return
        self._timer -= time.dt
        if self._timer <= 0:
            if not self._dim:
                self._dim = True
                self.color = color.rgba(80, 90, 100, 255)
                self._pool.color = color.rgba(80, 90, 100, 12)
                self._timer = random.uniform(0.04, 0.12)
            else:
                self._dim = False
                self.color = color.rgba(200, 220, 230, 255)
                self._pool.color = color.rgba(180, 200, 220, 35)
                self._timer = random.uniform(1.0, 4.0)


def _world_text(s, position, rotation, scale, col, created, parent=None):
    """Place 3D world-space Text by parenting it to a transparent anchor Entity."""
    anchor = Entity(position=position, rotation=rotation)
    if parent is not None:
        anchor.parent = parent
    created.append(anchor)
    t = Text(parent=anchor, text=s, position=(0, 0, 0),
             origin=(0, 0), scale=scale, color=col,
             font="VeraMono.ttf")
    return t


def _make_door(label, position, rotation_y, color_door, created,
               locked=False, code=None, on_unlock=None):
    """Build a cabin door + label + (optional) keypad. Returns the pivot."""
    pivot = Entity(position=position, rotation=(0, rotation_y, 0))
    door = Entity(parent=pivot, model="cube",
                  scale=(1.0, 2.4, 0.12),
                  position=(-0.5, 1.20, 0),
                  color=color_door, collider="box")
    created.append(pivot)
    # Door label plate
    plate = Entity(parent=pivot, model="cube",
                   scale=(0.4, 0.12, 0.02),
                   position=(-0.5, 2.20, -0.07),
                   color=color.rgb(180, 200, 220))
    created.append(plate)
    Text(parent=plate, text=label, position=(0, 0, -0.05),
         origin=(0, 0), scale=4, color=color.rgb(20, 30, 40),
         font="VeraMono.ttf")
    pivot._door_pivot = True
    pivot._door_locked = locked

    def open_door():
        """Animate door rotation."""
        pivot.animate("rotation_y", rotation_y + 90, duration=0.4)
        pivot._door_opened = True

    if locked:
        # Wall-mounted keypad next to the door
        keypad = Entity(model="cube",
                        scale=(0.20, 0.30, 0.06),
                        position=(position[0] + 0.6, 1.4, position[2]),
                        color=color.rgb(60, 70, 80), collider="box")

        def unlock_cb():
            """Run the optional unlock hook then open the door."""
            if callable(on_unlock):
                on_unlock()
            pivot._door_locked = False
            open_door()
        make_interactable(keypad, "Enter code", "keypad",
                          code=code, on_unlock=unlock_cb)
        created.append(keypad)
        make_interactable(door, "Door " + label, "trigger_event",
                          callback=lambda: None)
    else:
        make_interactable(door, "Open " + label, "trigger_event",
                          callback=open_door)
    return pivot


# ----------------------------------------------------------------------------
# Scene build
# ----------------------------------------------------------------------------

def build(game):
    """Construct Act 2 geometry. Returns list of created entities."""
    created = []
    cabins = []

    # ----- Corridor: 22 units long -----
    # Floor (corridor + cabin alcoves)
    floor = Entity(model="plane", scale=(6, 1, 24),
                   position=(0, 0, 6),
                   color=color.rgb(110, 115, 125),
                   texture=visuals.make_grating(),
                   texture_scale=(3, 12),
                   collider="box")
    created.append(floor)
    ceil = Entity(model="cube", scale=(6, 0.2, 24),
                  position=(0, 3, 6),
                  color=color.rgb(70, 75, 85),
                  texture=visuals.make_metal_panel(),
                  texture_scale=(3, 12))
    created.append(ceil)
    # Long side walls of the corridor with alcoves
    for side, sign in [("east", 1), ("west", -1)]:
        wall_color = color.rgb(120, 130, 145)
        created.append(Entity(model="cube",
                              scale=(0.2, 3, 24),
                              position=(3 * sign, 1.5, 6),
                              color=wall_color,
                              texture=visuals.make_metal_panel(),
                              texture_scale=(12, 1.5),
                              collider="box"))
    # South cap (entry from Act 1, behind player) and north cap (hatch)
    south_cap = Entity(model="cube", scale=(6, 3, 0.2),
                       position=(0, 1.5, -6.1),
                       color=color.rgb(40, 50, 60), collider="box")
    created.append(south_cap)
    north_cap = Entity(model="cube", scale=(6, 3, 0.2),
                       position=(0, 1.5, 18.1),
                       color=color.rgb(40, 50, 60), collider="box")
    created.append(north_cap)

    # ----- Helper: build a cabin alcove (room) attached to one side -----
    def make_cabin_room(center, half_size=(2.5, 1.5, 2.5),
                        wall_color=color.rgb(55, 60, 70)):
        """Build floor/ceiling/walls for a single cabin alcove."""
        sx, sy, sz = half_size
        created.append(Entity(model="plane", scale=(sx * 2, 1, sz * 2),
                              position=(center[0], 0, center[2]),
                              color=color.rgb(60, 60, 65), collider="box"))
        created.append(Entity(model="cube", scale=(sx * 2, 0.2, sz * 2),
                              position=(center[0], sy * 2, center[2]),
                              color=color.rgb(30, 35, 40)))
        # Back wall
        created.append(Entity(model="cube", scale=(sx * 2, sy * 2, 0.2),
                              position=(center[0], sy, center[2] - sz),
                              color=wall_color, collider="box"))
        # Side walls
        for x in (-sx, sx):
            created.append(Entity(model="cube",
                                  scale=(0.2, sy * 2, sz * 2),
                                  position=(center[0] + x, sy, center[2]),
                                  color=wall_color, collider="box"))
        # Front wall with door opening: two segments leaving gap centered
        gap = 1.2
        seg_w = (sx * 2 - gap) / 2
        created.append(Entity(model="cube",
                              scale=(seg_w, sy * 2, 0.2),
                              position=(center[0] - (gap / 2 + seg_w / 2), sy,
                                        center[2] + sz),
                              color=wall_color, collider="box"))
        created.append(Entity(model="cube",
                              scale=(seg_w, sy * 2, 0.2),
                              position=(center[0] + (gap / 2 + seg_w / 2), sy,
                                        center[2] + sz),
                              color=wall_color, collider="box"))

    # ----- Layout - four cabins, alternating sides along z -----
    # Z positions for the cabin doors (along the corridor)
    felix_z = 0.0
    yuna_z = 4.5
    hargrove_z = 9.0
    mara_z = 13.5

    # FELIX cabin alcove (west side, x < 0)
    felix_center = (-5.5, 0, felix_z)
    make_cabin_room(felix_center, half_size=(2.5, 1.5, 2.5),
                    wall_color=color.rgb(55, 55, 65))
    # Door
    felix_door = _make_door("OKAFOR", position=(-3.0, 0, felix_z),
                            rotation_y=90, color_door=color.rgb(70, 80, 95),
                            created=created)
    # Felix's cabin is "open" so we pre-open the door
    felix_door.animate("rotation_y", 90 + 90, duration=0.01)
    felix_door._door_opened = True
    cabins.append(("felix", felix_center, felix_door))

    # FELIX's monitor + Amara drawing + Note 2
    desk = Entity(model="cube", scale=(1.2, 0.7, 0.6),
                  position=(felix_center[0] - 1.4, 0.35,
                            felix_center[2] - 1.5),
                  color=color.rgb(60, 50, 40), collider="box")
    created.append(desk)
    monitor_back = Entity(model="cube", scale=(0.7, 0.45, 0.05),
                          position=(felix_center[0] - 1.4, 1.0,
                                    felix_center[2] - 1.85),
                          color=color.rgb(40, 40, 50), collider="box")
    created.append(monitor_back)
    monitor_screen = Entity(model="quad", scale=(0.6, 0.35),
                            position=(felix_center[0] - 1.4, 1.0,
                                      felix_center[2] - 1.82),
                            color=color.rgba(80, 130, 180, 255))
    created.append(monitor_screen)
    Text(parent=monitor_screen, text="CONNECTING TO EARTH\n....\nNO RESPONSE",
         position=(0, 0, -0.01), origin=(0, 0), scale=3.5,
         color=color.rgb(20, 30, 50), font="VeraMono.ttf")
    # Amara drawing on top of monitor
    draw = Entity(model="quad", scale=(0.4, 0.32),
                  position=(felix_center[0] - 0.7, 1.30,
                            felix_center[2] - 1.83),
                  color=color.rgba(245, 230, 180, 255))
    created.append(draw)
    Entity(parent=draw, model="cube", scale=(0.04, 0.30, 0.01),
           position=(-0.12, 0.0, -0.005), color=color.rgb(40, 70, 200))
    Entity(parent=draw, model="sphere", scale=(0.10, 0.10, 0.01),
           position=(-0.12, 0.20, -0.005), color=color.rgb(40, 70, 200))
    Entity(parent=draw, model="cube", scale=(0.03, 0.18, 0.01),
           position=(0.12, -0.04, -0.005), color=color.rgb(220, 60, 80))
    Entity(parent=draw, model="sphere", scale=(0.07, 0.07, 0.01),
           position=(0.12, 0.10, -0.005), color=color.rgb(220, 60, 80))
    Entity(parent=draw, model="cube", scale=(0.20, 0.02, 0.01),
           position=(0, -0.05, -0.005), color=color.rgb(40, 70, 200))
    make_interactable(draw, "Look at drawing", "examine_only",
                      text=("Amara's drawing.  Two figures, holding hands, "
                            "'space but the pretty part.'  Felix said he "
                            "could see the pretty part every day."))

    # Note 2 (Felix's research journal)
    note2 = Entity(model="quad", scale=(0.35, 0.45),
                   rotation=(90, 0, 0),
                   position=(felix_center[0] - 1.4, 0.72,
                             felix_center[2] - 1.3),
                   color=color.rgba(230, 220, 200, 255), collider="box")
    make_interactable(note2, "Read journal", "collect_note",
                      note_id="note_2")
    created.append(note2)

    # Felix-Shape at the viewport (back wall of his cabin)
    felix_shape_cabin = FelixShape(
        position=(felix_center[0] + 1.0, 0, felix_center[2] - 2.2),
        rotation_y=180, audio=game.audio)
    game.shapes.register(felix_shape_cabin)
    created.append(felix_shape_cabin)
    # Viewport (simulate a window with a dark blue rectangle)
    viewport = Entity(model="quad", scale=(1.6, 1.2),
                      position=(felix_center[0] + 1.0, 1.3,
                                felix_center[2] - 2.49),
                      color=color.rgba(20, 35, 60, 255))
    created.append(viewport)

    # Intercom 2 - in corridor just outside Felix's cabin
    intercom2 = IntercomPanel(position=(-2.8, 1.8, felix_z),
                              rotation=(0, 90, 0))
    created.append(intercom2)
    game.register_ticker(intercom2.update)
    game.olen.add_proximity_trigger(
        intercom_id=2, position=(-2.0, 1.6, felix_z), panel=intercom2,
        radius=3.5)

    # ---- YUNA cabin alcove (east side) ----
    yuna_center = (5.5, 0, yuna_z)
    make_cabin_room(yuna_center, half_size=(2.5, 1.5, 2.5),
                    wall_color=color.rgb(60, 60, 60))
    yuna_door = _make_door("PARK", position=(3.0, 0, yuna_z),
                           rotation_y=-90, color_door=color.rgb(70, 80, 90),
                           created=created)
    cabins.append(("yuna", yuna_center, yuna_door))

    # Note 3 taped to the OUTSIDE of Yuna's door (corridor side)
    note3 = Entity(model="quad", scale=(0.30, 0.40),
                   position=(2.55, 1.55, yuna_z),
                   rotation=(0, 90, 0),
                   color=color.rgba(230, 220, 200, 255),
                   collider="box")
    make_interactable(note3, "Read door note", "collect_note",
                      note_id="note_3")
    created.append(note3)

    # Inside Yuna's cabin - desk + cold tea + (conditional) Shape OR floor arrangement
    yuna_desk = Entity(model="cube", scale=(1.0, 0.7, 0.5),
                      position=(yuna_center[0] + 1.3, 0.35,
                                yuna_center[2] - 1.5),
                      color=color.rgb(70, 60, 50), collider="box")
    created.append(yuna_desk)
    tea_mug = Entity(model="sphere", scale=(0.10, 0.15, 0.10),
                     position=(yuna_center[0] + 1.3, 0.78,
                               yuna_center[2] - 1.5),
                     color=color.rgb(180, 170, 160), collider="box")
    make_interactable(tea_mug, "Touch the mug", "examine_only",
                      text="Still warm.  It isn't.")
    created.append(tea_mug)

    # Both possible states - Shape OR floor arrangement; built on enter()
    yuna_shape_ref = []
    yuna_arrangement_ref = []

    def setup_yuna_state():
        """On entering the cabin, instantiate exactly one state."""
        # Tear down anything we previously built
        for e in yuna_shape_ref + yuna_arrangement_ref:
            try:
                destroy(e)
            except Exception:
                pass
        yuna_shape_ref.clear()
        yuna_arrangement_ref.clear()
        if game.notes.has("note_3"):
            # Note collected first - Shape absent, arrangement on floor
            spot = (yuna_center[0] - 0.5, 0.02, yuna_center[2] - 1.0)
            # Pen
            pen = Entity(model="cube", scale=(0.02, 0.02, 0.18),
                         position=spot, rotation=(0, 30, 0),
                         color=color.rgb(220, 60, 60))
            yuna_arrangement_ref.append(pen)
            created.append(pen)
            # Paperclip (small)
            clip = Entity(model="cube", scale=(0.10, 0.01, 0.04),
                          position=(spot[0] + 0.10, 0.02, spot[2] + 0.10),
                          color=color.rgb(180, 180, 200))
            yuna_arrangement_ref.append(clip)
            created.append(clip)
            # Stylus
            stylus = Entity(model="cube", scale=(0.015, 0.015, 0.20),
                            position=(spot[0] + 0.15, 0.02, spot[2] - 0.05),
                            rotation=(0, -25, 0),
                            color=color.rgb(40, 50, 70))
            yuna_arrangement_ref.append(stylus)
            created.append(stylus)
            # A faint hint - examine prompt on the cluster
            anchor = Entity(model="quad", scale=(0.6, 0.6),
                            rotation=(90, 0, 0),
                            position=(spot[0] + 0.05, 0.015, spot[2]),
                            color=color.rgba(0, 0, 0, 0), collider="box")
            make_interactable(anchor, "Look closer", "examine_only",
                              text=("A pen, a paperclip, and a stylus.  "
                                    "Arranged into two figures holding hands."),
                              duration=4.0)
            yuna_arrangement_ref.append(anchor)
            created.append(anchor)
        else:
            # Note NOT collected - Shape at the window, unreactive
            shape = YunaShape(
                position=(yuna_center[0], 0, yuna_center[2] - 2.0),
                rotation_y=180)
            game.shapes.register(shape)
            yuna_shape_ref.append(shape)
            created.append(shape)

    # We attach a one-shot trigger that initializes when player enters the cabin
    yuna_zone = Entity(model="quad", scale=(3.0, 3.0),
                       rotation=(90, 0, 0),
                       position=(yuna_center[0], 0.01, yuna_center[2]),
                       color=color.rgba(0, 0, 0, 0))
    yuna_zone._setup_done = False
    created.append(yuna_zone)

    def yuna_zone_tick():
        """Initialize the cabin's Shape/arrangement the first time player enters."""
        if yuna_zone._setup_done:
            return
        pp = game.player.position
        if (abs(pp.x - yuna_center[0]) < 2.4 and
                abs(pp.z - yuna_center[2]) < 2.4):
            setup_yuna_state()
            yuna_zone._setup_done = True
    game.register_ticker(yuna_zone_tick)

    # ---- HARGROVE cabin (west side) ----
    hargrove_center = (-5.5, 0, hargrove_z)
    make_cabin_room(hargrove_center, half_size=(2.5, 1.5, 2.5),
                    wall_color=color.rgb(60, 58, 55))
    # Locked - code 4301
    hargrove_door = _make_door(
        "HARGROVE", position=(-3.0, 0, hargrove_z),
        rotation_y=90, color_door=color.rgb(80, 70, 70),
        created=created, locked=True, code="4301")
    cabins.append(("hargrove", hargrove_center, hargrove_door))

    # Inside - desk + Note 4 + framed photo
    h_desk = Entity(model="cube", scale=(1.2, 0.7, 0.6),
                    position=(hargrove_center[0] - 1.3, 0.35,
                              hargrove_center[2] - 1.5),
                    color=color.rgb(55, 50, 45), collider="box")
    created.append(h_desk)
    note4 = Entity(model="quad", scale=(0.35, 0.45),
                   rotation=(90, 0, 0),
                   position=(hargrove_center[0] - 1.3, 0.72,
                             hargrove_center[2] - 1.5),
                   color=color.rgba(225, 215, 195, 255), collider="box")
    make_interactable(note4, "Read handwritten log", "collect_note",
                      note_id="note_4")
    created.append(note4)
    # Framed photo - face down
    photo = Entity(model="cube", scale=(0.25, 0.04, 0.18),
                   position=(hargrove_center[0] + 1.3, 0.72,
                             hargrove_center[2] - 1.5),
                   color=color.rgb(30, 30, 30), collider="box")
    photo._flipped = False

    def flip_photo():
        """Turn the photo over - reveal back-side detail."""
        if photo._flipped:
            return
        photo.animate("rotation_x", 180, duration=0.4)
        photo._flipped = True
        game.show_examine(
            "Two kids squinting into summer sun.  An old photo.")
    make_interactable(photo, "Turn over photo", "trigger_event",
                      callback=flip_photo)
    created.append(photo)

    # ---- MARA cabin (east side, open) ----
    mara_center = (5.5, 0, mara_z)
    make_cabin_room(mara_center, half_size=(2.5, 1.5, 2.5),
                    wall_color=color.rgb(55, 55, 65))
    mara_door = _make_door("VOSS", position=(3.0, 0, mara_z),
                           rotation_y=-90, color_door=color.rgb(70, 75, 90),
                           created=created)
    # Pre-open
    mara_door.animate("rotation_y", -90 - 90, duration=0.01)
    mara_door._door_opened = True
    cabins.append(("mara", mara_center, mara_door))

    # Inside - mug + Eli photo + mirror + Intercom 3 wall panel
    mara_desk = Entity(model="cube", scale=(1.2, 0.7, 0.5),
                      position=(mara_center[0] + 1.3, 0.35,
                                mara_center[2] - 1.5),
                      color=color.rgb(60, 60, 70), collider="box")
    created.append(mara_desk)
    mug = Entity(model="sphere", scale=(0.10, 0.15, 0.10),
                 position=(mara_center[0] + 1.3, 0.78, mara_center[2] - 1.5),
                 color=color.rgb(160, 170, 180), collider="box")
    make_interactable(mug, "Look at mug", "examine_only",
                      text="Your mug.  Empty.  Cold ring of tea at the bottom.")
    created.append(mug)
    # Eli photo (face up)
    eli_photo = Entity(model="cube", scale=(0.18, 0.02, 0.13),
                       position=(mara_center[0] + 0.9, 0.72,
                                 mara_center[2] - 1.5),
                       color=color.rgb(200, 200, 210), collider="box")
    make_interactable(eli_photo, "Look at photo", "examine_only",
                      text=("Your brother.  He had your eyes.  You haven't "
                            "looked at this photo in two months.  You don't "
                            "remember taking it out of the drawer."),
                      duration=5.0)
    created.append(eli_photo)
    # Mirror - 'YOU STARTED IT'
    mirror = Entity(model="cube", scale=(0.7, 0.9, 0.05),
                    position=(mara_center[0] - 1.2, 1.5,
                              mara_center[2] - 2.45),
                    color=color.rgb(150, 170, 200), collider="box")
    created.append(mirror)
    _world_text("YOU STARTED IT", position=(mara_center[0] - 1.2, 1.55,
                                            mara_center[2] - 2.42),
                rotation=(0, 0, 0), scale=2.0,
                col=color.rgb(220, 80, 90), created=created)
    make_interactable(mirror, "Look in mirror", "examine_only",
                      text="The mirror is just a mirror.",
                      duration=3.0)

    # Intercom 3 - manual interact - inside Mara's cabin
    intercom3 = IntercomPanel(position=(mara_center[0] + 1.4, 1.7,
                                        mara_center[2] - 2.45),
                              rotation=(0, 0, 0))
    created.append(intercom3)
    game.register_ticker(intercom3.update)
    make_interactable(intercom3, "Press intercom", "trigger_event",
                      callback=lambda: game.olen.trigger_manual(3, intercom3))

    # ---- North end: Felix-Shape + maintenance hatch with keypad code 7741 ----
    # Keypad on wall beside hatch
    hatch_pivot = Entity(position=(0.5, 0, 17.9))
    hatch_door = Entity(parent=hatch_pivot, model="cube",
                        scale=(1.2, 2.4, 0.18),
                        position=(-0.6, 1.2, 0),
                        color=color.rgb(80, 70, 60), collider="box")
    created.append(hatch_pivot)

    hatch_keypad = Entity(model="cube", scale=(0.22, 0.30, 0.06),
                          position=(1.5, 1.4, 17.7),
                          color=color.rgb(70, 70, 80), collider="box")
    created.append(hatch_keypad)

    def open_hatch():
        """Open the hatch door + Felix-Shape steps aside."""
        hatch_pivot.animate("rotation_y", 90, duration=0.5)
        game.audio.door()
        game.state.hatch_open = True
        # Felix-Shape steps quietly aside (move left along x)
        hatch_felix.animate("position",
                hatch_felix.position + Vec3(-1.6, 0, 0),
                duration=1.4)
    make_interactable(hatch_keypad, "Enter code", "keypad",
                      code="7741", on_unlock=open_hatch)
    game.state.hatch_open = False

    # Code 7741 scratched on wall beside the keypad - only readable with flashlight
    # We represent this by very low-contrast text that is visible regardless
    # (Ursina has no per-pixel light gating without shaders; we lean on color)
    _world_text("7741", position=(2.2, 1.7, 17.9),
                rotation=(0, 180, 0), scale=1.0,
                col=color.rgba(180, 170, 160, 90), created=created)

    # Felix-Shape next to keypad facing wall
    hatch_felix = FelixShape(position=(1.6, 0, 17.5),
                             rotation_y=180, audio=game.audio)
    game.shapes.register(hatch_felix)
    created.append(hatch_felix)

    # ---- Ceiling lighting panels ----
    # Steady panels every ~4 units, with two "dark sections" near z=2 and z=11
    for z in [-4, -1, 2, 5, 8, 11, 14, 17]:
        steady = z not in (2, 11)
        p = _FlickerPanel(position=(0, 2.9, z), steady=steady)
        created.append(p)
        game.register_ticker(p.update)

    # Player spawns just inside corridor from Act 1 (z=-5)
    game.player.position = Vec3(0, 1.6, -5.5)
    game.player.fpc.rotation_y = 0

    # Transition trigger - past the hatch (z > 18.0)
    def check_transition():
        """Trigger act transition when player crosses the hatch."""
        if game.state.hatch_open and game.player.position.z > 18.2:
            game.transition_to("act3")
    game.register_ticker(check_transition)

    return created
