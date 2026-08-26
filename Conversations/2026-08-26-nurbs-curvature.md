# NURBS curvature

Date: 2026-08-26

## User

> explain how to compute a quantity that indicates how much the nurbs curve is curving. this quantity should be higher when the nurbs curve is taking a sharper turn, and zero if the curve is totally straight

## Assistant

The quantity is **curvature**, usually written as $\kappa$ (kappa).

For a 2D parametric curve $C(u)=(x(u),y(u))$, compute its first and second derivatives and use

$$
\kappa(u)=
\frac{|x'(u)y''(u)-y'(u)x''(u)|}
{\left(x'(u)^2+y'(u)^2\right)^{3/2}}.
$$

In vector form this is

$$
\kappa(u)=\frac{|C'(u)\times C''(u)|}{\|C'(u)\|^3}.
$$

For 2D vectors, the “cross product” is the scalar
$C'_xC''_y-C'_yC''_x$. In 3D, use the magnitude of the ordinary vector cross product.

This has the desired behavior:

- A straight curve has $\kappa=0$, even if its parameterization speeds up or slows down.
- A sharper turn has larger curvature.
- A circle of radius $R$ has constant curvature $1/R$.
- The reciprocal $1/\kappa$ is the local radius of curvature.

For a rational NURBS, write

$$
A(u)=\sum_i N_{i,p}(u)w_iP_i,
\qquad
W(u)=\sum_i N_{i,p}(u)w_i,
\qquad
C(u)=\frac{A(u)}{W(u)}.
$$

After evaluating the basis functions and their first two derivatives, compute

$$
C'(u)=\frac{A'(u)-C(u)W'(u)}{W(u)},
$$

$$
C''(u)=\frac{A''(u)-C(u)W''(u)-2C'(u)W'(u)}{W(u)}.
$$

Insert those two vectors into the curvature formula. Analytic basis derivatives are preferable, but sampled positions can provide a fallback:

$$
C'(u)\approx\frac{C(u+h)-C(u-h)}{2h},
\qquad
C''(u)\approx\frac{C(u+h)-2C(u)+C(u-h)}{h^2}.
$$

Avoid evaluating the formula when $\|C'(u)\|$ is extremely small, since the denominator becomes unstable. At a knot where the curve is not twice differentiable, curvature may be discontinuous or undefined; use one-sided values if that behavior matters.

If the coordinates are measured in pixels, curvature has units of inverse pixels. For a scale-independent display value, multiply it by a chosen reference length, such as the canvas size or the curve's bounding-box diagonal. For coloring the curve, evaluate $\kappa$ at each sampled parameter and map low values to a cool color and high values to a warm color.

Do not use $\|C''(u)\|$ alone: it changes when the same geometric curve is parameterized differently and can be nonzero even along a straight line.

## User

> when referring simply to the "curvature" of a curve without any additional qualifiers, does this value have a direction?

## Assistant

No. For a curve, unqualified **curvature** conventionally means the nonnegative scalar $\kappa\geq0$. It says how sharply the curve bends, but not which way it bends.

Two related quantities add directional information:

- **Signed curvature** is a scalar used for an oriented 2D curve. Its sign distinguishes bending to the left from bending to the right relative to the direction in which the curve is traversed. Reversing that traversal direction reverses the sign.
- The **curvature vector** is $dT/ds=\kappa N$, where $T$ is the unit tangent, $s$ is arc length, and $N$ is the principal normal. It points toward the local inside of the bend (the center of the osculating circle). This form also works for curves in 3D.

Thus, “the curvature is 0.2” reports only sharpness. To report which way the curve bends, say “signed curvature” or “curvature vector.” At a point where $\kappa=0$, there is no uniquely defined principal-normal direction.

## User

> implement some kind of visual indicator for curvature

## Assistant

Implemented a toggleable CAD-style curvature comb in NURBS Studio.

The mathematical core now evaluates the NURBS position and its first two derivatives analytically, including rational weights and non-uniform knot vectors. It exposes unsigned and signed curvature, and tangent evaluation now uses the exact first derivative instead of a finite difference.

On the modeling canvas, sampled spikes point toward the inside of each bend. Their length increases with curvature and their color shifts from cyan toward warm pink as the turn becomes sharper. The display magnitude is normalized by the curve's bounding-box diagonal and compressed to a fixed screen-space maximum, keeping the visualization readable across model scales and zoom levels. Straight spans produce no spikes. A compact legend explains the encoding.

The comb is visible by default and can be hidden or restored with the new **Curvature** toolbar toggle.

Tests cover zero curvature on a rationally parameterized line, unit curvature on an exact rational quarter-circle (including endpoints), signed turning direction, agreement with finite differences on a rational non-uniform curve, and the UI toggle. Both the mathematical-core and application smoke suites passed under Godot 4.7.2. A rendered 1280×800 screenshot was also inspected to verify spike direction, relative magnitude, coloring, legend placement, and toolbar fit.

