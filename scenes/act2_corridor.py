"""
scenes/act2_corridor.py
-----------------------
ACT 2 - RESIDENTIAL CORRIDOR & CREW QUARTERS.

A curved corridor with four cabin doors:
    OKAFOR    (Felix)  - open, Note 2, monitor, Amara drawing, Felix-Shape at viewport
    PARK      (Yuna)   - door has Note 3 taped to it; Shape conditional on note pickup
    HARGROVE  (Raymond)- locked, code 4301 (Day 34 from Felix's journal, reversed)
    VOSS      (Mara)   - open; her things; Eli photo; mirror with 'YOU STARTED IT';
                         Intercom 3 manual on wall.

Maintenance hatch at corridor end. Code 7741 scratched on wall (flashlight only).
Felix-Shape stands beside the hatch, faces the wall; steps aside when door opens.
Intercom 2 fires on proximity outside Felix's cabin.
"""

import random

from ursina import (
    Entity, Text, Vec3, color, destroy, invoke, time,
)

from systems.entity import FelixShape, YunaShape
from systems.interaction import make_interactable
from systems.olen import IntercomPanel
from systems import visuals


# ----------------------------------------------------------------------------
# Helpers
# ----------------------------------------------------------------------------

class _FlickerPanel(Entity):
    """Cool-white ceiling panel that flickers fast (interval 1-4 s)."""

    def __init__(self, position, steady=False):
        """steady=True means it doesn't flicker (just dim cool white)."""
        super().__init__(model="cube", scale=(1.4, 0.06, 0.5),
                         position=position,
                         color=color.rgba(200, 220, 230, 255))
        self.steady = steady
        self._timer = random.uniform(1.0, 4.0)
        self._dim = False
        self._pool = Entity(model="quad",
                            scale=(2.4, 2.4),
                            rotation=(90, 0, 0),
                            position=(position[0], 0.05, position[2]),
                            color=color.rgba(180, 200, 220, 35))

    def update(self):
        """Flicker behavior; steady panels skip update entirely."""
        if self.steady:
            return
        self._timer -= time.dt
        if self._timer <= 0:
            if not self._dim:
                self._dim = True
                self.color = color.rgba(80, 90, 100, 255)
                self._pool.color = color.rgba(80, 90, 100, 12)
                self._timer = random.uniform(0.04, 0.12)
            else:
                self._dim = False
                self.color = color.rgba(200, 220, 230, 255)
                self._pool.color = color.rgba(180, 200, 220, 35)
                self._timer = random.uniform(1.0, 4.0)


def _world_text(s, position, rotation, scale, col, created, parent=None):
    """Place 3D world-space Text by parenting it to a transparent anchor Entity."""
    anchor = Entity(position=position, rotation=rotation)
    if parent is not None:
        anchor.parent = parent
    created.append(anchor)
    t = Text(parent=anchor, text=s, position=(0, 0, 0),
             origin=(0, 0), scale=scale, color=col,
             font="VeraMono.ttf")
    return t


