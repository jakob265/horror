"""
scenes/_chamber.py
------------------
Shared helpers for the extended-arc scenes (Acts 5-10).

Each of the new acts is a single rectangular chamber with:
    - floor (thin cube collider)
    - ceiling
    - 4 walls, each with an optional 1.4-wide door opening
    - an entry door (sealed, leading back) and an exit door (interactive)
    - one or two atmospheric props

These helpers keep the per-scene code small.
"""

from ursina import Entity, Text, Vec3, color, invoke

from systems.interaction import make_interactable
from systems import visuals


DOOR_W = 1.4
DOOR_H = 2.4


def build_floor_ceiling(created, w, d, h, *,
                        floor_color=(70, 75, 85),
                        ceiling_color=(40, 45, 55),
                        floor_tex="grating",
                        center=(0, 0, 0)):
    """Build floor + ceiling for a w x d room at center, with height h."""
    cx, _, cz = center
    tex_fn = (visuals.make_grating if floor_tex == "grating"
              else visuals.make_concrete)
    created.append(Entity(model="cube", scale=(w, 0.2, d),
                          position=(cx, -0.1, cz),
                          color=color.rgb(*floor_color),
                          texture=tex_fn(),
                          texture_scale=(w / 3, d / 3),
                          collider="box"))
    created.append(Entity(model="cube", scale=(w, 0.2, d),
                          position=(cx, h, cz),
                          color=color.rgb(*ceiling_color),
                          texture=visuals.make_metal_panel(),
                          texture_scale=(w / 3, d / 3)))


def build_wall(created, axis, fixed, span_min, span_max, h, *,
               gap_center=None, wall_color=(70, 80, 100)):
    """Build one wall.  Optionally cut a 1.4-wide door-shaped gap.

    axis: 'x' = wall runs along z at fixed x. 'z' = wall runs along x at
    fixed z.  span_min/span_max define the wall's other-axis extent.
    """
    wc = color.rgb(*wall_color)
    if gap_center is None:
        # Solid wall
        if axis == "x":
            length = span_max - span_min
            created.append(Entity(model="cube",
                                  scale=(0.2, h, length),
                                  position=(fixed, h / 2,
                                            (span_min + span_max) / 2),
                                  color=wc,
                                  texture=visuals.make_metal_panel(),
                                  texture_scale=(length / 2, h / 2),
                                  collider="box"))
        else:
            length = span_max - span_min
            created.append(Entity(model="cube",
                                  scale=(length, h, 0.2),
                                  position=((span_min + span_max) / 2,
                                            h / 2, fixed),
                                  color=wc,
                                  texture=visuals.make_metal_panel(),
                                  texture_scale=(length / 2, h / 2),
                                  collider="box"))
        return
    # Wall with 1.4-wide gap centered on gap_center
    gap_half = DOOR_W / 2
    seg1_start, seg1_end = span_min, gap_center - gap_half
    seg2_start, seg2_end = gap_center + gap_half, span_max
    header_h = h - DOOR_H
    for seg_start, seg_end in [(seg1_start, seg1_end), (seg2_start, seg2_end)]:
        if seg_end <= seg_start:
            continue
        length = seg_end - seg_start
        mid = (seg_start + seg_end) / 2
        if axis == "x":
            created.append(Entity(model="cube",
                                  scale=(0.2, h, length),
                                  position=(fixed, h / 2, mid),
                                  color=wc,
                                  texture=visuals.make_metal_panel(),
                                  texture_scale=(length / 2, h / 2),
                                  collider="box"))
        else:
            created.append(Entity(model="cube",
                                  scale=(length, h, 0.2),
                                  position=(mid, h / 2, fixed),
                                  color=wc,
                                  texture=visuals.make_metal_panel(),
                                  texture_scale=(length / 2, h / 2),
                                  collider="box"))
    # Header above the opening
    if axis == "x":
        created.append(Entity(model="cube",
                              scale=(0.2, header_h, DOOR_W + 0.2),
                              position=(fixed, DOOR_H + header_h / 2,
                                        gap_center),
                              color=wc,
                              collider="box"))
    else:
        created.append(Entity(model="cube",
                              scale=(DOOR_W + 0.2, header_h, 0.2),
                              position=(gap_center,
                                        DOOR_H + header_h / 2, fixed),
                              color=wc,
                              collider="box"))


