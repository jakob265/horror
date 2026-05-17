"""
scenes/act7_engineering.py
--------------------------
ACT 7 - ENGINEERING / POWER CORE (NEW).

The reactor housing.  A maintenance recorder near the calibration panel
contains Hargrove's verbatim 'I did this' confession (Note 11).  The
power core hums - the same hum Mara has been hearing under everything.
"""

import math

from ursina import Entity, Text, Vec3, color, time
from ursina.models.procedural.cylinder import Cylinder

from scenes._chamber import (
    DOOR_H, DOOR_W, build_floor_ceiling, build_wall, make_door,
)
from systems.interaction import make_interactable
from systems import visuals


class _PulsingCore(Entity):
    """Slowly-breathing reactor core sphere."""

    def __init__(self, position):
        super().__init__(model="sphere", scale=1.8,
                         position=position,
                         color=color.rgba(120, 160, 200, 255))
        self._t = 0.0

    def update(self):
        self._t += time.dt
        v = 0.5 + 0.5 * math.sin(self._t * 0.7)
        b = int(140 + 80 * v)
        self.color = color.rgba(110, 160, b, 255)


def build(game):
    """Engineering chamber with central reactor core."""
    created = []

    w, d, h = 10, 12, 4.0
    build_floor_ceiling(created, w, d, h,
                        floor_color=(70, 75, 80),
                        ceiling_color=(35, 40, 45),
                        floor_tex="concrete",
                        center=(0, 0, 0))

    for fx in (-w/2, w/2):
        build_wall(created, "x", fx, -d/2, d/2, h,
                   wall_color=(70, 80, 95))
    build_wall(created, "z", -d/2, -w/2, w/2, h,
               gap_center=0, wall_color=(70, 80, 95))
    build_wall(created, "z", d/2, -w/2, w/2, h,
               gap_center=0, wall_color=(70, 80, 95))

    # Doors
    make_door(created, "z", -d/2 + 0.05, 0, "HYDRO",
              side=+1, color_rgb=(72, 70, 60), sealed=True)
    def open_exit():
        game.state.engineering_door_open = True
    game.state.engineering_door_open = False
    make_door(created, "z", d/2 - 0.05, 0, "BRIDGE",
              side=-1, color_rgb=(72, 70, 60),
              callback=open_exit,
              interactable_label="Open BRIDGE")

    # Central reactor housing (large cylinder)
    housing = Entity(
        model=Cylinder(resolution=24, radius=0.5, height=1.0),
        scale=(2.6, h - 0.4, 2.6),
        position=(0, (h - 0.4) / 2, 0),
        color=color.rgb(60, 65, 75),
        texture=visuals.make_metal_panel(),
        texture_scale=(2.0, 2.0),
        collider="box")
    created.append(housing)
    # Pulsing core inside (visible through gaps in the housing - just a
    # colored sphere above the housing)
    core = _PulsingCore(position=(0, h - 1.0, 0))
    created.append(core)
    game.register_ticker(core.update)

    # Calibration maintenance panel on the west wall
    panel = Entity(model="cube", scale=(1.2, 0.9, 0.10),
                   position=(-w/2 + 0.10, 1.5, -3.0),
                   color=color.rgb(60, 70, 80),
                   collider="box")
    created.append(panel)
    screen = Entity(parent=panel, model="quad",
                    scale=(1.0, 0.7),
                    position=(0, 0, -0.55),
                    color=color.rgba(15, 30, 50, 255))
    Text(parent=screen,
         text="CALIBRATION 442-K\n\nARRAY  =  0.7 P-UNITS\nSTATUS =  ACTIVE\n\n*** READ TAPE ***",
         position=(0, 0, -0.01), origin=(0, 0), scale=3,
         color=color.rgb(200, 230, 250), font="VeraMono.ttf")

    # Maintenance tape (Note 11) on a shelf below the panel
    tape = Entity(model="cube", scale=(0.20, 0.10, 0.14),
                  position=(-w/2 + 0.55, 0.85, -3.0),
                  color=color.rgba(40, 40, 45, 255),
                  collider="box")
    make_interactable(tape, "Play tape", "collect_note",
                      note_id="note_11")
    created.append(tape)

    # Hargrove's lonely chair beside the panel
    chair = Entity(model="cube", scale=(0.5, 0.4, 0.5),
                   position=(-w/2 + 1.5, 0.20, -2.6),
                   color=color.rgb(40, 45, 55),
                   collider="box")
    created.append(chair)

    # The "plant in the corner with leaves all turned one direction"
    # from Hargrove's tape recording
    corner_pot = Entity(model="cube", scale=(0.3, 0.3, 0.3),
                        position=(w/2 - 0.8, 0.15, d/2 - 0.8),
                        color=color.rgb(120, 100, 80),
                        collider="box")
    created.append(corner_pot)
    stalk = Entity(parent=corner_pot, model="cube",
                   scale=(0.08, 2.0, 0.08),
                   position=(0, 1.0, 0),
                   color=color.rgb(70, 100, 65),
                   rotation=(0, 0, 15))  # leaning toward the array (east)
    Entity(parent=stalk, model="sphere",
           scale=(2.2, 1.0, 1.6),
           position=(0, 0.5, 0.5),
           color=color.rgb(80, 130, 80))
    make_interactable(corner_pot, "Look at the plant", "examine_only",
                      text=("Every leaf points east.  Toward the array.  "
                            "Even the ones in shadow."),
                      duration=4.0)

    # Player spawn
    game.player.position = Vec3(0, 1.6, -d/2 + 0.8)
    game.player.fpc.rotation_y = 0

    def check_transition():
        if game.state.engineering_door_open and \
                game.player.position.z > d/2 + 0.1:
            game.transition_to("act_storage")
    game.register_ticker(check_transition)

    return created
