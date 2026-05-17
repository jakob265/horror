"""
scenes/act4_lounge.py
---------------------
ACT 4 - OBSERVATION LOUNGE (NEW).

A small lounge off the main corridor with a viewport looking out at the
dead moon.  This is where Felix and Mara kissed in month three.

  - Wide viewport showing Kepler-442's dead moon (large dark sphere
    behind a deep-blue starfield)
  - A toy piano on a low table with two stuck keys
  - A couch facing the viewport with a forgotten paperback
  - A folded note from Felix (Note 9 - verbatim)
  - Felix-Shape at the viewport (the kiss memory)
"""

from ursina import Entity, Text, Vec3, color
from ursina.models.procedural.cylinder import Cylinder

from scenes._chamber import (
    DOOR_H, DOOR_W, build_floor_ceiling, build_wall, make_door,
)
from systems.entity import FelixShape
from systems.interaction import make_interactable
from systems import visuals


def build(game):
    """Build the observation lounge."""
    created = []

    w, d, h = 9, 8, 3.2
    build_floor_ceiling(created, w, d, h,
                        floor_color=(110, 100, 95),
                        ceiling_color=(45, 50, 60),
                        floor_tex="concrete",
                        center=(0, 0, 0))

    # Walls
    build_wall(created, "x", -w/2, -d/2, d/2, h,
               wall_color=(80, 85, 100))
    # East wall is the viewport (no solid wall, large window)
    # South wall - sealed entry from the corridor
    build_wall(created, "z", -d/2, -w/2, w/2, h,
               gap_center=0, wall_color=(80, 85, 100))
    # North wall - exit door back to corridor (we let the lounge dead-end
    # at the viewport instead of pushing the player further; exit is
    # west-side door back to corridor)
    build_wall(created, "z", d/2, -w/2, w/2, h,
               wall_color=(80, 85, 100))

    # Replace east wall with a huge viewport.  Solid frame around it.
    # Top and bottom solid strips
    for sy_y, sy_h in [(h - 0.3, 0.6), (0.3, 0.6)]:
        created.append(Entity(model="cube",
                              scale=(0.2, sy_h, d),
                              position=(w/2, sy_y, 0),
                              color=color.rgb(80, 85, 100),
                              texture=visuals.make_metal_panel(),
                              texture_scale=(d/2, sy_h/2),
                              collider="box"))
    # Left/right vertical frame strips
    for fz in (-d/2 + 0.3, d/2 - 0.3):
        created.append(Entity(model="cube",
                              scale=(0.2, h, 0.6),
                              position=(w/2, h/2, fz),
                              color=color.rgb(80, 85, 100),
                              texture=visuals.make_metal_panel(),
                              texture_scale=(0.6/2, h/2),
                              collider="box"))
    # Dark blue glass pane (visual + collider so player can't walk through)
    glass = Entity(model="cube",
                   scale=(0.05, h - 1.2, d - 1.2),
                   position=(w/2, h/2, 0),
                   color=color.rgba(20, 30, 60, 220),
                   collider="box")
    created.append(glass)
    # The "dead moon" outside: large dark sphere visible through the window
    moon = Entity(model="sphere",
                  scale=18,
                  position=(w/2 + 30, 8, 0),
                  color=color.rgb(90, 85, 80))
    created.append(moon)
    # Crater detail (small darker spheres on the moon)
    for cx, cy, cz in [(2, 3, 5), (-3, 1, 4), (4, -2, -2), (-1, 4, -5)]:
        Entity(parent=moon, model="sphere",
               scale=(0.25, 0.18, 0.25),
               position=(cx/18, cy/18, cz/18),
               color=color.rgb(60, 55, 50))

    # Entry door (sealed - corridor side)
    make_door(created, "z", -d/2 + 0.05, 0, "CORRIDOR",
              side=+1, color_rgb=(72, 70, 60), sealed=True)

    # Exit door - back to corridor on the WEST wall
    # We do this so the lounge has only one in/out doorway (player must
    # backtrack), but we also want forward progress.  Compromise: a SECOND
    # interactive door on the south wall leading "back" toward the lab.
    # Simpler: make the entry door open after the player examines the note
    # (so the lounge is a brief story beat, no maze).
    # Actually we'll add a small "FORWARD" door on the west wall:
    build_wall_with_west_door = True
    if build_wall_with_west_door:
        # We already built west wall; rebuild with a gap.
        # (Lazy approach: leave the west wall solid and use the south door
        # as the exit by making it openable.)
        pass

    # Replace south sealed door with an interactive forward door
    def open_exit():
        """Mark the lounge exit done so we transition back to corridor."""
        game.state.lounge_door_open = True
    game.state.lounge_door_open = False
    # The sealed entry door is already there.  Use an additional small
    # interactive door on the north wall facing the corridor (so the
    # player exits the way they came, but only after picking up the note).
    # Build a north exit:
    # First, cut a gap in north wall.  Since we already built the north
    # wall solid above, override it: build north wall as TWO segments
    # with a gap.
    # (Quick hack: spawn a door over the existing wall; the wall is solid
    # so the door won't actually open passage.  Instead, we replace the
    # exit logic: once the note is collected, we auto-transition.)

    # Felix-Shape at the viewport
    felix = FelixShape(position=(w/2 - 1.0, 0, 1.5),
                       rotation_y=-90, audio=game.audio)
    game.shapes.register(felix)
    created.append(felix)

    # Couch facing the viewport
    couch = Entity(model="cube", scale=(0.6, 0.4, 2.4),
                   position=(1.0, 0.2, 0),
                   color=color.rgb(55, 65, 90),
                   collider="box")
    created.append(couch)
    couch_back = Entity(model="cube", scale=(0.2, 0.9, 2.4),
                        position=(0.7, 0.45, 0),
                        color=color.rgb(55, 65, 90),
                        collider="box")
    created.append(couch_back)

    # Forgotten paperback on the couch
    book = Entity(model="cube", scale=(0.18, 0.04, 0.24),
                  position=(1.0, 0.42, -0.6),
                  color=color.rgb(190, 160, 80),
                  collider="box")
    make_interactable(book, "Examine paperback", "examine_only",
                      text=("A dog-eared paperback.  The bookmark is "
                            "halfway through.  It's Yuna's.  She told you "
                            "once she would finish it next Sunday.  Next "
                            "Sunday never came."),
                      duration=5.0)
    created.append(book)

    # Toy piano on a low table
    table = Entity(model="cube", scale=(0.8, 0.7, 0.5),
                   position=(-1.4, 0.35, -2.5),
                   color=color.rgb(70, 50, 35),
                   collider="box")
    created.append(table)
    piano = Entity(model="cube", scale=(0.6, 0.10, 0.30),
                   position=(-1.4, 0.75, -2.5),
                   color=color.rgb(20, 20, 25),
                   collider="box")
    created.append(piano)
    # White and black keys
    for i in range(7):
        Entity(parent=piano, model="cube",
               scale=(0.12, 0.30, 0.90),
               position=(-0.42 + i * 0.14, 0.6, 0),
               color=color.rgb(240, 235, 225))
    make_interactable(piano, "Touch the piano", "examine_only",
                      text=("A toy piano.  Felix bought it on a "
                            "supply run for Amara, then forgot to "
                            "send it home.  Two keys are stuck down.  "
                            "They ring a quiet open fifth that doesn't "
                            "resolve."),
                      duration=6.0)

    # Felix's folded note on the couch beside the book
    note9 = Entity(model="cube", scale=(0.18, 0.04, 0.14),
                   position=(1.0, 0.42, 0.4),
                   color=color.rgba(245, 230, 195, 255),
                   collider="box")
    make_interactable(note9, "Read folded paper", "collect_note",
                      note_id="note_9")
    created.append(note9)

    # Entry door pos
    game.player.position = Vec3(0, 1.6, -d/2 + 0.8)
    game.player.fpc.rotation_y = 0

    # Transition - once note 9 collected, the next door opens.  Player
    # turns around and walks back through the south wall to continue
    # forward.  Simpler: once note collected, auto-transition after a beat.
    def check_transition():
        if game.notes.has("note_9") and not getattr(
                game.state, "_lounge_transition_fired", False):
            game.state._lounge_transition_fired = True
            from ursina import invoke as _invoke
            _invoke(game.transition_to, "act_mess", delay=2.0)
    game.register_ticker(check_transition)

    return created
