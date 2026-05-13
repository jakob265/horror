"""
systems/entity.py
-----------------
The Shapes of VOID FREQUENCY.

Three dark, featureless humanoid figures. They do not chase. They do not
attack. They are simply present.

    FELIX-SHAPE   - placed in multiple scenes; static unless stared at for
                    5 seconds, then a single head-turn + "Amara" trigger fires
                    once across the whole game.
    YUNA-SHAPE    - one only, in Yuna's cabin; conditional on note state.
    HARGROVE-SHAPE - one only, in the array room; turns, waves, and walks
                    away on the terminal-reached event.
"""

import math

from ursina import (
    Entity, Vec3, camera, color, destroy, distance, held_keys,
    invoke, raycast, time,
)


# Module-level flag - Felix's "Amara" trigger fires at most once per game session.
_FELIX_AMARA_FIRED = False


def reset_global_state():
    """Reset module-level flags - called on New Game."""
    global _FELIX_AMARA_FIRED
    _FELIX_AMARA_FIRED = False


# ----------------------------------------------------------------------------
# Base Shape class
# ----------------------------------------------------------------------------

class Shape(Entity):
    """Featureless humanoid silhouette - the visual shell.

    The body is a tall capsule (cylinder + sphere caps) in near-black material
    with a faint emissive edge to remain legible in dark scenes.
    """

    def __init__(self, position=(0, 0, 0), rotation_y=0, crouched=False):
        """Build the body / head segments. crouched=True for Felix in the lab."""
        super().__init__(
            position=position,
            rotation=(0, rotation_y, 0),
            collision=False,
        )
        body_color = color.rgba(18, 18, 22, 255)
        edge_color = color.rgba(50, 60, 80, 255)
        # Torso (cylinder)
        if crouched:
            torso_h = 0.55
            torso_y = 0.55
            self.head_offset = 0.35
        else:
            torso_h = 0.95
            torso_y = 1.05
            self.head_offset = 0.55
        self.torso = Entity(parent=self, model="cube",
                            scale=(0.45, torso_h, 0.30),
                            position=(0, torso_y, 0),
                            color=body_color)
        Entity(parent=self.torso, model="cube",
               scale=(1.05, 1.02, 1.05),
               color=edge_color,
               position=(0, 0, 0),
               alpha=0.18)
        # Head (sphere)
        self.head_pivot = Entity(parent=self,
                                 position=(0, torso_y + torso_h * 0.55, 0))
        self.head = Entity(parent=self.head_pivot, model="sphere",
                           scale=0.22,
                           color=body_color)
        Entity(parent=self.head, model="sphere",
               scale=1.07, color=edge_color, alpha=0.20)
        # Arms - default at sides
        self.left_arm = Entity(parent=self, model="cube",
                               scale=(0.10, 0.65, 0.10),
                               position=(-0.28, torso_y - 0.05, 0),
                               color=body_color)
        self.right_arm_pivot = Entity(parent=self,
                                      position=(0.28, torso_y + 0.30, 0))
        self.right_arm = Entity(parent=self.right_arm_pivot, model="cube",
                                scale=(0.10, 0.65, 0.10),
                                position=(0, -0.32, 0),
                                color=body_color)
        # Legs
        Entity(parent=self, model="cube",
               scale=(0.13, 0.85, 0.18),
               position=(-0.13, 0.42, 0),
               color=body_color)
        Entity(parent=self, model="cube",
               scale=(0.13, 0.85, 0.18),
               position=(0.13, 0.42, 0),
               color=body_color)
        if crouched:
            # Bow the figure: tilt arms slightly forward, head down
            self.head_pivot.rotation_x = 20
            self.left_arm.rotation_x = 40
            self.right_arm.rotation_x = 40

    def look_target_pos(self):
        """World position used by the stare-detection raycast."""
        return self.head.world_position

    def slow_head_turn(self, target_y, duration=2.0, then_back=True):
        """Lerp the head_pivot rotation_y to target then optionally back."""
        self.head_pivot.animate("rotation_y", target_y, duration=duration,
                curve=None)
        if then_back:
            invoke(self._head_return, delay=duration + 2.0)

    def _head_return(self):
        """Return the head to neutral."""
        self.head_pivot.animate("rotation_y", 0, duration=1.4, curve=None)


# ----------------------------------------------------------------------------
# Felix-Shape
# ----------------------------------------------------------------------------

