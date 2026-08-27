# NURBS curve offset periodicity

Date: 2026-08-26

## User

> in the readme, is the definition for "nurbs curve offset" applicable to both
> non-periodic and periodic nurbs curves?

## Assistant

Yes. The definition applies to both non-periodic and periodic NURBS curves.
It assumes only that the planar source curve is regular at the parameter being
evaluated, meaning $C'(u)\neq 0$; it does not require endpoints or a clamped
knot vector.

For a periodic source with period $T$, differentiability gives
$C'(u+T)=C'(u)$, so its left normal and offset are periodic as well:

$$
n_L(u+T)=n_L(u),
\qquad
O_d(u+T)=O_d(u).
$$

The README's existing qualifications still apply. The raw offset is undefined
where $C'(u)=0$, and a knot at which the source has only positional continuity
is a corner with separate one-sided offset branches. A smoothly periodic join
needs no special seam treatment or end caps, while a non-periodic curve may
need end caps as a separate topology operation.

The wording is therefore correct, though adding "either non-periodic or
periodic" after "regular planar NURBS curve" would make its scope explicit.
