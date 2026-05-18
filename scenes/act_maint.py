"""
scenes/act_maint.py
-------------------
ACT 8.5 - MAINTENANCE CRAWL (NEW).

Between the bridge and the approach corridor.  A claustrophobic service
shaft running between the comms deck and the array antechamber.  Lower
ceiling than the rest of the station (2.2 m).  Exposed cabling, conduit
bundles, sparking junction boxes.  Through grates in the floor the
player can see the bottom of the array tower one deck down, glowing
faintly.

A previous technician (Sato, in retrospect) scratched a warning into a
service panel halfway down (Note 18).

A sparking junction box every few meters throws a faint flicker.
"""

import math
import random

from ursina import Entity, Text, Vec3, color, time

from scenes._chamber import (
    DOOR_H, DOOR_W, build_floor_ceiling, build_wall, make_door,
)
from systems.interaction import make_interactable
from systems import visuals


class _Sparker(Entity):
    """Sparking junction box - cycles between dim and a brief bright spark."""

    def __init__(self, position):
        super().__init__(model="cube",
                         scale=(0.30, 0.30, 0.20),
                         position=position,
                         color=color.rgb(50, 55, 65),
                         collider="box")
        self.glow = Entity(parent=self, model="cube",
                           scale=(0.15, 0.10, 0.05),
                           position=(0, 0, -0.13),
                           color=color.rgba(255, 220, 80, 80))
        self._t = random.uniform(0, 5)
        self._next = random.uniform(2.5, 6.0)
        self._sparking = False
        self._spark_t = 0.0

    def update(self):
        self._t += time.dt
        if not self._sparking:
            if self._t >= self._next:
                self._sparking = True
                self._spark_t = 0.0
                self.glow.color = color.rgba(255, 240, 160, 255)
        else:
            self._spark_t += time.dt
            if self._spark_t >= 0.18:
                self._sparking = False
                self._t = 0.0
                self._next = random.uniform(2.5, 6.0)
                self.glow.color = color.rgba(255, 220, 80, 60)


