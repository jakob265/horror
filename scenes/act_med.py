"""
scenes/act_med.py
-----------------
ACT 2.5 - MEDICAL BAY (NEW).

Between the decon antechamber and the residential corridor.  The decon
scanner flagged Mara's neural anomaly; the med bay is where she finds
the rest of the report.

Layout:
    A 14x12 chamber with an examination alcove (north-east), a row of
    autodoc lockers (west wall), a wash station (south-west), a
    drug-cart on its side, and a small mirror over the wash basin.
    The mirror is interactive - examining it triggers a memory beat.

    A trail of dried blood leads from the autodoc alcove toward the
    north exit.  Mara doesn't remember bleeding.

Note 14 - autodoc transcript (the full neural scan report).
"""

import math

from ursina import Entity, Text, Vec3, color, time

from scenes._chamber import (
    DOOR_H, DOOR_W, build_floor_ceiling, build_wall, make_door,
)
from systems.interaction import make_interactable
from systems import visuals


class _HeartMonitor(Entity):
    """Small wall monitor showing a slow EKG trace."""

    def __init__(self, position, rotation=(0, 0, 0)):
        super().__init__(model="cube", scale=(0.7, 0.45, 0.06),
                         position=position, rotation=rotation,
                         color=color.rgb(25, 30, 40), collider="box")
        self.screen = Entity(parent=self, model="quad",
                             scale=(0.62, 0.36),
                             position=(0, 0, -0.045),
                             color=color.rgba(15, 25, 30, 255))
        self.bars = []
        for i in range(24):
            b = Entity(parent=self.screen, model="quad",
                       scale=(0.02, 0.05),
                       position=(-0.28 + i * 0.024, 0, -0.001),
                       color=color.rgba(60, 220, 120, 255))
            self.bars.append(b)
        self._t = 0.0

    def update(self):
        self._t += time.dt
        for i, b in enumerate(self.bars):
            # Slow flatline with intermittent blip
            phase = self._t * 0.6 + i * 0.12
            blip = max(0, math.sin(phase) - 0.85) * 8.0
            b.position = (b.x, 0.10 * blip, b.z)


