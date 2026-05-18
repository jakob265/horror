"""
scenes/act7_engineering.py
--------------------------
ACT 7 - ENGINEERING / POWER CORE.

The reactor housing.  A maintenance recorder near the calibration panel
contains Hargrove's verbatim 'I did this' confession (Note 11).  The
power core hums - the same hum Mara has been hearing under everything.

Revamped (Phase 2):  the space is now a proper engineering bay - 18x20,
the reactor cylinder running floor to ceiling at the centre, a metal
catwalk ringing the core, tool benches and coolant tanks along the
walls, a wall of secondary panels.  The corner plant Hargrove described
on the tape is still here, every leaf pointing east.
"""

import math
import random

from ursina import Entity, Text, Vec3, color, time
from ursina.models.procedural.cylinder import Cylinder

from scenes._chamber import (
    DOOR_H, DOOR_W, build_floor_ceiling, build_wall, make_door,
)
from systems.interaction import make_interactable
from systems import visuals


class _PulsingCore(Entity):
    """Slowly-breathing reactor core sphere."""

    def __init__(self, position):
        super().__init__(model="sphere", scale=2.4,
                         position=position,
                         color=color.rgba(120, 160, 200, 255))
        self._t = 0.0

    def update(self):
        self._t += time.dt
        v = 0.5 + 0.5 * math.sin(self._t * 0.7)
        b = int(140 + 80 * v)
        self.color = color.rgba(110, 160, b, 255)


def _build_coolant_tank(created, x, z, *, label="COOL"):
    """Vertical coolant tank with a label and gauge."""
    base = Entity(model="cube",
                  scale=(0.8, 0.20, 0.8),
                  position=(x, 0.10, z),
                  color=color.rgb(60, 65, 75),
                  collider="box")
    created.append(base)
    body = Entity(model=Cylinder(resolution=16, radius=0.5, height=1.0),
                  scale=(0.8, 3.0, 0.8),
                  position=(x, 1.7, z),
                  color=color.rgb(180, 180, 190),
                  texture=visuals.make_metal_panel(),
                  texture_scale=(1.5, 2.0),
                  collider="box")
    created.append(body)
    # Top cap
    Entity(parent=body, model="sphere",
           scale=(1.0, 0.4, 1.0),
           position=(0, 0.5, 0),
           color=color.rgb(140, 145, 155))
    # Gauge
    Entity(parent=body, model="cube",
           scale=(0.10, 0.30, 0.30),
           position=(0, 0.20, -0.51),
           color=color.rgb(40, 40, 50))
    Entity(parent=body, model="quad",
           scale=(0.25, 0.25),
           position=(0, 0.20, -0.57),
           color=color.rgba(160, 220, 180, 255))
    # Label band
    Entity(parent=body, model="cube",
           scale=(0.92, 0.20, 0.92),
           position=(0, -0.20, 0),
           color=color.rgb(220, 180, 30))
    Text(parent=body, text=label,
         position=(0, -0.20, -0.55),
         origin=(0, 0), scale=5,
         color=color.rgb(30, 25, 20), font="VeraMono.ttf")
    return body


