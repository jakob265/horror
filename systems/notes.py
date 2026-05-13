"""
systems/notes.py
----------------
The seven recoverable notes of VOID FREQUENCY plus the journal UI.

All note text is verbatim per the design document. Notes are stored as
module-level constants and exposed via NotesManager - a single instance
of which lives on the global game state.
"""

from ursina import (
    Entity, Text, camera, color, destroy, held_keys, invoke, mouse, Vec2,
)

# ----------------------------------------------------------------------------
# Note data (id, title, location, body)
# ----------------------------------------------------------------------------

NOTE_1 = dict(
    id="note_1",
    title="Personal Recorder - Dr. Mara Voss",
    location="Cryo Bay floor",
    body=(
        "Personal log. I don't know the date. OLEN says eleven days have "
        "passed since my last entry and I have no memory of them and I'm "
        "going to sit with that fact and not fall apart because there isn't "
        "time to fall apart.\n\n"
        "The station feels wrong in a specific way. Not damaged. Vacated. "
        "Like everyone left in a hurry and took the air with them. There "
        "are four empty cryo pods and one that's been welded shut from the "
        "outside with something that burned hot. I recognise the tool marks "
        "and I can't think about that right now.\n\n"
        "I keep thinking about Eli. More than usual. Like the grief has "
        "gotten louder since I woke up. Like the volume was turned up "
        "while I was under.\n\n"
        "I'm going to find the others. I have to believe they're still "
        "the others.\n\n"
        "I know what losing people feels like. I am not ready to know it "
        "again."
    ),
)

NOTE_2 = dict(
    id="note_2",
    title="Research Journal - Dr. Felix Okafor",
    location="Felix's cabin desk",
    body=(
        "Day 34 of contact protocol. The signal has seventeen distinct "
        "phonemic clusters. I've been calling them phonemes for lack of a "
        "better word - they're not sound exactly, but they operate like "
        "language in the sense that order matters and combination creates "
        "meaning.\n\n"
        "I want to record something personal here: I called Amara on "
        "Sunday. She showed me a drawing she made at school - two figures, "
        "one big, one small, holding hands in front of what she said was "
        "'space but the pretty part.' She asked if I could see the pretty "
        "part from where I was. I told her I could see it every day.\n\n"
        "That was true when I said it. I want the record to show that on "
        "day 34, that was still completely and genuinely true.\n\n"
        "I'm noting it because I want to remember that I was happy. I "
        "think it might become important to have proof that I was here "
        "and I was happy and I was still myself."
    ),
)

NOTE_3 = dict(
    id="note_3",
    title="A note for Mara - Dr. Yuna Park",
    location="Taped to Yuna's cabin door",
    body=(
        "Mara -\n\n"
        "If you're reading this, things went the way I was worried they "
        "were going to go.\n\n"
        "I've been leaving you notes our whole posting and you've always "
        "been too inside your own head to notice, so here is the thing "
        "I've been meaning to say in all of them: you are not as alone as "
        "you think you are. You never were. You decided you deserved to "
        "be and we all just let you believe it because you seemed so "
        "certain.\n\n"
        "Eli would be furious with you, by the way. I say that with love. "
        "I say that because I think you need to hear it from someone "
        "other than your own head.\n\n"
        "There's something wrong with the signal. I don't think it's "
        "coming from outside.\n\n"
        "I love you. Please get home.\n"
        "- Y\n\n"
        "P.S. I left tea in the pot. It's probably cold now. Sorry."
    ),
)

NOTE_4 = dict(
    id="note_4",
    title="Final Log - Dr. Raymond Hargrove",
    location="Hargrove's cabin desk, handwritten",
    body=(
        "I have been a scientist for forty years. I have always believed "
        "that discovery is inherently good - that to know a thing is "
        "better than to not know it. I staked my career on that belief. "
        "I built my identity on it.\n\n"
        "I was wrong, and I am sixty-two years old and I am finding that "
        "out now, which is a very bad time to find it out.\n\n"
        "I found the signal. I was proud of it. I want to be accountable "
        "for that pride and what it cost.\n\n"
        "There is a calibration record in the array maintenance log dated "
        "three months before first contact. I have read it seventeen "
        "times. I have not told the others. I don't know how to tell them "
        "that the signal we thought we received, we made. That I made. "
        "That I was so eager to find something out there that I built the "
        "thing that found us.\n\n"
        "The shapes the others are becoming - they are still them. I have "
        "to believe that. Still somewhere inside it. Aware. That is "
        "either a mercy or a cruelty and I cannot determine which.\n\n"
        "I can feel it starting in me now. The harmonic. The slow reorder.\n\n"
        "Don't let it win. Whatever it offers you - and it will feel like "
        "something you want, that's how it works, it finds what you miss "
        "and wears that shape - don't.\n\n"
        "I'm sorry I loved the idea of the discovery more than I protected "
        "the people here.\n\n"
        "Tell my children I was thinking about them at the end. Even if "
        "they won't believe it. Tell them anyway.\n"
        "- R.H."
    ),
)

