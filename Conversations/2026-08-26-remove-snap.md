# Remove Snap functionality

Date: 2026-08-26

## User

> Remove the "Snap" functionality entirely. i don't need it.

## Assistant

Removed grid snapping from NURBS Studio end to end.

- Removed the **Snap** toolbar toggle and its callback.
- Removed the canvas snapping state and coordinate-quantization helper.
- Changed point insertion and dragging to retain exact pointer coordinates.
- Removed the snapping reference from the README.

The NURBS mathematical-core and application smoke test suites both pass under Godot 4.7.2.

The implementation was committed separately as `8175f27` (`Remove grid snapping support`).
