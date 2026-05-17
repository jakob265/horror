"""
scenes/act_mess.py
------------------
ACT 4.5 - CREW MESS HALL (NEW).

Between the observation lounge and the signal lab.  A wide communal
dining space with the crew's last shared meal still on the table - five
place settings, four meals barely touched, one (Felix's chair) empty.

Layout:
    A 16x14 hall.  Long communal table down the center with 5 seats.
    Galley counter along the east wall (sinks, coffee, cabinets).
    A whiteboard on the west wall with the rotating mess schedule.
    A small plant beside the coffee pot.

Notes:
    Note 15 - the grocery list pinned by the coffee pot.
    Note 16 - a handwritten apology Yuna left under Mara's plate.
"""

from ursina import Entity, Text, Vec3, color

from scenes._chamber import (
    DOOR_H, DOOR_W, build_floor_ceiling, build_wall, make_door,
)
from systems.interaction import make_interactable
from systems import visuals


def _place_setting(created, parent_table_y, x, z, *, plate_color=(220, 220, 220),
                   food_color=None, mug_color=(140, 110, 90), empty=False,
                   name=None):
    """Build a single place setting: plate + mug + optional name plate."""
    plate = Entity(model="cube", scale=(0.42, 0.04, 0.42),
                   position=(x, parent_table_y + 0.04, z),
                   color=color.rgb(*plate_color),
                   collider="box")
    created.append(plate)
    # Food on the plate (a colored dome) unless empty
    if not empty and food_color is not None:
        Entity(parent=plate, model="sphere",
               scale=(0.7, 0.4, 0.7),
               position=(0, 0.6, 0),
               color=color.rgb(*food_color))
    # Mug to the upper-right of the plate
    mug = Entity(model="cube", scale=(0.12, 0.18, 0.12),
                 position=(x + 0.32, parent_table_y + 0.13, z - 0.18),
                 color=color.rgb(*mug_color),
                 collider="box")
    created.append(mug)
    # Cutlery (just two thin strips)
    Entity(model="cube", scale=(0.03, 0.02, 0.20),
           position=(x - 0.30, parent_table_y + 0.03, z),
           color=color.rgb(190, 195, 205))
    Entity(model="cube", scale=(0.03, 0.02, 0.20),
           position=(x + 0.30, parent_table_y + 0.03, z + 0.05),
           color=color.rgb(190, 195, 205))
    # Name plate at the head of the setting (just an embossed plate)
    if name is not None:
        nplate = Entity(model="cube",
                        scale=(0.30, 0.02, 0.08),
                        position=(x, parent_table_y + 0.05, z + 0.55),
                        color=color.rgb(120, 110, 90),
                        collider="box")
        created.append(nplate)
        Text(parent=nplate, text=name,
             position=(0, 0, 4.5),
             rotation=(90, 0, 0),
             origin=(0, 0), scale=8,
             color=color.rgb(40, 30, 20), font="VeraMono.ttf")
    return plate


