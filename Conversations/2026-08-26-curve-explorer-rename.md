# Rename application to Curve Explorer

Date: 2026-08-26

## User

> I want this application to be named "Curve Explorer". Do a complete rename on the repo. However, don't attempt renames on the files in Conversations.

## Assistant

Renamed the application from **NURBS Studio** to **Curve Explorer** throughout the tracked project while leaving all existing files in `Conversations` untouched.

The rename covers:

- Godot project and runtime window metadata.
- The in-app brand, document labels, and root scene identifier.
- Windows export product metadata and the `CurveExplorer.exe` / `CurveExplorer.pck` artifact names.
- `Run.cmd` build, launch, and error messages.
- README naming and build instructions.
- Smoke-test assertions that guard the new identity.

Both the NURBS core tests and application smoke tests passed. A fresh Windows build was exported and its product metadata was verified as **Curve Explorer**. Obsolete generated `NURBSStudio` build artifacts were removed after the replacement build succeeded.

The implementation and this conversation record were committed separately.
