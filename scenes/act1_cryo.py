"""
scenes/act1_cryo.py
-------------------
ACT 1 - CRYO BAY.

Mara wakes in a cryo pod that opens with a hiss. Deep red emergency lighting.
Five pods in a row - four open, one welded shut with burn marks. A crayon
drawing (DADDY and ME, charred) is taped to the welded pod. Note 1 lies near
her pod. The exit door is locked by keycard. The keycard is on the floor
across the room, half-hidden under an overturned crate.

Scratched on the wall by the exit:
        I'M STILL HERE.
   SO IS SOMETHING ELSE.

OLEN's Intercom 1 fires 3 seconds after the player first moves.
"""

import random

from ursina import Entity, Text, Vec3, color, destroy, time

from systems.interaction import make_interactable
from systems.olen import IntercomPanel
from systems import visuals


# ----------------------------------------------------------------------------
# Flickering fixture (red emergency)
# ----------------------------------------------------------------------------

class _FlickerFixture(Entity):
    """A small emissive sphere acting as a red ceiling lamp.

    The light snaps from full intensity to a dim value briefly at random
    intervals between 4 and 18 seconds, simulating ailing emergency lighting.
    A child quad below the lamp approximates the floor light pool.
    """

    def __init__(self, position, base_color=color.rgba(220, 30, 30, 255)):
        """Build the lamp fixture + its floor light pool."""
        super().__init__(model="sphere", scale=0.25, position=position,
                         color=base_color)
        self.base_color = base_color
        self.dim_color = color.rgba(60, 10, 10, 255)
        self.is_dim = False
        self._timer = random.uniform(4.0, 18.0)
        self._pool = Entity(model="circle",
                            color=color.rgba(220, 40, 40, 70),
                            scale=4.5,
                            rotation=(90, 0, 0),
                            position=(position[0], 0.02, position[2]))

    def update(self):
        """Drive the random flicker pattern."""
        self._timer -= time.dt
        if self._timer <= 0:
            if not self.is_dim:
                self.is_dim = True
                self.color = self.dim_color
                self._pool.color = color.rgba(80, 20, 20, 40)
                self._timer = random.uniform(0.05, 0.2)
            else:
                self.is_dim = False
                self.color = self.base_color
                self._pool.color = color.rgba(220, 40, 40, 70)
                self._timer = random.uniform(4.0, 18.0)


# ----------------------------------------------------------------------------
# Cryo pod (visual)
# ----------------------------------------------------------------------------

