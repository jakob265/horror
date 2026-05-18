"""
scenes/act2_decon.py
--------------------
ACT 2 - DECON ANTECHAMBER.

A pressure-equalization room between the cryo bay and the medical bay.
Mara passes through here on her way out.  A medical scanner flags her
neural anomaly (Note 8 - the decon log).  She remembers Felix's
morning-shift joke but can't recall it.

Revamped (Phase 2):  the antechamber is no longer a corridor-room.
It's now a proper decon bay - 9x12 with overhead spray nozzles, a
biohazard waste chute, a UV-decon arch, lockers for hazard suits,
a sealed window into a quarantine cell, and a wall of monitors
showing the scanner output.
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

    w, d, h = 9, 12, 3.4
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
    build_wall(created, "z", -d/2, -w/2, w/2, h,
               gap_center=0, wall_color=(75, 80, 95))
    build_wall(created, "z", d/2, -w/2, w/2, h,
               gap_center=0, wall_color=(75, 80, 95))

    # Doors
    make_door(created, "z", -d/2 + 0.05, 0, "CRYO",
              side=+1, color_rgb=(72, 70, 60), sealed=True)
    def open_exit():
        game.state.decon_door_open = True
    game.state.decon_door_open = False
    make_door(created, "z", d/2 - 0.05, 0, "MEDICAL",
              side=-1, color_rgb=(72, 70, 60),
              callback=open_exit,
              interactable_label="Open MEDICAL")

    # --- UV decon arch the player walks through ---
    # Two columns + a top header forming an archway
    for ax in (-1.5, 1.5):
        col = Entity(model="cube",
                     scale=(0.30, 2.6, 0.30),
                     position=(ax, 1.30, -2.5),
                     color=color.rgb(140, 145, 155),
                     texture=visuals.make_metal_panel(),
                     texture_scale=(0.4, 1.6),
                     collider="box")
        created.append(col)
        # UV strip
        Entity(parent=col, model="cube",
               scale=(0.10, 2.20, 0.10),
               position=(0.18, 0, 0.18),
               color=color.rgba(180, 140, 240, 220))
    # Header above the arch
    Entity(model="cube",
           scale=(3.0, 0.40, 0.30),
           position=(0, 2.50, -2.5),
           color=color.rgb(140, 145, 155),
           collider="box")
    Text(parent=Entity(position=(0, 2.50, -2.65),
                       rotation=(0, 0, 0)),
         text="UV DECON",
         origin=(0, 0), scale=6,
         color=color.rgb(20, 25, 35), font="VeraMono.ttf")

    # --- Overhead spray nozzles (ceiling) ---
    for tx in (-2, 0, 2):
        for tz in (-1.0, 0.5, 2.0):
            Entity(model="cube",
                   scale=(0.18, 0.18, 0.18),
                   position=(tx, h - 0.15, tz),
                   color=color.rgb(120, 130, 140))
            Entity(model="cube",
                   scale=(0.08, 0.20, 0.08),
                   position=(tx, h - 0.32, tz),
                   color=color.rgb(160, 170, 180))

    # --- Scanner pillar on the west side of the room ---
    scanner = Entity(model="cube",
                     scale=(0.9, 1.8, 0.55),
                     position=(-w/2 + 0.6, 0.90, 0),
                     color=color.rgb(60, 65, 75),
                     texture=visuals.make_metal_panel(),
                     texture_scale=(0.5, 0.9),
                     collider="box")
    created.append(scanner)
    # Screen
    screen = Entity(parent=scanner, model="quad",
                    scale=(0.75, 0.50),
                    position=(0, 0.30, -0.30),
                    color=color.rgba(50, 110, 150, 255))
    Text(parent=screen,
         text="SCAN:\nANOMALY",
         position=(0, 0, -0.01), origin=(0, 0), scale=4,
         color=color.rgb(220, 240, 255), font="VeraMono.ttf")
    # Note 8 reader (small slot below the screen)
    note8 = Entity(parent=scanner, model="cube",
                   scale=(0.50, 0.10, 0.40),
                   position=(0, -0.30, -0.10),
                   color=color.rgba(230, 220, 200, 255),
                   collider="box")
    make_interactable(note8, "Read decon log", "collect_note",
                      note_id="note_8")

    # --- Hazard suit lockers along the east wall ---
    for i, lz in enumerate((-3.5, -1.5, 0.5, 2.5, 4.5)):
        lock = Entity(model="cube",
                      scale=(0.45, 2.4, 1.2),
                      position=(w/2 - 0.30, 1.20, lz),
                      color=color.rgb(150, 155, 165),
                      texture=visuals.make_metal_panel(),
                      texture_scale=(0.4, 1.2),
                      collider="box")
        created.append(lock)
        # Door handle
        Entity(parent=lock, model="cube",
               scale=(0.16, 0.08, 0.10),
               position=(-0.50, 0.05, 0),
               color=color.rgb(40, 45, 55))
        # Suit-name plate
        Entity(parent=lock, model="cube",
               scale=(0.08, 0.16, 0.5),
               position=(-0.45, 0.90, 0),
               color=color.rgb(220, 200, 160))
        # Open one (Mara's)
        if i == 2:
            # Slightly ajar - rotate the locker door
            Entity(parent=lock, model="cube",
                   scale=(0.10, 2.20, 1.00),
                   position=(-0.55, 0, 0.20),
                   rotation=(0, -20, 0),
                   color=color.rgb(150, 155, 165))
            # Empty hook inside
            Entity(parent=lock, model="cube",
                   scale=(0.10, 0.04, 0.30),
                   position=(0.15, 0.6, 0),
                   color=color.rgb(180, 185, 195))

    # --- Quarantine cell window on the south-east corner ---
    # A 1.0x1.8 quad set into the south wall (visible from the entry)
    # Frame
    qframe = Entity(model="cube",
                    scale=(1.6, 1.8, 0.10),
                    position=(2.5, 1.20, -d/2 + 0.10),
                    color=color.rgb(80, 85, 100),
                    collider="box")
    created.append(qframe)
    # The "glass" pane
    Entity(parent=qframe, model="cube",
           scale=(1.2, 1.4, 0.06),
           position=(0, 0, -0.08),
           color=color.rgba(80, 130, 160, 220))
    # Inside the quarantine cell, the suggestion of a cot + a slumped
    # silhouette - just a dark sphere parked behind the glass
    Entity(parent=qframe, model="sphere",
           scale=(0.40, 0.30, 0.20),
           position=(-0.20, -0.20, -0.30),
           color=color.rgba(40, 50, 60, 220))
    make_interactable(qframe, "Look into the cell", "examine_only",
                      text=("Through the inset window you can see a "
                            "small quarantine bunk.  There is the "
                            "suggestion of something on it - cloth, "
                            "or a person, or a person-shaped pile of "
                            "cloth.  The interior speaker is on.  "
                            "Whatever is in there is humming, very "
                            "quietly, at 0.7 Planck units."),
                      duration=8.0)

    # --- Discarded medical glove with name tag ---
    glove = Entity(model="cube",
                   scale=(0.18, 0.04, 0.10),
                   position=(1.6, 0.04, -3.0),
                   color=color.rgb(120, 110, 105),
                   collider="box")
    make_interactable(glove, "Pick up the glove", "examine_only",
                      text=("Medical glove.  The name tag reads VOSS, "
                            "M. in your own handwriting.  You don't "
                            "remember taking it off."),
                      duration=5.0)
    created.append(glove)

    # --- Crew photo on the west wall (above the scanner) ---
    photo = Entity(model="cube",
                   scale=(0.06, 0.5, 0.7),
                   position=(-w/2 + 0.13, 2.40, 0),
                   color=color.rgb(220, 215, 195),
                   collider="box")
    Entity(parent=photo, model="cube",
           scale=(0.10, 0.44, 0.62),
           position=(0.55, 0, 0),
           rotation=(0, 90, 0),
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

    # --- Biohazard waste chute, south-west corner ---
    chute = Entity(model="cube",
                   scale=(0.8, 1.4, 0.8),
                   position=(-w/2 + 0.7, 0.70, -d/2 + 1.5),
                   color=color.rgb(180, 140, 40),
                   collider="box")
    created.append(chute)
    Entity(parent=chute, model="cube",
           scale=(0.70, 0.30, 0.70),
           position=(0, 0.40, 0),
           color=color.rgb(30, 30, 40))
    Text(parent=chute, text="BIOHAZARD",
         position=(0, 0, -0.55), origin=(0, 0), scale=3.5,
         color=color.rgb(20, 20, 25), font="VeraMono.ttf")
    make_interactable(chute, "Look at the waste chute", "examine_only",
                      text=("Biohazard waste chute.  The bag inside is "
                            "full.  At the top of the bag, the corner "
                            "of a station-issue jumpsuit, name tag "
                            "still attached:  SATO, K.  You feel like "
                            "you should know who that is."),
                      duration=6.0)

    # --- Bench against the north wall (the side facing the medical exit) ---
    bench = Entity(model="cube", scale=(2.4, 0.45, 0.5),
                   position=(-2.4, 0.22, d/2 - 0.7),
                   color=color.rgb(95, 80, 60),
                   collider="box")
    created.append(bench)
    # Folded jumpsuit on the bench
    Entity(parent=bench, model="cube",
           scale=(0.55, 0.20, 0.40),
           position=(-0.5, 0.32, 0),
           color=color.rgb(220, 220, 220))
    # Boots
    Entity(parent=bench, model="cube",
           scale=(0.40, 0.20, 0.18),
           position=(0.5, 0.32, 0),
           color=color.rgb(40, 35, 30))
    make_interactable(bench, "Look at the bench", "examine_only",
                      text=("Folded fresh jumpsuit, boots, towel.  All "
                            "set out for someone.  You look at the size "
                            "label on the jumpsuit.  It is yours.  You "
                            "don't remember laying it out."),
                      duration=5.0)

    # --- Floor drain at the centre (just a grate quad) ---
    Entity(model="quad",
           scale=(0.80, 0.80),
           rotation=(90, 0, 0),
           position=(0, 0.02, 0),
           color=color.rgba(50, 55, 65, 255))

    # --- Slim overhead light strips ---
    for tz in (-4, 0, 4):
        Entity(model="cube",
               scale=(2.0, 0.05, 0.40),
               position=(0, h - 0.10, tz),
               color=color.rgba(220, 235, 250, 240))

    # Player spawn near the south door, facing +z
    game.player.position = Vec3(0, 1.6, -d/2 + 0.8)
    game.player.fpc.rotation_y = 0

    # Transition - cross the north door threshold (decon -> med bay)
    def check_transition():
        if game.state.decon_door_open and game.player.position.z > d/2 + 0.1:
            game.transition_to("act_med")
    game.register_ticker(check_transition)

    return created
