# NURBS Studio

A focused 2D non-uniform rational B-spline modeler for Godot 4.7.2.

## Run

On Windows, double-click **Run.cmd** in File Explorer. It locates Godot 4.7.2, builds the standalone Windows application at `build/NURBSStudio.exe`, and launches it. The build uses the installed editor executable as a custom template and places the project data beside it in `NURBSStudio.pck`, so separate export-template installation is not required. Keep the EXE and PCK together when moving the application.

`Run.cmd` searches the project-local tool cache, `PATH`, common installation locations, and the adjacent Godot 4.7.2 source build. You can also set `GODOT_4_7_2` to the full path of the standard Godot executable.

Alternatively, open this folder in Godot 4.7.2 and run the project, or start it directly from a terminal:

```powershell
godot --path .
```

## Editing

- **Select** selects and drags control points.
- **Add point** inserts a control point into the nearest control-polygon segment.
- **Delete** removes the point under the cursor. **Remove selected point** removes the selected point.
- The inspector edits exact X/Y coordinates, rational weight, curve degree, and the full knot vector.
- Control vertices stay a constant size; their rational weights use a cool-to-warm color gradient centered on weight 1.
- **Tessellation vertices** sets the exact number of vertices in the displayed polyline. Purple diamonds show the adaptively placed result, concentrated around the curve's strongest bends.
- The toggleable **Curvature** comb points into each bend; longer, warmer spikes mark sharper curvature and disappear on straight spans.
- The mouse wheel zooms around the pointer; middle- or right-drag pans. **Fit** frames the curve.
- Grid snapping is optional.

All commands and canvas tools are mouse-only. The keyboard is available only while editing text or numeric values; click the relevant button to apply or perform an action.

Documents are saved as readable `*.nurbs.json` files. **Export SVG** writes a densely tessellated, standalone SVG path suitable for other graphics tools.

## Tests

Run the headless mathematical-core checks with the Godot executable:

```powershell
godot --headless --path . --script tests/test_nurbs_curve.gd
```
