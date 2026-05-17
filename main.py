"""
main.py
-------
VOID FREQUENCY - entry point.

Boots Ursina, creates the global Game wrapper, shows the main menu, drives
the four-act flow + pause menu + endings, and routes player input each frame.

Run from source:    python main.py
Build to .exe:      build.bat   (Windows, produces dist/VoidFrequency.exe)
"""

import math
import random
import sys

from ursina import (
    Button, Entity, Text, Ursina, Vec2, Vec3, application, camera, color,
    destroy, held_keys, invoke, mouse, time, window,
)

from systems.audio import AudioManager
from systems.endings import EndingPlayer
from systems.entity import ShapeTracker, reset_global_state as reset_shape_state
from systems.interaction import InteractionManager
from systems.notes import NotesManager
from systems.olen import OlenManager
from systems.player import Player
from systems import visuals

# NOTE: scene module names follow the ORIGINAL four-act design.  The
# extended 10-act playthrough remaps which scene plays at which "act"
# slot (see _build_scene below).
import scenes.act1_cryo as scene_act1_cryo
import scenes.act2_corridor as scene_corridor
import scenes.act3_lab as scene_lab
import scenes.act4_array as scene_array
import scenes.act2_decon as scene_decon
import scenes.act4_lounge as scene_lounge
import scenes.act6_hydro as scene_hydro
import scenes.act7_engineering as scene_engineering
import scenes.act8_bridge as scene_bridge
import scenes.act9_approach as scene_approach


# ----------------------------------------------------------------------------
# State container
# ----------------------------------------------------------------------------

class GameState:
    """Plain bag for cross-scene flags."""

    def __init__(self):
        """Reset per New Game."""
        self.cryo_keycard = False
        self.cryo_door_open = False
        self.hatch_open = False
        self.array_keycard = False
        self.array_door_open = False
        self.hargrove_shape = None
        self.terminal_ui = None


# ----------------------------------------------------------------------------
# Post-processing - GLSL screenspace shader applied to the main camera
# ----------------------------------------------------------------------------

class _PostFX:
    """Camera-level vignette / scanlines / chromatic aberration / grain."""

    def __init__(self):
        """Apply the post-fx shader to the active camera."""
        try:
            camera.shader = visuals.POSTFX_SHADER
            camera.set_shader_input("u_time", 0.0)
            camera.set_shader_input("u_vignette", 0.30)
            camera.set_shader_input("u_desat", 0.08)
            camera.set_shader_input("u_scanline", 0.05)
            camera.set_shader_input("u_grain", 0.03)
            camera.set_shader_input("u_ca", 0.0018)
            self.enabled = True
        except Exception:
            self.enabled = False

    def set_act(self, act):
        """Tune per-act intensity. Acts 3+4 push desat + scanline."""
        if not self.enabled:
            return
        if act in ("act3", "act4"):
            camera.set_shader_input("u_desat", 0.18)
            camera.set_shader_input("u_scanline", 0.08)
            camera.set_shader_input("u_vignette", 0.38)
        elif act == "act1":
            camera.set_shader_input("u_desat", 0.05)
            camera.set_shader_input("u_scanline", 0.05)
            camera.set_shader_input("u_vignette", 0.32)
        else:
            camera.set_shader_input("u_desat", 0.10)
            camera.set_shader_input("u_scanline", 0.05)
            camera.set_shader_input("u_vignette", 0.30)

    def update(self):
        """Per-frame: advance the grain seed."""
        if self.enabled:
            camera.set_shader_input("u_time", time.time())


# ----------------------------------------------------------------------------
# Main menu
# ----------------------------------------------------------------------------