def build(game):
    """Crew mess hall - communal table + galley + last meal still set."""
    created = []

    w, d, h = 16, 14, 3.4
    build_floor_ceiling(created, w, d, h,
                        floor_color=(140, 125, 110),
                        ceiling_color=(45, 40, 35),
                        floor_tex="concrete",
                        center=(0, 0, 0))

    for fx in (-w/2, w/2):
        build_wall(created, "x", fx, -d/2, d/2, h,
                   wall_color=(120, 100, 85))
    build_wall(created, "z", -d/2, -w/2, w/2, h,
               gap_center=0, wall_color=(120, 100, 85))
    build_wall(created, "z", d/2, -w/2, w/2, h,
               gap_center=0, wall_color=(120, 100, 85))

    # Doors
    make_door(created, "z", -d/2 + 0.05, 0, "LOUNGE",
              side=+1, color_rgb=(72, 70, 60), sealed=True)
    def open_exit():
        game.state.mess_door_open = True
    game.state.mess_door_open = False
    make_door(created, "z", d/2 - 0.05, 0, "LAB",
              side=-1, color_rgb=(72, 70, 60),
              callback=open_exit,
              interactable_label="Open LAB")

    # --- Communal table down the middle ---
    table = Entity(model="cube",
                   scale=(2.0, 0.85, 8.5),
                   position=(0, 0.42, 0),
                   color=color.rgb(110, 85, 65),
                   collider="box")
    created.append(table)
    # Wood grain - lighter strip
    Entity(parent=table, model="cube",
           scale=(1.95, 0.05, 8.45),
           position=(0, 0.45, 0),
           color=color.rgb(140, 110, 85))

    # --- 5 place settings: Mara, Felix (empty), Yuna, Hargrove, Sato ---
    # Settings alternate sides of the table.
    table_y = 0.85
    _place_setting(created, table_y, x=-0.55, z=-3.0,
                   plate_color=(220, 215, 205), food_color=(180, 100, 60),
                   mug_color=(120, 90, 70), name="VOSS")
    # Felix's seat: empty plate, mug knocked over.
    _place_setting(created, table_y, x=0.55, z=-1.5,
                   plate_color=(220, 215, 205), empty=True,
                   mug_color=(160, 60, 50), name="OKAFOR")
    _place_setting(created, table_y, x=-0.55, z=0.0,
                   plate_color=(220, 215, 205), food_color=(120, 140, 80),
                   mug_color=(80, 110, 130), name="PARK")
    _place_setting(created, table_y, x=0.55, z=1.5,
                   plate_color=(220, 215, 205), food_color=(180, 100, 60),
                   mug_color=(40, 60, 80), name="HARGROVE")
    _place_setting(created, table_y, x=-0.55, z=3.0,
                   plate_color=(220, 215, 205), food_color=(150, 120, 70),
                   mug_color=(180, 150, 100), name="SATO")

    # Felix's chair tipped over, on the floor next to his place
    fell_chair = Entity(model="cube",
                        scale=(0.45, 0.95, 0.45),
                        position=(1.6, 0.10, -1.5),
                        rotation=(0, 0, 90),
                        color=color.rgb(85, 70, 60),
                        collider="box")
    created.append(fell_chair)
    make_interactable(fell_chair, "Look at the fallen chair", "examine_only",
                      text=("Felix's chair is tipped over on the floor.  "
                            "His mug is on its side on the table, brown "
                            "ring soaked into the wood.  His plate is "
                            "empty - either he didn't eat or someone "
                            "cleared it before he got here.  Knowing "
                            "Felix it was the second one."),
                      duration=6.0)

    # Upright chairs at the other four settings
    for cx, cz in [(-1.5, -3.0), (-1.5, 0.0), (1.5, 1.5), (-1.5, 3.0)]:
        c = Entity(model="cube",
                   scale=(0.45, 0.85, 0.45),
                   position=(cx, 0.42, cz),
                   color=color.rgb(85, 70, 60),
                   collider="box")
        created.append(c)
        # Backrest
        Entity(parent=c, model="cube",
               scale=(0.90, 1.10, 0.10),
               position=(0, 0.55, -0.55 if cx > 0 else 0.55),
               color=color.rgb(85, 70, 60))

    # Note 16 - Yuna's handwritten apology, tucked under Mara's plate
    note16 = Entity(model="quad", scale=(0.30, 0.30),
                    rotation=(90, 0, 0),
                    position=(-0.55, table_y + 0.02, -3.3),
                    color=color.rgba(245, 230, 200, 245),
                    collider="box")
    make_interactable(note16, "Slide out the folded note", "collect_note",
                      note_id="note_16")
    created.append(note16)

    # --- Galley counter along the east wall ---
    counter = Entity(model="cube",
                     scale=(2.0, 0.95, d - 1.0),
                     position=(w/2 - 1.0, 0.47, 0),
                     color=color.rgb(95, 100, 110),
                     collider="box")
    created.append(counter)
    # Counter top
    Entity(parent=counter, model="cube",
           scale=(2.05, 0.06, d - 0.95),
           position=(0, 0.50, 0),
           color=color.rgb(220, 220, 225))

    # Sink basins (two)
    for sz in (-3.0, -1.5):
        Entity(model="cube",
               scale=(1.2, 0.08, 1.0),
               position=(w/2 - 1.0, 0.95, sz),
               color=color.rgba(60, 70, 80, 255),
               collider="box")
        # Faucet
        Entity(model="cube",
               scale=(0.06, 0.25, 0.06),
               position=(w/2 - 1.5, 1.12, sz - 0.05),
               color=color.rgb(180, 190, 200))

    # Coffee pot on the counter
    coffee_pot = Entity(model="cube",
                        scale=(0.40, 0.55, 0.30),
                        position=(w/2 - 1.0, 1.27, 1.0),
                        color=color.rgb(40, 45, 55),
                        collider="box")
    created.append(coffee_pot)
    Entity(parent=coffee_pot, model="cube",
           scale=(0.30, 0.40, 0.20),
           position=(0, -0.05, -0.18),
           color=color.rgba(220, 130, 60, 255))
    # Glowing red light on the coffee pot - it's still on
    Entity(parent=coffee_pot, model="cube",
           scale=(0.08, 0.06, 0.06),
           position=(0.20, 0.18, -0.16),
           color=color.rgba(220, 60, 60, 255))
    make_interactable(coffee_pot, "Look at the coffee pot", "examine_only",
                      text=("The coffee pot is still warm.  Some of it "
                            "has reduced to a black sludge in the bottom.  "
                            "OLEN keeps the warmer on a five-day timer for "
                            "the morning shift.  It has been five days."),
                      duration=5.0)

    # Note 15 - grocery list pinned to a small corkboard above the coffee
    cork = Entity(model="cube",
                  scale=(0.04, 0.50, 0.40),
                  position=(w/2 - 0.13, 2.0, 1.0),
                  color=color.rgb(160, 130, 90),
                  collider="box")
    created.append(cork)
    Entity(parent=cork, model="quad",
           scale=(0.40, 0.50),
           position=(0.55, 0, 0),
           rotation=(0, 90, 0),
           color=color.rgba(240, 230, 200, 250))
    make_interactable(cork, "Read the pinned list", "collect_note",
                      note_id="note_15")

    # Microwave on the counter
    micro = Entity(model="cube",
                   scale=(0.7, 0.45, 0.6),
                   position=(w/2 - 1.0, 1.22, 3.5),
                   color=color.rgb(80, 85, 95),
                   collider="box")
    created.append(micro)
    Entity(parent=micro, model="quad",
           scale=(0.50, 0.30),
           position=(0, 0, -0.31),
           color=color.rgba(20, 30, 30, 255))

    # Stack of trays at the south end of the counter
    for ty in range(4):
        Entity(model="cube",
               scale=(0.55, 0.04, 0.40),
               position=(w/2 - 1.0, 1.00 + ty * 0.05, -5.5),
               color=color.rgb(230, 225, 210),
               collider=None)

    # Small potted herb plant by the coffee pot (Yuna's, of course)
    pot = Entity(model="cube",
                 scale=(0.20, 0.20, 0.20),
                 position=(w/2 - 1.5, 1.10, 0),
                 color=color.rgb(170, 130, 90),
                 collider="box")
    created.append(pot)
    Entity(parent=pot, model="sphere",
           scale=(1.4, 0.8, 1.4),
           position=(0, 0.9, 0),
           color=color.rgb(80, 130, 80))
    make_interactable(pot, "Examine the herb pot", "examine_only",
                      text=("Yuna's basil plant.  A handwritten tag in "
                            "the soil:  'pinch the tops weekly.  do not "
                            "let it flower.  ask Mara to water on "
                            "Tuesdays.'  You don't remember being asked."),
                      duration=5.0)

    # --- West wall: mess schedule whiteboard ---
    board = Entity(model="cube",
                   scale=(0.10, 1.6, 2.4),
                   position=(-w/2 + 0.10, 1.8, 0),
                   color=color.rgb(240, 240, 245),
                   collider="box")
    created.append(board)
    Entity(parent=board, model="quad",
           scale=(0.90, 1.50, 2.30),
           position=(0.55, 0, 0),
           rotation=(0, 90, 0),
           color=color.rgba(245, 245, 250, 250))
    make_interactable(board, "Read the mess schedule", "examine_only",
                      text=("MESS ROTATION - week 8\n"
                            "  Mon  Park\n"
                            "  Tue  Okafor\n"
                            "  Wed  Sato\n"
                            "  Thu  Hargrove\n"
                            "  Fri  Voss\n"
                            "  Sat  Park / Voss (bake-off, !)\n"
                            "  Sun  free\n\n"
                            "Below it in Yuna's handwriting:\n"
                            "  Mara - I covered Friday for you again.\n"
                            "  Please come eat with us.  We saved you a "
                            "seat.  Yuna."),
                      duration=8.0)

    # --- Side bench at the south-east corner with a tablet ---
    bench = Entity(model="cube", scale=(2.0, 0.40, 0.6),
                   position=(w/2 - 3.0, 0.20, -d/2 + 1.0),
                   color=color.rgb(90, 70, 55),
                   collider="box")
    created.append(bench)
    tablet = Entity(model="cube",
                    scale=(0.30, 0.04, 0.20),
                    position=(w/2 - 3.0, 0.42, -d/2 + 1.0),
                    color=color.rgba(40, 50, 60, 255),
                    collider="box")
    make_interactable(tablet, "Wake the tablet", "examine_only",
                      text=("A station-issue tablet.  The lock screen "
                            "wallpaper is a photo of Hargrove's dog, "
                            "a big golden retriever named WALTER.  "
                            "Below it the message preview reads:\n"
                            "  'pls call when you can.  miss u.  - L.'"),
                      duration=6.0)
    created.append(tablet)

    # --- A row of pendant lights over the table ---
    for tz in (-3, 0, 3):
        Entity(model="cube",
               scale=(0.12, 0.40, 0.12),
               position=(0, h - 0.4, tz),
               color=color.rgb(40, 40, 50))
        Entity(model="sphere",
               scale=0.20,
               position=(0, h - 0.75, tz),
               color=color.rgba(255, 220, 160, 255))

    # Player spawn
    game.player.position = Vec3(0, 1.6, -d/2 + 0.8)
    game.player.fpc.rotation_y = 0

    def check_transition():
        if game.state.mess_door_open and game.player.position.z > d/2 + 0.1:
            game.transition_to("act5")
    game.register_ticker(check_transition)

    return created
