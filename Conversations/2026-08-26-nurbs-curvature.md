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
