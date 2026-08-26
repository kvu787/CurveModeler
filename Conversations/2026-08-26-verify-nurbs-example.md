# Verify NURBS example and curvature

Date: 2026-08-26

## User

> `C:\Users\k\Repository\Godot\CurveModeling\nurbstestyo.nurbs.json`
>
> verify that everything is working as expected from this example, especially the curvature stuff.

The user also attached a screenshot of the example open in NURBS Studio.

## Assistant

Verified the supplied document end to end under Godot 4.7.2. No product defect was found and no source change was needed.

- The JSON parses as a valid degree-3 NURBS with five control points, nine nondecreasing knots, positive weights, and domain `[0, 1]`.
- The application opens the exact file, retains its control points, weights, degree, and custom knot vector, shows the curvature comb, and creates exactly 32 adaptive tessellation vertices.
- Save/reload and SVG export preserve the example successfully.
- The core suite, application smoke suite, editor/import check, focused example checks, and Windows standalone export all completed successfully.
- An independent homogeneous de Boor derivative implementation agreed with the application's analytic rational derivatives and curvature. A separate five-point finite-difference check had a worst relative curvature difference of about `0.0153%` away from near-zero values.
- The largest absolute curvature is approximately `0.126861383` at the interior knot `u = 0.5`, corresponding to a local radius of curvature of about `7.8826` world units.
- The curve has inflections near `u = 0.363925` and `u = 0.620125`. The curvature-comb spikes correctly reverse direction at those two locations, so the visually busy central pattern is expected for this high-weight geometry.
- For 32 vertices, the adaptive polyline's measured maximum deviation is about `0.50044` world units, compared with `1.79510` for uniform-parameter placement with the same vertex count.

The only diagnostics were host certificate-store and editor-settings write warnings caused by the restricted test environment; all relevant commands exited successfully.
