# Curve Explorer

A focused 2D non-uniform rational B-spline modeler for Godot 4.7.2.

## Run

On Windows, double-click **Run.cmd** in File Explorer. It locates Godot 4.7.2, builds the standalone Windows application at `build/CurveExplorer.exe`, and launches it. The build uses the installed editor executable as a custom template and places the project data beside it in `CurveExplorer.pck`, so separate export-template installation is not required. Keep the EXE and PCK together when moving the application.

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
- The toggleable **Curvature** comb points into each bend; longer, warmer spikes mark sharper curvature and disappear on straight spans.
- The mouse wheel zooms around the pointer; middle- or right-drag pans. **Fit** frames the curve.

All commands and canvas tools are mouse-only. The keyboard is available only while editing text or numeric values; click the relevant button to apply or perform an action.

Documents are saved as readable `*.nurbs.json` files. **Export SVG** writes a standalone SVG path suitable for other graphics tools.

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
1,&u_i\leq u\lt u_{i+1},\\
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

The **NURBS curve offset at signed distance** $d$ is the derived parametric curve

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

## Tests

Run the headless mathematical-core checks with the Godot executable:

```powershell
godot --headless --path . --script tests/test_nurbs_curve.gd
```