def _make_door(label, gap_x, gap_z, side, color_door, created,
               locked=False, code=None, on_unlock=None,
               opens_inward=True):
    """Build a sliding cabin door + visible doorframe in a wall opening.

    The door is a thin vertical panel sitting in the corridor-wall opening
    at (gap_x, gap_z) of width 1.4.  Two vertical jambs flank the opening
    and a labeled plate sits above the door on the corridor-facing side.
    When unlocked the door slides up into the header and despawns.

    side: 'west' = door is in the west corridor wall (cabin on -x side).
          'east' = door is in the east corridor wall (cabin on +x side).
    """
    DOOR_W = 1.4
    DOOR_H = 2.4
    JAMB_T = 0.08          # jamb thickness in z
    JAMB_DEPTH = 0.12      # jamb extends into the corridor a bit
    # Corridor side multiplier: +1 if cabin is east of corridor, -1 if west
    corridor_dir = +1 if side == "west" else -1

    # --- Doorframe jambs (vertical side frames) -----------------------------
    for dz in (-DOOR_W / 2, DOOR_W / 2):
        created.append(Entity(model="cube",
                              scale=(JAMB_DEPTH, DOOR_H + 0.05, JAMB_T),
                              position=(gap_x + corridor_dir * JAMB_DEPTH / 2,
                                        (DOOR_H + 0.05) / 2,
                                        gap_z + dz),
                              color=color.rgb(70, 75, 85),
                              texture=visuals.make_metal_panel(),
                              texture_scale=(0.4, DOOR_H / 2)))
    # Threshold strip on the floor of the opening
    created.append(Entity(model="cube",
                          scale=(JAMB_DEPTH * 1.5, 0.04, DOOR_W),
                          position=(gap_x + corridor_dir * 0.02,
                                    0.02, gap_z),
                          color=color.rgb(90, 95, 105)))

    # --- Door panel ---------------------------------------------------------
    door = Entity(
        model="cube",
        scale=(0.10, DOOR_H, DOOR_W),
        position=(gap_x, DOOR_H / 2, gap_z),
        color=color_door,
        texture=visuals.make_metal_panel(),
        texture_scale=(DOOR_W / 2, DOOR_H / 2),
        collider="box",
    )
    door._door_opened = False
    door._door_locked = locked
    door._door_base_y = DOOR_H / 2
    created.append(door)

    # Inset panel detail on the corridor-facing side (just a thin offset slab)
    detail = Entity(parent=door, model="cube",
                    scale=(0.18, 0.55, 0.50),
                    position=(corridor_dir * 0.06, 0, 0),
                    color=color.rgb(40, 45, 55))
    # door handle plate
    handle = Entity(parent=door, model="cube",
                    scale=(0.16, 0.10, 0.08),
                    position=(corridor_dir * 0.06, -0.10,
                              DOOR_W / 2 - 0.20),
                    color=color.rgb(180, 180, 190))

    # --- Door label plate ---------------------------------------------------
    # Plate sits above the door, on the corridor-facing side.  We parent the
    # label Text to a small entity rotated to face the corridor.
    plate_x = gap_x + corridor_dir * (JAMB_DEPTH + 0.04)
    plate = Entity(model="cube",
                   scale=(0.04, 0.18, 0.48),
                   position=(plate_x, DOOR_H + 0.20, gap_z),
                   color=color.rgb(180, 200, 220))
    created.append(plate)
    # Text floats on the corridor-facing face of the plate
    label_text = Text(
        parent=plate,
        text=label,
        # Local +x or -x is the corridor side (depends on which wall)
        position=(corridor_dir * 0.55, 0, 0),
        rotation=(0, 90 * corridor_dir, 0),
        origin=(0, 0),
        scale=6,
        color=color.rgb(20, 30, 40),
        font="VeraMono.ttf",
    )

    def open_door():
        """Slide the door up into the header opening."""
        if door._door_opened:
            return
        door.animate("y", DOOR_H + DOOR_H / 2, duration=0.45)
        invoke(_clear_collision, door, delay=0.40)
        invoke(setattr, door, "visible", False, delay=0.45)
        door._door_opened = True

    if locked:
        # Wall-mounted keypad to the side of the door on the corridor face
        keypad_z = gap_z + (DOOR_W / 2 + 0.35)
        keypad = Entity(model="cube",
                        scale=(0.08, 0.30, 0.18),
                        position=(gap_x + corridor_dir * 0.10, 1.4, keypad_z),
                        color=color.rgb(60, 70, 80), collider="box")
        # Lit pad squares
        for ki in range(9):
            kr, kc = ki // 3, ki % 3
            Entity(parent=keypad, model="cube",
                   scale=(1.4, 0.18, 0.18),
                   position=(corridor_dir * 0.6,
                             0.08 - kr * 0.07,
                             -0.05 + kc * 0.05),
                   color=color.rgba(180, 220, 200, 230))
        created.append(keypad)

        def unlock_cb():
            """Run the optional unlock hook then open the door."""
            if callable(on_unlock):
                on_unlock()
            door._door_locked = False
            open_door()
        make_interactable(keypad, "Enter code", "keypad",
                          code=code, on_unlock=unlock_cb)

        def hint_use_keypad():
            """Tell the player to use the wall keypad."""
            from systems.interaction import get_manager as _im
            mgr = _im()
            if mgr is not None:
                mgr._examine(
                    f"{label} cabin door locked.  Use the wall keypad.",
                    3.0)
        make_interactable(door, "Door " + label, "trigger_event",
                          callback=hint_use_keypad)
    else:
        make_interactable(door, "Open " + label, "trigger_event",
                          callback=open_door)
    return door


def _clear_collision(entity):
    """Disable an entity's collider (used after a door has slid open)."""
    try:
        entity.collider = None
    except Exception:
        pass


# ----------------------------------------------------------------------------
# Scene build
# ----------------------------------------------------------------------------

