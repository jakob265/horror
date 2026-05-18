"""
scenes/act9_approach.py
-----------------------
ACT 9 - APPROACH CORRIDOR.

A long, dark corridor leading to the array room.  The station hum is
loudest here.  A small message scratched into a wall panel (Note 13) -
Mara's handwriting, even though she has no memory of writing it.

Hargrove-Shape stands at the far end facing away.  As the player gets
close, it walks slowly into the dark and disappears.

Revamped (Phase 2):  the corridor is longer (32 units) and slightly
wider (5).  Two recessed alcoves break the run - one holds a sealed
maintenance hatch, the other a dead emergency phone.  Pipe bundles
and conduit run along the walls.  A pressure bulkhead halfway down
sits partially open, like something walked through and didn't bother
to close it.
"""

import math
import random

from ursina import Entity, Text, Vec3, color, distance, time

from scenes._chamber import (
    DOOR_H, DOOR_W, build_floor_ceiling, build_wall, make_door,
)
from systems.entity import HargroveShape
from systems.interaction import make_interactable
from systems import visuals


class _SlowFlicker(Entity):
    """A ceiling fixture that flickers very slowly and quietly."""

    def __init__(self, position, base_rgba=(180, 200, 220, 180)):
        super().__init__(model="cube",
                         scale=(0.6, 0.04, 0.20),
                         position=position,
                         color=color.rgba(*base_rgba))
        self.base = base_rgba
        self._timer = random.uniform(3.0, 11.0)
        self._dim = False

    def update(self):
        self._timer -= time.dt
        if self._timer <= 0:
            if not self._dim:
                self._dim = True
                self.color = color.rgba(40, 50, 60, 80)
                self._timer = random.uniform(0.05, 0.20)
            else:
                self._dim = False
                self.color = color.rgba(*self.base)
                self._timer = random.uniform(4.0, 14.0)


