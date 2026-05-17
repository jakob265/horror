"""
scenes/act_storage.py
---------------------
ACT 7.5 - SECONDARY CRYO STORAGE (NEW).

Between engineering and the bridge.  A long storage chamber where the
station's *backup* cryo pods are kept - 10 pods in two rows of 5.

This is where Mara finds out the awful thing:  the array is not
broadcasting outward to an alien intelligence.  It is *receiving* the
crew's signatures and storing them in these pods.  Most of the pods
are dark and empty.  Three are still cycling: SATO (technician),
OKAFOR (Felix), and HARGROVE.  Their pods are sealed.  The lights on
them slowly pulse in sync with the array hum.

One pod near the back is the slot reserved for VOSS, M.  It is open.
Waiting.

Note 17 - the storage technician's last log (Sato's voice).
"""

import math

from ursina import Entity, Text, Vec3, color, time

from scenes._chamber import (
    DOOR_H, DOOR_W, build_floor_ceiling, build_wall, make_door,
)
from systems.interaction import make_interactable
from systems import visuals


class _PodLight(Entity):
    """A pod-status indicator that slowly breathes between dim and bright."""

    def __init__(self, position, base_rgb=(60, 220, 180), period=4.0,
                 phase=0.0):
        super().__init__(model="cube",
                         scale=(0.12, 0.04, 0.04),
                         position=position,
                         color=color.rgba(*base_rgb, 255))
        self.base_rgb = base_rgb
        self.period = period
        self._t = phase

    def update(self):
        self._t += time.dt
        v = 0.4 + 0.6 * (0.5 + 0.5 * math.sin(self._t * (2 * math.pi
                                                         / self.period)))
        r = int(self.base_rgb[0] * v)
        g = int(self.base_rgb[1] * v)
        b = int(self.base_rgb[2] * v)
        self.color = color.rgba(r, g, b, 255)


def _build_pod(created, game, x, z, *, label, occupied=True, color_rgb=None,
               opened=False):
    """Build one cryo pod at (x, z).  Returns the pod entity."""
    # Pod body - a horizontal capsule made from a cube + two end caps
    pod = Entity(model="cube",
                 scale=(1.0, 0.9, 2.6),
                 position=(x, 0.50, z),
                 color=color.rgb(70, 80, 95),
                 texture=visuals.make_metal_panel(),
                 texture_scale=(0.6, 1.6),
                 collider="box")
    created.append(pod)
    # Rounded end caps
    for dz in (-1.30, 1.30):
        Entity(parent=pod, model="sphere",
               scale=(0.7, 0.7, 0.4),
               position=(0, 0, dz),
               color=color.rgb(60, 70, 85))
    # Window (the cold pane on top) - quad tilted up slightly
    if not opened:
        Entity(parent=pod, model="cube",
               scale=(0.65, 0.10, 1.8),
               position=(0, 0.50, 0),
               color=color.rgba(140, 200, 230, 220) if occupied
               else color.rgba(50, 60, 80, 220))
    else:
        # Opened lid lifted off
        lid = Entity(model="cube",
                     scale=(0.95, 0.10, 2.40),
                     position=(x, 1.45, z - 0.6),
                     rotation=(-22, 0, 0),
                     color=color.rgb(60, 70, 85),
                     collider="box")
        created.append(lid)
        # Inner glow (the empty waiting slot - faint cyan)
        Entity(model="cube",
               scale=(0.80, 0.04, 2.10),
               position=(x, 0.96, z),
               color=color.rgba(80, 160, 200, 255))
    # Name plate on the side
    plate = Entity(parent=pod, model="cube",
                   scale=(0.04, 0.18, 0.7),
                   position=(0.52, 0.10, -0.5),
                   color=color.rgb(220, 200, 160))
    Text(parent=plate, text=label,
         position=(0.55, 0, 0),
         rotation=(0, 90, 0),
         origin=(0, 0), scale=6,
         color=color.rgb(40, 30, 20), font="VeraMono.ttf")
    # Status light on the lid
    light_rgb = color_rgb if color_rgb else (
        (180, 60, 60) if not occupied and not opened else (60, 220, 180))
    light = _PodLight(position=(x + 0.30, 0.96, z + 1.10),
                      base_rgb=light_rgb,
                      phase=(z * 0.4 + x * 0.3))
    if occupied and not opened:
        game.register_ticker(light.update)
    created.append(light)
    # A small interactable readout
    body = ""
    if opened:
        body = ("Pod V-05 (assigned to:  VOSS, M.)\n\n"
                "STATUS:  STAGED.  AWAITING SUBJECT.\n"
                "Sample chamber:  primed.\n"
                "Neural lock:  ARMED.\n\n"
                "Last technician note:\n"
                "  'pod prepped per array calibration target.\n"
                "   subject scheduled for cycle 0084.\n"
                "   - Sato.'")
    elif occupied and label == "OKAFOR":
        body = ("Pod V-02 - OKAFOR, F.\n\n"
                "STATUS:  CYCLING (slow).\n"
                "Subharmonic lock:  STABLE.  0.7 P-units.\n"
                "Neural waveform:  matches array transmission.\n\n"
                "Through the rime on the window you can see\n"
                "him.  His eyes are open.  He is not blinking.")
    elif occupied and label == "HARGROVE":
        body = ("Pod V-03 - HARGROVE, R.\n\n"
                "STATUS:  CYCLING (slow).\n"
                "Subharmonic lock:  STABLE.  0.7 P-units.\n"
                "Neural waveform:  matches array transmission.\n\n"
                "He looks asleep.  He does not look at peace.")
    elif occupied and label == "PARK":
        body = ("Pod V-04 - PARK, Y.\n\n"
                "STATUS:  CYCLING (slow).\n"
                "Subharmonic lock:  STABLE.  0.7 P-units.\n"
                "Neural waveform:  matches array transmission.\n\n"
                "Her mouth is slightly open.  Like she was\n"
                "in the middle of saying something.")
    elif occupied and label == "SATO":
        body = ("Pod V-01 - SATO, K.\n\n"
                "STATUS:  CYCLING (slow).\n"
                "Subharmonic lock:  UNSTABLE.  drift +0.02 P-units.\n"
                "Neural waveform:  partial match.\n\n"
                "Sato was the station technician.  You do not\n"
                "remember him at all.  His face is unfamiliar.\n"
                "His name is on the duty roster in your own\n"
                "handwriting.")
    else:
        body = (f"Pod {label}\n\n"
                "STATUS:  DARK.  Empty.\n"
                "No subject record.")
    make_interactable(pod, "Read pod readout", "examine_only",
                      text=body, duration=8.0)
    return pod