The analytic curvature engine and visual/UI layer were committed separately for review. This conversation continuation is recorded in its own commit as required by the repository instructions.

## User

> what is the term that describes taking a nurbs curve (or any mathematically defined curve) and sampling points on it that resemble the curve given enough samples and connecting straight line segments between the points.

## Assistant

The most general term is **polyline approximation**, or more formally, a **piecewise-linear approximation** of the curve.

Related terms emphasize slightly different aspects:

- **Curve tessellation**: common in graphics and CAD for the process of converting the curve into line segments.
- **Curve flattening**: common when recursively subdividing a curve until each segment is sufficiently straight, usually according to an error tolerance.
- **Curve discretization**: broader; it means representing the continuous curve with discrete samples, not necessarily connecting them.
- **Adaptive tessellation** or **adaptive subdivision**: places more samples where the curve bends sharply and fewer where it is nearly straight.

Thus, the sampled-and-connected result is a **polyline**, and the operation is **approximating/tessellating the curve as a polyline**.

## User

> for a nurbs curve, what definition or algorithm for tessellation that accepts some sort of resolution input parameter would provide an ideal visual result

## Assistant

The best choice is **view-adaptive, error-bounded polyline tessellation**—also called **adaptive curve flattening**—with resolution expressed as a maximum **screen-space error in pixels**, not as a fixed number of segments.

Define the result by requiring every emitted chord to satisfy

```text
max distance(screen_curve(t), chord) <= epsilon_px
```

over that chord's parameter interval. This directly describes visual quality: zooming in automatically produces more segments, straight regions use very few, tight bends use more, and non-uniform NURBS parameterization cannot waste or starve samples. The GLU NURBS specification uses essentially this notion as its pixel-space parametric-error sampling mode.

A robust NURBS implementation is:

1. Split the NURBS at its distinct knots into rational Bézier spans (conceptually, insert each interior knot until its multiplicity is the degree).
2. Store each rational Bézier control point homogeneously as `(w*x, w*y, w)`.
3. Recursively split each span at `t = 0.5` with homogeneous de Casteljau subdivision.
4. Perspective-divide the subspan's control points, transform them to screen space, and compute

   ```text
   E = max distance(interior_control_point, endpoint_chord_segment)
   ```

5. If `E <= epsilon_px`, emit the subspan endpoint. Otherwise subdivide again.

For positive NURBS weights, the convex-hull property makes this control-point test a conservative flatness bound; it also avoids the classic failure of a midpoint-only test on an S-curve whose midpoint happens to lie on its chord. Include a maximum recursion depth/minimum parameter interval as a numerical safety valve, preserve every nonzero knot span boundary, and start a separate polyline at a true discontinuity.

Recommended controls are:

- `epsilon_px = 1.0`: fast preview
- `epsilon_px = 0.5`: excellent default
- `epsilon_px = 0.25`: high quality

If the public API must call its input `resolution`, make higher values mean finer output with, for example, `epsilon_px = 0.5 / resolution`, where `resolution = 1` is normal quality. Exposing `max_error_pixels` directly is less ambiguous.

A maximum chord length is useful as a secondary condition for dashed strokes, picking, per-vertex attributes, or animation, but it should not be the primary visual-quality criterion. A perfectly straight span can be rendered exactly by one arbitrarily long segment.

The project's current `tessellate(segment_count)` uniformly samples the NURBS parameter. That is simple, but it is not visually ideal: the parameter is generally neither distance nor curvature uniform, and the chosen count does not account for zoom. In this 2D canvas, tessellating after the world-to-screen transform—or equivalently using `epsilon_world = epsilon_px / zoom`—would give stable quality as the view changes.

If a fixed vertex count is absolutely required, equal-arc-length spacing is better than equal-parameter spacing, but it still allocates too few samples to high-curvature areas and too many to straight ones. An error tolerance is the better contract.

## User

> let's make this much simpler. what definition or algorithm for tessellation would provide an ideal visual result. it must accept an integer parameter greater than 2 that specifies the number of vertices in the tessellation

## Assistant

Use an **adaptive maximum-error tessellation**.

Given `vertex_count > 2`:

1. Start with the curve's two endpoints.
2. For every current line segment, find the point on the corresponding curve interval that is farthest from that line segment.
3. Select the interval having the largest such error and insert its farthest curve point.
4. Repeat until there are exactly `vertex_count` vertices.

In pseudocode:

```text
parameters = [curve_start, curve_end]

while parameters.size < vertex_count:
    best_error = -infinity
    best_parameter = curve_start

    for each adjacent (t0, t1) in parameters:
        t, error = farthest_point_from_chord(t0, t1)
        if error > best_error:
            best_error = error
            best_parameter = t

    insert best_parameter in sorted order

return parameters.map(curve.evaluate)
```

This always returns exactly the requested number of vertices and naturally spends them where the curve bends most. The ideal mathematical definition behind it is: choose the `vertex_count` ordered curve parameters that minimize the maximum distance between the curve and the resulting polyline. The algorithm above is a simple greedy approximation to that minimax definition.

`farthest_point_from_chord` can be implemented by sampling the interval reasonably densely, then optionally refining around the best sample. Always choose an interior parameter; if all remaining errors are zero because the curve is straight, split the longest interval at its midpoint. This is visually much better than uniform parameter sampling and simpler than converting the NURBS into Bézier spans.

## User

> implement this feature in the visualizer. i should be able to adjust a vertex count and have the visualizer show the vertices that are the result of this tessellation algorithm.

## Assistant

Implemented the adjustable adaptive tessellation visualizer.

- Added `NurbsCurve2D.tessellate_adaptive(vertex_count)`, which repeatedly inserts the maximum-error curve point and always returns exactly the requested number of vertices. It explicitly considers knot locations, refines the maximum-error search, preserves endpoints, and splits the longest remaining chord at an interior midpoint for straight-curve ties.
- Added a **Tessellation vertices** integer control to the Curve inspector, ranging from 3 to 512 with a default of 32.
- The visible cyan curve is now the resulting adaptive polyline, and every tessellation vertex is marked with a purple diamond.
- Cached tessellation geometry avoids recomputing it during pan, zoom, and unrelated redraws; curve edits and count changes invalidate the cache.
- Updated the README and added mathematical and application tests for exact counts, endpoints, approximation improvement, straight curves, and live inspector-to-canvas behavior.

Both the NURBS core tests and application smoke tests passed under Godot 4.7.2. A 1280×800 rendered capture was inspected to verify control placement, adaptive polyline shape, marker visibility, endpoint overlap, and inspector layout.

The implementation was committed separately as `c8dc7e8` (`Add adjustable adaptive curve tessellation`).

## User

> explain why the answer to this prompt:
>
> let's make this much simpler. what definition or algorithm for tessellation would provide an ideal visual result. it must accept an integer parameter greater than 2 that specifies the number of vertices in the tessellation
>
> was "adaptive maximum-error tessellation", instead of something that more places vertices at higher curvature areas and fewer verts at lower curvature places, which seems more intuitive to me.

## Assistant

That intuition is correct: an effective tessellator should generally put more vertices where curvature is high. **Maximum-error tessellation does that indirectly**, while also considering the length of each segment.

For a short curve interval with arc length `s` and approximately constant curvature `kappa`, the deviation between the curve and its chord is approximately

```text
error ~= |kappa| * s^2 / 8
```

Consequently, visual error is not determined by curvature alone. A moderately curved but very long chord can be more visibly wrong than a highly curved but already tiny chord. Maximum-error insertion measures that combined result directly: whichever interval currently has the largest chord deviation receives the next vertex. High-curvature regions usually win first, but stop receiving vertices once their segments are short enough that some other interval has become the worse approximation.

A curvature-distribution algorithm is also legitimate. For smooth, regular curves and a sufficiently large vertex budget, equalizing the approximate error above gives

```text
segment_length proportional to 1 / sqrt(|kappa|)
vertex_density proportional to sqrt(|kappa|)
```

Thus vertices should not generally be distributed in direct proportion to curvature. A curvature-driven implementation would numerically integrate `sqrt(abs(kappa))` with respect to arc length, divide that cumulative measure into `vertex_count - 1` equal portions, and invert it to obtain the parameters.

I chose the maximum-error algorithm because it:

- optimizes the visible quantity of interest—curve-to-chord deviation—rather than a proxy;
- naturally combines curvature and segment length;
- is independent of the NURBS parameterization;
- behaves sensibly at straight regions, knot corners, and awkward derivative cases;
- is incremental and always returns exactly the requested vertex count.

There is one qualification to my earlier wording: the greedy maximum-error algorithm is not the mathematically global optimum. The strict “ideal” definition would be to choose all `N` ordered parameters simultaneously so that the maximum curve-to-polyline distance is minimized. Greedy maximum-error insertion is a simple approximation to that minimax problem. Curvature-weighted arc-length placement is another approximation, with particularly good asymptotic behavior for smooth curves.

So the difference is not “error-based instead of curvature-aware.” The implemented method is curvature-aware through the actual geometric error it produces. Curvature-weighted placement would be a reasonable alternative, but maximum error more directly answers “where would one additional vertex improve the currently visible polyline the most?”
