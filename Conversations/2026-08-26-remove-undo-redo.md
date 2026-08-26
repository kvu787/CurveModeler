# Remove undo and redo

Date: 2026-08-26

## User

> i don't need the undo/redo feature. remove it and simplify the codebase where possible.

## Assistant

Removed undo and redo from NURBS Studio end to end.

- Removed the toolbar buttons, keyboard shortcuts, inspector hint, and README reference.
- Removed the undo and redo stacks, edit snapshots, restoration functions, and new/open document history handling.
- Removed the canvas edit-boundary signals and emissions, which existed only to group history snapshots.
- Reused the existing curve-change handler for inspector property edits, eliminating the separate property-commit path.
- Replaced undo/redo smoke coverage with assertions that curve edits update the active document and mark it modified.

The change removes 98 lines while adding 12. The NURBS mathematical-core and application smoke test suites both pass under Godot 4.7.2.

The implementation was committed separately as `240ead4` (`Remove undo and redo support`).
