# Vesper (Godot 4.3)

A first-person Antarctic horror descent. This is the **Godot** version of the
project (the older Python "Void Frequency" build still lives in `main.py` /
`systems/` and is built with `build.bat`).

## Play it — no editor, no install

Every push builds standalone binaries in CI. To get one:

1. Open the repo's **Actions** tab (or the PR's **Checks** tab).
2. Click the most recent **Build Vesper** run.
3. Under **Artifacts**, download **`VesperHorror-Windows`** (or `-Linux`).
4. Unzip and **double-click `VesperHorror.exe`**.

No Godot, no Python, no dependencies — the PCK is embedded in the executable
(~50 MB). Tagged releases (`git tag v1.0 && git push --tags`) also publish a
GitHub Release with the zipped builds attached.

## Build it locally (no editor)

If you have Godot 4.3 on your PATH and the export templates installed:

```bash
# from the repo root
cd godot
./build_godot.sh          # Linux/macOS  -> build/linux/VesperHorror.x86_64
build_godot.bat           # Windows      -> build\windows\VesperHorror.exe
```

Both scripts just run a headless import + `--export-release` against the
presets in `export_presets.cfg`.

## Open it in the editor

`godot/project.godot` — open in Godot 4.3, press **F5**. Main scene is
`res://scenes/main.tscn`. Press **F9** in-game for the debug act-warp menu.

## Controls

- **WASD** move, **Shift** sprint, **Ctrl** crouch, mouse look
- **F** flashlight, **R** reload battery
- **E** interact / read / hide / step out
- **Tab** journal, **I** inventory
- **Left click** fire (once you have the bolt gun, Act 10)
