@echo off
setlocal

title Curve Explorer - Build and Run
cd /d "%~dp0"

set "PROJECT_DIR=%~dp0"
set "PROJECT_DIR=%PROJECT_DIR:~0,-1%"
set "OUTPUT_DIR=%PROJECT_DIR%\build"
set "OUTPUT_EXE=%OUTPUT_DIR%\CurveExplorer.exe"
set "TEMPLATE_DIR=%PROJECT_DIR%\.godot\run"
set "CUSTOM_TEMPLATE=%TEMPLATE_DIR%\export-template.exe"
set "GODOT_EXE="
set "GODOT_VERSION="

if defined GODOT_4_7_2 set "GODOT_EXE=%GODOT_4_7_2:"=%"
if defined GODOT_EXE goto validate_godot

if exist "%PROJECT_DIR%\.godot\tools\godot-4.7.2\Godot_v4.7.2-stable_win64.exe" set "GODOT_EXE=%PROJECT_DIR%\.godot\tools\godot-4.7.2\Godot_v4.7.2-stable_win64.exe"
if defined GODOT_EXE goto validate_godot

for /f "delims=" %%I in ('where godot4.7.2.exe 2^>nul') do if not defined GODOT_EXE set "GODOT_EXE=%%I"
for /f "delims=" %%I in ('where godot4.exe 2^>nul') do if not defined GODOT_EXE set "GODOT_EXE=%%I"
for /f "delims=" %%I in ('where godot.exe 2^>nul') do if not defined GODOT_EXE set "GODOT_EXE=%%I"
if defined GODOT_EXE goto validate_godot

if exist "%LOCALAPPDATA%\Programs\Godot\Godot_v4.7.2-stable_win64.exe" set "GODOT_EXE=%LOCALAPPDATA%\Programs\Godot\Godot_v4.7.2-stable_win64.exe"
if defined GODOT_EXE goto validate_godot

if exist "%USERPROFILE%\Downloads\Godot_v4.7.2-stable_win64.exe" set "GODOT_EXE=%USERPROFILE%\Downloads\Godot_v4.7.2-stable_win64.exe"
if defined GODOT_EXE goto validate_godot

if exist "%PROJECT_DIR%\..\..\External\Godot_4-7-2\bin\godot.windows.editor.x86_64.exe" set "GODOT_EXE=%PROJECT_DIR%\..\..\External\Godot_4-7-2\bin\godot.windows.editor.x86_64.exe"
if defined GODOT_EXE goto validate_godot

goto godot_not_found

:validate_godot
if not exist "%GODOT_EXE%" goto godot_not_found

set "GUI_GODOT=%GODOT_EXE:_console.exe=.exe%"
if exist "%GUI_GODOT%" set "GODOT_EXE=%GUI_GODOT%"

for /f "delims=" %%V in ('"%GODOT_EXE%" --version 2^>nul') do if not defined GODOT_VERSION set "GODOT_VERSION=%%V"
echo %GODOT_VERSION% | findstr /b /c:"4.7.2" >nul
if errorlevel 1 goto wrong_version

echo.
echo Curve Explorer
echo ==============
echo Godot: %GODOT_VERSION%
echo.
echo [1/2] Preparing the Windows standalone template...

if not exist "%TEMPLATE_DIR%" mkdir "%TEMPLATE_DIR%"
copy /y "%GODOT_EXE%" "%CUSTOM_TEMPLATE%" >nul
if errorlevel 1 goto build_failed

if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"
if exist "%OUTPUT_DIR%\CurveExplorer.exe" del /q "%OUTPUT_DIR%\CurveExplorer.exe" >nul 2>&1
if exist "%OUTPUT_DIR%\CurveExplorer.exe" goto app_running
if exist "%OUTPUT_DIR%\CurveExplorer.pck" del /q "%OUTPUT_DIR%\CurveExplorer.pck" >nul 2>&1
if exist "%OUTPUT_DIR%\CurveExplorer.tmp" del /q "%OUTPUT_DIR%\CurveExplorer.tmp" >nul 2>&1

echo [2/2] Building CurveExplorer.exe...
"%GODOT_EXE%" --headless --path "%PROJECT_DIR%" --export-release "Windows Desktop" "%OUTPUT_EXE%" --log-file "%TEMPLATE_DIR%\export.log"
if errorlevel 1 goto build_failed
if not exist "%OUTPUT_EXE%" goto build_failed

echo.
echo Build complete: build\CurveExplorer.exe
echo Launching Curve Explorer...
start "" "%OUTPUT_EXE%"
exit /b 0

:godot_not_found
echo.
echo ERROR: Godot 4.7.2 was not found.
echo.
echo Install the standard Windows build of Godot 4.7.2, then either:
echo   - Add its folder to PATH, or
echo   - Set GODOT_4_7_2 to the full path of the Godot executable.
echo.
echo Example:
echo   set GODOT_4_7_2=C:\Tools\Godot_v4.7.2-stable_win64.exe
echo.
pause
exit /b 1

:wrong_version
echo.
echo ERROR: Run.cmd found "%GODOT_EXE%", but it is not Godot 4.7.2.
echo Found version: %GODOT_VERSION%
echo Set GODOT_4_7_2 to the full path of a Godot 4.7.2 executable.
echo.
pause
exit /b 1

:app_running
echo.
echo ERROR: build\CurveExplorer.exe is currently running.
echo Close Curve Explorer, then double-click Run.cmd again to rebuild it.
echo.
pause
exit /b 1

:build_failed
echo.
echo ERROR: The standalone build failed.
echo See .godot\run\export.log for Godot's export diagnostics.
echo.
pause
exit /b 1
