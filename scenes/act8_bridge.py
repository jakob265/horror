"""
scenes/act8_bridge.py
---------------------
ACT 8 - BRIDGE / COMMUNICATIONS.

The communications bridge.  An Earth-uplink terminal blinks failed.  The
crew's group photo on the wall.  Mara's second personal recorder entry
(Note 12) sits on the failed terminal - she dictated it before walking
toward the array.

Hargrove-Shape is briefly visible at the far end of the room, facing
away.  It doesn't react.

Revamped (Phase 2):  the bridge is now 18x16 with a raised captain's
platform at the rear, five crew stations along a curving forward
console, side comms / nav alcoves, and a small holographic system
map on a pedestal at the centre.
"""

import math

from ursina import Entity, Text, Vec3, color, time

from scenes._chamber import (
    DOOR_H, DOOR_W, build_floor_ceiling, build_wall, make_door,
)
from systems.entity import HargroveShape
from systems.interaction import make_interactable
from systems import visuals


def _crew_station(created, x, z, *, label_text, screen_color=(40, 80, 50),
                  text_color=(160, 230, 180)):
    """Build a single crew station (back + screen + small console)."""
    # Console under the screen
    console = Entity(model="cube",
                     scale=(1.2, 0.85, 0.6),
                     position=(x, 0.42, z),
                     color=color.rgb(45, 50, 60),
                     collider="box")
    created.append(console)
    # Sloped front panel (just a tilted quad)
    Entity(parent=console, model="cube",
           scale=(1.10, 0.30, 0.20),
           position=(0, 0.30, -0.30),
           color=color.rgb(35, 40, 50),
           rotation=(20, 0, 0))
    # Buttons - row of small colored squares
    for bi, brgb in enumerate([(220, 60, 60), (220, 180, 60),
                                (60, 220, 100), (60, 180, 220)]):
        Entity(parent=console, model="cube",
               scale=(0.10, 0.04, 0.10),
               position=(-0.40 + bi * 0.26, 0.46, -0.20),
               color=color.rgba(*brgb, 255))
    # Vertical back with the screen
    back = Entity(model="cube",
                  scale=(1.0, 0.7, 0.06),
                  position=(x, 1.20, z + 0.18),
                  color=color.rgb(30, 30, 35),
                  collider="box")
    created.append(back)
    scr = Entity(parent=back, model="quad",
                 scale=(0.92, 0.62),
                 position=(0, 0, -0.055),
                 color=color.rgba(*screen_color, 255))
    Text(parent=scr, text=label_text,
         position=(0, 0, -0.01), origin=(0, 0), scale=3.5,
         color=color.rgb(*text_color), font="VeraMono.ttf")
    return console, back