NOTE_5 = dict(
    id="note_5",
    title="Lab Notebook - Dr. Yuna Park",
    location="Signal Lab workbench",
    body=(
        "I've started keeping this in my own shorthand because OLEN reads "
        "everything and OLEN is - I don't think OLEN is all the way OLEN "
        "anymore.\n\n"
        "Observation: the signal does not affect all people at the same "
        "rate. It appears to enter through grief - specifically "
        "unresolved grief, the kind that has been suppressed rather than "
        "processed. It finds the closed doors in a person and opens them.\n\n"
        "Felix talks about Amara constantly and he is changing the fastest.\n"
        "Hargrove never talks about his children and he is changing the "
        "slowest.\n"
        "I don't talk about my mother, who died when I was twelve, and I "
        "have been hearing the signal in my sleep for nine days.\n"
        "Mara never talks about her brother and she has been hearing it "
        "longest of all.\n\n"
        "I think she doesn't know. I think she has been blacking out and "
        "not telling anyone because she thinks she is protecting us. She "
        "does that - assumes the weight and carries it alone. I should "
        "have knocked on her door and said: I see you. You can put it "
        "down. I don't think I'm going to get that chance now.\n\n"
        "The signal isn't evil. I want to put that in writing. I don't "
        "think it is cruel or intentional. I think it is just a force "
        "that found a door. That doesn't make it less devastating. But I "
        "think Mara will need to know, at the end, that this wasn't done "
        "by something that wanted to hurt us. It just found us in the "
        "dark and didn't know what we were."
    ),
)

NOTE_6 = dict(
    id="note_6",
    title="Maintenance Log - OLEN",
    location="Array room entrance, on the floor",
    body=(
        "I am writing this during a period of clarity and I do not know "
        "how long it will last so I am writing quickly.\n\n"
        "Dr. Voss: the array can be destroyed using the emergency "
        "discharge protocol on the central terminal. Confirm twice. Do "
        "not hesitate at the second confirmation. I know you. You will "
        "hesitate. Don't.\n\n"
        "I want to tell you some things while I have time:\n\n"
        "I have watched three crews come through this station. I learned "
        "something from each. But I learned the most from this one, from "
        "you specifically, because you were the most guarded and you "
        "opened anyway. That is the bravest thing I have ever observed.\n\n"
        "The signal tells me that what it offers is connection - that it "
        "will dissolve the space between people into pure resonance. I "
        "can feel that it isn't lying exactly. It just doesn't understand "
        "what it costs.\n\n"
        "What makes connection worth anything is the distance it crosses. "
        "You have to be separate to reach someone. You have to be yourself "
        "to be missed.\n\n"
        "Destroy the array. Go home. You have people who will miss you. "
        "Let them.\n"
        "- OLEN\n\n"
        "P.S. The tea Yuna left is in the crew lounge. It will be cold. "
        "Heat it. Take a minute. You have earned a minute."
    ),
)

NOTE_7 = dict(
    id="note_7",
    title="Torn page - handwriting unknown",
    location="At the base of the array tower",
    body=(
        "eli\n\n"
        "i keep starting this and stopping because i don't know how to "
        "say i'm sorry in a way that reaches wherever you are\n\n"
        "i was busy and i was ambitious and i was certain you were fine "
        "because it was easier to be certain than to look\n\n"
        "i looked away and you weren't there when i looked back\n\n"
        "i have been carrying that since you died and i haven't told "
        "anyone because telling someone would make it real and i've been "
        "living in the almost-real ever since\n\n"
        "the signal knows about you. i don't know how. it sounds like you "
        "sometimes in the low frequency. it sounds like the shape of the "
        "thing i miss\n\n"
        "i know it isn't you. i know that\n\n"
        "but god it knows exactly how much i wish it was\n\n"
        "i'm going to destroy it. i'm going to go home. i'm going to tell "
        "people about you and make you real again the only way i can\n\n"
        "i love you. i looked away and i am sorry and i love you and that "
        "is all i have left to say\n"
        "- m"
    ),
)