class FelixShape(Shape):
    """Felix Shape - stare 5s anywhere in the game triggers 'Amara' once."""

    def __init__(self, position=(0, 0, 0), rotation_y=0, crouched=False,
                 audio=None):
        """audio: AudioManager (for the sting + signal-proximity tone)."""
        super().__init__(position=position, rotation_y=rotation_y,
                         crouched=crouched)
        self.audio = audio
        self._stare_time = 0.0
        self.shape_kind = "felix"

    def update_stare(self, player):
        """Run the stare-detection raycast. Fire Felix's 'Amara' once globally."""
        global _FELIX_AMARA_FIRED
        if _FELIX_AMARA_FIRED:
            return
        origin = camera.world_position
        direction = camera.forward
        hit = raycast(origin, direction, distance=18.0, ignore=[player],
                      debug=False)
        is_looking = False
        if hit.hit and hit.entity is not None:
            ent = hit.entity
            # Climb to top-level Shape
            while ent is not None and not isinstance(ent, Shape):
                ent = getattr(ent, "parent", None)
            if ent is self:
                is_looking = True
        if is_looking:
            self._stare_time += time.dt
            if self._stare_time >= 5.0 and not _FELIX_AMARA_FIRED:
                _FELIX_AMARA_FIRED = True
                self._fire_amara()
        else:
            self._stare_time = max(0.0, self._stare_time - time.dt * 0.5)

    def _fire_amara(self):
        """Slow head turn, sting + 'Amara' (placeholder), then head returns."""
        if self.audio is not None:
            self.audio.shape_sting()
        # SOUND: Felix's voice saying "Amara" - soft, slightly distorted, as if
        #         heard through water. Drop mono .wav here.
        target_y = 80
        self.slow_head_turn(target_y, duration=2.0, then_back=True)


# ----------------------------------------------------------------------------
# Yuna-Shape
# ----------------------------------------------------------------------------

class YunaShape(Shape):
    """Yuna Shape - present only when the door-note has NOT been collected."""

    def __init__(self, position=(0, 0, 0), rotation_y=180):
        """Build, no special behavior."""
        super().__init__(position=position, rotation_y=rotation_y)
        self.shape_kind = "yuna"


# ----------------------------------------------------------------------------
# Hargrove-Shape
# ----------------------------------------------------------------------------

class HargroveShape(Shape):
    """Hargrove Shape - static until terminal_reached; then turn, wave, walk off."""

    def __init__(self, position=(0, 0, 0), rotation_y=0, audio=None):
        """audio: AudioManager for the wave sting."""
        super().__init__(position=position, rotation_y=rotation_y)
        self.audio = audio
        self.shape_kind = "hargrove"
        self.farewell_done = False

    def farewell(self, on_complete=None):
        """Turn to player, raise arm, hold, walk into dark corner, despawn."""
        if self.farewell_done:
            return
        self.farewell_done = True
        if self.audio is not None:
            self.audio.shape_sting()
        # Turn to face player (assume player is in front of tower base ~ z+)
        self.animate("rotation_y", self.rotation_y + 180, duration=2.0,
                curve=None)
        # Lift the right arm pivot from default down to outstretched (wave)
        invoke(self._raise_arm, delay=2.1)
        invoke(self._walk_away, on_complete, delay=5.5)

    def _raise_arm(self):
        """Slow upward lerp of right-arm pivot to a wave pose."""
        self.right_arm_pivot.animate("rotation_x", -110,
                duration=1.4, curve=None)

    def _walk_away(self, on_complete):
        """Pathfind into the dark corner of the room (off-camera) and despawn."""
        # Lower arm
        self.right_arm_pivot.animate("rotation_x", 0, duration=1.0)
        target = self.position + Vec3(-7, 0, -9)
        self.animate("position", target, duration=4.0, curve=None)
        # Fade out
        for c in self.children:
            try:
                c.animate("color",
                        color.rgba(0, 0, 0, 0), duration=3.5)
            except Exception:
                pass
        invoke(self._despawn, on_complete, delay=4.2)

    def _despawn(self, on_complete):
        """Disable the entity and notify."""
        self.enabled = False
        destroy(self)
        if callable(on_complete):
            on_complete()


# ----------------------------------------------------------------------------
# Tracker - holds active Shapes for proximity/stare updates each frame
# ----------------------------------------------------------------------------

class ShapeTracker:
    """Holds every active Shape so the main loop can update them uniformly."""

    def __init__(self, audio):
        """audio: AudioManager. Tracker drives the signal-proximity tone."""
        self.audio = audio
        self.shapes = []
        self._proximity_volume = 0.0

    def register(self, shape):
        """Add a Shape to the tracker."""
        self.shapes.append(shape)

    def clear(self):
        """Drop all references (called on scene transition)."""
        self.shapes.clear()
        self._proximity_volume = 0.0
        self.audio.set_signal_proximity_volume(0.0)

    def update(self, player):
        """Drive per-Shape behavior + the global proximity tone volume."""
        target_vol = 0.0
        for s in self.shapes:
            if not s.enabled:
                continue
            d = distance(s.position, player.position)
            # 4 unit fade in
            if d < 4.0:
                v = (1.0 - d / 4.0) * 0.07
                if v > target_vol:
                    target_vol = v
            if isinstance(s, FelixShape):
                s.update_stare(player.fpc)
        # Smooth the proximity volume so it fades, not snaps
        self._proximity_volume += (target_vol - self._proximity_volume) * \
            min(1.0, time.dt * 4.0)
        self.audio.set_signal_proximity_volume(self._proximity_volume)
