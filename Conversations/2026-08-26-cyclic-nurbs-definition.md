# Cyclic NURBS definition

Date: 2026-08-26

## User

> how is a cyclic nurbs curve defined?

## Assistant

A cyclic NURBS is most cleanly defined as a periodic rational B-spline.
For degree \(p\), take \(N>p\) unique control points \(P_0,\ldots,P_{N-1}\)
with positive weights \(w_i\), and extend them periodically over all integer
indices:

\[
P_{i+N}=P_i, \qquad w_{i+N}=w_i.
\]

Use an unclamped periodic knot sequence satisfying

\[
u_{i+N}=u_i+T,
\]

where \(T>0\) is the parameter period. If \(N_{i,p}(u)\) are the associated
B-spline basis functions, then

\[
C(u)=
\frac{\displaystyle\sum_{i\in\mathbb Z}N_{i,p}(u)w_iP_i}
     {\displaystyle\sum_{i\in\mathbb Z}N_{i,p}(u)w_i}.
\]

Although the sums are written over all integers, only \(p+1\) terms are
nonzero at any regular parameter value. The periodic control data and knots
imply

\[
C(u+T)=C(u).
\]

Thus the curve has no distinguished beginning or end. With simple knots at
the seam, its generic seam continuity is \(C^{p-1}\), so position and the first
\(p-1\) derivatives match there. A seam knot of multiplicity \(r\) reduces the
generic continuity to \(C^{p-r}\).

In an implementation, the infinite construction is represented by storing the
\(N\) unique control points and wrapping indices modulo \(N\), or by appending
the first \(p\) control points and weights to the end and using a compatible
unclamped knot vector over one parameter period.

This is stronger than merely making a clamped NURBS *closed*. Setting the last
control point equal to the first guarantees endpoint coincidence only; it does
not generally make the tangent or higher derivatives agree. Terminology varies
between libraries, so “cyclic” should be specified as **periodic**, not only
**closed**.

## User

> is the proper way to refer to this "cyclic", "periodic", or something else

## Assistant

The standard mathematical term is **periodic NURBS curve**. More explicitly,
one can say **closed periodic NURBS curve** when it is useful to emphasize both
the geometric closure and the periodic parameterization.

The terms have different strengths:

- **Closed** means only that the curve's endpoints coincide:
  \(C(a)=C(b)\). It does not imply matching derivatives at the join.
- **Periodic** means that the parameterization repeats:
  \(C(u+T)=C(u)\), normally with the corresponding derivatives matching across
  the period. This is the precise property in the definition above.
- **Cyclic** is a reasonable UI or implementation term, especially for wrapped
  indexing or a “cyclic” toggle, but it is less standard and less mathematically
  precise than *periodic*.

Therefore, use **periodic NURBS curve** in mathematical documentation and APIs
that expose the mathematical representation. A UI may use **Cyclic** if that is
friendlier, but its documentation should state that it constructs a periodic
NURBS rather than merely joining the endpoints.

## User

> Edit the readme to include the definition of a periodic nurbs curve

## Assistant

Added a **Periodic NURBS curve** subsection to the README's mathematical model.
It defines the periodically extended control points and weights, the unclamped
periodic knot sequence, the rational curve equation, the parameter period, and
the generic continuity at knots and across the period join. It also distinguishes
a periodic curve from a curve whose endpoints merely coincide and records
*periodic* as the mathematical term in preference to *cyclic*.

The introductory assumptions were adjusted so the mathematical section covers
both open and periodic planar curves. The documentation change was committed as
`2d216af` (`Define periodic NURBS curves`).