def build(game):
    """Bridge - now a proper command deck."""
    created = []

    w, d, h = 18, 16, 3.8
    build_floor_ceiling(created, w, d, h,
                        floor_color=(75, 80, 90),
                        ceiling_color=(30, 35, 45),
                        floor_tex="grating",
                        center=(0, 0, 0))

    for fx in (-w/2, w/2):
        build_wall(created, "x", fx, -d/2, d/2, h,
                   wall_color=(65, 75, 90))
    build_wall(created, "z", -d/2, -w/2, w/2, h,
               gap_center=0, wall_color=(65, 75, 90))
    build_wall(created, "z", d/2, -w/2, w/2, h,
               gap_center=0, wall_color=(65, 75, 90))

    # Doors
    make_door(created, "z", -d/2 + 0.05, 0, "STORAGE",
              side=+1, color_rgb=(72, 70, 60), sealed=True)
    def open_exit():
        game.state.bridge_door_open = True
    game.state.bridge_door_open = False
    make_door(created, "z", d/2 - 0.05, 0, "MAINTENANCE",
              side=-1, color_rgb=(72, 70, 60),
              callback=open_exit,
              interactable_label="Open MAINTENANCE")

    # --- Five crew stations along a curving forward console ---
    # Stations at (-5, 2.5), (-2.5, 1.8), (0, 1.5), (2.5, 1.8), (5, 2.5)
    stations = [
        (-5.0, 2.5, "NAVIGATION\nCOURSE  LOCKED\nFUEL    72%"),
        (-2.5, 1.8, "UPLINK\nFAILED\n--.--.--"),
        (0.0, 1.5, "RELAY\nSILENT\n--.--.--"),
        (2.5, 1.8, "SIGNAL\n??.??.??\n*** INWARD ***"),
        (5.0, 2.5, "POWER\nCORE    NOMINAL\nLOAD    37%"),
    ]
    for sx, sz, txt in stations:
        sc, br = _crew_station(created, sx, sz, label_text=txt)

    # Curving rail / desk lip in front of the stations (the curve is
    # faked with three short segments)
    for dx, dz in [(-4.0, 1.5), (-2.0, 1.0), (0.0, 0.8),
                   (2.0, 1.0), (4.0, 1.5)]:
        Entity(model="cube",
               scale=(2.0, 0.06, 0.2),
               position=(dx, 0.90, dz),
               color=color.rgb(80, 90, 110))

    # Crew chairs in front of each station
    for sx, sz in [(-5.0, 3.4), (-2.5, 2.7), (0, 2.4),
                   (2.5, 2.7), (5.0, 3.4)]:
        ch = Entity(model="cube", scale=(0.55, 0.40, 0.55),
                    position=(sx, 0.20, sz),
                    color=color.rgb(45, 50, 60),
                    collider="box")
        created.append(ch)
        Entity(parent=ch, model="cube",
               scale=(1.0, 1.4, 0.10),
               position=(0, 0.85, 0.45),
               color=color.rgb(40, 45, 55))

    # --- Mara's personal recorder (Note 12) on the centre station ---
    rec = Entity(model="cube", scale=(0.25, 0.08, 0.16),
                 position=(0, 0.92, 0.6),
                 color=color.rgba(220, 215, 200, 255),
                 collider="box")
    make_interactable(rec, "Play personal recorder", "collect_note",
                      note_id="note_12")
    created.append(rec)

    # --- Raised captain's platform at the rear ---
    plat_y = 0.30
    plat = Entity(model="cube",
                  scale=(5.5, plat_y, 3.5),
                  position=(0, plat_y / 2, -4.0),
                  color=color.rgb(55, 60, 75),
                  texture=visuals.make_metal_panel(),
                  texture_scale=(2.5, 1.5),
                  collider="box")
    created.append(plat)
    # Captain's chair on the platform
    cap_chair = Entity(model="cube",
                       scale=(0.80, 0.50, 0.80),
                       position=(0, plat_y + 0.25, -4.0),
                       color=color.rgb(30, 35, 45),
                       collider="box")
    created.append(cap_chair)
    Entity(parent=cap_chair, model="cube",
           scale=(1.0, 1.8, 0.12),
           position=(0, 1.05, -0.45),
           color=color.rgb(30, 35, 45))
    # Armrests
    for ax in (-0.5, 0.5):
        Entity(parent=cap_chair, model="cube",
               scale=(0.12, 0.30, 0.7),
               position=(ax, 0.50, 0),
               color=color.rgb(30, 35, 45))
    make_interactable(cap_chair, "Sit in the captain's chair", "examine_only",
                      text=("You sit in the chair Hargrove used to sit in.  "
                            "The view from here is excellent.  Five stations "
                            "below you.  A window above with the dead moon "
                            "behind it.  You used to mock him for sitting "
                            "here.  You miss the version of yourself that "
                            "got to mock anyone for anything."),
                      duration=8.0)

    # Steps up to the platform
    for sy, sd in [(0.10, 0.6), (0.20, 1.2)]:
        Entity(model="cube",
               scale=(3.5, sy, sd),
               position=(0, sy / 2, -2.0 - sd / 2),
               color=color.rgb(70, 75, 90),
               collider="box")

    # --- Holographic system map on a pedestal between the stations and the
    # captain's platform ---
    ped = Entity(model="cube",
                 scale=(1.0, 0.95, 1.0),
                 position=(0, 0.47, -0.8),
                 color=color.rgb(40, 45, 55),
                 collider="box")
    created.append(ped)
    Entity(parent=ped, model="cube",
           scale=(1.10, 0.10, 1.10),
           position=(0, 0.55, 0),
           color=color.rgb(20, 25, 35))
    # The hologram: a blueish translucent sphere with a tiny moon
    hologram = Entity(model="sphere",
                      scale=(0.65, 0.65, 0.65),
                      position=(0, 1.45, -0.8),
                      color=color.rgba(140, 200, 230, 130))
    created.append(hologram)
    # Tiny moon
    Entity(parent=hologram, model="sphere",
           scale=(0.30, 0.30, 0.30),
           position=(1.6, 0.2, 0),
           color=color.rgba(180, 170, 150, 200))
    # Tiny station marker
    Entity(parent=hologram, model="sphere",
           scale=(0.10, 0.10, 0.10),
           position=(0.4, -0.2, 0.5),
           color=color.rgba(220, 80, 60, 255))
    make_interactable(ped, "Examine the system map", "examine_only",
                      text=("A holographic projection of the Kepler-442 "
                            "system.  Star, dead moon, station.  The red "
                            "dot is the station.  The dotted line drawn "
                            "in marker on the pedestal lip is the array's "
                            "broadcast cone.  It is a circle.  It points "
                            "back at the station.  We have been broadcasting "
                            "to ourselves since we got here."),
                      duration=10.0)

    # --- Forward window / starfield above the stations ---
    # We just place a darker quad to suggest a viewport.  The procedural
    # sky is already visible behind it.
    win_frame_top = Entity(model="cube",
                           scale=(w - 2, 0.30, 0.20),
                           position=(0, h - 0.5, d/2 - 0.15),
                           color=color.rgb(65, 75, 90))
    created.append(win_frame_top)
    win_frame_bot = Entity(model="cube",
                           scale=(w - 2, 0.30, 0.20),
                           position=(0, h - 2.0, d/2 - 0.15),
                           color=color.rgb(65, 75, 90))
    created.append(win_frame_bot)
    for fx in (-(w - 2)/2, (w - 2)/2):
        Entity(model="cube",
               scale=(0.30, 1.7, 0.20),
               position=(fx, h - 1.25, d/2 - 0.15),
               color=color.rgb(65, 75, 90))
    # Dark blue window
    Entity(model="cube",
           scale=(w - 2.6, 1.4, 0.05),
           position=(0, h - 1.25, d/2 - 0.15),
           color=color.rgba(20, 40, 70, 220),
           collider="box")

    # --- Crew group photo - frame on the east wall ---
    photo_frame = Entity(model="cube",
                         scale=(0.10, 1.4, 2.2),
                         position=(w/2 - 0.13, 1.9, -2.5),
                         color=color.rgb(220, 215, 195),
                         collider="box")
    created.append(photo_frame)
    Entity(parent=photo_frame, model="cube",
           scale=(0.10, 1.1, 1.8),
           position=(-0.55, 0, 0),
           color=color.rgb(70, 90, 120))
    make_interactable(photo_frame, "Look at crew photo", "examine_only",
                      text=("Five people in matching white jumpsuits.  "
                            "Pre-flight, taken on the gantry.  Felix is "
                            "behind you with his hand on your shoulder.  "
                            "Yuna is leaning on the rail.  Hargrove is "
                            "saying something that's making everyone "
                            "laugh.  Sato is at the very edge of the "
                            "frame, half-cropped, looking sideways at "
                            "something off-camera.  You don't remember "
                            "the joke.  You are sure there was one."),
                      duration=10.0)

    # --- Whiteboard with the calibration error scrawled on it ---
    board = Entity(model="cube", scale=(0.10, 1.6, 2.4),
                   position=(-w/2 + 0.13, 2.0, 0),
                   color=color.rgb(230, 230, 235),
                   collider="box")
    created.append(board)
    Entity(parent=board, model="quad",
           scale=(0.85, 1.4, 2.2),
           position=(0.55, 0, 0),
           rotation=(0, 90, 0),
           color=color.rgba(0, 0, 0, 0))
    make_interactable(board, "Read whiteboard", "examine_only",
                      text=("Hargrove's handwriting in red marker:\n"
                            "  array  442-K  -> 0.7 Pu\n"
                            "  WE MADE IT\n"
                            "and then crossed out:  THERE WAS NEVER "
                            "ANYTHING OUT THERE\n"
                            "(Crossed out so hard the marker tore through.)"),
                      duration=8.0)

    # --- Side comms alcove on the west wall ---
    alcove = Entity(model="cube", scale=(1.4, 1.6, 0.6),
                    position=(-w/2 + 0.50, 0.80, 3.0),
                    color=color.rgb(50, 55, 70),
                    collider="box")
    created.append(alcove)
    Entity(parent=alcove, model="quad",
           scale=(1.20, 1.20),
           position=(0, 0.20, -0.31),
           color=color.rgba(40, 60, 80, 255))
    Text(parent=alcove, text=("LONG-RANGE\n"
                              "  carrier:  OFFLINE\n"
                              "  buffer:   FULL\n"
                              "  msgs out: 0\n"
                              "  msgs in:  0"),
         position=(0, 0.20, -0.32), origin=(0, 0), scale=3,
         color=color.rgb(160, 200, 240), font="VeraMono.ttf")

    # --- Hargrove-Shape at the back of the bridge, facing away ---
    hg = HargroveShape(position=(0, plat_y, -d/2 + 1.5),
                       rotation_y=0, audio=game.audio)
    game.shapes.register(hg)
    created.append(hg)

    # --- A scattered mug on the platform near Hargrove-Shape ---
    mug = Entity(model="cube", scale=(0.15, 0.22, 0.15),
                 position=(0.9, plat_y + 0.11, -3.5),
                 rotation=(0, 0, 70),
                 color=color.rgb(40, 60, 80),
                 collider="box")
    created.append(mug)
    Entity(model="quad", scale=(0.40, 0.30),
           rotation=(90, 0, 0),
           position=(0.7, plat_y + 0.01, -3.7),
           color=color.rgba(80, 50, 30, 220))
    make_interactable(mug, "Look at the tipped mug", "examine_only",
                      text=("A blue ceramic mug on its side, dark stain "
                            "fanning out from it.  Hargrove's mug.  He "
                            "must have set it down here and never picked "
                            "it back up."),
                      duration=5.0)

    # Player spawn
    game.player.position = Vec3(0, 1.6, -d/2 + 0.8)
    game.player.fpc.rotation_y = 0

    def check_transition():
        if game.state.bridge_door_open and \
                game.player.position.z > d/2 + 0.1:
            game.transition_to("act_maint")
    game.register_ticker(check_transition)

    return created
