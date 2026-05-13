"""
systems/interaction.py
----------------------
The interaction subsystem for VOID FREQUENCY.

- Raycasts forward 1.8 units from the camera each frame
- Shows the floating "[E] - {label}" prompt when an 'interactable' is in range
- Routes interact_type to the right handler:
    examine_only, collect_note, read_terminal, move_object, keypad,
    toggle_door, trigger_event
"""

from ursina import (
    Entity, Text, Vec2, Vec3, camera, color, destroy, held_keys,
    invoke, mouse, raycast, time,
)


# Module-level singleton, set by main.py at boot.
_active = None


def get_manager():
    """Return the running InteractionManager (created in main.py)."""
    return _active


def set_manager(mgr):
    """Register the running InteractionManager."""
    global _active
    _active = mgr


# ----------------------------------------------------------------------------
# Helper to mark an Ursina entity as interactable
# ----------------------------------------------------------------------------

def make_interactable(entity, label, interact_type, **kwargs):
    """Attach the metadata the interaction raycast looks for.

    interact_type is one of:
        'examine_only'  - kwargs: text (str), [duration]
        'collect_note'  - kwargs: note_id
        'read_terminal' - kwargs: text (multi-line str), [title]
        'move_object'   - kwargs: offset (Vec3), [reveals_callback]
        'keypad'        - kwargs: code (str), on_unlock (callable)
        'toggle_door'   - kwargs: pivot (Entity)
        'trigger_event' - kwargs: callback (callable)
    """
    entity.tag = "interactable"
    entity.interact_label = label
    entity.interact_type = interact_type
    entity.interact_data = kwargs
    entity.interact_used = False
    entity.collision = True
    return entity


# ----------------------------------------------------------------------------
# Interaction manager
# ----------------------------------------------------------------------------