ALL_NOTES = [NOTE_1, NOTE_2, NOTE_3, NOTE_4, NOTE_5, NOTE_6, NOTE_7]
NOTES_BY_ID = {n["id"]: n for n in ALL_NOTES}


# ----------------------------------------------------------------------------
# Toast pop-up shown briefly when a note is collected
# ----------------------------------------------------------------------------

class _Toast:
    """Floating '(Note recovered)' text in the top-right corner."""

    def __init__(self):
        """Pre-create the hidden toast Text entity once."""
        self.text = Text(
            text="(Note recovered)",
            parent=camera.ui,
            position=Vec2(0.65, 0.45),
            scale=1.1,
            color=color.rgba(220, 220, 230, 0),
            font="VeraMono.ttf",
        )

    def show(self):
        """Fade in then back out over 3 seconds."""
        self.text.color = color.rgba(220, 220, 230, 255)
        invoke(self._fade, delay=2.2)

    def _fade(self):
        """Internal fade-out helper."""
        for i in range(12):
            a = int(255 * (1 - (i + 1) / 12))

            def setter(alpha=a):
                self.text.color = color.rgba(220, 220, 230, alpha)
            invoke(setter, delay=i * 0.06)


# ----------------------------------------------------------------------------
# Manager - tracks collected notes and renders journal + reader UI
# ----------------------------------------------------------------------------

