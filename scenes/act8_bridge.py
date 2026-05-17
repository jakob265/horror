"""
scenes/act8_bridge.py
---------------------
ACT 8 - BRIDGE / COMMUNICATIONS (NEW).

The communications bridge.  An Earth-uplink terminal blinks failed.  The
crew's group photo on the wall.  Mara's second personal recorder entry
(Note 12) sits on the failed terminal - she dictated it before walking
toward the array.

Hargrove-Shape is briefly visible at the far end of the room, facing
away.  It doesn't react.
"""

from ursina import Entity, Text, Vec3, color

from scenes._chamber import (
    DOOR_H, DOOR_W, build_floor_ceiling, build_wall, make_door,
)
from systems.entity import HargroveShape
from systems.interaction import make_interactable
from systems import visuals


def build(game):
    """Bridge chamber with the failed uplink + crew photo + recorder."""
    created = []

    w, d, h = 10, 10, 3.4
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
    make_door(created, "z", -d/2 + 0.05, 0, "ENGINEERING",
              side=+1, color_rgb=(72, 70, 60), sealed=True)
    def open_exit():
        game.state.bridge_door_open = True
    game.state.bridge_door_open = False
    make_door(created, "z", d/2 - 0.05, 0, "APPROACH",
              side=-1, color_rgb=(72, 70, 60),
              callback=open_exit,
              interactable_label="Open APPROACH")

    # Comms console - long curved desk in the middle
    desk = Entity(model="cube", scale=(6, 0.85, 1.4),
                  position=(0, 0.42, 1.0),
                  color=color.rgb(50, 55, 65),
                  collider="box")
    created.append(desk)
    # Three monitor stations on the desk
    for sx, label_text in [(-1.8, "UPLINK\nFAILED"),
                            (0, "RELAY\nSILENT"),
                            (1.8, "SIGNAL\n??.??.??")]:
        back = Entity(model="cube", scale=(0.9, 0.65, 0.06),
                      position=(sx, 1.20, 0.5),
                      color=color.rgb(30, 30, 35),
                      collider="box")
        created.append(back)
        scr = Entity(parent=back, model="quad",
                     scale=(0.85, 0.55),
                     position=(0, 0, -0.55),
                     color=color.rgba(40, 80, 50, 255))
        Text(parent=scr, text=label_text,
             position=(0, 0, -0.01), origin=(0, 0), scale=3.5,
             color=color.rgb(160, 230, 180), font="VeraMono.ttf")

    # Mara's personal recorder on the center monitor (Note 12)
    rec = Entity(model="cube", scale=(0.25, 0.08, 0.16),
                  position=(0, 0.92, 0.8),
                  color=color.rgba(220, 215, 200, 255),
                  collider="box")
    make_interactable(rec, "Play personal recorder", "collect_note",
                      note_id="note_12")
    created.append(rec)

    # Crew group photo - large frame on the east wall
    photo_frame = Entity(model="cube",
                         scale=(0.10, 1.2, 1.8),
                         position=(w/2 - 0.13, 1.7, -2.5),
                         color=color.rgb(220, 215, 195),
                         collider="box")
    created.append(photo_frame)
    Entity(parent=photo_frame, model="cube",
           scale=(0.10, 0.92, 0.92),
           position=(-0.55, 0, 0),
           color=color.rgb(70, 90, 120))
    make_interactable(photo_frame, "Look at crew photo", "examine_only",
                      text=("Five people in matching white jumpsuits.  "
                            "Pre-flight, taken on the gantry.  Felix is "
                            "behind you with his hand on your shoulder.  "
                            "Yuna is leaning on the rail.  Hargrove is "
                            "saying something that's making everyone "
                            "laugh.  You don't remember the joke.  You "
                            "are sure there was one."),
                      duration=8.0)

    # A whiteboard with the calibration error scrawled on it
    board = Entity(model="cube", scale=(0.10, 1.4, 2.0),
                   position=(-w/2 + 0.13, 1.8, 0),
                   color=color.rgb(230, 230, 235),
                   collider="box")
    created.append(board)
    # Scrawled text on the board
    Entity(parent=board, model="quad",
           scale=(0.85, 1.6),
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

    # Hargrove-Shape at the back of the bridge, facing away
    hg = HargroveShape(position=(0, 0, d/2 - 1.2),
                       rotation_y=0, audio=game.audio)
    game.shapes.register(hg)
    created.append(hg)

    # Player spawn
    game.player.position = Vec3(0, 1.6, -d/2 + 0.8)
    game.player.fpc.rotation_y = 0

    def check_transition():
        if game.state.bridge_door_open and \
                game.player.position.z > d/2 + 0.1:
            game.transition_to("act_maint")
    game.register_ticker(check_transition)

    return created