def build(game):
    """Construct Act 2 geometry. Returns list of created entities."""
    created = []
    cabins = []

    # ----- Corridor: 22 units long -----
    # Floor (corridor + cabin alcoves)
    floor = Entity(model="cube", scale=(6, 0.2, 24),
                   position=(0, -0.1, 6),
                   color=color.rgb(110, 115, 125),
                   texture=visuals.make_grating(),
                   texture_scale=(3, 12),
                   collider="box")
    created.append(floor)
    ceil = Entity(model="cube", scale=(6, 0.2, 24),
                  position=(0, 3, 6),
                  color=color.rgb(70, 75, 85),
                  texture=visuals.make_metal_panel(),
                  texture_scale=(3, 12))
    created.append(ceil)
    # Corridor side walls.  Each wall has cut-outs for cabin doors:
    #   west (x=-3): Felix at z=0, Hargrove at z=9
    #   east (x=+3): Yuna at z=4.5, Mara at z=13.5
    # Each opening is 1.4 wide (cabin door is 1.4).  We build the wall as
    # a sequence of segments between the gaps + a header above each opening.
    DOOR_W = 1.4
    DOOR_H = 2.4
    CORRIDOR_TOP = 3.0
    wall_color = color.rgb(120, 130, 145)
    wall_z_min, wall_z_max = -6, 18

    def build_wall_with_gaps(x_pos, gap_z_centers):
        """Build a 0.2-thick wall along z with gaps cut for doors.

        Each gap leaves a (DOOR_W) wide opening centered at z=gz.  A header
        cube fills the space above the opening up to the ceiling.
        """
        # Sort gap centers and produce segment ranges
        gz_sorted = sorted(gap_z_centers)
        cursor = wall_z_min
        for gz in gz_sorted:
            seg_start = cursor
            seg_end = gz - DOOR_W / 2
            if seg_end > seg_start:
                w = seg_end - seg_start
                created.append(Entity(model="cube",
                                      scale=(0.2, CORRIDOR_TOP, w),
                                      position=(x_pos,
                                                CORRIDOR_TOP / 2,
                                                seg_start + w / 2),
                                      color=wall_color,
                                      texture=visuals.make_metal_panel(),
                                      texture_scale=(w / 2, 1.5),
                                      collider="box"))
            # Header above the opening
            header_h = CORRIDOR_TOP - DOOR_H
            created.append(Entity(model="cube",
                                  scale=(0.2, header_h, DOOR_W),
                                  position=(x_pos,
                                            DOOR_H + header_h / 2,
                                            gz),
                                  color=wall_color,
                                  texture=visuals.make_metal_panel(),
                                  texture_scale=(DOOR_W / 2, header_h / 2),
                                  collider="box"))
            cursor = gz + DOOR_W / 2
        # Final segment to wall_z_max
        if wall_z_max > cursor:
            w = wall_z_max - cursor
            created.append(Entity(model="cube",
                                  scale=(0.2, CORRIDOR_TOP, w),
                                  position=(x_pos,
                                            CORRIDOR_TOP / 2,
                                            cursor + w / 2),
                                  color=wall_color,
                                  texture=visuals.make_metal_panel(),
                                  texture_scale=(w / 2, 1.5),
                                  collider="box"))

    build_wall_with_gaps(-3, [0, 9])       # west: Felix, Hargrove
    build_wall_with_gaps(+3, [4.5, 13.5])  # east: Yuna, Mara
    # South cap (entry from Act 1) and north cap (hatch leading to Act 3).
    # Both caps have a 1.4-wide opening with a sealed door panel that shows
    # the player where they came from / are going to.
    south_seg_w = (6 - 1.4) / 2
    for sx in (-(0.7 + south_seg_w / 2), (0.7 + south_seg_w / 2)):
        created.append(Entity(model="cube",
                              scale=(south_seg_w, 3, 0.2),
                              position=(sx, 1.5, -6.1),
                              color=color.rgb(60, 65, 75),
                              texture=visuals.make_metal_panel(),
                              texture_scale=(south_seg_w / 2, 1.5),
                              collider="box"))
    # South header above the opening
    created.append(Entity(model="cube",
                          scale=(1.4 + 0.2, 0.6, 0.2),
                          position=(0, 2.7, -6.1),
                          color=color.rgb(60, 65, 75),
                          collider="box"))
    # Sealed door panel where the player entered from Act 1 (north-facing).
    # Single bright solid slab with NO texture so it reads unambiguously
    # as a closed door against the dark corridor walls.
    entry_door = Entity(model="cube",
                        scale=(1.4, 2.4, 0.10),
                        position=(0, 1.2, -6.05),
                        color=color.rgb(200, 205, 215),
                        collider="box")
    created.append(entry_door)
    # Three thin horizontal grooves to look like door panel seams
    for dy in (0.6, 0.0, -0.6):
        Entity(parent=entry_door, model="cube",
               scale=(0.92, 0.03, 0.30),
               position=(0, dy, 0.51),
               color=color.rgb(60, 65, 75))
    # Small red status light (locked from this side)
    Entity(parent=entry_door, model="cube",
           scale=(0.10, 0.10, 0.20),
           position=(0.55, 0.95, 0.51),
           color=color.rgba(220, 60, 60, 255))
    # Label plate above entry door
    entry_plate = Entity(model="cube",
                         scale=(0.48, 0.18, 0.04),
                         position=(0, 2.55, -6.0),
                         color=color.rgb(180, 200, 220))
    created.append(entry_plate)
    Text(parent=entry_plate, text="CRYO BAY",
         position=(0, 0, -0.55), rotation=(0, 0, 0),
         origin=(0, 0), scale=6,
         color=color.rgb(20, 30, 40), font="VeraMono.ttf")
    # Jambs flanking the entry opening
    for dx in (-0.7, 0.7):
        created.append(Entity(model="cube",
                              scale=(0.08, 2.45, 0.12),
                              position=(dx, 1.225, -6.05),
                              color=color.rgb(70, 75, 85),
                              texture=visuals.make_metal_panel(),
                              texture_scale=(0.4, 1.2)))

    north_seg_w = (6 - 1.4) / 2
    for sx in (-(0.7 + north_seg_w / 2), (0.7 + north_seg_w / 2)):
        created.append(Entity(model="cube",
                              scale=(north_seg_w, 3, 0.2),
                              position=(sx, 1.5, 18.1),
                              color=color.rgb(60, 65, 75),
                              texture=visuals.make_metal_panel(),
                              texture_scale=(north_seg_w / 2, 1.5),
                              collider="box"))
    # North header
    created.append(Entity(model="cube",
                          scale=(1.4 + 0.2, 0.6, 0.2),
                          position=(0, 2.7, 18.1),
                          color=color.rgb(60, 65, 75),
                          collider="box"))

    # ----- Helper: build a cabin alcove attached to one side of the corridor -----
    # The cabin "connects" to the corridor through the matching opening
    # already cut in the corridor wall (build_wall_with_gaps above).
    # We do NOT build a wall on the corridor-facing side.
    def make_cabin_room(center, half_size=(2.5, 1.5, 2.5),
                        wall_color=color.rgb(55, 60, 70),
                        corridor_side="west"):
        """Build floor/ceiling/walls for a single cabin alcove.

        corridor_side: which face of the cabin is open to the corridor.
            'west' = cabin sits west of corridor (x < -3), its east face is open.
            'east' = cabin sits east of corridor (x > +3), its west face is open.
        """
        sx, sy, sz = half_size
        cx, _, cz = center
        # Floor
        created.append(Entity(model="cube", scale=(sx * 2, 0.2, sz * 2),
                              position=(cx, -0.1, cz),
                              color=color.rgb(60, 60, 65),
                              texture=visuals.make_concrete(),
                              texture_scale=(sx, sz),
                              collider="box"))
        # Ceiling
        created.append(Entity(model="cube", scale=(sx * 2, 0.2, sz * 2),
                              position=(cx, sy * 2, cz),
                              color=color.rgb(50, 55, 65),
                              texture=visuals.make_metal_panel(),
                              texture_scale=(sx, sz)))
        # Back wall (always - opposite corridor side)
        # North wall (cz + sz) and south wall (cz - sz) are always solid
        created.append(Entity(model="cube", scale=(sx * 2, sy * 2, 0.2),
                              position=(cx, sy, cz - sz),
                              color=wall_color,
                              texture=visuals.make_metal_panel(),
                              texture_scale=(sx, sy),
                              collider="box"))
        created.append(Entity(model="cube", scale=(sx * 2, sy * 2, 0.2),
                              position=(cx, sy, cz + sz),
                              color=wall_color,
                              texture=visuals.make_metal_panel(),
                              texture_scale=(sx, sy),
                              collider="box"))
        # Outer side wall - the cabin face away from the corridor.
        # corridor_side=='west' means cabin sits west of corridor, so its
        # OPEN face is east (+sx) and its solid outer face is west (-sx).
        outer_x = cx + (-sx if corridor_side == "west" else sx)
        created.append(Entity(model="cube",
                              scale=(0.2, sy * 2, sz * 2),
                              position=(outer_x, sy, cz),
                              color=wall_color,
                              texture=visuals.make_metal_panel(),
                              texture_scale=(sz, sy),
                              collider="box"))
        # NOTE: the corridor-facing side intentionally has no wall here -
        # the corridor's wall (with its 1.4-wide door opening) is the
        # shared boundary.

    # ----- Layout - four cabins, alternating sides along z -----
    # Z positions for the cabin doors (along the corridor)
    felix_z = 0.0
    yuna_z = 4.5
    hargrove_z = 9.0
    mara_z = 13.5

    # FELIX cabin alcove (west side, x < 0)
    felix_center = (-5.5, 0, felix_z)
    make_cabin_room(felix_center, half_size=(2.5, 1.5, 2.5),
                    wall_color=color.rgb(55, 55, 65),
                    corridor_side="west")
    # Door sits in the corridor's west wall opening (x=-3, z=felix_z)
    felix_door = _make_door("OKAFOR", gap_x=-3, gap_z=felix_z,
                            side="west",
                            color_door=color.rgb(70, 80, 95),
                            created=created)
    # Felix's cabin door is already open (per spec) - hide entirely
    felix_door.visible = False
    felix_door._door_opened = True
    felix_door.collider = None
    cabins.append(("felix", felix_center, felix_door))

    # FELIX's monitor + Amara drawing + Note 2
    desk = Entity(model="cube", scale=(1.2, 0.7, 0.6),
                  position=(felix_center[0] - 1.4, 0.35,
                            felix_center[2] - 1.5),
                  color=color.rgb(60, 50, 40), collider="box")
    created.append(desk)
    monitor_back = Entity(model="cube", scale=(0.7, 0.45, 0.05),
                          position=(felix_center[0] - 1.4, 1.0,
                                    felix_center[2] - 1.85),
                          color=color.rgb(40, 40, 50), collider="box")
    created.append(monitor_back)
    monitor_screen = Entity(model="quad", scale=(0.6, 0.35),
                            position=(felix_center[0] - 1.4, 1.0,
                                      felix_center[2] - 1.82),
                            color=color.rgba(80, 130, 180, 255))
    created.append(monitor_screen)
    Text(parent=monitor_screen, text="CONNECTING TO EARTH\n....\nNO RESPONSE",
         position=(0, 0, -0.01), origin=(0, 0), scale=3.5,
         color=color.rgb(20, 30, 50), font="VeraMono.ttf")
    # Amara drawing on top of monitor
    draw = Entity(model="quad", scale=(0.4, 0.32),
                  position=(felix_center[0] - 0.7, 1.30,
                            felix_center[2] - 1.83),
                  color=color.rgba(245, 230, 180, 255))
    created.append(draw)
    Entity(parent=draw, model="cube", scale=(0.04, 0.30, 0.01),
           position=(-0.12, 0.0, -0.005), color=color.rgb(40, 70, 200))
    Entity(parent=draw, model="sphere", scale=(0.10, 0.10, 0.01),
           position=(-0.12, 0.20, -0.005), color=color.rgb(40, 70, 200))
    Entity(parent=draw, model="cube", scale=(0.03, 0.18, 0.01),
           position=(0.12, -0.04, -0.005), color=color.rgb(220, 60, 80))
    Entity(parent=draw, model="sphere", scale=(0.07, 0.07, 0.01),
           position=(0.12, 0.10, -0.005), color=color.rgb(220, 60, 80))
    Entity(parent=draw, model="cube", scale=(0.20, 0.02, 0.01),
           position=(0, -0.05, -0.005), color=color.rgb(40, 70, 200))
    make_interactable(draw, "Look at drawing", "examine_only",
                      text=("Amara's drawing.  Two figures, holding hands, "
                            "'space but the pretty part.'  Felix said he "
                            "could see the pretty part every day."))

    # Note 2 (Felix's research journal)
    note2 = Entity(model="quad", scale=(0.35, 0.45),
                   rotation=(90, 0, 0),
                   position=(felix_center[0] - 1.4, 0.72,
                             felix_center[2] - 1.3),
                   color=color.rgba(230, 220, 200, 255), collider="box")
    make_interactable(note2, "Read journal", "collect_note",
                      note_id="note_2")
    created.append(note2)

    # Felix-Shape at the viewport (back wall of his cabin)
    felix_shape_cabin = FelixShape(
        position=(felix_center[0] + 1.0, 0, felix_center[2] - 2.2),
        rotation_y=180, audio=game.audio)
    game.shapes.register(felix_shape_cabin)
    created.append(felix_shape_cabin)
    # Viewport (simulate a window with a dark blue rectangle)
    viewport = Entity(model="quad", scale=(1.6, 1.2),
                      position=(felix_center[0] + 1.0, 1.3,
                                felix_center[2] - 2.49),
                      color=color.rgba(20, 35, 60, 255))
    created.append(viewport)

    # Intercom 2 - in corridor just outside Felix's cabin
    intercom2 = IntercomPanel(position=(-2.8, 1.8, felix_z),
                              rotation=(0, 90, 0))
    created.append(intercom2)
    game.register_ticker(intercom2.update)
    game.olen.add_proximity_trigger(
        intercom_id=2, position=(-2.0, 1.6, felix_z), panel=intercom2,
        radius=3.5)

    # ---- YUNA cabin alcove (east side) ----
    yuna_center = (5.5, 0, yuna_z)
    make_cabin_room(yuna_center, half_size=(2.5, 1.5, 2.5),
                    wall_color=color.rgb(60, 60, 60),
                    corridor_side="east")
    yuna_door = _make_door("PARK", gap_x=3, gap_z=yuna_z,
                           side="east",
                           color_door=color.rgb(70, 80, 90),
                           created=created)
    cabins.append(("yuna", yuna_center, yuna_door))

    # Note 3 taped to the OUTSIDE of Yuna's door (corridor side)
    note3 = Entity(model="quad", scale=(0.30, 0.40),
                   position=(2.55, 1.55, yuna_z),
                   rotation=(0, 90, 0),
                   color=color.rgba(230, 220, 200, 255),
                   collider="box")
    make_interactable(note3, "Read door note", "collect_note",
                      note_id="note_3")
    created.append(note3)

    # Inside Yuna's cabin - desk + cold tea + (conditional) Shape OR floor arrangement
    yuna_desk = Entity(model="cube", scale=(1.0, 0.7, 0.5),
                      position=(yuna_center[0] + 1.3, 0.35,
                                yuna_center[2] - 1.5),
                      color=color.rgb(70, 60, 50), collider="box")
    created.append(yuna_desk)
    tea_mug = Entity(model="sphere", scale=(0.10, 0.15, 0.10),
                     position=(yuna_center[0] + 1.3, 0.78,
                               yuna_center[2] - 1.5),
                     color=color.rgb(180, 170, 160), collider="box")
    make_interactable(tea_mug, "Touch the mug", "examine_only",
                      text="Still warm.  It isn't.")
    created.append(tea_mug)

    # Both possible states - Shape OR floor arrangement; built on enter()
    yuna_shape_ref = []
    yuna_arrangement_ref = []

    def setup_yuna_state():
        """On entering the cabin, instantiate exactly one state."""
        # Tear down anything we previously built
        for e in yuna_shape_ref + yuna_arrangement_ref:
            try:
                destroy(e)
            except Exception:
                pass
        yuna_shape_ref.clear()
        yuna_arrangement_ref.clear()
        if game.notes.has("note_3"):
            # Note collected first - Shape absent, arrangement on floor
            spot = (yuna_center[0] - 0.5, 0.02, yuna_center[2] - 1.0)
            # Pen
            pen = Entity(model="cube", scale=(0.02, 0.02, 0.18),
                         position=spot, rotation=(0, 30, 0),
                         color=color.rgb(220, 60, 60))
            yuna_arrangement_ref.append(pen)
            created.append(pen)
            # Paperclip (small)
            clip = Entity(model="cube", scale=(0.10, 0.01, 0.04),
                          position=(spot[0] + 0.10, 0.02, spot[2] + 0.10),
                          color=color.rgb(180, 180, 200))
            yuna_arrangement_ref.append(clip)
            created.append(clip)
            # Stylus
            stylus = Entity(model="cube", scale=(0.015, 0.015, 0.20),
                            position=(spot[0] + 0.15, 0.02, spot[2] - 0.05),
                            rotation=(0, -25, 0),
                            color=color.rgb(40, 50, 70))
            yuna_arrangement_ref.append(stylus)
            created.append(stylus)
            # A faint hint - examine prompt on the cluster
            anchor = Entity(model="quad", scale=(0.6, 0.6),
                            rotation=(90, 0, 0),
                            position=(spot[0] + 0.05, 0.015, spot[2]),
                            color=color.rgba(0, 0, 0, 0), collider="box")
            make_interactable(anchor, "Look closer", "examine_only",
                              text=("A pen, a paperclip, and a stylus.  "
                                    "Arranged into two figures holding hands."),
                              duration=4.0)
            yuna_arrangement_ref.append(anchor)
            created.append(anchor)
        else:
            # Note NOT collected - Shape at the window, unreactive
            shape = YunaShape(
                position=(yuna_center[0], 0, yuna_center[2] - 2.0),
                rotation_y=180)
            game.shapes.register(shape)
            yuna_shape_ref.append(shape)
            created.append(shape)

    # We attach a one-shot trigger that initializes when player enters the cabin
    yuna_zone = Entity(model="quad", scale=(3.0, 3.0),
                       rotation=(90, 0, 0),
                       position=(yuna_center[0], 0.01, yuna_center[2]),
                       color=color.rgba(0, 0, 0, 0))
    yuna_zone._setup_done = False
    created.append(yuna_zone)

    def yuna_zone_tick():
        """Initialize the cabin's Shape/arrangement the first time player enters."""
        if yuna_zone._setup_done:
            return
        pp = game.player.position
        if (abs(pp.x - yuna_center[0]) < 2.4 and
                abs(pp.z - yuna_center[2]) < 2.4):
            setup_yuna_state()
            yuna_zone._setup_done = True
    game.register_ticker(yuna_zone_tick)

    # ---- HARGROVE cabin (west side) ----
    hargrove_center = (-5.5, 0, hargrove_z)
    make_cabin_room(hargrove_center, half_size=(2.5, 1.5, 2.5),
                    wall_color=color.rgb(60, 58, 55),
                    corridor_side="west")
    hargrove_door = _make_door(
        "HARGROVE", gap_x=-3, gap_z=hargrove_z,
        side="west",
        color_door=color.rgb(80, 70, 70),
        created=created, locked=True, code="4301")
    cabins.append(("hargrove", hargrove_center, hargrove_door))

    # Inside - desk + Note 4 + framed photo
    h_desk = Entity(model="cube", scale=(1.2, 0.7, 0.6),
                    position=(hargrove_center[0] - 1.3, 0.35,
                              hargrove_center[2] - 1.5),
                    color=color.rgb(55, 50, 45), collider="box")
    created.append(h_desk)
    note4 = Entity(model="quad", scale=(0.35, 0.45),
                   rotation=(90, 0, 0),
                   position=(hargrove_center[0] - 1.3, 0.72,
                             hargrove_center[2] - 1.5),
                   color=color.rgba(225, 215, 195, 255), collider="box")
    make_interactable(note4, "Read handwritten log", "collect_note",
                      note_id="note_4")
    created.append(note4)
    # Framed photo - face down
    photo = Entity(model="cube", scale=(0.25, 0.04, 0.18),
                   position=(hargrove_center[0] + 1.3, 0.72,
                             hargrove_center[2] - 1.5),
                   color=color.rgb(30, 30, 30), collider="box")
    photo._flipped = False

    def flip_photo():
        """Turn the photo over - reveal back-side detail."""
        if photo._flipped:
            return
        photo.animate("rotation_x", 180, duration=0.4)
        photo._flipped = True
        game.show_examine(
            "Two kids squinting into summer sun.  An old photo.")
    make_interactable(photo, "Turn over photo", "trigger_event",
                      callback=flip_photo)
    created.append(photo)

    # ---- MARA cabin (east side, open) ----
    mara_center = (5.5, 0, mara_z)
    make_cabin_room(mara_center, half_size=(2.5, 1.5, 2.5),
                    wall_color=color.rgb(55, 55, 65),
                    corridor_side="east")
    mara_door = _make_door("VOSS", gap_x=3, gap_z=mara_z,
                           side="east",
                           color_door=color.rgb(70, 75, 90),
                           created=created)
    # Mara's door is pre-opened
    mara_door.visible = False
    mara_door._door_opened = True
    mara_door.collider = None
    cabins.append(("mara", mara_center, mara_door))

    # Inside - mug + Eli photo + mirror + Intercom 3 wall panel
    mara_desk = Entity(model="cube", scale=(1.2, 0.7, 0.5),
                      position=(mara_center[0] + 1.3, 0.35,
                                mara_center[2] - 1.5),
                      color=color.rgb(60, 60, 70), collider="box")
    created.append(mara_desk)
    mug = Entity(model="sphere", scale=(0.10, 0.15, 0.10),
                 position=(mara_center[0] + 1.3, 0.78, mara_center[2] - 1.5),
                 color=color.rgb(160, 170, 180), collider="box")
    make_interactable(mug, "Look at mug", "examine_only",
                      text="Your mug.  Empty.  Cold ring of tea at the bottom.")
    created.append(mug)
    # Eli photo (face up)
    eli_photo = Entity(model="cube", scale=(0.18, 0.02, 0.13),
                       position=(mara_center[0] + 0.9, 0.72,
                                 mara_center[2] - 1.5),
                       color=color.rgb(200, 200, 210), collider="box")
    make_interactable(eli_photo, "Look at photo", "examine_only",
                      text=("Your brother.  He had your eyes.  You haven't "
                            "looked at this photo in two months.  You don't "
                            "remember taking it out of the drawer."),
                      duration=5.0)
    created.append(eli_photo)
    # Mirror - 'YOU STARTED IT'
    mirror = Entity(model="cube", scale=(0.7, 0.9, 0.05),
                    position=(mara_center[0] - 1.2, 1.5,
                              mara_center[2] - 2.45),
                    color=color.rgb(150, 170, 200), collider="box")
    created.append(mirror)
    _world_text("YOU STARTED IT", position=(mara_center[0] - 1.2, 1.55,
                                            mara_center[2] - 2.42),
                rotation=(0, 0, 0), scale=2.0,
                col=color.rgb(220, 80, 90), created=created)
    make_interactable(mirror, "Look in mirror", "examine_only",
                      text="The mirror is just a mirror.",
                      duration=3.0)

    # Intercom 3 - manual interact - inside Mara's cabin
    intercom3 = IntercomPanel(position=(mara_center[0] + 1.4, 1.7,
                                        mara_center[2] - 2.45),
                              rotation=(0, 0, 0))
    created.append(intercom3)
    game.register_ticker(intercom3.update)
    make_interactable(intercom3, "Press intercom", "trigger_event",
                      callback=lambda: game.olen.trigger_manual(3, intercom3))

    # ---- North end: Felix-Shape + maintenance hatch (slides up when unlocked) ----
    hatch_door = Entity(model="cube",
                        scale=(1.4, 2.4, 0.10),
                        position=(0, 1.2, 18.05),
                        color=color.rgb(110, 90, 70),
                        texture=visuals.make_metal_panel(),
                        texture_scale=(0.7, 1.2),
                        collider="box")
    created.append(hatch_door)
    # Hatch panel detail + hazard stripes
    Entity(parent=hatch_door, model="cube",
           scale=(0.50, 0.55, 0.20),
           position=(0, 0, -0.06),
           color=color.rgb(40, 35, 25))
    Entity(parent=hatch_door, model="cube",
           scale=(0.90, 0.08, 0.20),
           position=(0, 0.40, -0.06),
           color=color.rgb(220, 180, 30))
    Entity(parent=hatch_door, model="cube",
           scale=(0.90, 0.08, 0.20),
           position=(0, -0.50, -0.06),
           color=color.rgb(220, 180, 30))
    hatch_door._slot = Entity(parent=hatch_door, model="cube",
                              scale=(0.20, 0.08, 0.20),
                              position=(0.40, -0.10, -0.06),
                              color=color.rgba(220, 60, 60, 255))
    # Jambs on the corridor side of the hatch
    for dx in (-0.75, 0.75):
        created.append(Entity(model="cube",
                              scale=(0.10, 2.45, 0.18),
                              position=(dx, 1.225, 17.97),
                              color=color.rgb(140, 110, 80),
                              texture=visuals.make_metal_panel(),
                              texture_scale=(0.4, 1.2)))
    # MAINTENANCE label above the hatch
    hatch_plate = Entity(model="cube",
                         scale=(0.75, 0.18, 0.04),
                         position=(0, 2.55, 17.96),
                         color=color.rgb(220, 200, 160))
    created.append(hatch_plate)
    Text(parent=hatch_plate, text="MAINT.",
         position=(0, 0, -0.55), origin=(0, 0), scale=6,
         color=color.rgb(30, 30, 35), font="VeraMono.ttf")

    # Wall-mounted keypad to the east of the hatch
    hatch_keypad = Entity(model="cube", scale=(0.08, 0.30, 0.18),
                          position=(1.0, 1.4, 18.0),
                          color=color.rgb(60, 70, 80), collider="box")
    created.append(hatch_keypad)
    # Lit pad squares on the corridor-facing face
    for ki in range(9):
        kr, kc = ki // 3, ki % 3
        Entity(parent=hatch_keypad, model="cube",
               scale=(1.4, 0.18, 0.18),
               position=(-0.6, 0.08 - kr * 0.07, -0.05 + kc * 0.05),
               color=color.rgba(180, 220, 200, 230))

    def open_hatch():
        """Open the hatch by sliding it up + Felix-Shape steps aside."""
        hatch_door.animate("y", 2.4 + 1.2, duration=0.5)
        invoke(_clear_collision, hatch_door, delay=0.45)
        invoke(setattr, hatch_door, "visible", False, delay=0.50)
        try:
            hatch_door._slot.color = color.rgba(80, 220, 90, 255)
        except Exception:
            pass
        game.audio.door()
        game.state.hatch_open = True
        # Felix-Shape steps quietly aside
        hatch_felix.animate("position",
                            hatch_felix.position + Vec3(-1.6, 0, 0),
                            duration=1.4)
    make_interactable(hatch_keypad, "Enter code", "keypad",
                      code="7741", on_unlock=open_hatch)
    game.state.hatch_open = False

    # Code 7741 scratched on wall beside the keypad - readable as faint text
    _world_text("7741", position=(2.1, 1.7, 17.9),
                rotation=(0, 180, 0), scale=1.4,
                col=color.rgba(200, 190, 180, 130), created=created)

    # Felix-Shape next to keypad facing wall
    hatch_felix = FelixShape(position=(1.6, 0, 17.5),
                             rotation_y=180, audio=game.audio)
    game.shapes.register(hatch_felix)
    created.append(hatch_felix)

    # ---- Ceiling lighting panels ----
    # Steady panels every ~4 units, with two "dark sections" near z=2 and z=11
    for z in [-4, -1, 2, 5, 8, 11, 14, 17]:
        steady = z not in (2, 11)
        p = _FlickerPanel(position=(0, 2.9, z), steady=steady)
        created.append(p)
        game.register_ticker(p.update)

    # Player spawns just inside corridor from Act 1 (z=-5)
    game.player.position = Vec3(0, 1.6, -5.5)
    game.player.fpc.rotation_y = 0

    # Transition trigger - past the hatch (z > 18.0)
    def check_transition():
        """Trigger act transition when player crosses the hatch."""
        if game.state.hatch_open and game.player.position.z > 18.2:
            game.transition_to("act3")
    game.register_ticker(check_transition)

    return created
