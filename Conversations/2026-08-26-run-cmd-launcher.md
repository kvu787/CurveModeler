# Double-click Windows build launcher

Date: 2026-08-26

## User

> include a "Run.cmd" file that builds and launches the standalone exe of the Godot project by double clicking the Run.cmd from File Explorer.

## Assistant

Added and tested `Run.cmd` together with a Godot 4.7.2 Windows export preset.

The launcher:

- Starts from the project directory when double-clicked in File Explorer.
- Locates Godot 4.7.2 through `GODOT_4_7_2`, the project-local tool cache, `PATH`, common Windows install locations, or the adjacent Godot source build.
- Rejects an incompatible Godot version with a clear message.
- Creates the standalone application as `build/NURBSStudio.exe` with `build/NURBSStudio.pck` beside it.
- Uses the installed 4.7.2 executable as a custom export template, avoiding a separate export-template installation.
- Launches the built executable after a successful export.
- Detects an already-running build and asks the user to close it before rebuilding.
- Writes export diagnostics to `.godot/run/export.log` when troubleshooting is needed.

The exact `cmd.exe /d /c Run.cmd` path was exercised end to end. The build completed, the generated executable launched a live NURBS Studio window, and the existing application smoke test still passed afterward.

The launcher implementation and Godot-generated metadata were committed separately from this conversation record.
