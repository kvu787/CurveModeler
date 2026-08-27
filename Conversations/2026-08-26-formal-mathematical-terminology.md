# Formal mathematical terminology

Date: 2026-08-26

## User

> We need to start formalizing the math and terminology that we've been
> discussing. Create a section in the README for this.
>
> Start be defining the following
> * NURBS curve
> * NURBS curve offset
> * Optimal fixed vertex count tessellation algorithms for nurbs curve and nurbs
>   curve offset

## Assistant

Added a **Mathematical model and terminology** section to the README.

The section formally defines a planar NURBS from its control points, positive
weights, knot vector, Cox-de Boor basis functions, parameter domain, and rational
curve equation. It defines a signed NURBS offset using the source curve's left
unit normal, specifies the sign convention, and distinguishes the exact derived
offset from a control-polygon offset or a fitted NURBS approximation. It also
records the relevant failure and topology cases: zero source derivative,
one-sided normals at corners, offset singularities and cusps, self-intersections,
joins, and end caps.

For fixed vertex counts, the README now defines “optimal” as minimizing the
maximum subcurve-to-chord deviation over all ordered sets of exactly \(M>2\)
curve samples. It distinguishes that continuous minimax definition from the
interactive greedy maximum-error implementation. It documents optional local
minimax relaxation, a candidate-grid dynamic-programming solver with a precise
grid-optimal guarantee, and the more expensive requirements for a certified
continuous optimum.

Separate specializations explain how the source NURBS uses knot-span-aware
rational evaluation and Bézier bounds, while the offset must be sampled from the
offset evaluator itself and divided into regular branches around undefined
points and tangent discontinuities. Offset cusp handling, mandatory-feature
budget feasibility, and the offset-curvature amplification formula are included.

The README change was committed as `2f9cf32` (`Define NURBS offset and
tessellation terminology`).