def _make_cryo_pod(position, welded, created):
    """Build a single cryo pod entity and append children to created list."""
    px, _, pz = position
    base = Entity(model="cube", scale=(0.9, 0.4, 2.4),
                  position=(px, 0.20, pz),
                  color=color.rgb(50, 55, 65), collider="box")
    created.append(base)
    body = Entity(model="cube", scale=(0.9, 1.0, 2.4),
                  position=(px, 0.95, pz),
                  color=color.rgb(70, 78, 90), collider="box")
    created.append(body)
    lid_y = 1.6
    if welded:
        lid = Entity(model="cube",
                     scale=(0.85, 0.10, 2.30),
                     position=(px, lid_y, pz),
                     color=color.rgb(40, 40, 45), collider="box")
        created.append(lid)
        # Burn marks
        for ox, oz in [(-0.35, -1.05), (0.35, 1.05), (0.40, -0.40),
                       (-0.40, 0.40), (0.0, -1.10)]:
            bm = Entity(model="quad", scale=(0.30, 0.30),
                        rotation=(90, 0, 0),
                        position=(px + ox, lid_y + 0.06, pz + oz),
                        color=color.rgba(20, 10, 8, 230))
            created.append(bm)
        # Crayon drawing taped to the outside of the pod (south face)
        draw = Entity(model="quad",
                      scale=(0.55, 0.45),
                      position=(px, 1.10, pz - 1.205),
                      color=color.rgba(245, 230, 180, 250))
        created.append(draw)
        # Big stick figure (Daddy)
        created.append(Entity(parent=draw, model="cube",
                              scale=(0.03, 0.30, 0.01),
                              position=(-0.10, 0.0, -0.005),
                              color=color.rgb(40, 70, 200)))
        created.append(Entity(parent=draw, model="sphere",
                              scale=(0.10, 0.10, 0.01),
                              position=(-0.10, 0.20, -0.005),
                              color=color.rgb(40, 70, 200)))
        # Small stick figure (Me)
        created.append(Entity(parent=draw, model="cube",
                              scale=(0.02, 0.18, 0.01),
                              position=(0.10, -0.04, -0.005),
                              color=color.rgb(220, 60, 80)))
        created.append(Entity(parent=draw, model="sphere",
                              scale=(0.07, 0.07, 0.01),
                              position=(0.10, 0.10, -0.005),
                              color=color.rgb(220, 60, 80)))
        # Hand-link
        created.append(Entity(parent=draw, model="cube",
                              scale=(0.20, 0.02, 0.01),
                              position=(0.0, -0.05, -0.005),
                              color=color.rgb(40, 70, 200)))
        # Charred edges
        created.append(Entity(parent=draw, model="quad",
                              scale=(1.04, 1.04),
                              position=(0, 0, 0.001),
                              color=color.rgba(20, 8, 4, 90)))
    else:
        # Open lid (tilted upward)
        lid = Entity(model="cube",
                     scale=(0.85, 0.10, 2.30),
                     position=(px, lid_y + 0.20, pz - 0.6),
                     rotation=(-25, 0, 0),
                     color=color.rgb(60, 70, 85), collider="box")
        created.append(lid)
        # Inner pod glow (dim cyan)
        glow = Entity(model="cube",
                      scale=(0.75, 0.04, 2.00),
                      position=(px, 0.46, pz),
                      color=color.rgba(50, 140, 180, 255))
        created.append(glow)


# ----------------------------------------------------------------------------
# In-world etched text helper (uses Text with world=True)
# ----------------------------------------------------------------------------

def _world_text(s, position, rotation, scale, col, created):
    """Place 3D world-space Text by parenting it to a transparent anchor Entity.

    Ursina's Text doesn't honor a `world=True` kwarg; parenting to a world-
    space Entity is how text lives in 3D space.
    """
    anchor = Entity(position=position, rotation=rotation)
    created.append(anchor)
    t = Text(parent=anchor, text=s, position=(0, 0, 0),
             origin=(0, 0), scale=scale, color=col,
             font="VeraMono.ttf")
    return t


# ----------------------------------------------------------------------------
# Scene build
# ----------------------------------------------------------------------------