def build(game):
    """Tight maintenance crawl between bridge and approach."""
    created = []

    # Narrow, low.  Wider than approach but with a much lower ceiling.
    w, d, h = 4.5, 20, 2.2
    build_floor_ceiling(created, w, d, h,
                        floor_color=(50, 55, 65),
                        ceiling_color=(25, 30, 40),
                        floor_tex="grating",
                        center=(0, 0, 0))

    for fx in (-w/2, w/2):
        build_wall(created, "x", fx, -d/2, d/2, h,
                   wall_color=(45, 55, 70))
    build_wall(created, "z", -d/2, -w/2, w/2, h,
               gap_center=0, wall_color=(45, 55, 70))
    build_wall(created, "z", d/2, -w/2, w/2, h,
               gap_center=0, wall_color=(45, 55, 70))

    # Doors
    make_door(created, "z", -d/2 + 0.05, 0, "BRIDGE",
              side=+1, color_rgb=(72, 70, 60), sealed=True)
    def open_exit():
        game.state.maint_door_open = True
    game.state.maint_door_open = False
    make_door(created, "z", d/2 - 0.05, 0, "APPROACH",
              side=-1, color_rgb=(72, 70, 60),
              callback=open_exit,
              interactable_label="Open APPROACH")

    # --- Conduit / pipe bundles along both side walls ---
    for fx in (-w/2 + 0.30, w/2 - 0.30):
        # Three pipes at different heights
        for py, prgb in [(0.40, (140, 110, 60)),
                         (1.10, (60, 80, 110)),
                         (1.70, (110, 60, 60))]:
            Entity(model="cube",
                   scale=(0.16, 0.16, d - 1.0),
                   position=(fx, py, 0),
                   color=color.rgb(*prgb))
            # Bracket clamps every couple meters
            for cz in range(-9, 10, 3):
                Entity(model="cube",
                       scale=(0.22, 0.22, 0.10),
                       position=(fx, py, cz),
                       color=color.rgb(60, 60, 70))

    # --- Cable runs across the ceiling ---
    for cz in range(-9, 10, 2):
        Entity(model="cube",
               scale=(w - 0.2, 0.06, 0.18),
               position=(0, h - 0.05, cz),
               color=color.rgb(30, 35, 45))
        # A few cables drooping down
        if cz % 4 == 0:
            Entity(model="cube",
                   scale=(0.05, 0.35, 0.05),
                   position=(0.7, h - 0.20, cz),
                   color=color.rgb(40, 40, 50))

    # --- Floor grates revealing the array tower glow below ---
    for fz in (-7, -3, 3, 7):
        Entity(model="quad",
               scale=(1.4, 1.0),
               rotation=(90, 0, 0),
               position=(0, 0.02, fz),
               color=color.rgba(140, 180, 220, 130))
        # Faint warm undertone (the array's pulse)
        Entity(model="circle",
               scale=1.6,
               rotation=(90, 0, 0),
               position=(0, 0.03, fz),
               color=color.rgba(220, 170, 120, 60))

    # --- Sparking junction boxes along the walls ---
    for sx, sz in [(-w/2 + 0.20, -6), (w/2 - 0.20, -1),
                   (-w/2 + 0.20, 4), (w/2 - 0.20, 9)]:
        sp = _Sparker(position=(sx, 1.5, sz))
        created.append(sp)
        game.register_ticker(sp.update)

    # --- Note 18 - the scratched warning, partway down ---
    # Service panel at x = -w/2 + 0.10, z = 1.0
    panel = Entity(model="cube",
                   scale=(0.06, 0.50, 0.50),
                   position=(-w/2 + 0.10, 1.20, 1.0),
                   color=color.rgb(40, 50, 65),
                   collider="box")
    created.append(panel)
    Entity(parent=panel, model="quad",
           scale=(0.80, 0.80),
           position=(0.55, 0, 0),
           rotation=(0, 90, 0),
           color=color.rgba(60, 70, 90, 250))
    make_interactable(panel, "Read scratched panel", "collect_note",
                      note_id="note_18")

    # --- Toolbox left in the middle of the floor ---
    toolbox = Entity(model="cube",
                     scale=(0.55, 0.30, 0.30),
                     position=(0.6, 0.15, -2.5),
                     color=color.rgb(180, 130, 60),
                     collider="box")
    created.append(toolbox)
    # Wrench on top
    Entity(parent=toolbox, model="cube",
           scale=(0.06, 0.02, 0.40),
           position=(0, 0.17, 0),
           color=color.rgb(180, 185, 195))
    make_interactable(toolbox, "Open the toolbox", "examine_only",
                      text=("A station-issue maintenance kit.  The lid "
                            "is open.  Most of the tools are gone.  The "
                            "label on the inside lid says: K. SATO, in "
                            "neat block letters that match the duty "
                            "roster."),
                      duration=6.0)

    # --- A small service ladder going down into a grate (visual only) ---
    ladder_x, ladder_z = -1.4, -5.5
    # Ladder rails
    for dx in (-0.20, 0.20):
        Entity(model="cube",
               scale=(0.05, 1.8, 0.05),
               position=(ladder_x + dx, 0.90, ladder_z),
               color=color.rgb(140, 140, 150),
               collider="box")
    # Rungs
    for ry in (0.20, 0.55, 0.90, 1.25, 1.60):
        Entity(model="cube",
               scale=(0.50, 0.04, 0.05),
               position=(ladder_x, ry, ladder_z),
               color=color.rgb(140, 140, 150))
    # Hole in the floor next to the ladder (a dark quad)
    Entity(model="quad",
           scale=(0.7, 0.7),
           rotation=(90, 0, 0),
           position=(ladder_x, 0.02, ladder_z + 0.7),
           color=color.rgba(20, 30, 40, 255))

    # --- A red blinking warning light at the far end ---
    warn_box = Entity(model="cube",
                      scale=(0.30, 0.20, 0.30),
                      position=(0, h - 0.20, d/2 - 1.5),
                      color=color.rgb(40, 40, 50))
    created.append(warn_box)
    warn_light = Entity(parent=warn_box, model="sphere",
                        scale=(0.6, 0.6, 0.6),
                        position=(0, -0.30, 0),
                        color=color.rgba(220, 50, 50, 255))

    class _Pulse(Entity):
        """Just animate the warning light pulse."""
        def __init__(self_):
            super().__init__()
            self_._t = 0.0
        def update(self_):
            self_._t += time.dt
            v = 0.4 + 0.6 * (0.5 + 0.5 * math.sin(self_._t * 3.5))
            warn_light.color = color.rgba(int(220 * v), int(40 * v),
                                          int(40 * v), 255)

    p = _Pulse()
    created.append(p)
    game.register_ticker(p.update)

    # --- Periodic faint floor lights along the corridor (dim) ---
    for tz in range(-8, 9, 2):
        Entity(model="quad",
               scale=(1.2, 0.16),
               rotation=(90, 0, 0),
               position=(0, 0.02, tz),
               color=color.rgba(140, 160, 200, 70))

    # Player spawn (just inside south door)
    game.player.position = Vec3(0, 1.6, -d/2 + 0.8)
    game.player.fpc.rotation_y = 0

    def check_transition():
        if game.state.maint_door_open and \
                game.player.position.z > d/2 + 0.1:
            game.transition_to("act9")
    game.register_ticker(check_transition)

    return created