def build(game):
    """Long dark approach corridor with alcoves and a half-open bulkhead."""
    created = []

    w, d, h = 5.0, 32, 3.2
    build_floor_ceiling(created, w, d, h,
                        floor_color=(40, 45, 55),
                        ceiling_color=(20, 25, 30),
                        floor_tex="concrete",
                        center=(0, 0, 0))

    for fx in (-w/2, w/2):
        build_wall(created, "x", fx, -d/2, d/2, h,
                   wall_color=(50, 55, 70))
    build_wall(created, "z", -d/2, -w/2, w/2, h,
               gap_center=0, wall_color=(50, 55, 70))
    build_wall(created, "z", d/2, -w/2, w/2, h,
               gap_center=0, wall_color=(50, 55, 70))

    # Doors - entry from bridge, exit to array
    make_door(created, "z", -d/2 + 0.05, 0, "MAINTENANCE",
              side=+1, color_rgb=(72, 70, 60), sealed=True)
    def open_exit():
        game.state.approach_door_open = True
    game.state.approach_door_open = False
    make_door(created, "z", d/2 - 0.05, 0, "ARRAY",
              side=-1, color_rgb=(110, 80, 60),
              callback=open_exit,
              interactable_label="Open ARRAY")

    # --- Pipe bundles along the walls ---
    for fx in (-w/2 + 0.20, w/2 - 0.20):
        for py, prgb in [(0.40, (140, 110, 60)),
                         (1.10, (60, 80, 110))]:
            Entity(model="cube",
                   scale=(0.14, 0.14, d - 2),
                   position=(fx, py, 0),
                   color=color.rgb(*prgb))
        # Bracket clamps every couple meters
        for cz in range(-13, 14, 3):
            Entity(model="cube",
                   scale=(0.20, 0.20, 0.10),
                   position=(fx, 0.75, cz),
                   color=color.rgb(60, 60, 70))

    # --- Periodic faint floor lights along the corridor ---
    for tz in range(-14, 15, 3):
        Entity(model="quad",
               scale=(2.0, 0.30),
               rotation=(90, 0, 0),
               position=(0, 0.02, tz),
               color=color.rgba(150, 170, 200, 80))

    # --- Slow-flickering ceiling lights ---
    for tz in range(-13, 14, 4):
        fl = _SlowFlicker(position=(0, h - 0.10, tz))
        created.append(fl)
        game.register_ticker(fl.update)

    # --- Half-open pressure bulkhead at the midpoint (z = -2) ---
    # Bulkhead frame - two side jambs and a header
    bulk_z = -2.0
    for jx in (-w/2 + 0.30, w/2 - 0.30):
        Entity(model="cube",
               scale=(0.40, h, 0.40),
               position=(jx, h/2, bulk_z),
               color=color.rgb(80, 70, 50),
               texture=visuals.make_metal_panel(),
               texture_scale=(0.4, 1.5),
               collider="box")
    # Header
    Entity(model="cube",
           scale=(w - 0.6, 0.40, 0.40),
           position=(0, h - 0.20, bulk_z),
           color=color.rgb(80, 70, 50),
           collider="box")
    # The bulkhead door panel itself, half-open (slid partially up)
    bulk_door = Entity(model="cube",
                       scale=(w - 0.8, 2.0, 0.10),
                       position=(0, 2.0, bulk_z),
                       color=color.rgb(110, 90, 60),
                       texture=visuals.make_metal_panel(),
                       texture_scale=((w - 0.8) / 2, 1.0),
                       collider="box")
    created.append(bulk_door)
    # Yellow hazard stripes on the door
    for sy in (0.6, -0.6):
        Entity(parent=bulk_door, model="cube",
               scale=(w - 1.2, 0.10, 0.20),
               position=(0, sy, -0.06),
               color=color.rgb(220, 180, 30))
    # "ARRAY ACCESS" label on the bulkhead
    Text(parent=Entity(position=(0, h - 0.20, bulk_z - 0.25)),
         text="ARRAY ACCESS",
         origin=(0, 0), scale=5,
         color=color.rgb(220, 200, 160), font="VeraMono.ttf")

    # --- West alcove: sealed maintenance hatch (z = -8) ---
    # Cut a recess into the west wall by adding a small inner box that
    # creates a 1.2-deep alcove visually.
    alc_z_west = -8.0
    alc_back = Entity(model="cube",
                      scale=(0.10, 2.2, 1.6),
                      position=(-w/2 - 0.55, 1.1, alc_z_west),
                      color=color.rgb(55, 60, 75),
                      texture=visuals.make_metal_panel(),
                      texture_scale=(0.8, 1.1),
                      collider="box")
    created.append(alc_back)
    # Sealed circular hatch (a disc)
    hatch = Entity(model="cube",
                   scale=(0.20, 1.0, 1.0),
                   position=(-w/2 - 0.30, 1.10, alc_z_west),
                   color=color.rgb(80, 70, 50),
                   collider="box")
    created.append(hatch)
    # Hatch wheel
    Entity(parent=hatch, model="sphere",
           scale=(0.30, 0.10, 0.50),
           position=(0.30, 0, 0),
           color=color.rgb(140, 130, 100))
    # Status light (red - sealed)
    Entity(parent=hatch, model="cube",
           scale=(0.04, 0.10, 0.10),
           position=(0.40, 0.35, 0.30),
           color=color.rgba(220, 60, 60, 255))
    make_interactable(hatch, "Try the maintenance hatch", "examine_only",
                      text=("A sealed maintenance hatch.  Status light "
                            "is red.  The wheel won't turn.  In the "
                            "frost on the porthole someone has written, "
                            "in the same lowercase hand as everything "
                            "else now:  'do not open until it is done.'"),
                      duration=6.0)

    # --- East alcove: dead emergency phone (z = 6) ---
    alc_z_east = 6.0
    alc_back_e = Entity(model="cube",
                       scale=(0.10, 2.2, 1.6),
                       position=(w/2 + 0.55, 1.1, alc_z_east),
                       color=color.rgb(55, 60, 75),
                       texture=visuals.make_metal_panel(),
                       texture_scale=(0.8, 1.1),
                       collider="box")
    created.append(alc_back_e)
    # Phone box
    phone_box = Entity(model="cube",
                       scale=(0.40, 0.70, 0.40),
                       position=(w/2 - 0.10, 1.30, alc_z_east),
                       color=color.rgb(220, 60, 50),
                       collider="box")
    created.append(phone_box)
    # Handset
    Entity(parent=phone_box, model="cube",
           scale=(0.10, 0.10, 0.40),
           position=(-0.30, -0.10, 0.0),
           color=color.rgb(30, 30, 35))
    # Coiled cable down to the floor
    Entity(parent=phone_box, model="cube",
           scale=(0.06, 1.20, 0.06),
           position=(-0.30, -0.85, 0.10),
           color=color.rgb(30, 30, 35))
    # Receiver dangling
    Entity(model="cube",
           scale=(0.10, 0.10, 0.30),
           position=(w/2 - 0.40, 0.10, alc_z_east),
           color=color.rgb(30, 30, 35))
    make_interactable(phone_box, "Pick up the emergency phone", "examine_only",
                      text=("Bright red emergency phone.  Receiver is "
                            "off the hook, lying on the alcove floor.  "
                            "You hold it to your ear.  There is no dial "
                            "tone.  There is breathing, very slow.  "
                            "You realise after a long moment that it "
                            "is your own breathing, and that the phone "
                            "isn't connected to anything."),
                      duration=8.0)

    # --- Note 13 - scratched into a wall panel partway down ---
    note13 = Entity(model="cube", scale=(0.08, 0.4, 0.6),
                    position=(-w/2 + 0.10, 1.3, 3.5),
                    color=color.rgb(45, 50, 65),
                    collider="box")
    Entity(parent=note13, model="quad",
           scale=(0.85, 0.85),
           position=(0.55, 0, 0),
           rotation=(0, 90, 0),
           color=color.rgba(60, 70, 90, 255))
    make_interactable(note13, "Read scratched panel", "collect_note",
                      note_id="note_13")
    created.append(note13)

    # --- A discarded boot in the middle of the corridor ---
    boot = Entity(model="cube",
                  scale=(0.20, 0.18, 0.40),
                  position=(0.8, 0.09, -5),
                  rotation=(0, 25, 0),
                  color=color.rgb(40, 35, 30),
                  collider="box")
    created.append(boot)
    make_interactable(boot, "Look at the boot", "examine_only",
                      text=("A single station-issue boot in the middle "
                            "of the corridor.  Size says HARGROVE.  Why "
                            "would he have only worn one?"),
                      duration=5.0)

    # --- A long smear on the floor leading toward the array ---
    for sz in range(-2, 14, 2):
        Entity(model="quad",
               scale=(0.40, 0.80),
               rotation=(90, 0, 0),
               position=(-0.5 + (sz % 3) * 0.2, 0.02, sz),
               color=color.rgba(40, 30, 30, 160))

    # --- Wall stains near the array end (something dragged through) ---
    for sz, sy in [(10, 1.0), (11.5, 0.7), (12.8, 1.4)]:
        Entity(model="quad",
               scale=(0.40, 0.70),
               rotation=(0, 90, 0),
               position=(-w/2 + 0.11, sy, sz),
               color=color.rgba(30, 25, 30, 180))

    # --- Hargrove-Shape at the far end - facing AWAY from the player ---
    hg = HargroveShape(position=(0, 0, d/2 - 3.0),
                       rotation_y=0, audio=game.audio)
    game.shapes.register(hg)
    created.append(hg)

    # Make Hargrove slowly retreat when the player gets close
    state = {"retreating": False, "t": 0.0}

    def hargrove_retreat():
        if not state["retreating"]:
            if distance(game.player.position, hg.position) < 8.0:
                state["retreating"] = True
        else:
            state["t"] += time.dt
            # Move toward the array door, then fade
            hg.z += time.dt * 0.5
            if state["t"] > 8.0:
                hg.enabled = False
    game.register_ticker(hargrove_retreat)

    # Player spawn
    game.player.position = Vec3(0, 1.6, -d/2 + 0.8)
    game.player.fpc.rotation_y = 0

    def check_transition():
        if game.state.approach_door_open and \
                game.player.position.z > d/2 + 0.1:
            game.transition_to("act10")
    game.register_ticker(check_transition)

    return created