class MainMenu:
    """Full-black main menu with a glitchy VOID FREQUENCY title."""

    def __init__(self, on_new_game, on_quit):
        """Build the menu root + title + buttons."""
        self.on_new_game = on_new_game
        self.on_quit = on_quit
        self.root = Entity(parent=camera.ui)
        Entity(parent=self.root, model="quad",
               color=color.rgba(0, 0, 0, 255),
               scale=(2.5, 1.5), position=(0, 0, 0.5))
        # Title (we keep each character as its own Text for glitching)
        self.title_text = "VOID FREQUENCY"
        self.char_entities = []
        spacing = 0.058
        total_w = spacing * (len(self.title_text) - 1)
        for i, ch in enumerate(self.title_text):
            t = Text(parent=self.root, text=ch,
                     position=(-total_w / 2 + i * spacing, 0.20),
                     origin=(0, 0), scale=3.0,
                     color=color.rgb(230, 230, 240),
                     font="VeraMono.ttf")
            t._base_x = t.x
            self.char_entities.append(t)
        # Buttons
        try:
            Button(parent=self.root, text="NEW GAME",
                   position=(0, -0.08), scale=(0.5, 0.08),
                   color=color.rgba(50, 50, 60, 255),
                   text_color=color.rgb(230, 240, 250),
                   on_click=self._click_new)
            Button(parent=self.root, text="QUIT",
                   position=(0, -0.20), scale=(0.5, 0.08),
                   color=color.rgba(50, 50, 60, 255),
                   text_color=color.rgb(230, 240, 250),
                   on_click=self._click_quit)
        except Exception:
            Text(parent=self.root, text="[N]  NEW GAME      [Q]  QUIT",
                 position=(0, -0.10), origin=(0, 0), scale=1.2,
                 color=color.rgb(220, 230, 240), font="VeraMono.ttf")
        # Bottom line
        Text(parent=self.root,
             text="CRESTFALL-9 // SIGNAL LOG ARCHIVE // ALL TRANSMISSIONS STORED",
             position=(0, -0.45), origin=(0, 0), scale=0.7,
             color=color.rgba(120, 130, 140, 130),
             font="VeraMono.ttf")
        # Glitch timer
        self._glitch_timer = random.uniform(2.0, 6.0)
        self._big_shift_timer = random.uniform(12.0, 20.0)
        mouse.locked = False
        mouse.visible = True

    def _click_new(self):
        """NEW GAME pressed."""
        self.close()
        self.on_new_game()

    def _click_quit(self):
        """QUIT pressed."""
        self.on_quit()

    def update(self):
        """Drive the title glitching."""
        if self.root is None:
            return
        self._glitch_timer -= time.dt
        if self._glitch_timer <= 0:
            self._glitch_timer = random.uniform(2.0, 6.0)
            n = random.randint(1, 3)
            indices = random.sample(range(len(self.char_entities)), n)
            shift_amounts = []
            for idx in indices:
                t = self.char_entities[idx]
                shift_px = random.uniform(0.012, 0.028) * random.choice([-1, 1])
                t.x = t._base_x + shift_px
                shift_amounts.append((t, t._base_x))
            invoke(self._unshift, shift_amounts,
                   delay=random.uniform(0.05, 0.12))
        self._big_shift_timer -= time.dt
        if self._big_shift_timer <= 0:
            self._big_shift_timer = random.uniform(12.0, 20.0)
            for t in self.char_entities:
                t.x = t._base_x + 0.008
            invoke(self._big_unshift, delay=1.0 / 30.0)

    def _unshift(self, shift_amounts):
        """Reset characters from a small-scale glitch."""
        for t, x in shift_amounts:
            try:
                t.x = x
            except Exception:
                pass

    def _big_unshift(self):
        """Reset characters from the full-title shift."""
        for t in self.char_entities:
            try:
                t.x = t._base_x
            except Exception:
                pass

    def handle_input(self, key):
        """Keyboard fallback."""
        if self.root is None:
            return
        if key == "n":
            self._click_new()
        elif key == "q":
            self._click_quit()

    def close(self):
        """Destroy the menu overlay."""
        if self.root is not None:
            destroy(self.root)
            self.root = None


# ----------------------------------------------------------------------------
# Pause menu
# ----------------------------------------------------------------------------

RESOLUTION_OPTIONS = [
    (1280, 720),
    (1600, 900),
    (1920, 1080),
    (2560, 1440),
    (3840, 2160),
]


