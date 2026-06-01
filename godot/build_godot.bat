@echo off
REM Local headless build of Vesper (Windows). Requires Godot 4.3 on PATH
REM (as `godot`) with export templates installed.
REM Output: build\windows\VesperHorror.exe
cd /d "%~dp0"
if not exist build\windows mkdir build\windows
godot --headless --import .
godot --headless --verbose --export-release "Windows Desktop" build\windows\VesperHorror.exe
echo Built: build\windows\VesperHorror.exe
