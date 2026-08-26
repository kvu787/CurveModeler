# Make the knot-vector UI read-only

Date: 2026-08-26

## User

> Remove knot vector stuff from the UI entirely, except preserve a small read-only text box that shows the knot vector

## Assistant

Removed knot-vector editing from the inspector while preserving a compact read-only display of the active curve's knot vector.

- Removed the editable knot field, Apply knots and Uniform buttons, validation label, parsing callback, and manual reset callback.
- Kept knot vectors in the NURBS data model and document serialization, so imported custom vectors remain intact.
- Kept the displayed value synchronized when the curve changes or a document loads.
- Updated the README and application smoke test for the read-only behavior.
- Verified the NURBS core and application smoke suites under Godot 4.7.2; both passed. The restricted environment emitted its existing log-file and certificate-store warnings.

Implementation commit: `1590a1d` (`Make knot vector display read-only`).