class PauseMenu:
    """Resume + Mouse sensitivity + Resolution / fullscreen + Quit to Main Menu."""

    def __init__(self, game):
        """Build the pause overlay; mark game as modal."""
        self.game = game
        self.root = Entity(parent=camera.ui)
        Entity(parent=self.root, model="quad",
               color=color.rgba(0, 0, 0, 220),
               scale=(1.4, 1.1), position=(0, 0, 0.5))
        Text(parent=self.root, text="-- PAUSED --",
             position=(0, 0.42), origin=(0, 0), scale=1.4,
             color=color.rgb(220, 220, 230), font="VeraMono.ttf")
        # Mouse sensitivity row
        Text(parent=self.root,
             text="Mouse sensitivity",
             position=(-0.30, 0.27), origin=(-0.5, 0), scale=0.75,
             color=color.rgb(200, 215, 230), font="VeraMono.ttf")
        self.sens_label = Text(
            parent=self.root, text=str(int(game.mouse_sens)),
            position=(0.30, 0.27), origin=(0.5, 0), scale=0.85,
            color=color.rgb(220, 230, 245), font="VeraMono.ttf")
        try:
            Button(parent=self.root, text="-",
                   position=(0.05, 0.27), scale=(0.05, 0.06),
                   color=color.rgba(50, 55, 70, 255),
                   text_color=color.rgb(225, 235, 245),
                   on_click=lambda: game.adjust_mouse_sens(-5))
            Button(parent=self.root, text="+",
                   position=(0.14, 0.27), scale=(0.05, 0.06),
                   color=color.rgba(50, 55, 70, 255),
                   text_color=color.rgb(225, 235, 245),
                   on_click=lambda: game.adjust_mouse_sens(+5))
        except Exception:
            pass

        # Resolution row
        Text(parent=self.root, text="Resolution",
             position=(-0.30, 0.15), origin=(-0.5, 0), scale=0.75,
             color=color.rgb(200, 215, 230), font="VeraMono.ttf")
        self.res_label = Text(
            parent=self.root, text=self._res_text(),
            position=(0.30, 0.15), origin=(0.5, 0), scale=0.75,
            color=color.rgb(220, 230, 245), font="VeraMono.ttf")
        try:
            Button(parent=self.root, text="<",
                   position=(-0.06, 0.15), scale=(0.05, 0.06),
                   color=color.rgba(50, 55, 70, 255),
                   text_color=color.rgb(225, 235, 245),
                   on_click=lambda: game.cycle_resolution(-1))
            Button(parent=self.root, text=">",
                   position=(0.02, 0.15), scale=(0.05, 0.06),
                   color=color.rgba(50, 55, 70, 255),
                   text_color=color.rgb(225, 235, 245),
                   on_click=lambda: game.cycle_resolution(+1))
        except Exception:
            pass

        # Fullscreen row
        Text(parent=self.root, text="Fullscreen",
             position=(-0.30, 0.03), origin=(-0.5, 0), scale=0.75,
             color=color.rgb(200, 215, 230), font="VeraMono.ttf")
        self.fs_label = Text(
            parent=self.root, text=("ON" if game.fullscreen else "OFF"),
            position=(0.30, 0.03), origin=(0.5, 0), scale=0.85,
            color=color.rgb(220, 230, 245), font="VeraMono.ttf")
        try:
            Button(parent=self.root, text="Toggle",
                   position=(0.00, 0.03), scale=(0.18, 0.06),
                   color=color.rgba(50, 55, 70, 255),
                   text_color=color.rgb(225, 235, 245),
                   on_click=game.toggle_fullscreen)
        except Exception:
            pass

        try:
            Button(parent=self.root, text="RESUME",
                   position=(0, -0.16), scale=(0.45, 0.08),
                   color=color.rgba(60, 60, 80, 255),
                   text_color=color.rgb(225, 235, 245),
                   on_click=game.resume_from_pause)
            Button(parent=self.root, text="QUIT TO MAIN MENU",
                   position=(0, -0.30), scale=(0.45, 0.08),
                   color=color.rgba(60, 50, 60, 255),
                   text_color=color.rgb(225, 215, 220),
                   on_click=game.quit_to_menu)
        except Exception:
            Text(parent=self.root,
                 text="[R] Resume     [Q] Quit to menu",
                 position=(0, -0.16), origin=(0, 0), scale=0.9,
                 color=color.rgb(220, 230, 245),
                 font="VeraMono.ttf")
        Text(parent=self.root,
             text="(keys: [-]/[+] sens   [<]/[>] res   [B] fullscreen)",
             position=(0, -0.42), origin=(0, 0), scale=0.6,
             color=color.rgba(160, 175, 195, 200),
             font="VeraMono.ttf")
        mouse.locked = False
        mouse.visible = True

    def _res_text(self):
        """Format the current resolution string."""
        w, h = self.game.resolution
        return f"{w} x {h}"

    def update_sens(self, new_val):
        """Reflect new mouse sensitivity in the label and on the controller."""
        self.sens_label.text = str(int(new_val))

    def update_resolution(self, w, h):
        """Reflect new resolution selection in the label."""
        try:
            self.res_label.text = f"{w} x {h}"
        except Exception:
            pass

    def update_fullscreen(self, on):
        """Reflect new fullscreen state in the label."""
        try:
            self.fs_label.text = "ON" if on else "OFF"
        except Exception:
            pass

    def close(self):
        """Destroy the pause overlay."""
        if self.root is not None:
            destroy(self.root)
            self.root = None


