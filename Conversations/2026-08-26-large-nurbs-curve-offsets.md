# Large NURBS curve offsets

Date: 2026-08-26

## User

> for a nurbs curve offset, explain what happens when the offset distance is
> large enough that odd things start happening

## Assistant

For a planar regular curve, write the signed offset as

$$
O_d(s)=C(s)+dN(s),
$$

where $s$ is arc length and $N$ is the left unit normal. If signed curvature
$\kappa$ is defined by $T'(s)=\kappa(s)N(s)$, then

$$
O_d'(s)=\bigl(1-d\kappa(s)\bigr)T(s).
$$

This equation explains the first kind of odd behavior. When
$d\kappa(s)=1$, the offset speed becomes zero. Generically the offset develops
a cusp there. Past that distance, $1-d\kappa$ changes sign, so that portion of
the offset runs backward relative to the source curve and often forms a small
loop. Geometrically, the offset has crossed the local center of curvature. In
unsigned terms, this becomes possible when an offset toward the inside of a
bend reaches the local radius of curvature $1/|\kappa|$.

There is also a separate global limit. Normals from two distant parameters can
meet, making the offset self-intersect even though $1-d\kappa$ is nonzero
everywhere. A narrow hairpin illustrates this: two almost straight branches
can collide at about half the gap between them, despite both having very large
radii of curvature. The first distance at which either curvature focusing or
this kind of branch collision occurs is related to the curve's **reach** (or
normal injectivity radius). Beyond it, a point may have more than one nearest
point on the source curve, so the offset is no longer a simple boundary.

A circle makes the local event especially clear. For a counterclockwise circle
of radius $R$, the left normal points inward, and the left offset has signed
radius $R-d$:

- For $d<R$, it is a smaller circle.
- At $d=R$, the whole offset collapses to the center.
- For $d>R$, the raw formula produces a circle again, but with reversed
  orientation. That reappearing circle is not the boundary of a meaningful
  inward buffer; the inward region should already be empty.

This distinction matters in software. A **raw offset** is simply the locus
$C+dN$ and is allowed to contain cusps, reversed pieces, loops, and
self-intersections. A usable stroke outline, machining path, or expanded/
contracted region usually needs a second topological stage that finds
intersections, splits the curve, discards interior or reversed loops, joins
corner branches, and selects the desired envelope. As $d$ passes critical
values, the result can change topology: loops appear or disappear, gaps close,
and separate regions merge.

NURBS add a representation issue, but they do not cause the geometry. Except
for special cases such as circular arcs, the exact offset of a NURBS curve is
generally not itself a NURBS curve because the unit normal contains the factor
$1/\|C'(u)\|$. It therefore has to be approximated. Near cusps and
self-intersections that approximation is difficult: the offset speed approaches
zero, curvature becomes extreme, and fitting or tessellation can introduce
wiggles, spikes, missed intersections, or many extra control points. Those are
numerical artifacts layered on top of a genuine geometric singularity.

So there is no single universal “maximum offset distance.” Check both:

1. **Local curvature:** whether $1-d\kappa(u)$ approaches or crosses zero on
   the chosen side.
2. **Global proximity:** whether distinct normal rays collide, often well
   before the curvature limit.

If the goal is a clean region boundary rather than the raw mathematical
offset, offset generation and loop/envelope cleanup should be treated as two
separate operations.