def make_door(created, axis, fixed, gap_center, label, *,
              side, color_rgb=(72, 70, 60), interactable_label=None,
              callback=None, sealed=False):
    """Build a sliding door panel inside a wall opening.

    axis: 'x' = wall normal is along x.  'z' = wall normal is along z.
    side: which direction faces the player approaching this door.
          For 'x' walls: +1 means cabin side is +x; -1 means -x.
          For 'z' walls: +1 means player approaches from -z; -1 from +z.
    """
    if axis == "x":
        scale = (0.10, DOOR_H, DOOR_W)
        pos = (fixed, DOOR_H / 2, gap_center)
    else:
        scale = (DOOR_W, DOOR_H, 0.10)
        pos = (gap_center, DOOR_H / 2, fixed)
    door = Entity(model="cube",
                  scale=scale,
                  position=pos,
                  color=color.rgb(*color_rgb),
                  texture=visuals.make_metal_panel(),
                  texture_scale=(0.5, 0.9),
                  collider="box")
    created.append(door)
    # Horizontal seams on the player-facing side
    if axis == "x":
        seam_x = side * 0.51
        for dy in (0.6, 0.0, -0.6):
            Entity(parent=door, model="cube",
                   scale=(0.02, 0.03, 0.92),
                   position=(seam_x, dy, 0),
                   color=color.rgb(35, 38, 38))
    else:
        seam_z = side * 0.51
        for dy in (0.6, 0.0, -0.6):
            Entity(parent=door, model="cube",
                   scale=(0.92, 0.03, 0.02),
                   position=(0, dy, seam_z),
                   color=color.rgb(35, 38, 38))
    # Status light on the door
    if axis == "x":
        Entity(parent=door, model="cube",
               scale=(0.02, 0.10, 0.20),
               position=(side * 0.51, 0.95, 0.45),
               color=(color.rgba(60, 220, 80, 255) if sealed
                      else color.rgba(220, 60, 60, 255)))
    else:
        Entity(parent=door, model="cube",
               scale=(0.20, 0.10, 0.02),
               position=(0.45, 0.95, side * 0.51),
               color=(color.rgba(60, 220, 80, 255) if sealed
                      else color.rgba(220, 60, 60, 255)))

    door._opened = False

    if not sealed:
        def open_door():
            """Slide the door up out of the way."""
            if door._opened:
                return
            from ursina import invoke as _invoke
            door.animate("y", DOOR_H + DOOR_H / 2, duration=0.45)
            _invoke(setattr, door, "collider", None, delay=0.40)
            _invoke(setattr, door, "visible", False, delay=0.45)
            door._opened = True
            if callable(callback):
                callback()
        make_interactable(door, interactable_label or ("Open " + label),
                          "trigger_event", callback=open_door)
    return door


def make_chamber(created, *, w, d, h, center=(0, 0, 0),
                 entry_axis="z", entry_fixed=None, entry_gap=0,
                 exit_axis="z", exit_fixed=None, exit_gap=0,
                 wall_color=(70, 80, 100),
                 floor_color=(70, 75, 85),
                 ceiling_color=(40, 45, 55),
                 floor_tex="grating"):
    """Build a complete rectangular chamber with one entry and one exit
    door.  Returns (entry_door, exit_door)."""
    cx, _, cz = center
    build_floor_ceiling(created, w, d, h,
                        floor_color=floor_color,
                        ceiling_color=ceiling_color,
                        floor_tex=floor_tex,
                        center=center)
    x_min, x_max = cx - w / 2, cx + w / 2
    z_min, z_max = cz - d / 2, cz + d / 2
    # West / east walls
    for fixed, name in [(x_min, "west"), (x_max, "east")]:
        gap = None
        if entry_axis == "x" and entry_fixed == fixed:
            gap = entry_gap
        elif exit_axis == "x" and exit_fixed == fixed:
            gap = exit_gap
        build_wall(created, "x", fixed, z_min, z_max, h,
                   gap_center=gap, wall_color=wall_color)
    # North / south walls
    for fixed, name in [(z_min, "south"), (z_max, "north")]:
        gap = None
        if entry_axis == "z" and entry_fixed == fixed:
            gap = entry_gap
        elif exit_axis == "z" and exit_fixed == fixed:
            gap = exit_gap
        build_wall(created, "z", fixed, x_min, x_max, h,
                   gap_center=gap, wall_color=wall_color)
    # Entry door (sealed - the way the player came in)
    entry_side = -1 if entry_axis == "x" and entry_fixed == x_min else \
                 +1 if entry_axis == "x" and entry_fixed == x_max else \
                 -1 if entry_axis == "z" and entry_fixed == z_min else +1
    entry_door = make_door(created, entry_axis, entry_fixed, entry_gap,
                           "BACK", side=entry_side, sealed=True)
    # Exit door (open with E)
    exit_side = -1 if exit_axis == "x" and exit_fixed == x_min else \
                +1 if exit_axis == "x" and exit_fixed == x_max else \
                -1 if exit_axis == "z" and exit_fixed == z_min else +1
    exit_door = make_door(created, exit_axis, exit_fixed, exit_gap,
                          "FORWARD", side=exit_side)
    return entry_door, exit_door


def add_examine_prop(created, position, label, body, *,
                     scale=(0.4, 0.4, 0.4), col=(120, 120, 130)):
    """Add a labeled examine-only prop at the given position."""
    p = Entity(model="cube", scale=scale, position=position,
               color=color.rgb(*col), collider="box")
    make_interactable(p, label, "examine_only", text=body, duration=5.0)
    created.append(p)
    return p