# ----------------------------------------------------------------------------
# Scene-transition fade overlay
# ----------------------------------------------------------------------------

class _Fader:
    """Full-screen black overlay used for act-to-act fade out / in."""

    def __init__(self):
        """Build the (initially transparent) fader."""
        self.quad = Entity(parent=camera.ui, model="quad",
                           color=color.rgba(0, 0, 0, 0),
                           scale=(2.5, 1.5), position=(0, 0, 0.4))

    def fade_to_black(self, duration=0.8, on_done=None):
        """Animate alpha 0 -> 255."""
        steps = 18
        for i in range(steps):
            a = int(255 * (i + 1) / steps)

            def setter(alpha=a):
                self.quad.color = color.rgba(0, 0, 0, alpha)
            invoke(setter, delay=duration * (i + 1) / steps)
        if callable(on_done):
            invoke(on_done, delay=duration + 0.02)

    def fade_from_black(self, duration=1.2):
        """Animate alpha 255 -> 0."""
        steps = 22
        for i in range(steps):
            a = int(255 * (1 - (i + 1) / steps))

            def setter(alpha=a):
                self.quad.color = color.rgba(0, 0, 0, alpha)
            invoke(setter, delay=duration * (i + 1) / steps)


# ----------------------------------------------------------------------------
# Game wrapper
# ----------------------------------------------------------------------------

