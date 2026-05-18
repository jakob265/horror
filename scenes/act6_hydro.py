"""
scenes/act6_hydro.py
--------------------
ACT 6 - HYDROPONICS BAY.

A working hydroponics bay where Yuna grew plants under blue UV light.
The plants are now wilting.  Yuna's hydroponics journal (Note 10) sits
on the tomato trough.  Her hand-labeled plant tags use the same little
sun drawing her mother used to draw on her school lunches.

Revamped (Phase 2):  the room is now a proper greenhouse - 16x16,
five planter rows running the long axis, grow-racks lining the side
walls, a sink/wash station, a propagation table with cuttings under
domes, and a broken automation arm hanging dead above the centre
row.  The lemon cutting still sits in its lonely clay pot, but is
joined by other personal touches Yuna left behind.
"""

import math
import random

from ursina import Entity, Text, Vec3, color, time

from scenes._chamber import (
    DOOR_H, DOOR_W, build_floor_ceiling, build_wall, make_door,
)
from systems.interaction import make_interactable
from systems import visuals


def _build_planter_row(created, *, x, length=10, plant_count=8,
                       wilted=True, has_tag=False, tag_text=""):
    """Build one long planter trough running along z."""
    trough = Entity(model="cube",
                    scale=(1.1, 0.40, length),
                    position=(x, 0.20, 0),
                    color=color.rgb(40, 50, 60),
                    collider="box")
    created.append(trough)
    # Soil strip on top
    Entity(parent=trough, model="cube",
           scale=(0.95, 0.10, length - 0.15),
           position=(0, 0.22, 0),
           color=color.rgb(35, 28, 22))
    # Plants spaced along the length
    half = (length - 1.0) / 2
    for i in range(plant_count):
        t = -half + i * ((length - 1.0) / max(plant_count - 1, 1))
        stem = Entity(parent=trough, model="cube",
                      scale=(0.05, 0.70, 0.05),
                      position=(0, 0.55, t),
                      color=color.rgb(70 if wilted else 100,
                                      90 if wilted else 140,
                                      60 if wilted else 80))
        leaf = Entity(parent=stem, model="sphere",
                      scale=(2.4, 0.7, 1.6),
                      position=(0, 0.4, 0),
                      color=color.rgb(55 if wilted else 90,
                                      90 if wilted else 150,
                                      55 if wilted else 70))
        # Some plants droop sideways
        if wilted and i % 3 == 1:
            leaf.rotation_z = 25
    # Optional plant tag stuck into the soil at the south end
    if has_tag:
        tag = Entity(parent=trough, model="cube",
                     scale=(0.12, 0.16, 0.02),
                     position=(0, 0.42, -length / 2 + 0.2),
                     color=color.rgba(245, 230, 200, 250),
                     collider="box")
        Text(parent=tag, text=tag_text,
             position=(0, 0, -0.51), origin=(0, 0),
             scale=4, color=color.rgb(40, 30, 25),
             font="VeraMono.ttf")


def _build_grow_rack(created, x, z, *, h_levels=3):
    """Build a wall-mounted grow-rack with seedling trays."""
    # Rack frame
    rack = Entity(model="cube",
                  scale=(0.30, h_levels * 0.70, 2.2),
                  position=(x, h_levels * 0.35, z),
                  color=color.rgb(80, 90, 100),
                  texture=visuals.make_metal_panel(),
                  texture_scale=(0.4, h_levels * 0.5),
                  collider="box")
    created.append(rack)
    # Trays on each level
    for level in range(h_levels):
        ty = 0.20 + level * 0.70
        # Tray
        tray = Entity(parent=rack, model="cube",
                      scale=(2.4, 0.20, 6.5),
                      position=(0.8, ty - h_levels * 0.35, 0),
                      color=color.rgba(70, 60, 50, 255))
        # Seedlings
        for sz in (-0.8, -0.4, 0, 0.4, 0.8):
            stem = Entity(parent=tray, model="cube",
                          scale=(0.05, 0.30, 0.05),
                          position=(0, 0.25, sz),
                          color=color.rgb(100, 130, 80))
            Entity(parent=stem, model="sphere",
                   scale=(1.8, 0.6, 1.4),
                   position=(0, 0.3, 0),
                   color=color.rgb(90, 140, 80))
        # Blue UV strip under each level
        Entity(parent=rack, model="cube",
               scale=(2.6, 0.04, 0.30),
               position=(0.5, ty - h_levels * 0.35 + 0.30, 0),
               color=color.rgba(140, 200, 255, 230))


