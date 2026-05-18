"""
scenes/act4_lounge.py
---------------------
ACT 4 - OBSERVATION LOUNGE.

A lounge off the main corridor with a viewport looking out at the
dead moon.  This is where Felix and Mara kissed in month three.

Revamped (Phase 2):  the lounge is now a proper observation deck -
14x12 with a wide curved seating area, a small library cart, a coffee
bar in the corner, a memorial wall, and a second small viewport on
the north wall.  The dead moon outside has more detail.

  - Wide viewport showing Kepler-442's dead moon
  - A toy piano on a low table with two stuck keys
  - A horseshoe-shaped couch facing the viewport
  - A library cart with a forgotten paperback
  - A folded note from Felix (Note 9 - verbatim)
  - Felix-Shape at the viewport (the kiss memory)
  - A coffee/tea bar in the corner with mugs left out
  - A memorial wall with the names of previous crews
"""

from ursina import Entity, Text, Vec3, color

from scenes._chamber import (
    DOOR_H, DOOR_W, build_floor_ceiling, build_wall, make_door,
)
from systems.entity import FelixShape
from systems.interaction import make_interactable
from systems import visuals


def build(game):
    """Build the observation lounge."""
    created = []

    w, d, h = 14, 12, 3.6
    build_floor_ceiling(created, w, d, h,
                        floor_color=(115, 105, 95),
                        ceiling_color=(45, 50, 60),
                        floor_tex="concrete",
                        center=(0, 0, 0))

    # Walls
    build_wall(created, "x", -w/2, -d/2, d/2, h,
               wall_color=(80, 85, 100))
    # South wall - sealed entry from the corridor
    build_wall(created, "z", -d/2, -w/2, w/2, h,
               gap_center=0, wall_color=(80, 85, 100))
    # North wall - solid (with a small porthole, built below)
    build_wall(created, "z", d/2, -w/2, w/2, h,
               wall_color=(80, 85, 100))

    # Replace east wall with a huge viewport - solid frame around it.
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
    # Vertical mullion in the middle (splits viewport in two)
    Entity(model="cube",
           scale=(0.20, h - 1.2, 0.30),
           position=(w/2, h/2, 0),
           color=color.rgb(80, 85, 100),
           collider="box")
    # Dark blue glass panes (visual + collider so player can't walk through)
    for gz_offset in (-(d - 1.2) / 4, (d - 1.2) / 4):
        glass = Entity(model="cube",
                       scale=(0.05, h - 1.2, (d - 1.4) / 2),
                       position=(w/2, h/2, gz_offset),
                       color=color.rgba(20, 30, 60, 220),
                       collider="box")
        created.append(glass)
    # The "dead moon" outside: large dark sphere visible through the window
    moon = Entity(model="sphere",
                  scale=22,
                  position=(w/2 + 35, 7, 0),
                  color=color.rgb(95, 90, 85))
    created.append(moon)
    # Crater detail (small darker spheres on the moon)
    for cx, cy, cz in [(2, 3, 5), (-3, 1, 4), (4, -2, -2), (-1, 4, -5),
                       (3, -3, 3), (-2, -4, -2), (5, 0, 0)]:
        Entity(parent=moon, model="sphere",
               scale=(0.25, 0.18, 0.25),
               position=(cx/22, cy/22, cz/22),
               color=color.rgb(60, 55, 50))
    # A faint distant nebula glow further out
    Entity(model="sphere",
           scale=8,
           position=(w/2 + 60, 14, -20),
           color=color.rgba(120, 90, 140, 100))

    # --- Small porthole on the north wall ---
    port_frame = Entity(model="cube",
                        scale=(1.6, 1.6, 0.20),
                        position=(0, 2.0, d/2 - 0.10),
                        color=color.rgb(80, 85, 100),
                        collider="box")
    created.append(port_frame)
    Entity(parent=port_frame, model="cube",
           scale=(1.20, 1.20, 0.06),
           position=(0, 0, -0.13),
           color=color.rgba(20, 30, 60, 220))
    # Distant star outside the porthole
    Entity(model="sphere",
           scale=0.8,
           position=(0, 3, d/2 + 8),
           color=color.rgba(240, 220, 180, 255))

    # Entry door (sealed - corridor side)
    make_door(created, "z", -d/2 + 0.05, 0, "CORRIDOR",
              side=+1, color_rgb=(72, 70, 60), sealed=True)

    # --- Horseshoe-shaped couch facing the viewport ---
    # Left segment (running along z)
    couch_l = Entity(model="cube", scale=(0.7, 0.45, 3.0),
                    position=(1.0, 0.22, -1.5),
                    color=color.rgb(55, 65, 90),
                    collider="box")
    created.append(couch_l)
    Entity(parent=couch_l, model="cube",
           scale=(0.7, 0.95, 0.20),
           position=(0, 0.50, -1.55),
           color=color.rgb(55, 65, 90))
    # Right segment
    couch_r = Entity(model="cube", scale=(0.7, 0.45, 3.0),
                    position=(1.0, 0.22, 1.5),
                    color=color.rgb(55, 65, 90),
                    collider="box")
    created.append(couch_r)
    Entity(parent=couch_r, model="cube",
           scale=(0.7, 0.95, 0.20),
           position=(0, 0.50, 1.55),
           color=color.rgb(55, 65, 90))
    # Centre segment (facing the window)
    couch_c = Entity(model="cube", scale=(0.7, 0.45, 1.8),
                    position=(-0.5, 0.22, 0),
                    color=color.rgb(55, 65, 90),
                    collider="box")
    created.append(couch_c)
    Entity(parent=couch_c, model="cube",
           scale=(0.20, 0.95, 1.8),
           position=(-0.50, 0.50, 0),
           color=color.rgb(55, 65, 90))
    # Throw pillows
    for pp in [(0.5, 0.50, -2.5), (0.5, 0.50, 2.5), (-0.2, 0.50, 0.5)]:
        Entity(model="cube",
               scale=(0.50, 0.20, 0.40),
               position=pp,
               color=color.rgba(180, 130, 90, 250))
    # Throw blanket on the right couch
    Entity(model="cube",
           scale=(0.75, 0.10, 1.8),
           position=(1.0, 0.50, 1.5),
           color=color.rgba(150, 80, 70, 250))

    # --- A low coffee table in the centre of the horseshoe ---
    coff_table = Entity(model="cube",
                        scale=(0.9, 0.35, 1.4),
                        position=(0.4, 0.17, 0),
                        color=color.rgb(80, 60, 45),
                        collider="box")
    created.append(coff_table)
    # Empty mug
    Entity(parent=coff_table, model="cube",
           scale=(0.15, 0.20, 0.15),
           position=(0.1, 0.27, -0.30),
           color=color.rgb(160, 120, 60))
    # A book
    Entity(parent=coff_table, model="cube",
           scale=(0.30, 0.05, 0.40),
           position=(-0.2, 0.20, 0.20),
           color=color.rgb(140, 60, 60))
    # Felix's folded note on the table beside the book (Note 9)
    note9 = Entity(model="cube", scale=(0.18, 0.04, 0.14),
                   position=(0.5, 0.39, 0.3),
                   color=color.rgba(245, 230, 195, 255),
                   collider="box")
    make_interactable(note9, "Read folded paper", "collect_note",
                      note_id="note_9")
    created.append(note9)

    # --- Felix-Shape at the viewport ---
    felix = FelixShape(position=(w/2 - 1.2, 0, 0),
                       rotation_y=-90, audio=game.audio)
    game.shapes.register(felix)
    created.append(felix)

    # --- Library cart at the south-east corner ---
    cart = Entity(model="cube", scale=(1.0, 1.0, 0.5),
                  position=(w/2 - 2.0, 0.50, -d/2 + 1.0),
                  color=color.rgb(85, 80, 75),
                  collider="box")
    created.append(cart)
    # Top shelf - row of books
    for bi, brgb in enumerate([(140, 60, 60), (60, 80, 130), (80, 110, 70),
                                (180, 140, 80), (140, 80, 130)]):
        Entity(parent=cart, model="cube",
               scale=(0.10, 0.30, 0.40),
               position=(-0.40 + bi * 0.18, 0.55, 0),
               color=color.rgba(*brgb, 255))
    # Middle shelf - more books
    for bi in range(4):
        Entity(parent=cart, model="cube",
               scale=(0.14, 0.26, 0.40),
               position=(-0.35 + bi * 0.22, 0.20, 0),
               color=color.rgba(100 + bi * 20, 80 + bi * 10, 60, 255))
    # Forgotten paperback on top
    book = Entity(model="cube", scale=(0.18, 0.04, 0.24),
                  position=(w/2 - 2.0, 1.06, -d/2 + 1.0),
                  color=color.rgb(190, 160, 80),
                  collider="box")
    make_interactable(book, "Examine paperback", "examine_only",
                      text=("A dog-eared paperback.  The bookmark is "
                            "halfway through.  It's Yuna's.  She told you "
                            "once she would finish it next Sunday.  Next "
                            "Sunday never came."),
                      duration=5.0)
    created.append(book)

    # --- Toy piano on a low side table on the west side ---
    table = Entity(model="cube", scale=(0.9, 0.7, 0.5),
                   position=(-w/2 + 1.4, 0.35, -2.0),
                   color=color.rgb(70, 50, 35),
                   collider="box")
    created.append(table)
    piano = Entity(model="cube", scale=(0.7, 0.10, 0.32),
                   position=(-w/2 + 1.4, 0.75, -2.0),
                   color=color.rgb(20, 20, 25),
                   collider="box")
    created.append(piano)
    # White and black keys
    for i in range(8):
        Entity(parent=piano, model="cube",
               scale=(0.12, 0.30, 0.90),
               position=(-0.48 + i * 0.14, 0.6, 0),
               color=color.rgb(240, 235, 225))
    make_interactable(piano, "Touch the piano", "examine_only",
                      text=("A toy piano.  Felix bought it on a "
                            "supply run for Amara, then forgot to "
                            "send it home.  Two keys are stuck down.  "
                            "They ring a quiet open fifth that doesn't "
                            "resolve."),
                      duration=6.0)

    # --- Coffee / tea bar at the north-west corner ---
    bar = Entity(model="cube", scale=(3.0, 1.0, 0.7),
                 position=(-w/2 + 1.7, 0.50, d/2 - 1.0),
                 color=color.rgb(75, 65, 55),
                 collider="box")
    created.append(bar)
    Entity(parent=bar, model="cube",
           scale=(3.05, 0.06, 0.75),
           position=(0, 0.53, 0),
           color=color.rgb(140, 100, 60))
    # Kettle
    Entity(parent=bar, model="cube",
           scale=(0.30, 0.30, 0.30),
           position=(-1.0, 0.70, 0),
           color=color.rgba(180, 180, 200, 255))
    # Row of mugs
    for mi, mrgb in enumerate([(160, 80, 60), (80, 110, 130),
                                (180, 150, 100), (40, 60, 80)]):
        Entity(parent=bar, model="cube",
               scale=(0.13, 0.18, 0.13),
               position=(0.0 + mi * 0.22, 0.62, -0.1),
               color=color.rgba(*mrgb, 255))
    # Tea tin
    Entity(parent=bar, model="cube",
           scale=(0.20, 0.20, 0.20),
           position=(1.2, 0.65, 0),
           color=color.rgba(90, 50, 50, 255))
    make_interactable(bar, "Look at the tea bar", "examine_only",
                      text=("Kettle's cold.  Four mugs left out, one for "
                            "each crew member who was supposed to be back.  "
                            "Yuna's blue one has tea in it.  She did say "
                            "she left tea in the pot.  She wasn't kidding."),
                      duration=6.0)

    # --- Memorial wall on the west side ---
    mem = Entity(model="cube",
                 scale=(0.06, 1.8, 3.0),
                 position=(-w/2 + 0.10, 1.8, 2.0),
                 color=color.rgb(180, 170, 150),
                 collider="box")
    created.append(mem)
    Entity(parent=mem, model="quad",
           scale=(0.90, 1.60, 2.80),
           position=(0.55, 0, 0),
           rotation=(0, 90, 0),
           color=color.rgba(200, 195, 175, 250))
    make_interactable(mem, "Read the memorial wall", "examine_only",
                      text=("CRESTFALL-9 - DEDICATION\n\n"
                            "In memory of every crew that has rotated "
                            "through this station.  Engraved at the "
                            "top:  'we go out so that others can come "
                            "home.'\n\n"
                            "Below it, names from previous rotations.  "
                            "Twenty-one names total.  Four of them have "
                            "been crossed out by hand.\n\n"
                            "At the very bottom, freshly added in pen:\n"
                            "  VOSS  OKAFOR  PARK  HARGROVE  SATO\n"
                            "All five names have a small dot beside "
                            "them, in your own handwriting, that you "
                            "do not remember making."),
                      duration=12.0)

    # --- A standing lamp by the couch (warm orange glow) ---
    lamp_pole = Entity(model="cube",
                       scale=(0.06, 1.8, 0.06),
                       position=(1.6, 0.90, -3.5),
                       color=color.rgb(60, 55, 45),
                       collider="box")
    created.append(lamp_pole)
    Entity(parent=lamp_pole, model="cube",
           scale=(0.50, 0.20, 0.50),
           position=(0, 0.95, 0),
           color=color.rgb(200, 180, 140))
    Entity(parent=lamp_pole, model="circle",
           scale=3.0,
           rotation=(90, 0, 0),
           position=(0, -0.88, 0),
           color=color.rgba(255, 210, 150, 60))

    # --- A small framed photo on the bar ---
    framed = Entity(parent=bar, model="cube",
                    scale=(0.20, 0.25, 0.06),
                    position=(-1.3, 0.66, 0.2),
                    color=color.rgb(80, 60, 40))
    Entity(parent=framed, model="quad",
           scale=(0.80, 0.85),
           position=(0, 0, -0.55),
           color=color.rgba(220, 200, 170, 255))
    make_interactable(framed, "Look at the framed photo", "examine_only",
                      text=("A small frame propped on the bar.  Inside, "
                            "a much younger photo of you and a boy.  "
                            "Eli.  Maybe ten years old.  Both of you "
                            "are squinting into the sun.  On the back, "
                            "in your own handwriting:  'don't forget "
                            "what he looked like.'"),
                      duration=8.0)

    # Entry door pos
    game.player.position = Vec3(0, 1.6, -d/2 + 0.8)
    game.player.fpc.rotation_y = 0

    # Transition - once note 9 collected, auto-transition after a beat
    def check_transition():
        if game.notes.has("note_9") and not getattr(
                game.state, "_lounge_transition_fired", False):
            game.state._lounge_transition_fired = True
            from ursina import invoke as _invoke
            _invoke(game.transition_to, "act_mess", delay=2.0)
    game.register_ticker(check_transition)

    return created
