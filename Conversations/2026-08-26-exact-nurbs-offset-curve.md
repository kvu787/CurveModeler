# Exact normal offsets of NURBS curves

Date: 2026-08-26

## User

> is there a way to derive an exact mathematical equation that represents a curve that is offset by N using normals from an input nurbs curve?

## Assistant

Yes. For a regular planar NURBS curve

\[
C(u)=(x(u),y(u)),
\]

the exact signed distance-\(d\) normal offset is

\[
C_d(u)=C(u)+d\,\frac{(-y'(u),x'(u))}{\sqrt{x'(u)^2+y'(u)^2}}.
\]

Thus its coordinates are

\[
x_d(u)=x(u)-d\frac{y'(u)}{\sqrt{x'(u)^2+y'(u)^2}},\qquad
y_d(u)=y(u)+d\frac{x'(u)}{\sqrt{x'(u)^2+y'(u)^2}}.
\]

Changing the sign of \(d\), or reversing the normal, selects the other side. This is an exact parametric equation and every resulting point is exactly \(|d|\) from its corresponding source point.

The important limitation is that the offset is generally **not another exact NURBS**. The source curve and its derivative are rational, but normalizing the derivative introduces the square root of \(x'^2+y'^2\), which is not usually rational. Exact rational offsets exist for special families, including lines, circles, and suitable Pythagorean-hodograph curves. Offsetting control points along sampled normals does not produce the exact offset.

An exact implicit algebraic equation can theoretically be produced by eliminating \(u\) from

\[
(X-x(u))^2+(Y-y(u))^2=d^2
\]

and

\[
(X-x(u))x'(u)+(Y-y(u))y'(u)=0.
\]

After clearing the NURBS denominators, a symbolic resultant can eliminate \(u\). The result is usually high-degree, may contain extraneous components, and still needs parameter-range trimming, so it is rarely the best representation for an interactive modeler.

The formula also has geometric failure cases. It is undefined where \(C'(u)=0\). The offset can form a cusp where \(1-d\kappa(u)=0\), with signed curvature \(\kappa\), and it can self-intersect even when the source curve does not.

For this 2D application, the practical exact representation is the source NURBS plus \(d\), evaluated through the formula above. Rendering or SVG export should adaptively tessellate or fit Bézier segments to a chosen tolerance. That output is an approximation of the exact procedural curve, rather than an exact NURBS conversion.

For a spatial 3D curve, there is no unique normal direction: each point has an entire normal plane. A Frenet normal, rotation-minimizing frame, surface normal, or another supplied direction field must be chosen before an offset curve is defined.

## User

> For the modeler, the best representation is therefore:
> - Retain the original NURBS and offset distance \(N\).
> - Evaluate the equation procedurally.
> - Adaptively tessellate or fit Bézier/NURBS segments within a selected tolerance for rendering and SVG export.
>
> explain this in greater detail

## Assistant

Think of the offset as a derived curve with three separate representations:

| Layer | Stored or generated data | Exact? |
|---|---|---|
| Document/model | Source NURBS plus signed offset distance \(N\) | Yes, as the definition of the offset |
| Evaluation | A point computed from the source position and analytic tangent at parameter \(u\) | Exact formula, subject to floating-point rounding |
| Display/export | Polyline vertices or fitted Bézier/NURBS segments | Approximate, with controlled error |

### 1. Retain the source NURBS and offset distance

Do not attempt to create the offset by moving the source control points. A NURBS control point is generally not on the curve, and its displacement does not correspond to pointwise displacement of the curve. Instead, store something conceptually like:

```text
OffsetCurve2D
    source_curve: NurbsCurve2D
    distance: -25.0
```

The source curve retains its control points, weights, degree, and knots. The signed distance selects the side. This pair is the exact, editable definition of the derived curve: changing a source control point immediately changes the offset, while changing only the distance moves the derived curve without destroying its relationship to the source.

Saving the document would serialize both the source NURBS and the offset distance. If the user later chooses **Bake offset**, the application could generate an independent approximation, but that is a deliberate conversion rather than the canonical representation.

### 2. Evaluate the offset procedurally

Whenever the application requests the offset at parameter \(u\), evaluate the source position and its analytic derivative:

```gdscript
func evaluate_offset(u: float, distance: float) -> Vector2:
    var derivatives := source.evaluate_derivatives(u)
    var position := derivatives[0]
    var velocity := derivatives[1]
    if velocity.length_squared() <= EPSILON * EPSILON:
        # The normal is undefined; report or handle a singular point.
        return position
    var left_normal := Vector2(-velocity.y, velocity.x) / velocity.length()
    return position + distance * left_normal
```

The existing `NurbsCurve2D.evaluate_derivatives()` already supplies the analytic derivative, including rational-weight and non-uniform-knot corrections. That is substantially better than estimating a tangent from nearby samples, whose normal changes with the finite-difference step.

“Exact” here describes the represented geometry: the procedure evaluates the mathematical offset rather than an independently fitted replacement. The actual coordinates are still ordinary floating-point approximations, just as source NURBS evaluation is.

Other operations can also use the derived evaluator:

- Picking computes distance to a tessellation, then refines the source parameter.
- Bounds may safely begin with the source bounds expanded by \(|N|\), although tighter bounds require finding offset extrema.
- Curvature and tangents can be derived from source derivatives. Away from singularities, \(C_N'(u)=(1-N\kappa(u))C'(u)\), using signed curvature with a consistent normal convention.

At a repeated knot that creates a corner, the curve has distinct left and right tangents, hence two normals. The raw offset branches do not automatically meet; the modeler must choose a round, bevel, or miter join. Where the source derivative is zero, no normal exists. Where \(1-N\kappa=0\), the offset has a cusp.

### 3. Adaptively tessellate for display

Godot ultimately draws line segments, so the screen does not need a second NURBS. It needs enough evaluated offset points that the connecting chords are visually indistinguishable from the procedural curve.

For each parameter interval \([u_0,u_1]\):

1. Evaluate the offset endpoints.
2. Evaluate one or more interior parameters, such as the midpoint and quarter points.
3. Measure each interior point's distance from the endpoint chord and optionally compare endpoint tangent directions.
4. Accept the chord if the error is below the display tolerance; otherwise split the parameter interval and repeat.

Uniformly taking 400 samples is simple but inefficient: nearly straight regions receive unnecessary vertices while a tight cusp may still receive too few. Adaptive subdivision concentrates vertices where the **offset** bends sharply. This must measure the derived offset rather than only the source curve, because an inside offset can become far more curved than its source.

For interactive display, a useful tolerance is screen-space, such as 0.25–0.5 pixels. Convert that to world units using the current zoom. Retessellate when the source, distance, or zoom changes, and cache the result otherwise. The application's current `tessellate_adaptive(vertex_count)` chooses a fixed vertex budget; it could be generalized or complemented by a tolerance-based variant for offset curves.

Sampling a few interior points gives an excellent practical approximation but not a formal error guarantee: an unsampled oscillation could be missed. A certified maximum-error bound requires derivative bounds, Bézier convex-hull bounds after span conversion, or interval arithmetic. Most interactive modelers use robust multi-sample subdivision with depth and singularity safeguards.

### 4. Export as polyline or fitted cubic Béziers

The simplest SVG representation is the same adaptive point sequence emitted as `M` followed by `L` commands. Unlike the current fixed 400-segment export, tolerance-based subdivision lets the user request a geometric error such as 0.01 document units and produces only as many segments as necessary.

Cubic Bézier fitting gives a smaller and smoother SVG:

1. Choose a parameter interval on the offset.
2. Use its evaluated endpoints as Bézier endpoints.
3. Place the two interior Bézier control points along the offset's endpoint tangent directions.
4. Choose their handle lengths by interpolation or least squares against interior offset samples.
5. Compare the fitted Bézier against additional procedural offset evaluations.
6. If its maximum observed error exceeds the export tolerance, split the interval and fit both halves.

The SVG then uses `C` commands rather than hundreds of `L` commands. It is still an approximation, but each candidate segment is validated against the exact procedural evaluator. Splitting at source knot spans, corners, and detected offset cusps makes the fit more stable.

Fitting another NURBS follows the same broad idea—choose degree and knots, solve for control points and weights, measure deviation, and refine—but it is considerably more complex. It is useful if the offset must be transferred back into CAD as an editable spline. For SVG, piecewise cubic Béziers are the natural target because SVG supports them directly.

### What this means for NURBS Studio

A clean implementation would add an offset-curve evaluator wrapping the existing `NurbsCurve2D`, reuse `evaluate_derivatives()` for normals, and generalize tessellation so it can sample either a source or derived evaluator. The canvas would cache a pixel-tolerance tessellation, while SVG export would create a separate document-unit-tolerance tessellation or cubic fit.

The saved model remains compact and mathematically faithful:

```text
source NURBS + signed N
          |
          +--> procedural evaluation --> adaptive screen polyline
          |
          +--> procedural evaluation --> SVG polyline or cubic fit
```

One final product distinction matters: this produces the raw parametric normal-offset locus. If the desired operation is a clean CAD-style outline or shape buffer, the application must additionally detect self-intersections, trim loops, and construct joins and end caps. Those are topology operations layered on top of the offset equation, not part of NURBS evaluation itself.

## User

> what does "analytic" mean

## Assistant

In this context, **analytic** means calculated directly from the curve's mathematical formula rather than estimated from sampled points.

For example, a numerical derivative estimates the tangent with two nearby evaluations:

\[
C'(u) \approx \frac{C(u+h)-C(u-h)}{2h}.
\]

Its answer depends on the chosen step size \(h\): too large loses detail, while too small can amplify floating-point rounding.

An analytic derivative differentiates the NURBS basis functions and rational quotient themselves. If

\[
C(u)=\frac{A(u)}{W(u)},
\]

then

\[
C'(u)=\frac{A'(u)W(u)-A(u)W'(u)}{W(u)^2}.
\]

This produces the tangent prescribed by the NURBS definition at that exact parameter, without choosing a nearby sampling distance. The computer still evaluates the formula using finite-precision floating-point numbers, so "analytic" does not mean infinitely precise; it means formula-derived rather than finite-difference-estimated.
