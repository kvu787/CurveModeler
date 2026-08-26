# Visualize CV weights with color

Date: 2026-08-26

## User

> to indicate the weight of a cv, don't use size. instead, use a color gradient.

## Assistant

Changed the control-vertex weight visualization from variable marker size to color.

- All control vertices now use the same 8-pixel radius.
- A logarithmic cool-to-warm gradient represents rational weight, with weight 1 at the neutral midpoint.
- Selection and hover use separate outer outlines so they do not hide the weight color.
- Added smoke coverage for low, unit, and high weight colors and documented the visualization.

The mathematical-core and application smoke test suites both pass under Godot 4.7.2.

The implementation was committed separately as `181fc1e` (`Visualize CV weights with color`).
