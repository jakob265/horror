================================================================
  VOID FREQUENCY
  A first-person walking-simulator horror game
================================================================

CRESTFALL-9. Kepler-442. The year is 2187.
The signal is calling. You came back.


----------------------------------------------------------------
  REQUIREMENTS
----------------------------------------------------------------

  - Windows 10 / 11   (for the .exe build)
  - Python 3.9 - 3.12 (recommended 3.11)
  - ~500 MB free disk during build

The released game (dist\VoidFrequency.exe) has zero dependencies
and runs by double-click.


----------------------------------------------------------------
  BUILDING THE EXECUTABLE
----------------------------------------------------------------

1.  Install Python from https://www.python.org/downloads/
    Make sure "Add Python to PATH" is checked.

2.  Open a Command Prompt in this folder.

3.  Install dependencies:

        pip install -r requirements.txt

4.  Build:

        build.bat

5.  The single-file game appears at:

        dist\VoidFrequency.exe

    Double-click to play.


----------------------------------------------------------------
  RUNNING FROM SOURCE
----------------------------------------------------------------

    pip install -r requirements.txt
    python main.py


----------------------------------------------------------------
  CONTROLS
----------------------------------------------------------------

    Mouse         Look
    W A S D       Move
    Shift         Sprint
    Ctrl          Crouch
    F             Toggle flashlight
    E             Interact / Read / Confirm
    Tab           Open notes journal
    Escape        Pause menu


----------------------------------------------------------------
  COMPLETING THE GAME
----------------------------------------------------------------

    Act 1  - Cryo Bay              wake up, find the keycard
    Act 2  - Residential Corridor  visit the cabins, reach the hatch
    Act 3  - Research Deck         find the array keycard
    Act 4  - Array Room            choose: DESTROY or LISTEN

Every code, keycard, and door is solvable with information found
in the world.  Listen to OLEN.  Read every note.


----------------------------------------------------------------
  CREDITS / NOTES
----------------------------------------------------------------

All geometry is generated from Ursina primitives.
All audio is procedurally generated at runtime - no external
asset files are included or required.

Built with the Ursina Engine (https://www.ursinaengine.org/).
