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