def build(game):
    """Medical bay - 14x12 chamber, autodoc + wash station + mirror."""
    created = []

    w, d, h = 14, 12, 3.2
    build_floor_ceiling(created, w, d, h,
                        floor_color=(150, 150, 160),
                        ceiling_color=(50, 55, 65),
                        floor_tex="concrete",
                        center=(0, 0, 0))

    # Solid east + west walls
    for fx in (-w/2, w/2):
        build_wall(created, "x", fx, -d/2, d/2, h,
                   wall_color=(95, 105, 120))
    # South wall (entry from decon) - door gap centered
    build_wall(created, "z", -d/2, -w/2, w/2, h,
               gap_center=0, wall_color=(95, 105, 120))
    # North wall (exit to corridor) - door gap centered
    build_wall(created, "z", d/2, -w/2, w/2, h,
               gap_center=0, wall_color=(95, 105, 120))

    # Doors
    make_door(created, "z", -d/2 + 0.05, 0, "DECON",
              side=+1, color_rgb=(72, 70, 60), sealed=True)
    def open_exit():
        game.state.med_door_open = True
    game.state.med_door_open = False
    make_door(created, "z", d/2 - 0.05, 0, "CORRIDOR",
              side=-1, color_rgb=(72, 70, 60),
              callback=open_exit,
              interactable_label="Open CORRIDOR")

    # --- Autodoc alcove on the east side: examination table ---
    # Table itself
    table = Entity(model="cube", scale=(2.4, 0.85, 1.0),
                   position=(w/2 - 2.4, 0.42, 1.0),
                   color=color.rgb(180, 185, 195),
                   collider="box")
    created.append(table)
    # Mattress
    mat = Entity(model="cube", scale=(2.3, 0.10, 0.95),
                 position=(w/2 - 2.4, 0.90, 1.0),
                 color=color.rgb(220, 220, 230),
                 collider="box")
    created.append(mat)
    # Restraint strap (dangling)
    Entity(parent=mat, model="cube",
           scale=(0.06, 0.30, 0.06),
           position=(0.40, -0.20, 0.50),
           color=color.rgb(80, 60, 50))
    # Robotic arm over the table (autodoc surgical arm)
    arm_base = Entity(model="cube",
                      scale=(0.20, 0.30, 0.20),
                      position=(w/2 - 2.4, h - 0.20, 1.0),
                      color=color.rgb(60, 65, 75),
                      collider="box")
    created.append(arm_base)
    Entity(parent=arm_base, model="cube",
           scale=(0.10, 4.0, 0.10),
           position=(0, -2.0, 0),
           color=color.rgb(140, 150, 160),
           rotation=(0, 0, 20))
    Entity(parent=arm_base, model="cube",
           scale=(0.18, 0.30, 0.18),
           position=(0.7, -2.0, 0),
           color=color.rgb(90, 100, 110))

    # Heart monitor wall-mounted next to the table
    hm = _HeartMonitor(position=(w/2 - 0.13, 1.7, 1.8),
                       rotation=(0, -90, 0))
    created.append(hm)
    game.register_ticker(hm.update)

    # Note 14 - autodoc transcript - on the autodoc table
    note14 = Entity(model="quad", scale=(0.38, 0.50),
                    rotation=(90, 0, 0),
                    position=(w/2 - 2.4, 0.97, 1.4),
                    color=color.rgba(230, 220, 200, 255),
                    collider="box")
    make_interactable(note14, "Read autodoc transcript", "collect_note",
                      note_id="note_14")
    created.append(note14)

    # --- Autodoc locker bank along the west wall ---
    for i, lz in enumerate((-3.5, -1.5, 0.5, 2.5, 4.5)):
        # Locker body
        lock = Entity(model="cube",
                      scale=(0.5, 2.4, 1.4),
                      position=(-w/2 + 0.35, 1.2, lz),
                      color=color.rgb(160, 165, 175),
                      texture=visuals.make_metal_panel(),
                      texture_scale=(0.4, 1.2),
                      collider="box")
        created.append(lock)
        # Handle
        Entity(parent=lock, model="cube",
               scale=(0.20, 0.10, 0.10),
               position=(0.55, 0.05, 0),
               color=color.rgb(40, 45, 55))
        # Door panel inset
        Entity(parent=lock, model="cube",
               scale=(0.10, 2.0, 1.10),
               position=(0.45, 0, 0),
               color=color.rgb(110, 115, 125))
        # Random ones flagged with a red strip (medical waste / hazard)
        if i in (1, 3):
            Entity(parent=lock, model="cube",
                   scale=(0.10, 0.10, 1.0),
                   position=(0.45, 0.85, 0),
                   color=color.rgba(220, 60, 60, 255))

    # --- Drug cart, knocked over in the middle of the floor ---
    cart = Entity(model="cube", scale=(1.4, 0.40, 0.7),
                  position=(-2.0, 0.20, 3.0),
                  rotation=(0, 0, 30),
                  color=color.rgb(130, 140, 150),
                  collider="box")
    created.append(cart)
    # Spilled vials around the cart
    for vx, vz in [(-2.6, 3.4), (-2.3, 3.6), (-1.8, 3.2),
                   (-1.4, 3.5), (-1.9, 2.7)]:
        Entity(model="cube", scale=(0.06, 0.08, 0.04),
               position=(vx, 0.04, vz),
               color=color.rgba(180, 200, 220, 240),
               collider=None).enabled = True
    make_interactable(cart, "Look at the drug cart", "examine_only",
                      text=("A standard meds cart, tipped onto its side.  "
                            "Vials of sedative scattered across the floor.  "
                            "The drawer marked NEUROACTIVE / RESTRICTED "
                            "has been pried open and emptied.  Mara doesn't "
                            "remember coming here."),
                      duration=6.0)

    # --- Wash station on the south-west corner with the mirror ---
    basin = Entity(model="cube", scale=(1.2, 0.85, 0.6),
                   position=(-w/2 + 1.0, 0.42, -d/2 + 1.0),
                   color=color.rgb(180, 180, 190),
                   collider="box")
    created.append(basin)
    Entity(parent=basin, model="cube",
           scale=(1.0, 0.10, 0.45),
           position=(0, 0.45, 0),
           color=color.rgba(60, 80, 100, 255))
    # Faucet
    Entity(parent=basin, model="cube",
           scale=(0.06, 0.25, 0.06),
           position=(0, 0.55, -0.10),
           color=color.rgb(180, 190, 200))
    # Mirror - simple framed quad on the west wall
    mirror_frame = Entity(model="cube", scale=(0.10, 0.9, 0.7),
                          position=(-w/2 + 0.10, 1.8, -d/2 + 1.0),
                          color=color.rgb(90, 95, 105),
                          collider="box")
    created.append(mirror_frame)
    Entity(parent=mirror_frame, model="quad",
           scale=(0.80, 0.60),
           position=(0.55, 0, 0),
           rotation=(0, 90, 0),
           color=color.rgba(120, 140, 170, 240))
    make_interactable(mirror_frame, "Look in the mirror", "examine_only",
                      text=("You look at yourself.  You look tired in a "
                            "way that goes past the body.  There is a "
                            "small red mark behind your left ear that "
                            "you do not remember and do not want to "
                            "remember.  You look away first."),
                      duration=6.0)

    # --- Dried blood trail leading from the autodoc alcove to the
    # north exit door ---
    trail_positions = [(w/2 - 2.6, 1.8), (w/2 - 3.8, 2.4),
                       (w/2 - 5.0, 3.0), (w/2 - 5.4, 3.8),
                       (w/2 - 5.0, 4.6), (w/2 - 4.0, 5.2),
                       (w/2 - 2.4, 5.4), (-0.6, 5.6),
                       (0, d/2 - 0.5)]
    for tx, tz in trail_positions:
        Entity(model="quad", scale=(0.30, 0.22),
               rotation=(90, 0, 0),
               position=(tx, 0.02, tz),
               color=color.rgba(100, 25, 25, 200))

    # --- A surgical caddy at the back of the room with empty syringes ---
    caddy = Entity(model="cube", scale=(0.8, 0.6, 0.5),
                   position=(2.5, 0.30, 4.0),
                   color=color.rgb(90, 95, 105),
                   collider="box")
    created.append(caddy)
    Entity(parent=caddy, model="cube",
           scale=(0.70, 0.04, 0.40),
           position=(0, 0.32, 0),
           color=color.rgb(180, 180, 190))
    # Three empty syringes on top
    for sx in (-0.18, 0, 0.18):
        Entity(parent=caddy, model="cube",
               scale=(0.04, 0.06, 0.20),
               position=(sx, 0.36, 0),
               color=color.rgba(220, 230, 240, 250))
    make_interactable(caddy, "Examine the caddy", "examine_only",
                      text=("A surgical caddy with three empty syringes "
                            "and one sealed.  The label on the sealed "
                            "one is in your own handwriting.  It just "
                            "says:  IF YOU READ THIS, USE THIS."),
                      duration=6.0)

    # --- Slim overhead light strips ---
    for tx in (-4, 0, 4):
        Entity(model="cube",
               scale=(0.4, 0.04, 4.0),
               position=(tx, h - 0.10, 0),
               color=color.rgba(220, 235, 250, 240))

    # --- Wall posters (anatomy chart + biohazard) ---
    poster = Entity(model="cube", scale=(0.04, 1.0, 0.7),
                    position=(-w/2 + 0.10, 1.7, 4.0),
                    color=color.rgb(240, 240, 230),
                    collider="box")
    created.append(poster)
    Entity(parent=poster, model="quad",
           scale=(0.90, 0.65),
           position=(0.55, 0, 0),
           rotation=(0, 90, 0),
           color=color.rgba(200, 220, 230, 240))
    make_interactable(poster, "Read anatomy chart", "examine_only",
                      text=("Standard CNS anatomy chart.  Someone has "
                            "circled the brainstem in red marker and "
                            "written next to it:  HERE.  THE FREQUENCY "
                            "LIVES HERE."),
                      duration=5.0)

    # Player spawn
    game.player.position = Vec3(0, 1.6, -d/2 + 0.8)
    game.player.fpc.rotation_y = 0

    def check_transition():
        if game.state.med_door_open and game.player.position.z > d/2 + 0.1:
            game.transition_to("act3")
    game.register_ticker(check_transition)

    return created
