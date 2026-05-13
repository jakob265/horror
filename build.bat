@echo off
REM ============================================================
REM VOID FREQUENCY - build script
REM ============================================================
REM Produces a single-file Windows executable in dist\VoidFrequency.exe
REM Requires:  Python 3.9+ with ursina + pyinstaller installed
REM ============================================================

echo.
echo === Installing / updating dependencies ===
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
if errorlevel 1 (
    echo Dependency install failed.
    exit /b 1
)

echo.
echo === Cleaning previous build artifacts ===
if exist build  rmdir /s /q build
if exist dist   rmdir /s /q dist
if exist VoidFrequency.spec del /q VoidFrequency.spec

echo.
echo === Running PyInstaller ===
pyinstaller --onefile --windowed --name VoidFrequency ^
    --collect-all ursina ^
    --collect-all panda3d ^
    --hidden-import systems.player ^
    --hidden-import systems.interaction ^
    --hidden-import systems.audio ^
    --hidden-import systems.notes ^
    --hidden-import systems.entity ^
    --hidden-import systems.olen ^
    --hidden-import systems.endings ^
    --hidden-import scenes.act1_cryo ^
    --hidden-import scenes.act2_corridor ^
    --hidden-import scenes.act3_lab ^
    --hidden-import scenes.act4_array ^
    main.py

if errorlevel 1 (
    echo Build failed.
    exit /b 1
)

echo.
echo === Build complete ===
echo Output: dist\VoidFrequency.exe
echo.
