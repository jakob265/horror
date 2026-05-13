"""
systems/player.py
-----------------
First-person controller for VOID FREQUENCY.

Wraps Ursina's FirstPersonController with:
    * Mouse look + adjustable sensitivity
    * WASD movement + Shift sprint + Ctrl crouch
    * Subtle head-bob while moving + breathing sway while standing still
    * F flashlight: spotlight on the camera with battery drain/recharge + HUD bar
    * E interact handled by InteractionManager
    * Tab notes journal handled by NotesManager
    * Escape pause menu handled by main.py

The flashlight is implemented as a SpotLight parented to the camera. Some
Ursina builds do not implement SpotLight; in that case we fall back to a
forward-facing emissive cone child that visually approximates a flashlight
beam and still gates the battery/HUD behavior the design calls for.
"""

import math

from ursina import (
    Entity, SpotLight, Text, Vec2, Vec3, camera, color, held_keys, mouse, time,
)
from ursina.prefabs.first_person_controller import FirstPersonController


class Player:
    """Player wrapper around Ursina's FirstPersonController."""

    def __init__(self):
        """Build the controller, flashlight, HUD, and head-bob state."""
        self.fpc = FirstPersonController(
            position=(0, 1.6, 0),
            speed=4.5,
            jump_height=0.0,
            gravity=1.0,
        )
        self.fpc.cursor.visible = False
        self.fpc.mouse_sensitivity = Vec2(40, 40)
        self.base_speed = 4.5
        self.base_camera_y = 2.0

        # ---------- Flashlight ----------
        self.flashlight_on = False
        self.flashlight_battery = 1.0   # 1.0 = full, 0.0 = empty
        self.flashlight = self._make_flashlight()
        self.flashlight.enabled = False

        # ---------- HUD ----------
        self._battery_bg = Entity(
            parent=camera.ui, model="quad",
            color=color.rgba(40, 40, 40, 220),
            scale=(0.16, 0.012), position=(-0.78, -0.46),
        )
        self._battery_bar = Entity(
            parent=camera.ui, model="quad",
            color=color.white,
            scale=(0.16, 0.012), position=(-0.78, -0.46, -0.01),
            origin=(-0.5, 0),
        )
        self._battery_bar.x = self._battery_bg.x - self._battery_bg.scale_x / 2
        self._battery_label = Text(
            text="BAT", parent=camera.ui, position=Vec2(-0.86, -0.46),
            origin=(0, 0), scale=0.7,
            color=color.rgba(200, 210, 230, 220),
            font="VeraMono.ttf",
        )
        # Crosshair (subtle dot)
        self._crosshair = Entity(
            parent=camera.ui, model="quad",
            color=color.rgba(220, 220, 230, 180),
            scale=(0.005, 0.005), position=(0, 0, -0.1),
        )

        # ---------- Head bob / breathing ----------
        self._bob_phase = 0.0
        self._breath_phase = 0.0
        self._frozen = False  # set True when a modal/menu is open
        self._crouching = False

    # ------------------------------------------------------------------
    # Flashlight construction (with graceful fallback)
    # ------------------------------------------------------------------

    def _make_flashlight(self):
        """Create the flashlight. Use SpotLight if available, else a fake cone."""
        try:
            light = SpotLight(parent=camera, shadows=False,
                              color=color.rgba(255, 240, 220, 255))
            # Cone angle ~ 28 degrees (Ursina SpotLight uses inner/outer attrs)
            try:
                light.inner = 18
                light.outer = 28
            except Exception:
                pass
            light.position = Vec3(0, 0, 0)
            light.rotation = Vec3(0, 0, 0)
            return light
        except Exception:
            # Fallback: a translucent emissive cone visually fakes a beam
            cone = Entity(parent=camera, model="cube",
                          scale=(0.18, 0.18, 0.6),
                          position=(0, -0.05, 0.5),
                          color=color.rgba(255, 240, 200, 22))
            cone.always_on_top = False
            return cone

    # ------------------------------------------------------------------
    # Public hooks
    # ------------------------------------------------------------------

    @property
    def position(self):
        """World position of the player feet."""
        return self.fpc.position

    @position.setter
    def position(self, v):
        """Teleport the player."""
        self.fpc.position = v

    @property
    def rotation_y(self):
        """Yaw of the player."""
        return self.fpc.rotation_y

    @rotation_y.setter
    def rotation_y(self, v):
        """Set yaw."""
        self.fpc.rotation_y = v

    def freeze(self):
        """Stop input + lock the mouse free (used during modals/menu)."""
        self._frozen = True
        self.fpc.enabled = False

    def unfreeze(self):
        """Resume input."""
        self._frozen = False
        self.fpc.enabled = True

    def set_mouse_sensitivity(self, val):
        """Apply a fresh mouse sensitivity (range ~ 10..120)."""
        self.fpc.mouse_sensitivity = Vec2(val, val)

    # ------------------------------------------------------------------
    # Flashlight + battery
    # ------------------------------------------------------------------

    def toggle_flashlight(self):
        """Press-F handler."""
        if self.flashlight_battery <= 0.0 and not self.flashlight_on:
            return
        self.flashlight_on = not self.flashlight_on
        self.flashlight.enabled = self.flashlight_on

    def _update_battery(self):
        """Drain or recharge the flashlight battery each frame, update the HUD."""
        dt = time.dt
        if self.flashlight_on:
            # 90 seconds full drain
            self.flashlight_battery -= dt / 90.0
            if self.flashlight_battery <= 0.0:
                self.flashlight_battery = 0.0
                self.flashlight_on = False
                self.flashlight.enabled = False
        else:
            # 2x recharge
            self.flashlight_battery += (dt / 90.0) * 2.0
            if self.flashlight_battery > 1.0:
                self.flashlight_battery = 1.0
        # HUD bar width
        full_w = 0.16
        self._battery_bar.scale_x = max(0.0001, full_w * self.flashlight_battery)
        # Color: white normally, pulse red below 15%
        if self.flashlight_battery < 0.15:
            pulse = 0.5 + 0.5 * math.sin(time.time() * 6.0)
            self._battery_bar.color = color.rgba(255, int(80 * pulse),
                                                 int(80 * pulse), 255)
        else:
            self._battery_bar.color = color.rgba(220, 220, 220, 255)

    # ------------------------------------------------------------------
    # Movement modifiers
    # ------------------------------------------------------------------

    def _update_movement(self):
        """Apply sprint and crouch state."""
        if self._frozen:
            return
        sprint = held_keys["shift"]
        crouch = held_keys["control"]
        speed = self.base_speed
        if sprint and not crouch:
            speed = self.base_speed * 1.6
        elif crouch:
            speed = self.base_speed * 0.6
        self.fpc.speed = speed

        # Crouch lowers the camera by 0.4 units (smooth)
        target_y = self.base_camera_y - (0.4 if crouch else 0.0)
        self.fpc.camera_pivot.y += (target_y - self.fpc.camera_pivot.y) * \
            min(1.0, time.dt * 10.0)
        self._crouching = crouch

    # ------------------------------------------------------------------
    # Head bob + breathing sway
    # ------------------------------------------------------------------

    def _update_head_bob(self):
        """Apply a tiny sine bob to camera Y when moving, breathing sway when still."""
        if self._frozen:
            return
        moving = (held_keys["w"] or held_keys["a"] or held_keys["s"]
                  or held_keys["d"])
        if moving:
            amp = 0.015 if not held_keys["shift"] else 0.028
            freq = 8.0 if not held_keys["shift"] else 11.0
            self._bob_phase += time.dt * freq
            offset = amp * math.sin(self._bob_phase)
        else:
            # Breathing sway: amplitude 0.004, frequency 0.28 Hz
            self._breath_phase += time.dt * (2.0 * math.pi * 0.28)
            offset = 0.004 * math.sin(self._breath_phase)
        # Apply on top of crouch-adjusted base camera_pivot.y
        base = self.base_camera_y - (0.4 if self._crouching else 0.0)
        self.fpc.camera_pivot.y = base + offset

    # ------------------------------------------------------------------
    # Frame update
    # ------------------------------------------------------------------

    def update(self):
        """Per-frame tick (call from main update)."""
        self._update_movement()
        self._update_head_bob()
        self._update_battery()

    def handle_input(self, key):
        """Forward key events to flashlight / etc."""
        if self._frozen:
            return
        if key == "f":
            self.toggle_flashlight()