def build(game):
    """Engineering chamber with central reactor, catwalk, tanks, benches."""
    created = []

    w, d, h = 18, 20, 4.6
    build_floor_ceiling(created, w, d, h,
                        floor_color=(70, 75, 80),
                        ceiling_color=(35, 40, 45),
                        floor_tex="concrete",
                        center=(0, 0, 0))

    for fx in (-w/2, w/2):
        build_wall(created, "x", fx, -d/2, d/2, h,
                   wall_color=(70, 80, 95))
    build_wall(created, "z", -d/2, -w/2, w/2, h,
               gap_center=0, wall_color=(70, 80, 95))
    build_wall(created, "z", d/2, -w/2, w/2, h,
               gap_center=0, wall_color=(70, 80, 95))

    # Doors
    make_door(created, "z", -d/2 + 0.05, 0, "HYDRO",
              side=+1, color_rgb=(72, 70, 60), sealed=True)
    def open_exit():
        game.state.engineering_door_open = True
    game.state.engineering_door_open = False
    make_door(created, "z", d/2 - 0.05, 0, "STORAGE",
              side=-1, color_rgb=(72, 70, 60),
              callback=open_exit,
              interactable_label="Open STORAGE")

    # --- Central reactor housing - large cylinder ---
    housing = Entity(
        model=Cylinder(resolution=24, radius=0.5, height=1.0),
        scale=(3.2, h - 0.4, 3.2),
        position=(0, (h - 0.4) / 2, 0),
        color=color.rgb(60, 65, 75),
        texture=visuals.make_metal_panel(),
        texture_scale=(2.5, 2.5),
        collider="box")
    created.append(housing)
    # Reactor band ring at mid-height
    Entity(parent=housing, model=Cylinder(resolution=24, radius=0.55,
                                          height=0.20),
           scale=(1.0, 1.0, 1.0),
           position=(0, 0, 0),
           color=color.rgba(220, 180, 30, 255))
    # Pulsing core sphere above the housing
    core = _PulsingCore(position=(0, h - 1.4, 0))
    created.append(core)
    game.register_ticker(core.update)
    # Floor light pool under the core
    Entity(model="circle", scale=8.0,
           rotation=(90, 0, 0),
           position=(0, 0.02, 0),
           color=color.rgba(120, 160, 200, 60))

    # --- Catwalk ring around the reactor at y=1.4 ---
    # We build it as four straight cube segments forming a square ring
    ring_inner = 2.4
    ring_outer = 4.0
    ring_y = 1.40
    # North + south rails
    for cz in (-ring_outer, ring_outer):
        Entity(model="cube",
               scale=(2 * ring_outer + 0.4, 0.20, 0.6),
               position=(0, ring_y, cz),
               color=color.rgb(85, 90, 100),
               texture=visuals.make_grating(),
               texture_scale=(4, 1))
    # East + west rails
    for cx in (-ring_outer, ring_outer):
        Entity(model="cube",
               scale=(0.6, 0.20, 2 * ring_outer + 0.4),
               position=(cx, ring_y, 0),
               color=color.rgb(85, 90, 100),
               texture=visuals.make_grating(),
               texture_scale=(1, 4))
    # Hand rails on the outside of the catwalk
    for cx, cz, sx, sz in [(0, -ring_outer - 0.3, 2 * ring_outer + 0.4, 0.05),
                            (0, ring_outer + 0.3, 2 * ring_outer + 0.4, 0.05),
                            (-ring_outer - 0.3, 0, 0.05, 2 * ring_outer + 0.4),
                            (ring_outer + 0.3, 0, 0.05, 2 * ring_outer + 0.4)]:
        Entity(model="cube",
               scale=(sx, 1.0, sz),
               position=(cx, ring_y + 0.6, cz),
               color=color.rgb(180, 150, 40))

    # --- Calibration maintenance panel on the west wall ---
    panel = Entity(model="cube", scale=(1.5, 1.1, 0.10),
                   position=(-w/2 + 0.10, 1.5, -4.0),
                   color=color.rgb(60, 70, 80),
                   collider="box")
    created.append(panel)
    screen = Entity(parent=panel, model="quad",
                    scale=(1.30, 0.90),
                    position=(0, 0, -0.55),
                    color=color.rgba(15, 30, 50, 255))
    Text(parent=screen,
         text="CALIBRATION 442-K\n\nARRAY  =  0.7 P-UNITS\nSTATUS =  ACTIVE\n\n*** READ TAPE ***",
         position=(0, 0, -0.01), origin=(0, 0), scale=3,
         color=color.rgb(200, 230, 250), font="VeraMono.ttf")

    # Maintenance tape (Note 11) on a shelf below the panel
    tape = Entity(model="cube", scale=(0.20, 0.10, 0.14),
                  position=(-w/2 + 0.55, 0.85, -4.0),
                  color=color.rgba(40, 40, 45, 255),
                  collider="box")
    make_interactable(tape, "Play tape", "collect_note",
                      note_id="note_11")
    created.append(tape)

    # --- Two more secondary panels along the west wall ---
    for panel_z, ptext in [(-1.0, ("PROPULSION\n"
                                   "  THRUST    0.0 kN\n"
                                   "  STATUS    STBY")),
                            (2.0, ("LIFE SUPPORT\n"
                                   "  O2        NOMINAL\n"
                                   "  CO2 SCR.  NOMINAL\n"
                                   "  THERMAL   NOMINAL"))]:
        p2 = Entity(model="cube", scale=(1.5, 1.0, 0.10),
                    position=(-w/2 + 0.10, 1.5, panel_z),
                    color=color.rgb(55, 65, 75),
                    collider="box")
        created.append(p2)
        sc = Entity(parent=p2, model="quad",
                    scale=(1.30, 0.80),
                    position=(0, 0, -0.55),
                    color=color.rgba(15, 30, 40, 255))
        Text(parent=sc, text=ptext,
             position=(0, 0, -0.01), origin=(0, 0), scale=3,
             color=color.rgb(160, 220, 180), font="VeraMono.ttf")

    # --- Coolant tanks along the east wall ---
    for tz, lbl in [(-5, "COOL A"), (-1, "COOL B"),
                    (3, "COOL C"), (6, "COOL D")]:
        _build_coolant_tank(created, w/2 - 1.0, tz, label=lbl)

    # --- Pipes running along the east wall connecting the tanks ---
    Entity(model="cube",
           scale=(0.20, 0.20, 13),
           position=(w/2 - 0.30, 0.40, 0),
           color=color.rgb(140, 110, 60))
    Entity(model="cube",
           scale=(0.20, 0.20, 13),
           position=(w/2 - 0.50, 0.80, 0),
           color=color.rgb(60, 80, 110))

    # --- Tool bench on the north-west, beside the maintenance panel ---
    bench = Entity(model="cube", scale=(2.0, 0.85, 0.7),
                   position=(-w/2 + 1.6, 0.42, 5.5),
                   color=color.rgb(80, 80, 90),
                   collider="box")
    created.append(bench)
    # Wrench
    Entity(parent=bench, model="cube",
           scale=(0.06, 0.04, 0.55),
           position=(-0.4, 0.45, 0),
           color=color.rgb(180, 185, 195))
    # Multi-meter
    Entity(parent=bench, model="cube",
           scale=(0.30, 0.10, 0.20),
           position=(0.2, 0.48, 0),
           color=color.rgb(220, 180, 60))
    # Spool of wire
    Entity(parent=bench, model="cube",
           scale=(0.24, 0.20, 0.24),
           position=(0.7, 0.53, 0.1),
           color=color.rgb(180, 50, 40))
    make_interactable(bench, "Look at the tool bench", "examine_only",
                      text=("Hargrove's tool bench.  Wrench, multimeter, "
                            "spool of red wire.  A small framed photo at "
                            "the back: two children, smiling, one "
                            "holding a fishing pole.  Behind the photo "
                            "a folded note that reads 'do better.'"),
                      duration=6.0)

    # --- Hargrove's lonely chair beside the panel ---
    chair = Entity(model="cube", scale=(0.5, 0.4, 0.5),
                   position=(-w/2 + 1.8, 0.20, -3.6),
                   color=color.rgb(40, 45, 55),
                   collider="box")
    created.append(chair)
    # Backrest
    Entity(parent=chair, model="cube",
           scale=(1.0, 1.4, 0.10),
           position=(0, 0.9, -0.45),
           color=color.rgb(40, 45, 55))
    # A coat draped over it
    Entity(parent=chair, model="cube",
           scale=(0.9, 0.90, 0.20),
           position=(0, 0.30, -0.20),
           color=color.rgb(80, 60, 40))

    # --- "Plant in the corner" from Hargrove's tape - leaves point east ---
    corner_pot = Entity(model="cube", scale=(0.35, 0.35, 0.35),
                        position=(w/2 - 1.5, 0.17, d/2 - 1.2),
                        color=color.rgb(120, 100, 80),
                        collider="box")
    created.append(corner_pot)
    stalk = Entity(parent=corner_pot, model="cube",
                   scale=(0.08, 2.4, 0.08),
                   position=(0, 1.2, 0),
                   color=color.rgb(70, 100, 65),
                   rotation=(0, 0, 18))  # leaning east toward the array
    Entity(parent=stalk, model="sphere",
           scale=(2.6, 1.2, 1.8),
           position=(0, 0.6, 0.6),
           color=color.rgb(80, 130, 80))
    # Smaller leaves all pointing one direction
    for ly, lr in [(0.30, 22), (0.60, 18), (-0.20, 25)]:
        l = Entity(parent=stalk, model="sphere",
                   scale=(0.9, 0.4, 0.6),
                   position=(0, ly, 0.30),
                   color=color.rgb(70, 110, 75),
                   rotation=(0, 0, lr))
    make_interactable(corner_pot, "Look at the plant", "examine_only",
                      text=("Every leaf points east.  Toward the array.  "
                            "Even the ones in shadow."),
                      duration=4.0)

    # --- Conduit and cable runs on the ceiling ---
    for tz in range(-8, 9, 4):
        Entity(model="cube",
               scale=(w - 1, 0.10, 0.15),
               position=(0, h - 0.20, tz),
               color=color.rgb(50, 60, 75))

    # --- Slow rotating warning light on the ceiling near the entry ---
    warn_box = Entity(model="cube",
                      scale=(0.30, 0.18, 0.30),
                      position=(0, h - 0.15, -d/2 + 1.5),
                      color=color.rgb(40, 40, 50))
    created.append(warn_box)
    warn_bulb = Entity(parent=warn_box, model="sphere",
                       scale=(0.7, 0.6, 0.7),
                       position=(0, -0.20, 0),
                       color=color.rgba(220, 180, 60, 255))

    class _RotatingWarn(Entity):
        def __init__(self_):
            super().__init__()
            self_._t = 0.0
        def update(self_):
            self_._t += time.dt
            v = 0.4 + 0.6 * (0.5 + 0.5 * math.sin(self_._t * 1.6))
            warn_bulb.color = color.rgba(int(220 * v), int(180 * v),
                                          int(60 * v), 255)
    rw = _RotatingWarn()
    created.append(rw)
    game.register_ticker(rw.update)

    # --- A small alcove with an emergency exit sign on the east wall ---
    Entity(model="cube",
           scale=(0.06, 0.30, 0.80),
           position=(w/2 - 0.10, 2.4, 6.5),
           color=color.rgb(80, 220, 100))
    Text(parent=Entity(position=(w/2 - 0.18, 2.4, 6.5),
                       rotation=(0, -90, 0)),
         text="EXIT",
         origin=(0, 0), scale=6,
         color=color.rgb(20, 30, 20), font="VeraMono.ttf")

    # Player spawn
    game.player.position = Vec3(0, 1.6, -d/2 + 0.8)
    game.player.fpc.rotation_y = 0

    def check_transition():
        if game.state.engineering_door_open and \
                game.player.position.z > d/2 + 0.1:
            game.transition_to("act_storage")
    game.register_ticker(check_transition)

    return created
