# 2D NURBS modeler

Date: 2026-08-26

## User

> create a 2d nurbs modeler using godot 4.7.2

## Assistant

Created **NURBS Studio**, a Godot 4.7.2 desktop modeler for open 2D non-uniform rational B-spline curves.

The implementation includes:

- A tested NURBS engine with arbitrary positive weights, configurable degree, open-uniform or custom nondecreasing knot vectors, curve evaluation, tangent estimation, tessellation, bounds, and JSON serialization.
- An interactive drafting canvas with a grid, axes, control polygon, weighted point indicators, select/add/delete tools, point dragging, pointer-centered zoom, panning, fit-to-curve, and optional grid snapping.
- Exact inspector controls for point coordinates and weight, curve degree, and the knot vector.
- Undo/redo, keyboard shortcuts, readable `.nurbs.json` documents, and standalone SVG export.
- A styled 1280×800 responsive interface and an included example curve.
- Core math tests and an application smoke test covering editing history, save, and export.

Verification used the official Godot 4.7.2 stable Windows build. Both automated test suites passed, the application launched without script or runtime errors, and a graphics-enabled render was visually inspected.

Implementation was split into separate commits for the NURBS engine, the interactive modeler, and Godot resource metadata. This conversation is recorded in its own commit as required by the repository instructions.
