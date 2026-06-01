#!/usr/bin/env bash
# Local headless build of Vesper (Linux/macOS). Requires Godot 4.3 on PATH
# with export templates installed. Output: build/linux/VesperHorror.x86_64
set -e
cd "$(dirname "$0")"
mkdir -p build/linux
godot --headless --import . || true
godot --headless --verbose --export-release "Linux/X11" build/linux/VesperHorror.x86_64
echo "Built: build/linux/VesperHorror.x86_64"
