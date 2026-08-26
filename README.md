# NURBS Studio

A focused 2D non-uniform rational B-spline modeler for Godot 4.7.2.

## Run

Open this folder in Godot 4.7.2 and run the project, or start it from a terminal:

```powershell
godot --path .
```

## Editing

- **Select** (`V`) selects and drags control points.
- **Add point** (`A`) inserts a control point into the nearest control-polygon segment.
- **Delete** (`X`) removes the point under the cursor. `Delete` removes the selected point.
- The inspector edits exact X/Y coordinates, rational weight, curve degree, and the full knot vector.
- The mouse wheel zooms around the pointer; middle- or right-drag pans. `F` fits the curve.
- Grid snapping is optional. Undo and redo retain up to 100 geometry states.

Documents are saved as readable `*.nurbs.json` files. **Export SVG** writes a densely tessellated, standalone SVG path suitable for other graphics tools.

## Tests

Run the headless mathematical-core checks with the Godot executable:

```powershell
godot --headless --path . --script tests/test_nurbs_curve.gd
```
