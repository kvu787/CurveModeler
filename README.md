# NURBS Studio

A focused 2D non-uniform rational B-spline modeler for Godot 4.7.2.

## Run

On Windows, double-click **Run.cmd** in File Explorer. It locates Godot 4.7.2, builds the standalone Windows application at `build/NURBSStudio.exe`, and launches it. The build uses the installed editor executable as a custom template and places the project data beside it in `NURBSStudio.pck`, so separate export-template installation is not required. Keep the EXE and PCK together when moving the application.

`Run.cmd` searches the project-local tool cache, `PATH`, common installation locations, and the adjacent Godot 4.7.2 source build. You can also set `GODOT_4_7_2` to the full path of the standard Godot executable.

Alternatively, open this folder in Godot 4.7.2 and run the project, or start it directly from a terminal:

```powershell
godot --path .
```

## Editing

- **Select** selects and drags control points.
- **Add point** inserts a control point into the nearest control-polygon segment.
- **Delete** removes the point under the cursor. **Remove selected point** removes the selected point.
- The inspector edits exact X/Y coordinates, rational weight, and curve degree. It also displays the current knot vector in a compact read-only field.
- Control vertices stay a constant size; their rational weights use a cool-to-warm color gradient centered on weight 1.
- **Tessellation vertices** sets the exact number of vertices in the displayed polyline. Purple diamonds show the adaptively placed result, concentrated around the curve's strongest bends.
- The toggleable **Curvature** comb points into each bend; longer, warmer spikes mark sharper curvature and disappear on straight spans.
- The mouse wheel zooms around the pointer; middle- or right-drag pans. **Fit** frames the curve.

All commands and canvas tools are mouse-only. The keyboard is available only while editing text or numeric values; click the relevant button to apply or perform an action.

Documents are saved as readable `*.nurbs.json` files. **Export SVG** writes a densely tessellated, standalone SVG path suitable for other graphics tools.

## Mathematical model and terminology

The definitions below assume an open planar curve. Parameters increase from the
curve's first endpoint to its last endpoint, and all distances are measured in
model space unless screen space is explicitly named.

### NURBS curve

A **non-uniform rational B-spline (NURBS) curve** of degree $p$ is specified by:

- Control points $P_0,\ldots,P_n\in\mathbb{R}^2$
- Positive weights $w_0,\ldots,w_n$
- A nondecreasing knot vector
  $U=(u_0,\ldots,u_{n+p+1})$

On the parameter domain $[u_p,u_{n+1}]$, the curve is

$$
C(u)=
\frac{\displaystyle\sum_{i=0}^{n}N_{i,p}(u)w_iP_i}
     {\displaystyle\sum_{i=0}^{n}N_{i,p}(u)w_i},
$$

where $N_{i,p}$ are the B-spline basis functions defined by the Cox-de Boor
recursion:

$$
N_{i,0}(u)=
\begin{cases}
1,&u_i\leq u<u_{i+1},\\
0,&\text{otherwise},
\end{cases}
$$

$$
N_{i,p}(u)=
\frac{u-u_i}{u_{i+p}-u_i}N_{i,p-1}(u)
+\frac{u_{i+p+1}-u}{u_{i+p+1}-u_{i+1}}N_{i+1,p-1}(u).
$$

A fraction with a zero denominator contributes zero. The final knot uses the
usual closed-endpoint convention so that the last curve endpoint is included.
"Non-uniform" permits unequal knot intervals and repeated knots. "Rational"
means that the weighted B-spline numerator is divided by its scalar weight sum.
The control points generally guide the curve rather than lie on it.

### NURBS curve offset

Let $C(u)=(x(u),y(u))$ be a regular planar NURBS curve, meaning
$C'(u)\neq0$. Its left unit normal is