def build(game):
    """Construct all Act 1 geometry; return list of created entities."""
    created = []

    # Floor / ceiling / walls
    floor = Entity(model="cube", scale=(12, 0.2, 16),
                   position=(0, -0.1, 0),
                   color=color.rgb(85, 80, 80),
                   texture=visuals.make_grating(),
                   texture_scale=(6, 8),
                   collider="box")
    created.append(floor)
    ceil = Entity(model="cube", scale=(12, 0.2, 16),
                  position=(0, 4, 0),
                  color=color.rgb(50, 45, 50),
                  texture=visuals.make_metal_panel(),
                  texture_scale=(3, 4))
    created.append(ceil)
    # East / west / south walls are solid; the north wall has a
    # 1.4-wide opening for the exit door at x in [-0.7, 0.7].
    for x, z, sx, sz in [(-6, 0, 0.2, 16), (6, 0, 0.2, 16),
                         (0, -8, 12, 0.2)]:
        w = Entity(model="cube", scale=(sx, 4, sz),
                   position=(x, 2, z),
                   color=color.rgb(110, 90, 90),
                   texture=visuals.make_metal_panel(),
                   texture_scale=(max(sx, sz) / 2, 2),
                   collider="box")
        created.append(w)
    # North wall - two segments leaving an exit-door gap at x in [-0.7, 0.7]
    north_gap = 1.4
    north_seg_w = (12 - north_gap) / 2
    for sx in (-(north_gap / 2 + north_seg_w / 2),
                (north_gap / 2 + north_seg_w / 2)):
        created.append(Entity(model="cube",
                              scale=(north_seg_w, 4, 0.2),
                              position=(sx, 2, 8),
                              color=color.rgb(110, 90, 90),
                              texture=visuals.make_metal_panel(),
                              texture_scale=(north_seg_w / 2, 2),
                              collider="box"))
    # Door frame caps above the opening
    created.append(Entity(model="cube",
                          scale=(north_gap + 0.2, 0.6, 0.2),
                          position=(0, 3.7, 8),
                          color=color.rgb(110, 90, 90),
                          collider="box"))
    # Visible jambs (side frames) on the room-side of the doorway
    for dx in (-0.75, 0.75):
        created.append(Entity(model="cube",
                              scale=(0.10, 2.45, 0.18),
                              position=(dx, 1.225, 7.92),
                              color=color.rgb(140, 110, 100),
                              texture=visuals.make_metal_panel(),
                              texture_scale=(0.4, 1.2)))
    # EXIT label above the door
    exit_plate = Entity(model="cube",
                        scale=(0.55, 0.18, 0.04),
                        position=(0, 2.55, 7.92),
                        color=color.rgb(220, 50, 50))
    created.append(exit_plate)
    Text(parent=exit_plate, text="EXIT",
         position=(0, 0, -0.55), origin=(0, 0), scale=6,
         color=color.rgb(255, 240, 240), font="VeraMono.ttf")
    # Threshold strip
    created.append(Entity(model="cube",
                          scale=(north_gap, 0.04, 0.20),
                          position=(0, 0.02, 8),
                          color=color.rgb(120, 90, 90)))

    # Five cryo pods along the back wall (z = -5)
    pod_z = -5.0
    pod_xs = [-4.4, -2.2, 0.0, 2.2, 4.4]
    welded_idx = 2  # middle pod is Felix's
    for i, x in enumerate(pod_xs):
        _make_cryo_pod((x, 0, pod_z), welded=(i == welded_idx),
                       created=created)

    # Note 1 - on the floor next to player's pod (right side, x=4.4)
    note1 = Entity(model="quad", scale=(0.45, 0.55),
                   rotation=(90, 0, 0),
                   position=(4.4, 0.04, -3.0),
                   color=color.rgba(230, 220, 200, 255),
                   collider="box")
    make_interactable(note1, "Read recorder", "collect_note",
                      note_id="note_1")
    created.append(note1)

    # Overturned crate hiding the keycard
    crate = Entity(model="cube", scale=(0.7, 0.5, 0.9),
                   position=(-3.2, 0.25, 2.0),
                   rotation=(0, 25, 60),
                   color=color.rgb(70, 60, 40), collider="box")
    keycard_root = Entity(model="cube", scale=(0.22, 0.04, 0.13),
                          position=(-3.05, 0.05, 2.05),
                          color=color.rgba(180, 200, 240, 255),
                          collider="box")
    # Hide the keycard until the crate is moved; using visible_self/visible
    # rather than enabled to avoid Panda3D's stash assertion on fresh nodes.
    keycard_root.visible = False
    keycard_root.collision = False
    created.append(keycard_root)

    def reveal_keycard():
        """Reveal the keycard after the crate has been moved.

        Guarded against the (rare) case where the keycard is no longer
        in the scene (e.g. the player somehow picked it up before this
        deferred callback ran).
        """
        try:
            if not keycard_root.enabled:
                return
            keycard_root.visible = True
            keycard_root.collision = True
        except Exception:
            pass
    make_interactable(crate, "Move crate", "move_object",
                      offset=Vec3(0.9, 0, 0.5), after=reveal_keycard)
    created.append(crate)

    # Exit door (north wall, +z).  Slides up when unlocked.
    door = Entity(model="cube",
                  scale=(1.4, 2.4, 0.10),
                  position=(0, 1.2, 8),
                  color=color.rgb(70, 70, 85),
                  texture=visuals.make_metal_panel(),
                  texture_scale=(1, 2),
                  collider="box")
    created.append(door)
    # Inset panel detail on the player-facing side
    Entity(parent=door, model="cube",
           scale=(0.50, 0.55, 0.20),
           position=(0, 0, -0.06),
           color=color.rgb(40, 45, 55))
    # Keycard slot indicator (red until unlocked)
    door_slot = Entity(parent=door, model="cube",
                       scale=(0.18, 0.06, 0.12),
                       position=(0.28, -0.20, -0.06),
                       color=color.rgba(220, 60, 60, 255))
    door._slot = door_slot
    # Handle
    Entity(parent=door, model="cube",
           scale=(0.12, 0.10, 0.16),
           position=(-0.40, -0.10, -0.06),
           color=color.rgb(180, 180, 190))

    def unlock_exit_door():
        """Slide the door up out of the way."""
        from ursina import invoke as _invoke
        door.animate("y", 2.4 + 1.2, duration=0.5)
        _invoke(setattr, door, "collider", None, delay=0.45)
        _invoke(setattr, door, "visible", False, delay=0.50)
        game.audio.door()
        game.state.cryo_door_open = True

    def collect_keycard():
        """Mark the cryo keycard collected.

        The door stays closed until the player walks up to it and presses
        E ('Try door').  That trigger then slides the door open.
        """
        game.state.cryo_keycard = True
        destroy(keycard_root)
        # Flip the door slot indicator from red to green
        try:
            door._slot.color = color.rgba(80, 220, 90, 255)
        except Exception:
            pass
        game.show_examine(
            "Keycard registered.  Try the door.")
    # The keycard is interactable but hidden + non-colliding until the
    # crate is moved, so the raycast won't pick it up early.
    make_interactable(keycard_root, "Take keycard", "trigger_event",
                      callback=collect_keycard)
    keycard_root.collision = False  # re-disable until revealed

    def try_open_door():
        """Door reader: 'locked' message until keycard collected."""
        if not game.state.cryo_keycard:
            game.show_examine(
                "Door locked.  A keycard slot blinks red.")
            return
        unlock_exit_door()
    make_interactable(door, "Try door", "trigger_event",
                      callback=try_open_door)
    game.state.cryo_door_open = False

    # Scratched messages by the exit
    _world_text("I'M STILL HERE.", position=(2.4, 2.0, 7.3),
                rotation=(0, 180, 0), scale=2,
                col=color.rgb(200, 180, 170), created=created)
    _world_text("SO IS SOMETHING ELSE.", position=(2.4, 1.4, 7.3),
                rotation=(0, 180, 0), scale=1.7,
                col=color.rgb(180, 150, 150), created=created)

    # Red emergency lights
    for x in [-4, -2, 0, 2, 4]:
        f = _FlickerFixture(position=(x, 3.7, -3))
        created.append(f)
        game.register_ticker(f.update)
    fx = _FlickerFixture(position=(0.6, 3.7, 6.0))
    created.append(fx)
    game.register_ticker(fx.update)

    # Intercom 1 panel on far wall (west wall, x=-5.9)
    intercom = IntercomPanel(position=(-5.85, 1.7, 0), rotation=(0, 90, 0))
    created.append(intercom)
    game.olen.add_proximity_trigger(
        intercom_id=1, position=(0, 1.6, 0), panel=intercom,
        radius=12.0, delay=3.0, gated_by_first_move=True)
    game.register_ticker(intercom.update)

    # Player spawn just in front of player's pod, facing the exit
    game.player.position = Vec3(4.4, 1.6, -3.0)
    game.player.fpc.rotation_y = 180

    # SOUND: Cryo pod hiss - steam burst, 1.2 seconds. (Act 1 intro)
    # SOUND: Slow breathing - very quiet, positional, from welded pod in Act 1.
    # SOUND: Distant metallic groan - positional, every 45-90 seconds.

    # Transition trigger - cross the door threshold (z > 8.0)
    def check_transition():
        """Trigger act transition when the player crosses the door threshold."""
        if game.state.cryo_door_open and game.player.position.z > 8.0:
            game.transition_to("act2")
    game.register_ticker(check_transition)

    return created