def build(game):
    """Secondary cryo storage - rows of pods, one open and waiting."""
    created = []

    w, d, h = 14, 22, 3.6
    build_floor_ceiling(created, w, d, h,
                        floor_color=(45, 55, 70),
                        ceiling_color=(20, 25, 35),
                        floor_tex="grating",
                        center=(0, 0, 0))

    for fx in (-w/2, w/2):
        build_wall(created, "x", fx, -d/2, d/2, h,
                   wall_color=(55, 65, 85))
    build_wall(created, "z", -d/2, -w/2, w/2, h,
               gap_center=0, wall_color=(55, 65, 85))
    build_wall(created, "z", d/2, -w/2, w/2, h,
               gap_center=0, wall_color=(55, 65, 85))

    # Doors
    make_door(created, "z", -d/2 + 0.05, 0, "ENGINEERING",
              side=+1, color_rgb=(72, 70, 60), sealed=True)
    def open_exit():
        game.state.storage_door_open = True
    game.state.storage_door_open = False
    make_door(created, "z", d/2 - 0.05, 0, "BRIDGE",
              side=-1, color_rgb=(72, 70, 60),
              callback=open_exit,
              interactable_label="Open BRIDGE")

    # --- Two rows of 5 pods on either side of a central aisle ---
    # West row at x = -3, east row at x = +3.  Pods spaced 4 units apart
    # in z from z = -8 to z = 8.
    west_x, east_x = -3.5, 3.5
    pod_zs = [-8, -4, 0, 4, 8]

    # Layout per pod:
    # West side (front to back):  V-06 dark, V-07 dark, V-08 dark, V-09 dark, V-10 dark
    # East side (front to back):  V-01 SATO, V-02 OKAFOR, V-03 HARGROVE, V-04 PARK, V-05 VOSS (open)
    west_labels = ["V-06", "V-07", "V-08", "V-09", "V-10"]
    east_labels = ["SATO", "OKAFOR", "HARGROVE", "PARK", "VOSS"]
    for i, pz in enumerate(pod_zs):
        _build_pod(created, game, west_x, pz, label=west_labels[i],
                   occupied=False)
    for i, pz in enumerate(pod_zs):
        lbl = east_labels[i]
        if lbl == "VOSS":
            _build_pod(created, game, east_x, pz, label=lbl,
                       occupied=False, opened=True)
        else:
            _build_pod(created, game, east_x, pz, label=lbl,
                       occupied=True)

    # --- Console at the south end with the technician's tape (note 17) ---
    console = Entity(model="cube",
                     scale=(2.0, 1.0, 0.8),
                     position=(0, 0.50, -d/2 + 1.4),
                     color=color.rgb(50, 60, 75),
                     collider="box")
    created.append(console)
    scr = Entity(parent=console, model="quad",
                 scale=(1.4, 0.7),
                 position=(0, 0.30, -0.41),
                 color=color.rgba(20, 40, 50, 255))
    Text(parent=scr,
         text=("CRYO STORAGE - CRESTFALL-9\n"
               "10 pods.  4 cycling.  1 staged.  5 dark.\n\n"
               "*** PLAY TECH LOG ***"),
         position=(0, 0, -0.01), origin=(0, 0), scale=2.4,
         color=color.rgb(140, 220, 200), font="VeraMono.ttf")

    tape17 = Entity(model="cube",
                    scale=(0.20, 0.10, 0.14),
                    position=(0, 1.08, -d/2 + 1.0),
                    color=color.rgba(50, 55, 65, 255),
                    collider="box")
    make_interactable(tape17, "Play tech tape", "collect_note",
                      note_id="note_17")
    created.append(tape17)

    # --- Frost on the floor around the cycling pods ---
    for pz in pod_zs:
        Entity(model="circle",
               scale=2.6,
               rotation=(90, 0, 0),
               position=(east_x, 0.02, pz),
               color=color.rgba(180, 210, 230, 90))

    # --- Centre aisle floor lights ---
    for fz in range(-9, 10, 3):
        Entity(model="quad",
               scale=(0.6, 0.18),
               rotation=(90, 0, 0),
               position=(0, 0.02, fz),
               color=color.rgba(170, 210, 240, 130))

    # --- Hanging conduit / coolant pipes overhead ---
    for tz in range(-9, 10, 4):
        Entity(model="cube",
               scale=(w - 0.6, 0.14, 0.18),
               position=(0, h - 0.35, tz),
               color=color.rgb(40, 50, 65))
        Entity(model="cube",
               scale=(w - 0.6, 0.10, 0.14),
               position=(0, h - 0.60, tz + 0.5),
               color=color.rgb(80, 70, 50))

    # --- A small workstation between the pods with the duty roster ---
    bench = Entity(model="cube", scale=(1.4, 0.85, 0.6),
                   position=(0, 0.42, -6),
                   color=color.rgb(60, 70, 85),
                   collider="box")
    created.append(bench)
    roster = Entity(parent=bench, model="quad",
                    scale=(1.10, 0.50),
                    position=(0, 0.45, 0),
                    rotation=(90, 0, 0),
                    color=color.rgba(240, 230, 200, 250))
    make_interactable(bench, "Read the duty roster", "examine_only",
                      text=("CRYO STORAGE DUTY ROSTER\n"
                            "Tech of record:  K. SATO\n\n"
                            "Cycle 0079:  V-01 prep.   (Sato)\n"
                            "Cycle 0080:  V-02 prep.   (Sato)\n"
                            "Cycle 0081:  V-03 prep.   (Sato)\n"
                            "Cycle 0082:  V-04 prep.   (Sato)\n"
                            "Cycle 0083:  V-05 prep.   (VOSS, in own hand)\n"
                            "Cycle 0084:  V-05 commit. (VOSS, in own hand)\n\n"
                            "The last two entries are in your handwriting.\n"
                            "You do not remember writing them."),
                      duration=10.0)

    # --- A wall plaque commemorating the station, on the north wall above
    # the exit door ---
    plaque = Entity(model="cube",
                    scale=(2.0, 0.40, 0.06),
                    position=(0, h - 0.5, d/2 - 0.10),
                    color=color.rgb(140, 110, 70),
                    collider="box")
    created.append(plaque)
    Text(parent=plaque, text=("CRESTFALL-9   CREW MANIFEST\n"
                              "VOSS  OKAFOR  PARK  HARGROVE  SATO"),
         position=(0, 0, -0.55),
         origin=(0, 0), scale=4.5,
         color=color.rgb(40, 30, 20), font="VeraMono.ttf")
    make_interactable(plaque, "Read the manifest plaque", "examine_only",
                      text=("The official crew manifest plaque.  All "
                            "five names engraved in brass.  The first "
                            "four are familiar.\n\n"
                            "SATO.  Kenji Sato.  Station technician.  "
                            "You stare at the name and feel exactly "
                            "nothing.  You are sure he was here.  His "
                            "handwriting was on the duty roster.  His "
                            "pod is cycling four feet to your left.\n\n"
                            "The signal has been eating the spaces "
                            "where memories used to be.  You should "
                            "have noticed when the first one went "
                            "missing.  You did not.  You did not "
                            "notice."),
                      duration=12.0)

    # Player spawn
    game.player.position = Vec3(0, 1.6, -d/2 + 0.8)
    game.player.fpc.rotation_y = 0

    def check_transition():
        if game.state.storage_door_open and \
                game.player.position.z > d/2 + 0.1:
            game.transition_to("act8")
    game.register_ticker(check_transition)

    return created