$$
n_L(u)=\frac{(-y'(u),x'(u))}{\lVert C'(u)\rVert}.
$$

The **signed distance-$d$ NURBS curve offset** is the derived parametric curve

$$
O_d(u)=C(u)+d\,n_L(u).
$$

Positive $d$ selects the left side relative to increasing $u$; negative
$d$ selects the right side. Each offset point is exactly $|d|$ from its
corresponding source point. This pointwise statement does not imply that the
source point is always the globally nearest point after the offset
self-intersects or approaches another part of the source.

In general, $O_d$ is **not itself a NURBS curve**: normalizing $C'(u)$
introduces a square root that is not generally rational. In this project,
"NURBS curve offset" therefore means the exact derived curve represented by the
source NURBS plus $d$, evaluated procedurally. It does not mean an offset of
the control polygon or a fitted NURBS approximation.

The raw offset is undefined where $C'(u)=0$. At a source corner, its two
one-sided normals define separate offset branches and a round, bevel, or miter
join is an additional modeling choice. Using the left-normal sign convention,
the signed source curvature is

$$
\kappa(u)=
\frac{x'(u)y''(u)-y'(u)x''(u)}{\lVert C'(u)\rVert^3}.
$$

It satisfies $dT/ds=\kappa n_L$, where $T$ is the unit tangent and $s$ is
source arc length. A regular offset branch therefore satisfies

$$
O_d'(u)=(1-d\kappa(u))C'(u),
$$

so it becomes singular, and ordinarily forms a cusp, where
$1-d\kappa(u)=0$. Trimming self-intersections and constructing joins or end
caps are topology operations, not part of the offset definition.

### Optimal fixed-vertex-count tessellation

Let $\Gamma:[a,b]\to\mathbb{R}^2$ denote either a NURBS curve $C$ or one
regular branch of an offset $O_d$. A fixed-vertex-count tessellation with an
integer $M>2$ chooses ordered parameters

$$
a=t_0<t_1<\cdots<t_{M-1}=b
$$

and joins the vertices $V_i=\Gamma(t_i)$ with straight segments. For this
project, the error of the tessellation $T=(t_0,\ldots,t_{M-1})$ is its maximum
subcurve-to-chord deviation:

$$
E(T;\Gamma)=
\max_{0\leq i<M-1}\;
\sup_{u\in[t_i,t_{i+1}]}
\operatorname{dist}\!\left(
\Gamma(u),\overline{V_iV_{i+1}}
\right).
$$

An **optimal fixed-vertex-count tessellation** is any

$$
T^*\in\operatorname*{arg\,min}_{T}E(T;\Gamma).
$$

This is a minimax definition: it places the limited vertices so that the worst
visible defect is as small as possible. It is invariant under a monotone
reparameterization of the same curve. It is not the only possible meaning of
"optimal"; equal arc length, minimum mean-square error, symmetric Hausdorff
distance, and screen-space error are different objectives. When visual output
is the goal, the definition is applied after the model-to-screen transform.

#### Practical minimax algorithm

The continuous minimax problem is nonsmooth and generally nonconvex. The
recommended practical fixed-budget approximation is **greedy maximum-error
insertion**:

1. Start with the branch endpoints and any mandatory feature parameters.
2. For every adjacent parameter pair, find the curve point farthest from its
   chord.
3. Split the interval having the greatest such deviation at that farthest
   parameter.
4. Repeat until exactly $M$ vertices exist.
5. Optionally perform local minimax relaxation sweeps: move each nonmandatory
   interior parameter between its neighbors to minimize the greater error of
   its two adjacent chords.

The greedy phase is an anytime algorithm that spends each new vertex on the
current worst defect. Relaxation corrects some suboptimal early choices. It is a
practical approximation to $T^*$, not a proof of the continuous global
minimum. On a smooth short segment with curvature magnitude $|\kappa|$ and
arc length $\Delta s$, the chord error is approximately

$$
e\approx\frac{|\kappa|\,\Delta s^2}{8},
$$

which explains why maximum-error insertion naturally concentrates vertices in
high-curvature regions while still accounting for segment length.

For a reproducible **grid-optimal** result, form a sufficiently dense ordered
candidate set $q_0,\ldots,q_{K-1}$, precompute the deviation $D(i,j)$ of the
subcurve from the chord joining $\Gamma(q_i)$ to $\Gamma(q_j)$, and solve

$$
\mathrm{DP}[m,j]=
\min_{i<j}\max\!\left(\mathrm{DP}[m-1,i],D(i,j)\right).
$$

The base case is $\mathrm{DP}[2,j]=D(0,j)$, and states with too few preceding
candidates are excluded. Backtracking at $\mathrm{DP}[M,K-1]$ gives the global
minimax solution whose vertices belong to that candidate set. Its
straightforward optimization cost is $O(MK^2)$, excluding construction of the
error table. Continuous relaxation can then remove candidate-grid quantization.
A certified continuous optimum requires global interval or branch-and-bound
optimization over the ordered parameter domain and is substantially more
expensive.

#### NURBS-curve specialization

For $\Gamma=C$, evaluate positions and derivatives directly from the rational
B-spline formula. Distinct knot spans define the natural search intervals;
repeated knots and one-sided derivatives must be examined explicitly. For a
certified error oracle, convert each nonzero knot span to a rational Bézier span
and use homogeneous de Casteljau subdivision with positive-weight convex-hull
bounds. Sampled search plus one-dimensional refinement is faster and is the
interactive implementation's approximation.

Knot-span boundaries are search features, but they are mandatory tessellation
vertices only when they contain a discontinuity or when preserving them is an
explicit constraint. Forcing every ordinary knot into the result can prevent a
true fixed-budget optimum.

#### NURBS-offset specialization

For $\Gamma=O_d$, tessellate evaluations of the analytic offset formula
directly. Never offset the vertices of a source-curve tessellation: doing so
optimizes a different, already approximated curve. Use one global maximum-error
queue across all regular branches so the fixed budget goes to the branch with
the current largest defect.

Split the domain at tangent discontinuities and points where $C'(u)=0$; these
are branch boundaries rather than ordinary smooth intervals. Detect offset cusp
candidates from $1-d\kappa(u)=0$ and preserve them as mandatory vertices when
the cusp must be represented exactly. If the endpoints and mandatory features
already require more than $M$ vertices, the constrained tessellation is
infeasible and must be reported rather than silently dropping a feature.

The offset error oracle must measure $O_d$ against offset chords. Source-curve
error and source curvature alone are insufficient because

$$
|\kappa_{O_d}(u)|=
\frac{|\kappa(u)|}{|1-d\kappa(u)|}
$$

on a regular branch, so an inside offset can become arbitrarily sharp near a
cusp. Adaptive offset sampling with local maximization is the practical oracle;
certified bounds require interval bounds for the normalized normal and its
derivatives. The same dynamic program gives a grid-optimal offset tessellation
once its candidate set and offset-specific error table have been constructed.

## Tests

Run the headless mathematical-core checks with the Godot executable:

```powershell
godot --headless --path . --script tests/test_nurbs_curve.gd
```
