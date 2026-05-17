"""
scenes/act2_decon.py
--------------------
ACT 2 - DECON ANTECHAMBER (NEW).

A small pressure-equalization room between the cryo bay and the residential
corridor.  Mara passes through here on her way out.  A medical scanner
flags her neural anomaly (Note 8 - the decon log).  She remembers Felix's
morning-shift joke but can't recall it.

This room sits between Act 1 (cryo bay) and what was Act 2 (corridor).
"""

from ursina import Entity, Text, Vec3, color

from scenes._chamber import (
    DOOR_H, DOOR_W, build_floor_ceiling, build_wall, make_door,
)
from systems.interaction import make_interactable
from systems.olen import IntercomPanel
from systems import visuals


def build(game):
    """Build the decon antechamber. Player enters from -z, exits to +z."""
    created = []

    # Room dimensions: a tight 4x8 corridor-room
    w, d, h = 4, 8, 3.0
    build_floor_ceiling(created, w, d, h,
                        floor_color=(95, 95, 105),
                        ceiling_color=(40, 45, 55),
                        floor_tex="concrete",
                        center=(0, 0, 0))

    # Walls
    build_wall(created, "x", -w/2, -d/2, d/2, h,
               wall_color=(75, 80, 95))
    build_wall(created, "x", w/2, -d/2, d/2, h,
               wall_color=(75, 80, 95))
    # South wall - entry from cryo bay (sealed)
    build_wall(created, "z", -d/2, -w/2, w/2, h,
               gap_center=0, wall_color=(75, 80, 95))
    # North wall - exit to corridor (interactive door)
    build_wall(created, "z", d/2, -w/2, w/2, h,
               gap_center=0, wall_color=(75, 80, 95))

    # Entry door (sealed - cryo bay side)
    make_door(created, "z", -d/2 + 0.05, 0, "CRYO",
              side=+1, color_rgb=(72, 70, 60), sealed=True)
    # Exit door (interactive)
    def open_exit():
        game.state.decon_door_open = True
    game.state.decon_door_open = False
    make_door(created, "z", d/2 - 0.05, 0, "CORRIDOR",
              side=-1, color_rgb=(72, 70, 60),
              callback=open_exit,
              interactable_label="Open CORRIDOR")

    # ---- Scanner pillar in the middle ----
    scanner = Entity(model="cube",
                     scale=(0.8, 1.6, 0.5),
                     position=(-1.0, 0.8, 0),
                     color=color.rgb(60, 65, 75),
                     texture=visuals.make_metal_panel(),
                     texture_scale=(0.5, 0.8),
                     collider="box")
    created.append(scanner)
    # Screen
    screen = Entity(parent=scanner, model="quad",
                    scale=(0.7, 0.45),
                    position=(0, 0.2, -0.51),
                    color=color.rgba(50, 110, 150, 255))
    Text(parent=screen,
         text="SCAN:\nANOMALY",
         position=(0, 0, -0.01), origin=(0, 0), scale=4,
         color=color.rgb(220, 240, 255), font="VeraMono.ttf")
    # Make the scanner readable as Note 8
    note8 = Entity(parent=scanner, model="cube",
                   scale=(0.4, 0.1, 0.4),
                   position=(0, -0.85, -0.3),
                   color=color.rgba(230, 220, 200, 255),
                   collider="box")
    make_interactable(note8, "Read decon log", "collect_note",
                      note_id="note_8")

    # Discarded medical glove with name tag
    glove = Entity(model="cube",
                   scale=(0.18, 0.04, 0.10),
                   position=(1.2, 0.04, -2.0),
                   color=color.rgb(120, 110, 105),
                   collider="box")
    make_interactable(glove, "Pick up the glove", "examine_only",
                      text=("Medical glove.  The name tag reads VOSS, "
                            "M. in your own handwriting.  You don't "
                            "remember taking it off."),
                      duration=5.0)
    created.append(glove)

    # Crew photo on the wall
    photo = Entity(model="cube",
                   scale=(0.6, 0.4, 0.04),
                   position=(w/2 - 0.13, 1.7, 1.5),
                   rotation=(0, -90, 0),
                   color=color.rgb(220, 215, 195),
                   collider="box")
    Entity(parent=photo, model="cube",
           scale=(0.92, 0.88, 0.10),
           position=(0, 0, -0.55),
           color=color.rgb(60, 80, 110))
    make_interactable(photo, "Crew photo", "examine_only",
                      text=("Pre-flight crew photo.  Five people in "
                            "uniform, all smiling.  You stand on the "
                            "left.  Felix has his arm around your "
                            "shoulder.  Yuna is laughing at something "
                            "Hargrove just said.  You remember the day "
                            "it was taken.  Felix told a joke at the "
                            "scanner that morning.  You can't remember "
                            "the joke."),
                      duration=8.0)
    created.append(photo)

    # Single dim overhead light strip (visual)
    created.append(Entity(model="cube",
                          scale=(1.2, 0.06, 0.4),
                          position=(0, 2.85, 0),
                          color=color.rgba(190, 210, 230, 255)))

    # Player spawn near the south door, facing +z
    game.player.position = Vec3(0, 1.6, -d/2 + 0.8)
    game.player.fpc.rotation_y = 0

    # Transition - cross the north door threshold
    def check_transition():
        if game.state.decon_door_open and game.player.position.z > d/2 + 0.1:
            game.transition_to("act3")  # corridor
    game.register_ticker(check_transition)

    return created
