"""
scenes/act6_hydro.py
--------------------
ACT 6 - HYDROPONICS BAY (NEW).

A small hydroponics bay where Yuna grew plants under blue UV light.  The
plants are now wilting.  Yuna's hydroponics journal (Note 10) is on the
tomato trough.  Her hand-labeled plant tags use the same little sun
drawing her mother used to draw on her school lunches.
"""

from ursina import Entity, Text, Vec3, color

from scenes._chamber import (
    DOOR_H, DOOR_W, build_floor_ceiling, build_wall, make_door,
)
from systems.interaction import make_interactable
from systems import visuals


def build(game):
    """Hydroponics bay - small chamber with planter rows."""
    created = []

    w, d, h = 8, 9, 3.0
    build_floor_ceiling(created, w, d, h,
                        floor_color=(80, 90, 80),
                        ceiling_color=(35, 50, 45),
                        floor_tex="concrete",
                        center=(0, 0, 0))

    # Walls (entry south, exit north)
    for fx in (-w/2, w/2):
        build_wall(created, "x", fx, -d/2, d/2, h,
                   wall_color=(60, 75, 70))
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

    # Planter troughs - three rows
    for tx in (-2.5, 0, 2.5):
        # Trough body
        trough = Entity(model="cube", scale=(1.2, 0.4, 5.5),
                        position=(tx, 0.2, 0),
                        color=color.rgb(50, 55, 65),
                        collider="box")
        created.append(trough)
        # Wilted plants - dim green spheres
        for tz in range(-2, 3):
            stem = Entity(model="cube",
                          scale=(0.04, 0.3, 0.04),
                          position=(tx, 0.55, tz * 1.0),
                          color=color.rgb(80, 95, 70))
            leaf = Entity(parent=stem, model="sphere",
                          scale=(2.0, 0.6, 1.4),
                          position=(0, 0.5, 0),
                          color=color.rgb(60, 95, 65))
            created.append(stem)

    # Blue UV grow-lamp strips on the ceiling
    for tz in (-3, 0, 3):
        Entity(parent=Entity(parent=game.world_root), model="cube",
               scale=(6, 0.06, 0.4),
               position=(0, h - 0.15, tz),
               color=color.rgba(140, 200, 255, 230))

    # Note 10 - Yuna's hydroponics journal on the middle trough
    note10 = Entity(model="quad", scale=(0.42, 0.52),
                    rotation=(90, 0, 0),
                    position=(0, 0.45, -2.0),
                    color=color.rgba(230, 220, 200, 255),
                    collider="box")
    make_interactable(note10, "Read hydroponics journal", "collect_note",
                      note_id="note_10")
    created.append(note10)

    # Small lemon-tree cutting in a pot
    pot = Entity(model="cube", scale=(0.3, 0.3, 0.3),
                 position=(2.5, 0.55, -3.5),
                 color=color.rgb(160, 130, 100),
                 collider="box")
    created.append(pot)
    Entity(parent=pot, model="cube", scale=(0.10, 1.2, 0.10),
           position=(0, 0.8, 0),
           color=color.rgb(80, 60, 50))
    Entity(parent=pot, model="sphere", scale=(1.0, 1.0, 1.0),
           position=(0, 1.4, 0),
           color=color.rgb(70, 110, 70))
    make_interactable(pot, "Look at the pot", "examine_only",
                      text=("A clay pot with a young lemon-tree cutting.  "
                            "A tag in Yuna's handwriting reads 'home'.  "
                            "She drew a sun with a face on the tag."),
                      duration=5.0)

    # Player spawn
    game.player.position = Vec3(0, 1.6, -d/2 + 0.8)
    game.player.fpc.rotation_y = 0

    def check_transition():
        if game.state.hydro_door_open and game.player.position.z > d/2 + 0.1:
            game.transition_to("act7")
    game.register_ticker(check_transition)

    return created
