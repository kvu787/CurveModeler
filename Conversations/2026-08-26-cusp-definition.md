# Cusp definition

Date: 2026-08-26

## User

> explain the definition of "cusp"

## Assistant

A **cusp** is a genuine singular point of a curve where the curve comes to a
point and turns back along the same tangent line. The standard ordinary, or
semicubical, cusp is

$$
\gamma(t)=(t^2,t^3).
$$

At $t=0$,

$$
\gamma'(0)=(0,0),
$$

so the curve has zero velocity and is not regular there. Nevertheless, its
tangent **line** is well defined: it is the $x$-axis. The two sides approach
that line with opposite oriented tangent directions, and both lie on the same
side of the cusp point because $x=t^2\geq 0$. This produces the characteristic
pointed shape.

For a smooth planar parameterization, a common sufficient condition for an
**ordinary cusp** at $t_0$ is

$$
\gamma'(t_0)=0,\qquad
\gamma''(t_0)\neq 0,\qquad
\det\!\left(\gamma''(t_0),\gamma'''(t_0)\right)\neq 0.
$$

These conditions make the curve locally equivalent, after smooth changes of
coordinates and parameter, to $(t^2,t^3)$.

Zero derivative alone is not enough to define a geometric cusp. For example,
$\gamma(t)=(t^3,0)$ has $\gamma'(0)=0$, but its image is just a straight line;
the zero speed is removable by using a better parameter. At a genuine cusp,
the singular pointed geometry cannot be removed by a regular smooth
reparameterization.

For the offset of a regular curve parameterized by arc length,

$$
O_d(s)=C(s)+dN(s),
$$

the derivative is

$$
O_d'(s)=\bigl(1-d\kappa(s)\bigr)T(s).
$$

Thus an offset is singular at $s_0$ when

$$
d\kappa(s_0)=1.
$$

At that point, the offset distance equals the signed local radius of curvature
on the chosen side. The offset point is the local center of curvature, nearby
normal lines focus there, and the offset velocity vanishes. If
$1-d\kappa(s)$ crosses zero simply---equivalently,
$\kappa'(s_0)\neq 0$ for fixed nonzero $d$---the velocity reverses and the
offset has an ordinary cusp.

Special cases can be more degenerate. If $\kappa'(s_0)=0$, higher derivatives
decide the singularity. At the first critical offset of a smoothly varying
curvature maximum, the initial singularity can be a higher-order cusp; just
beyond that distance, it commonly separates into two ordinary cusps bounding
a loop. For a circle offset inward by exactly its radius,
$1-d\kappa$ vanishes everywhere and the entire curve collapses to one point
rather than forming an isolated ordinary cusp.

A cusp should also be distinguished from two other features:

- At a **corner**, the two sides have different tangent lines; each side can
  remain regular up to the corner.
- At a **self-intersection**, two distinct parameter values reach the same
  point, usually with nonzero velocities.
- At a **cusp**, one parameter value is singular, its velocity vanishes, and
  the two local branches normally share one tangent line.

In short, the pointed appearance is the visible consequence of the offset
mapping losing regularity: the moving point stops and then reverses along its
local tangent direction.
