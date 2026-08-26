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
