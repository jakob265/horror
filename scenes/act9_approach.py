"""
scenes/act9_approach.py
-----------------------
ACT 9 - APPROACH CORRIDOR (NEW).

A long, dark corridor leading to the array room.  The station hum is
loudest here.  A small message scratched into a wall panel (Note 13) -
Mara's handwriting, even though she has no memory of writing it.

Hargrove-Shape stands at the far end facing away.  As the player gets
close, it walks slowly into the dark and disappears.
"""

import math

from ursina import Entity, Text, Vec3, color, distance, time

from scenes._chamber import (
    DOOR_H, DOOR_W, build_floor_ceiling, build_wall, make_door,
)
from systems.entity import HargroveShape
from systems.interaction import make_interactable
from systems import visuals


def build(game):
    """Long dark approach corridor."""
    created = []

    w, d, h = 3.5, 22, 3.0
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
    make_door(created, "z", -d/2 + 0.05, 0, "BRIDGE",
              side=+1, color_rgb=(72, 70, 60), sealed=True)
    def open_exit():
        game.state.approach_door_open = True
    game.state.approach_door_open = False
    make_door(created, "z", d/2 - 0.05, 0, "ARRAY",
              side=-1, color_rgb=(110, 80, 60),
              callback=open_exit,
              interactable_label="Open ARRAY")

    # Note 13 - scratched into a wall panel partway down
    # We represent it as a small wall plaque the player can interact with
    note13 = Entity(model="cube", scale=(0.08, 0.4, 0.6),
                    position=(-w/2 + 0.10, 1.3, 2.0),
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

    # Periodic faint floor lights along the corridor
    for tz in range(-9, 10, 3):
        Entity(parent=Entity(parent=game.world_root), model="quad",
               scale=(1.8, 0.3),
               rotation=(90, 0, 0),
               position=(0, 0.02, tz),
               color=color.rgba(150, 170, 200, 80))

    # Hargrove-Shape at the far end - facing AWAY from the player so just
    # a silhouette walking ahead.
    hg = HargroveShape(position=(0, 0, d/2 - 2.8),
                       rotation_y=0, audio=game.audio)
    game.shapes.register(hg)
    created.append(hg)

    # Make Hargrove slowly retreat when the player gets close
    state = {"retreating": False, "t": 0.0}

    def hargrove_retreat():
        if not state["retreating"]:
            if distance(game.player.position, hg.position) < 6.0:
                state["retreating"] = True
        else:
            state["t"] += time.dt
            # Move toward the array door, then fade
            hg.z += time.dt * 0.6
            if state["t"] > 6.0:
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