class Game:
    """Top-level Game object: owns subsystems, drives main loop."""

    def __init__(self):
        """Wire up subsystems but leave the player + scenes uninstantiated."""
        self.mouse_sens = 40
        # Resolution / fullscreen tracking - default matches the size used
        # at Ursina() init.
        self.resolution = (1280, 720)
        self.resolution_idx = RESOLUTION_OPTIONS.index((1280, 720)) \
            if (1280, 720) in RESOLUTION_OPTIONS else 0
        self.fullscreen = False
        self.audio = AudioManager()
        self.notes = NotesManager(
            on_open=lambda: self._set_player_freeze(True),
            on_close=lambda: self._set_player_freeze(False))
        self.olen = OlenManager(self.audio)
        self.player = None
        self.interaction = None
        self.shapes = ShapeTracker(self.audio)
        self.ending_player = None
        self.menu = None
        self.pause_menu = None
        self.postfx = None
        self.fader = _Fader()
        self.state = GameState()
        self.world_root = Entity()    # parent for scene-only entities (unused but reserved)
        self.scene_entities = []
        self.tickers = []             # functions called every frame
        self.current_act = None
        self.is_paused = False
        self.modal_count = 0
        self.in_ending = False
        self._has_first_move_been_seen = False
        self.light_rig = None         # per-scene LightRig
        self.sky = None               # starfield sphere
        # Generate procedural textures now that asset_folder is wired up
        visuals.bake_all_textures()
        # Show main menu
        self._show_main_menu()

    # ------------------------------------------------------------------
    # Modal lock helper
    # ------------------------------------------------------------------

    def _set_player_freeze(self, frozen):
        """Pause/unfreeze the player. Used by Notes/Interaction/PauseMenu."""
        if self.player is None:
            return
        if frozen:
            self.modal_count += 1
            self.player.freeze()
        else:
            self.modal_count -= 1
            if self.modal_count <= 0:
                self.modal_count = 0
                self.player.unfreeze()
                mouse.locked = True
                mouse.visible = False

    def set_modal(self, on):
        """Public wrapper used by other systems (Terminal UI)."""
        self._set_player_freeze(on)

    # ------------------------------------------------------------------
    # Main menu / start
    # ------------------------------------------------------------------

    def _show_main_menu(self):
        """Display the main menu."""
        if self.postfx is None:
            self.postfx = _PostFX()
        self.menu = MainMenu(on_new_game=self._begin_new_game,
                             on_quit=self._quit_app)

    def _begin_new_game(self):
        """Start a fresh playthrough at Act 1."""
        # Tear down the main menu if still showing
        if self.menu is not None:
            try:
                self.menu.close()
            except Exception:
                pass
            self.menu = None
        # Reset module-level Shape state
        reset_shape_state()
        self.state = GameState()
        self._has_first_move_been_seen = False
        # Build player
        if self.player is None:
            self.player = Player()
            self.player.set_mouse_sensitivity(self.mouse_sens)
            self.interaction = InteractionManager(
                self.player, self.notes, self.audio,
                on_modal_open=lambda: self._set_player_freeze(True),
                on_modal_close=lambda: self._set_player_freeze(False))
        else:
            self.player.fpc.enabled = True
        # Reset olen
        self.olen.fired.clear()
        self.olen.reset_scene_triggers()
        # Start Act 1
        self.current_act = None
        self.transition_to("act1", instant_in=True)

    def _quit_app(self):
        """Hard-exit the app."""
        application.quit()

    # ------------------------------------------------------------------
    # Public helpers used by scene modules
    # ------------------------------------------------------------------

    def register_ticker(self, fn):
        """Register a per-frame update function (cleared each scene transition)."""
        self.tickers.append(fn)

    def show_examine(self, text, duration=3.0):
        """Used by callbacks that aren't tied to an interactable entity."""
        if self.interaction is not None:
            self.interaction._examine(text, duration)

    # ------------------------------------------------------------------
    # Scene transitions
    # ------------------------------------------------------------------

    def transition_to(self, act, instant_in=False):
        """Fade out, tear down current scene, build new scene, fade in.

        Guards against re-entry: each scene's check_transition ticker fires
        every frame, so without this guard 60+ do_swap callbacks pile up
        during the 0.8s fade and the build runs that many times, exploding
        the entity count and crashing the game.
        """
        if self.current_act == act:
            return
        if getattr(self, "_transitioning", False):
            return
        self._transitioning = True
        target = act

        def do_swap():
            """Inside the fade - rebuild the world."""
            self._teardown_scene()
            self._build_scene(target)
            self.current_act = target
            self._transitioning = False
            if self.postfx is not None:
                self.postfx.set_act(target)
            if instant_in:
                self.fader.quad.color = color.rgba(0, 0, 0, 0)
            else:
                self.fader.fade_from_black(duration=1.2)
            mouse.locked = True
            mouse.visible = False

        if self.current_act is None and instant_in:
            do_swap()
            return
        self.fader.fade_to_black(duration=0.8, on_done=do_swap)

    def _teardown_scene(self):
        """Destroy current scene entities + clear per-scene state."""
        for e in self.scene_entities:
            try:
                destroy(e)
            except Exception:
                pass
        self.scene_entities = []
        self.tickers = []
        self.olen.reset_scene_triggers()
        self.shapes.clear()
        if self.light_rig is not None:
            self.light_rig.destroy()
            self.light_rig = None
        if self.sky is not None:
            try:
                destroy(self.sky)
            except Exception:
                pass
            self.sky = None

    def _build_scene(self, act):
        """Dispatch to the appropriate scene module + set up lights, sky, fog."""
        # Build the starfield sky for every scene (visible through windows)
        try:
            self.sky = visuals.make_sky()
        except Exception:
            self.sky = None
        # 10-act playthrough order:
        #  act1  cryo bay         act6  hydroponics
        #  act2  decon antecham   act7  engineering
        #  act3  residential cor  act8  bridge / comms
        #  act4  observation lng  act9  approach corridor
        #  act5  signal lab       act10 array room
        if act == "act1":
            self.light_rig = visuals.make_act1_lights()
            self.scene_entities = scene_act1_cryo.build(self)
        elif act == "act2":
            self.light_rig = visuals.make_act2_lights()
            self.scene_entities = scene_decon.build(self)
        elif act == "act3":
            self.light_rig = visuals.make_act2_lights()
            self.scene_entities = scene_corridor.build(self)
        elif act == "act4":
            self.light_rig = visuals.make_act2_lights()
            self.scene_entities = scene_lounge.build(self)
        elif act == "act5":
            self.light_rig = visuals.make_act3_lights()
            self.scene_entities = scene_lab.build(self)
        elif act == "act6":
            self.light_rig = visuals.make_act3_lights()
            self.scene_entities = scene_hydro.build(self)
        elif act == "act7":
            self.light_rig = visuals.make_act3_lights()
            self.scene_entities = scene_engineering.build(self)
        elif act == "act8":
            self.light_rig = visuals.make_act3_lights()
            self.scene_entities = scene_bridge.build(self)
        elif act == "act9":
            self.light_rig = visuals.make_act4_lights()
            self.scene_entities = scene_approach.build(self)
        elif act == "act10":
            self.light_rig = visuals.make_act4_lights()
            self.scene_entities = scene_array.build(self)
        # Reset the FPC's accumulated air_time so gravity doesn't carry a
        # massive downward velocity through the transition (this would
        # otherwise drop the player far below the new floor before the
        # collider catches them).
        if self.player is not None:
            try:
                self.player.fpc.air_time = 0
                self.player.fpc.jumping = False
            except Exception:
                pass
        # Unlit rendering: keep Ursina's default shader so Entity colors and
        # textures render predictably across all hardware. Lights stay as
        # mood/atmosphere via emissive fixtures and fog.
        pass

    # ------------------------------------------------------------------
    # Pause
    # ------------------------------------------------------------------

    def open_pause(self):
        """Show the pause menu."""
        if self.is_paused or self.in_ending or self.menu is not None:
            return
        self.is_paused = True
        self._set_player_freeze(True)
        self.pause_menu = PauseMenu(self)

    def resume_from_pause(self):
        """Close the pause menu."""
        if not self.is_paused:
            return
        self.is_paused = False
        if self.pause_menu is not None:
            self.pause_menu.close()
            self.pause_menu = None
        self._set_player_freeze(False)

    def quit_to_menu(self):
        """End the current run, return to the main menu."""
        if self.pause_menu is not None:
            self.pause_menu.close()
            self.pause_menu = None
        self.is_paused = False
        self._teardown_scene()
        if self.player is not None:
            try:
                destroy(self.player.fpc)
            except Exception:
                pass
            self.player = None
            self.interaction = None
        # reset hum
        self.audio.station_hum.volume = 0.12
        self.audio.signal_tone.volume = 0.0
        self.audio.signal_tone_harm.volume = 0.0
        self._show_main_menu()

    def adjust_mouse_sens(self, delta):
        """Bump mouse sensitivity by delta (clamped 5..120)."""
        self.mouse_sens = max(5, min(120, self.mouse_sens + delta))
        if self.player is not None:
            self.player.set_mouse_sensitivity(self.mouse_sens)
        if self.pause_menu is not None:
            self.pause_menu.update_sens(self.mouse_sens)

    # ------------------------------------------------------------------
    # Resolution / fullscreen
    # ------------------------------------------------------------------

    def cycle_resolution(self, direction):
        """Step through RESOLUTION_OPTIONS by `direction` (-1 or +1)."""
        self.resolution_idx = (self.resolution_idx + direction) \
            % len(RESOLUTION_OPTIONS)
        w, h = RESOLUTION_OPTIONS[self.resolution_idx]
        self.resolution = (w, h)
        try:
            window.size = (w, h)
        except Exception:
            try:
                from panda3d.core import WindowProperties
                import builtins as _b
                wp = WindowProperties()
                wp.set_size(w, h)
                _b.base.win.request_properties(wp)
            except Exception:
                pass
        if self.pause_menu is not None:
            self.pause_menu.update_resolution(w, h)

    def toggle_fullscreen(self):
        """Toggle fullscreen mode."""
        self.fullscreen = not self.fullscreen
        try:
            window.fullscreen = self.fullscreen
        except Exception:
            try:
                from panda3d.core import WindowProperties
                import builtins as _b
                wp = WindowProperties()
                wp.set_fullscreen(self.fullscreen)
                _b.base.win.request_properties(wp)
            except Exception:
                pass
        if self.pause_menu is not None:
            self.pause_menu.update_fullscreen(self.fullscreen)

    # ------------------------------------------------------------------
    # Endings
    # ------------------------------------------------------------------

    def start_ending(self, which):
        """Trigger Ending A (DESTROY) or Ending B (LISTEN)."""
        if self.in_ending:
            return
        self.in_ending = True
        # Lock player, hide HUD-ish elements
        self._set_player_freeze(True)
        if self.player is not None:
            try:
                self.player.flashlight.enabled = False
            except Exception:
                pass
            self.player._battery_bar.enabled = False
            self.player._battery_bg.enabled = False
            self.player._battery_label.enabled = False
            self.player._crosshair.enabled = False
        if self.interaction is not None:
            self.interaction.prompt.enabled = False
        if self.ending_player is None:
            self.ending_player = EndingPlayer(self.audio,
                                              on_return_to_menu=self._end_to_menu)
        else:
            # Force fresh state per playthrough
            self.ending_player.audio = self.audio
            self.ending_player.on_return = self._end_to_menu
        if which == "A":
            self.ending_player.play_ending_a()
        else:
            self.ending_player.play_ending_b()

    def _end_to_menu(self):
        """Called when the player clicks Return to Main Menu after an ending."""
        self.in_ending = False
        if self.player is not None:
            self.player._battery_bar.enabled = True
            self.player._battery_bg.enabled = True
            self.player._battery_label.enabled = True
            self.player._crosshair.enabled = True
        if self.interaction is not None:
            self.interaction.prompt.enabled = True
        self.quit_to_menu()

    # ------------------------------------------------------------------
    # Frame update
    # ------------------------------------------------------------------

    def update(self):
        """Per-frame tick - drives subsystems, scene tickers, and OLEN."""
        if self.postfx is not None:
            self.postfx.update()
        if self.menu is not None:
            self.menu.update()
            return
        # First-move gate for Intercom 1
        if (self.player is not None and not self.is_paused
                and not self._has_first_move_been_seen):
            if held_keys["w"] or held_keys["a"] or held_keys["s"] or \
                    held_keys["d"]:
                self._has_first_move_been_seen = True
                self.olen.mark_first_move()
        if self.player is not None and not self.is_paused:
            self.player.update()
        if self.interaction is not None and not self.is_paused:
            self.interaction.update()
        if not self.is_paused:
            for fn in list(self.tickers):
                try:
                    fn()
                except Exception:
                    pass
            if self.player is not None:
                self.olen.update(self.player.position)
                self.shapes.update(self.player)

    # ------------------------------------------------------------------
    # Input
    # ------------------------------------------------------------------

    def input(self, key):
        """Dispatch raw input to the right subsystem."""
        if self.menu is not None:
            self.menu.handle_input(key)
            return
        if self.in_ending and self.ending_player is not None:
            self.ending_player.handle_input(key)
            return
        if self.is_paused:
            if key == "r":
                self.resume_from_pause()
            elif key == "q":
                self.quit_to_menu()
            elif key in ("+", "="):
                self.adjust_mouse_sens(+5)
            elif key in ("-", "_"):
                self.adjust_mouse_sens(-5)
            elif key in ("<", ","):
                self.cycle_resolution(-1)
            elif key in (">", "."):
                self.cycle_resolution(+1)
            elif key == "b":
                self.toggle_fullscreen()
            return
        if key == "escape":
            # Close any modal first; else open pause
            if self.notes.is_open:
                self.notes.close()
                return
            if (self.interaction is not None and
                    (self.interaction.examine_root is not None or
                     self.interaction.terminal_root is not None or
                     self.interaction.keypad_root is not None)):
                self.interaction.handle_input("escape")
                return
            self.open_pause()
            return
        # Notes journal handling first (Tab + 1..7 + E to close reader)
        self.notes.handle_input(key)
        # Terminal UI (Act 4)
        if (self.state is not None and self.state.terminal_ui is not None
                and self.state.terminal_ui.is_open):
            self.state.terminal_ui.handle_input(key)
        # Interaction system
        if self.interaction is not None:
            self.interaction.handle_input(key)
        # Player input (flashlight)
        if self.player is not None:
            self.player.handle_input(key)


# ----------------------------------------------------------------------------
# Bootstrap
# ----------------------------------------------------------------------------

def main():
    """App entry point."""
    app = Ursina(title="Void Frequency", borderless=False, fullscreen=False,
                 vsync=True)
    window.color = color.rgb(8, 8, 12)
    window.exit_button.enabled = False
    window.fps_counter.enabled = False
    window.title = "VOID FREQUENCY"

    game = Game()

    def _on_update():
        """Global per-frame hook."""
        game.update()

    def _on_input(key):
        """Global input hook."""
        game.input(key)

    # Ursina expects free-floating update() / input(key) functions in __main__
    # Attach them to the running module
    import builtins
    builtins.update = _on_update      # not strictly needed
    sys.modules["__main__"].update = _on_update
    sys.modules["__main__"].input = _on_input

    app.run()


if __name__ == "__main__":
    main()