class InteractionManager:
    """Per-frame raycast + dispatch to the right interaction handler."""

    def __init__(self, player, notes, audio, on_modal_open=None,
                 on_modal_close=None):
        """player: the Player instance; notes: NotesManager; audio: AudioManager."""
        self.player = player
        self.notes = notes
        self.audio = audio
        self.modal_open = False
        self._on_modal_open = on_modal_open or (lambda: None)
        self._on_modal_close = on_modal_close or (lambda: None)
        self.prompt = Text(
            text="", parent=camera.ui,
            position=Vec2(0, 0.04), scale=1.0, origin=(0, 0),
            color=color.rgb(220, 225, 235),
            font="VeraMono.ttf",
        )
        self.examine_root = None
        self.terminal_root = None
        self.keypad_root = None
        self._keypad_buffer = ""
        self._keypad_target = None
        self._current_target = None
        set_manager(self)

    # --------------------------------------------------------------------
    # Per-frame raycast + prompt
    # --------------------------------------------------------------------

    def update(self):
        """Called each frame. Updates the prompt text based on the forward raycast."""
        if self.modal_open or self.notes.is_open:
            self.prompt.text = ""
            self._current_target = None
            return
        origin = camera.world_position
        direction = camera.forward
        hit = raycast(origin, direction, distance=1.8, ignore=[self.player],
                      debug=False)
        target = None
        if hit.hit and hit.entity is not None:
            ent = hit.entity
            # Walk up to find a parent with 'interactable' tag if needed
            if getattr(ent, "tag", None) != "interactable":
                p = ent.parent
                while p is not None and getattr(p, "tag", None) != "interactable":
                    p = getattr(p, "parent", None)
                if getattr(p, "tag", None) == "interactable":
                    ent = p
                else:
                    ent = None
            if ent is not None and getattr(ent, "tag", None) == "interactable":
                if not getattr(ent, "interact_used", False) or \
                   ent.interact_type in ("read_terminal", "toggle_door",
                                         "keypad", "examine_only"):
                    target = ent
        self._current_target = target
        if target is not None:
            self.prompt.text = "[E] " + target.interact_label
        else:
            self.prompt.text = ""

    # --------------------------------------------------------------------
    # Input dispatch
    # --------------------------------------------------------------------

    def handle_input(self, key):
        """Route key events for E interact, keypad input, modal close."""
        if key == "e":
            # E closes the active modal first
            if self.examine_root is not None:
                self._close_examine()
                return
            if self.terminal_root is not None:
                self._close_terminal()
                return
            if self.keypad_root is not None:
                self._keypad_submit()
                return
            self._trigger_current()
            return
        if key == "escape":
            if self.examine_root is not None:
                self._close_examine()
            if self.terminal_root is not None:
                self._close_terminal()
            if self.keypad_root is not None:
                self._close_keypad()
            return
        # Keypad number input
        if self.keypad_root is not None:
            if key in "0123456789" and len(self._keypad_buffer) < 6:
                self._keypad_buffer += key
                self._keypad_display.text = self._keypad_buffer + "_"
            elif key == "backspace":
                self._keypad_buffer = self._keypad_buffer[:-1]
                self._keypad_display.text = self._keypad_buffer + "_"
            elif key == "enter":
                self._keypad_submit()

    # --------------------------------------------------------------------
    # Dispatch to handler
    # --------------------------------------------------------------------

    def _trigger_current(self):
        """Invoke the right handler for whatever target the raycast is on."""
        ent = self._current_target
        if ent is None:
            return
        kind = ent.interact_type
        data = ent.interact_data
        if kind == "examine_only":
            self._examine(data.get("text", ""), data.get("duration", 3.0))
            ent.interact_used = True
        elif kind == "collect_note":
            self.notes.collect(data["note_id"], audio=self.audio)
            destroy(ent)
        elif kind == "read_terminal":
            self._open_terminal(data.get("title", "TERMINAL"),
                                data.get("text", ""))
        elif kind == "move_object":
            self._move_object(ent, data)
        elif kind == "keypad":
            self._open_keypad(ent, data)
        elif kind == "toggle_door":
            self._toggle_door(ent, data)
        elif kind == "trigger_event":
            cb = data.get("callback")
            if callable(cb):
                cb()
            ent.interact_used = True

    # --------------------------------------------------------------------
    # examine_only
    # --------------------------------------------------------------------

    def _examine(self, text, duration):
        """Show a single line of descriptive text near the bottom of the screen."""
        if self.examine_root is not None:
            destroy(self.examine_root)
        self.examine_root = Entity(parent=camera.ui)
        bg = Entity(parent=self.examine_root, model="quad",
                    color=color.rgba(0, 0, 0, 210),
                    scale=(1.4, 0.20), position=(0, -0.30, 0.4))
        Text(parent=self.examine_root, text=text, position=(0, -0.30),
             origin=(0, 0), scale=0.80, color=color.rgb(225, 225, 230),
             font="VeraMono.ttf", wordwrap=58)
        invoke(self._close_examine, delay=duration)

    def _close_examine(self):
        """Tear down the examine overlay."""
        if self.examine_root is not None:
            destroy(self.examine_root)
            self.examine_root = None

    # --------------------------------------------------------------------
    # read_terminal
    # --------------------------------------------------------------------

    def _open_terminal(self, title, body):
        """Open a fullscreen readable terminal display."""
        if self.modal_open:
            return
        self.modal_open = True
        self._on_modal_open()
        mouse.locked = False
        mouse.visible = True
        self.terminal_root = Entity(parent=camera.ui)
        Entity(parent=self.terminal_root, model="quad",
               color=color.rgba(0, 8, 12, 245),
               scale=(1.7, 1.0), position=(0, 0, 0.5))
        Text(parent=self.terminal_root, text=title,
             position=(-0.6, 0.42), scale=1.0,
             color=color.rgb(120, 220, 200), font="VeraMono.ttf")
        Text(parent=self.terminal_root, text=body,
             position=(-0.6, 0.36), scale=0.65, line_height=1.05,
             color=color.rgb(130, 230, 200), font="VeraMono.ttf",
             wordwrap=82)
        Text(parent=self.terminal_root, text="Close [E]",
             position=(0.50, -0.45), scale=0.85,
             color=color.rgba(120, 220, 200, 220),
             font="VeraMono.ttf")

    def _close_terminal(self):
        """Close the terminal modal."""
        if self.terminal_root is not None:
            destroy(self.terminal_root)
            self.terminal_root = None
        if self.modal_open:
            self.modal_open = False
            self._on_modal_close()
            mouse.locked = True
            mouse.visible = False

    # --------------------------------------------------------------------
    # move_object
    # --------------------------------------------------------------------

    def _move_object(self, ent, data):
        """Animate the entity to a small offset; mark it used; play scrape."""
        offset = data.get("offset", Vec3(0.6, 0, 0))
        new_pos = ent.position + offset
        ent.animate("position", new_pos, duration=0.5)
        if self.audio is not None:
            self.audio.scrape()
        ent.interact_used = True
        cb = data.get("after")
        if callable(cb):
            invoke(cb, delay=0.5)

    # --------------------------------------------------------------------
    # keypad
    # --------------------------------------------------------------------

    def _open_keypad(self, ent, data):
        """Open the digit-entry overlay tied to a particular keypad entity."""
        if self.modal_open:
            return
        self.modal_open = True
        self._on_modal_open()
        mouse.locked = False
        mouse.visible = True
        self._keypad_target = ent
        self._keypad_buffer = ""
        self.keypad_root = Entity(parent=camera.ui)
        Entity(parent=self.keypad_root, model="quad",
               color=color.rgba(0, 0, 0, 235),
               scale=(0.7, 0.7), position=(0, 0, 0.5))
        Text(parent=self.keypad_root, text="ENTER CODE",
             position=(0, 0.27), origin=(0, 0), scale=1.2,
             color=color.rgb(200, 220, 240), font="VeraMono.ttf")
        self._keypad_display = Text(
            parent=self.keypad_root, text="_",
            position=(0, 0.16), origin=(0, 0), scale=2.2,
            color=color.rgb(180, 240, 220), font="VeraMono.ttf")
        # Number grid
        for i in range(10):
            row = (i - 1) // 3 if i != 0 else 3
            col = (i - 1) % 3 if i != 0 else 1
            x = -0.16 + col * 0.16
            y = 0.04 - row * 0.08
            Text(parent=self.keypad_root, text=str(i),
                 position=(x, y), origin=(0, 0), scale=1.4,
                 color=color.rgba(180, 200, 220, 200),
                 font="VeraMono.ttf")
        Text(parent=self.keypad_root,
             text="[type digits]  [Enter]=confirm  [E]=confirm  [Esc]=cancel",
             position=(0, -0.30), origin=(0, 0), scale=0.7,
             color=color.rgba(150, 170, 190, 220),
             font="VeraMono.ttf")

    def _keypad_submit(self):
        """Validate the typed digit string against the target's expected code."""
        ent = self._keypad_target
        if ent is None or self.keypad_root is None:
            return
        expected = str(ent.interact_data.get("code", ""))
        if self._keypad_buffer == expected:
            self.audio.keypad_accept()
            cb = ent.interact_data.get("on_unlock")
            ent.interact_used = True
            self._close_keypad()
            if callable(cb):
                invoke(cb, delay=0.2)
        else:
            self.audio.keypad_reject()
            self._keypad_buffer = ""
            self._keypad_display.text = "_  (incorrect)"
            invoke(self._keypad_clear_message, delay=1.2)

    def _keypad_clear_message(self):
        """Reset the keypad display after a wrong-code message."""
        if self.keypad_root is not None:
            self._keypad_display.text = self._keypad_buffer + "_"

    def _close_keypad(self):
        """Tear down the keypad overlay."""
        if self.keypad_root is not None:
            destroy(self.keypad_root)
            self.keypad_root = None
        self._keypad_target = None
        if self.modal_open:
            self.modal_open = False
            self._on_modal_close()
            mouse.locked = True
            mouse.visible = False

    # --------------------------------------------------------------------
    # toggle_door
    # --------------------------------------------------------------------

    def _toggle_door(self, ent, data):
        """Rotate the door pivot 90 degrees (or back) over 0.4 s."""
        pivot = data.get("pivot", ent)
        opened = getattr(pivot, "_door_opened", False)
        target_y = 0 if opened else 90
        pivot.animate("rotation_y", target_y, duration=0.4)
        pivot._door_opened = not opened
        if self.audio is not None:
            self.audio.door()
