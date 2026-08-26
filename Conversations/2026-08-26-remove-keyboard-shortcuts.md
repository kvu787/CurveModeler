# Remove keyboard shortcut functionality

Date: 2026-08-26

## User

> Remove all keyboard shortcut functionality. i should only be able to use the app via mouse, except for using keyboard to input values.

## Assistant

Removed keyboard-driven application actions from NURBS Studio while preserving keyboard editing in text and numeric value fields.

- Removed the New, Open, Save, Export SVG, tool-selection, Fit, and point-deletion shortcuts.
- Removed shortcut labels from tooltips and documentation.
- Made the canvas, toolbar buttons, tool buttons, and toggles reject keyboard focus.
- Added an application-level input boundary that accepts only value-editing keys when a text-entry control has focus.
- Blocked Enter-based knot submission so applying a knot vector requires clicking **Apply knots**.
- Added smoke coverage for mouse-only controls and permitted value entry.

The mathematical-core and application smoke test suites both pass under Godot 4.7.2.

The implementation was committed separately as `21c28f8` (`Remove keyboard shortcut functionality`).