def build(game):
    """Hydroponics bay - now 16x16 with multiple rows + side racks."""
    created = []

    w, d, h = 16, 16, 3.6
    build_floor_ceiling(created, w, d, h,
                        floor_color=(85, 95, 85),
                        ceiling_color=(35, 50, 45),
                        floor_tex="concrete",
                        center=(0, 0, 0))

    # Side walls
    for fx in (-w/2, w/2):
        build_wall(created, "x", fx, -d/2, d/2, h,
                   wall_color=(60, 75, 70))
    # South / north with door gaps centered
    build_wall(created, "z", -d/2, -w/2, w/2, h,
               gap_center=0, wall_color=(60, 75, 70))
    build_wall(created, "z", d/2, -w/2, w/2, h,
               gap_center=0, wall_color=(60, 75, 70))

    # Doors
    make_door(created, "z", -d/2 + 0.05, 0, "LAB",
              side=+1, color_rgb=(72, 70, 60), sealed=True)
    def open_exit():
        game.state.hydro_door_open = True
    game.state.hydro_door_open = False
    make_door(created, "z", d/2 - 0.05, 0, "ENGINEERING",
              side=-1, color_rgb=(72, 70, 60),
              callback=open_exit,
              interactable_label="Open ENGINEERING")

    # --- Five planter rows running the long axis ---
    row_labels = [
        ("tomatoes,  pinch tops 2x/wk"),
        ("lettuce,  cut outer leaves"),
        ("beans,  Felix will steal them"),
        ("herbs,  yes the basil too,  thx"),
        ("strawberries,  Amara's request"),
    ]
    for i, rx in enumerate((-5.0, -2.5, 0, 2.5, 5.0)):
        _build_planter_row(created, x=rx, length=12, plant_count=10,
                           wilted=True, has_tag=True,
                           tag_text=row_labels[i])

    # --- Blue UV grow-lamp strips on the ceiling ---
    for tz in (-6, -3, 0, 3, 6):
        for tx in (-4, 0, 4):
            Entity(model="cube",
                   scale=(2.6, 0.06, 0.3),
                   position=(tx, h - 0.15, tz),
                   color=color.rgba(140, 200, 255, 230))

    # --- Side wall grow-racks (west and east) ---
    for rz in (-5, 0, 5):
        _build_grow_rack(created, x=-w/2 + 0.30, z=rz)
        _build_grow_rack(created, x=w/2 - 0.30, z=rz)

    # --- Sink / wash station at the south-east corner ---
    sink = Entity(model="cube", scale=(1.8, 0.90, 0.9),
                  position=(w/2 - 1.4, 0.45, -d/2 + 1.2),
                  color=color.rgb(140, 145, 155),
                  collider="box")
    created.append(sink)
    Entity(parent=sink, model="cube",
           scale=(1.7, 0.10, 0.80),
           position=(0, 0.45, 0),
           color=color.rgba(60, 75, 95, 255))
    Entity(parent=sink, model="cube",
           scale=(0.08, 0.32, 0.08),
           position=(0, 0.66, -0.20),
           color=color.rgb(180, 190, 200))
    # Watering can on the counter
    can = Entity(parent=sink, model="cube",
                 scale=(0.35, 0.35, 0.30),
                 position=(0.5, 0.65, 0),
                 color=color.rgba(110, 180, 110, 255))
    Entity(parent=can, model="cube",
           scale=(0.18, 0.05, 0.35),
           position=(-0.7, 0.10, 0),
           color=color.rgba(110, 180, 110, 255))
    make_interactable(sink, "Look at the wash station", "examine_only",
                      text=("The sink is dry.  The water line above it "
                            "is intact.  The watering can sits on the "
                            "counter.  Yuna's handwriting on the lip:  "
                            "'fill morning AND evening.  the plants "
                            "drink more than you think.'"),
                      duration=5.0)

    # --- Propagation table with glass domes (south-west corner) ---
    prop_table = Entity(model="cube", scale=(3.0, 0.80, 1.4),
                        position=(-w/2 + 2.0, 0.40, -d/2 + 1.6),
                        color=color.rgb(75, 65, 55),
                        collider="box")
    created.append(prop_table)
    # Three propagation domes
    for px in (-0.8, 0, 0.8):
        # Pot
        Entity(parent=prop_table, model="cube",
               scale=(0.20, 0.18, 0.20),
               position=(px, 0.50, 0),
               color=color.rgb(160, 130, 100))
        # Cutting
        Entity(parent=prop_table, model="cube",
               scale=(0.04, 0.40, 0.04),
               position=(px, 0.78, 0),
               color=color.rgb(80, 110, 75))
        # Glass dome
        Entity(parent=prop_table, model="sphere",
               scale=(0.40, 0.55, 0.40),
               position=(px, 0.70, 0),
               color=color.rgba(220, 230, 240, 90))
    make_interactable(prop_table, "Look at the cuttings", "examine_only",
                      text=("Three cuttings under glass domes.  All "
                            "labeled in Yuna's handwriting.  Left: "
                            "'rosemary - for Hargrove who pretends he "
                            "doesn't like it.'  Centre: 'mint - for "
                            "Mara's tea.'  Right: 'a flower whose "
                            "name I keep meaning to ask her - she "
                            "calls it the orange one.'"),
                      duration=8.0)

    # --- Broken automation arm hanging dead over the centre row ---
    arm_base = Entity(model="cube",
                      scale=(0.30, 0.30, 0.30),
                      position=(0, h - 0.15, 0),
                      color=color.rgb(80, 90, 100),
                      collider="box")
    created.append(arm_base)
    arm_link1 = Entity(parent=arm_base, model="cube",
                       scale=(0.15, 1.4, 0.15),
                       position=(0, -0.7, 0),
                       color=color.rgb(140, 150, 160),
                       rotation=(0, 0, 35))
    arm_link2 = Entity(parent=arm_link1, model="cube",
                       scale=(1.0, 0.10, 0.10),
                       position=(0, -0.7, 0),
                       color=color.rgb(140, 150, 160),
                       rotation=(0, 0, -55))
    # The arm's gripper
    Entity(parent=arm_link2, model="cube",
           scale=(0.20, 0.30, 0.20),
           position=(0.5, 0, 0),
           color=color.rgb(80, 90, 100))
    make_interactable(arm_base, "Look at the harvest arm", "examine_only",
                      text=("Maintenance arm SAF-7.  It hangs slack in "
                            "the middle of its arc, frozen mid-motion.  "
                            "A red fault light blinks at its base.  "
                            "The error code on the wrist screen is "
                            "442-K.  Same as the array."),
                      duration=6.0)

    # --- Note 10 - Yuna's hydroponics journal on the centre trough ---
    note10 = Entity(model="quad", scale=(0.42, 0.52),
                    rotation=(90, 0, 0),
                    position=(0, 0.45, -3.0),
                    color=color.rgba(230, 220, 200, 255),
                    collider="box")
    make_interactable(note10, "Read hydroponics journal", "collect_note",
                      note_id="note_10")
    created.append(note10)

    # --- The lemon-tree cutting in its lonely clay pot ---
    pot = Entity(model="cube", scale=(0.32, 0.32, 0.32),
                 position=(5.5, 0.55, -6.0),
                 color=color.rgb(160, 130, 100),
                 collider="box")
    created.append(pot)
    Entity(parent=pot, model="cube",
           scale=(0.10, 1.4, 0.10),
           position=(0, 0.9, 0),
           color=color.rgb(80, 60, 50))
    Entity(parent=pot, model="sphere",
           scale=(1.2, 1.2, 1.2),
           position=(0, 1.5, 0),
           color=color.rgb(70, 110, 70))
    make_interactable(pot, "Look at the pot", "examine_only",
                      text=("A clay pot with a young lemon-tree cutting.  "
                            "A tag in Yuna's handwriting reads 'home'.  "
                            "She drew a sun with a face on the tag."),
                      duration=5.0)

    # --- Tool wall with hand tools hanging by the south-east corner ---
    tool_wall = Entity(model="cube",
                       scale=(0.06, 1.8, 2.4),
                       position=(w/2 - 0.10, 1.6, -d/2 + 4.0),
                       color=color.rgb(85, 80, 70),
                       collider="box")
    created.append(tool_wall)
    # A trowel, a pair of shears, gloves
    Entity(parent=tool_wall, model="cube",
           scale=(0.06, 0.50, 0.10),
           position=(0.55, 0.20, 0.5),
           color=color.rgb(150, 140, 130))
    Entity(parent=tool_wall, model="cube",
           scale=(0.06, 0.40, 0.18),
           position=(0.55, -0.20, 0),
           color=color.rgb(180, 80, 60))
    Entity(parent=tool_wall, model="cube",
           scale=(0.06, 0.20, 0.22),
           position=(0.55, -0.55, -0.5),
           color=color.rgba(200, 200, 180, 255))
    make_interactable(tool_wall, "Look at the tool wall", "examine_only",
                      text=("Yuna's tool wall.  Trowel, shears, gloves "
                            "still warm from the last time she used "
                            "them.  Hanging on the nail at the end is "
                            "a single sneaker, which makes no sense "
                            "and is unmistakably hers."),
                      duration=5.0)

    # --- A bench in the north-west corner with a logbook ---
    bench = Entity(model="cube", scale=(2.0, 0.5, 0.6),
                   position=(-w/2 + 2.0, 0.25, d/2 - 1.0),
                   color=color.rgb(80, 70, 60),
                   collider="box")
    created.append(bench)
    log = Entity(model="cube",
                 scale=(0.30, 0.06, 0.40),
                 position=(-w/2 + 2.0, 0.53, d/2 - 1.0),
                 color=color.rgba(100, 80, 60, 255),
                 collider="box")
    created.append(log)
    make_interactable(log, "Flip through the logbook", "examine_only",
                      text=("Yuna's logbook.  The most recent entries:\n\n"
                            "  day 71 -  beans:  yield down 30%.  cause "
                            "unknown.\n"
                            "  day 72 -  beans:  yield down 50%.  same.\n"
                            "  day 73 -  every plant is hearing the\n"
                            "            same thing i am.  i think we\n"
                            "            are all the bean now.\n"
                            "  day 74 -  (no entry)"),
                      duration=10.0)

    # --- Some faint mist/steam particles at the planter level (visual) ---
    for tx in (-5, -2.5, 0, 2.5, 5):
        for tz in range(-5, 6, 2):
            Entity(model="quad",
                   scale=(0.6, 0.6),
                   rotation=(90, 0, 0),
                   position=(tx, 0.6, tz),
                   color=color.rgba(180, 220, 230, 25))

    # Player spawn
    game.player.position = Vec3(0, 1.6, -d/2 + 0.8)
    game.player.fpc.rotation_y = 0

    def check_transition():
        if game.state.hydro_door_open and game.player.position.z > d/2 + 0.1:
            game.transition_to("act7")
    game.register_ticker(check_transition)

    return created