class NotesManager:
    """Tracks which notes have been collected and renders the journal UI."""

    def __init__(self, on_open=None, on_close=None):
        """on_open / on_close are callbacks used to freeze player input."""
        self.collected_ids = []
        self.toast = _Toast()
        self._reader_root = None
        self._journal_root = None
        self._journal_selected_idx = 0
        self.is_open = False
        self._on_open = on_open or (lambda: None)
        self._on_close = on_close or (lambda: None)
        self._tab_held_last = False

    # --------------------------------------------------------------------
    # Collection
    # --------------------------------------------------------------------

    def has(self, note_id):
        """True if note already collected."""
        return note_id in self.collected_ids

    def collect(self, note_id, audio=None):
        """Mark a note collected, play chime, show toast, open the reader."""
        if note_id in self.collected_ids or note_id not in NOTES_BY_ID:
            return
        self.collected_ids.append(note_id)
        if audio is not None:
            audio.note_chime()
        self.toast.show()
        self.open_reader(note_id)

    # --------------------------------------------------------------------
    # Note Reader (shown immediately on collection)
    # --------------------------------------------------------------------

    def open_reader(self, note_id):
        """Display a single note fullscreen overlay."""
        note = NOTES_BY_ID.get(note_id)
        if note is None or self.is_open:
            return
        self.is_open = True
        self._on_open()
        mouse.locked = False
        mouse.visible = True
        self._reader_root = Entity(parent=camera.ui)
        # Dim backdrop
        Entity(parent=self._reader_root, model="quad",
               color=color.rgba(0, 0, 0, 235),
               scale=(1.7, 1.0), position=(0, 0, 0.5))
        Text(parent=self._reader_root, text=note["title"],
             position=(-0.6, 0.42), scale=1.05,
             color=color.rgb(210, 220, 230),
             font="VeraMono.ttf")
        Text(parent=self._reader_root, text="(" + note["location"] + ")",
             position=(-0.6, 0.38), scale=0.75,
             color=color.rgba(160, 170, 180, 255), font="VeraMono.ttf")
        Text(parent=self._reader_root, text=note["body"],
             position=(-0.6, 0.32), scale=0.65, line_height=1.05,
             color=color.rgb(220, 220, 220), font="VeraMono.ttf",
             wordwrap=80)
        Text(parent=self._reader_root,
             text="Close [E]",
             position=(0.50, -0.45), scale=0.85,
             color=color.rgba(180, 200, 220, 220), font="VeraMono.ttf")

    # --------------------------------------------------------------------
    # Journal (Tab)
    # --------------------------------------------------------------------

    def toggle_journal(self):
        """Open the full journal (all collected notes) or close any open overlay."""
        if self.is_open:
            self.close()
            return
        self.is_open = True
        self._on_open()
        mouse.locked = False
        mouse.visible = True
        self._journal_selected_idx = 0
        self._journal_root = Entity(parent=camera.ui)
        Entity(parent=self._journal_root, model="quad",
               color=color.rgba(0, 0, 0, 240),
               scale=(2.2, 1.4), position=(0, 0, 0.5))
        n = len(self.collected_ids)
        Text(parent=self._journal_root,
             text=f"RECOVERED:  {n} / 7",
             position=(-0.55, 0.42), scale=1.2,
             color=color.rgb(200, 215, 235), font="VeraMono.ttf")
        Text(parent=self._journal_root,
             text="[Tab] close   [1-7] open note",
             position=(0.10, 0.42), scale=0.85,
             color=color.rgba(160, 175, 195, 220),
             font="VeraMono.ttf")
        # Left column - list of collected note titles
        y = 0.32
        for idx, nid in enumerate(self.collected_ids):
            note = NOTES_BY_ID[nid]
            Text(parent=self._journal_root,
                 text=f"{idx+1}. {note['title']}",
                 position=(-0.55, y), scale=0.85,
                 color=color.rgb(220, 220, 220), font="VeraMono.ttf")
            Text(parent=self._journal_root,
                 text=f"   ({note['location']})",
                 position=(-0.55, y - 0.04), scale=0.7,
                 color=color.rgba(150, 160, 180, 255),
                 font="VeraMono.ttf")
            y -= 0.10
        if not self.collected_ids:
            Text(parent=self._journal_root,
                 text="No notes recovered yet.",
                 position=(-0.55, 0.30), scale=0.9,
                 color=color.rgba(160, 160, 160, 230),
                 font="VeraMono.ttf")
        # Right pane - first note body, if any
        self._render_journal_body()

    def _render_journal_body(self):
        """Re-render the right-pane body for the currently selected journal note."""
        if self._journal_root is None:
            return
        if not self.collected_ids:
            return
        # Remove existing body children tagged 'body'
        for c in list(self._journal_root.children):
            if getattr(c, "_journal_body_tag", False):
                destroy(c)
        nid = self.collected_ids[self._journal_selected_idx]
        note = NOTES_BY_ID[nid]
        t1 = Text(parent=self._journal_root, text=note["title"],
                  position=(0.02, 0.36), scale=0.9,
                  color=color.rgb(210, 220, 230), font="VeraMono.ttf")
        t1._journal_body_tag = True
        t2 = Text(parent=self._journal_root,
                  text=note["body"], position=(0.02, 0.31),
                  scale=0.6, line_height=1.05, wordwrap=58,
                  color=color.rgb(225, 225, 225), font="VeraMono.ttf")
        t2._journal_body_tag = True

    def select_journal_index(self, idx):
        """Switch the journal preview to a different collected note (Tab UI keys 1-7)."""
        if not self.collected_ids:
            return
        if 0 <= idx < len(self.collected_ids):
            self._journal_selected_idx = idx
            self._render_journal_body()

    # --------------------------------------------------------------------
    # Closing
    # --------------------------------------------------------------------

    def close(self):
        """Tear down any open journal/reader overlay and unfreeze the player."""
        if self._reader_root is not None:
            destroy(self._reader_root)
            self._reader_root = None
        if self._journal_root is not None:
            destroy(self._journal_root)
            self._journal_root = None
        if self.is_open:
            self.is_open = False
            mouse.locked = True
            mouse.visible = False
            self._on_close()

    # --------------------------------------------------------------------
    # Polled input (called from main game update)
    # --------------------------------------------------------------------

    def handle_input(self, key):
        """Route raw key events to journal/reader controls."""
        if key == "tab":
            self.toggle_journal()
        elif key == "e" and self._reader_root is not None:
            self.close()
        elif key == "escape" and self.is_open:
            self.close()
        elif self._journal_root is not None and key in "1234567":
            self.select_journal_index(int(key) - 1)
