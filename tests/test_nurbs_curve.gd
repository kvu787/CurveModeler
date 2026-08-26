extends SceneTree

var failures := 0


func _init() -> void:
	_test_linear_curve()
	_test_quadratic_rational_arc()
	_test_serialization()
	_test_custom_knot_validation()
	if failures == 0:
		print("NURBS core tests passed")
	quit(failures)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func _test_linear_curve() -> void:
	var curve := NurbsCurve2D.new([Vector2(0, 0), Vector2(10, 20)])
	_expect(curve.evaluate(0.0).is_equal_approx(Vector2.ZERO), "Line must start at P0")
	_expect(curve.evaluate(1.0).is_equal_approx(Vector2(10, 20)), "Line must end at P1")
	_expect(curve.evaluate(0.5).is_equal_approx(Vector2(5, 10)), "Line midpoint must interpolate")


func _test_quadratic_rational_arc() -> void:
	var curve := NurbsCurve2D.new([Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)])
	curve.set_degree(2)
	curve.weights[1] = sqrt(0.5)
	var midpoint := curve.evaluate(0.5)
	_expect(midpoint.distance_to(Vector2(sqrt(0.5), sqrt(0.5))) < 0.0001, "Rational quadratic must reproduce a quarter circle")


func _test_serialization() -> void:
	var source := NurbsCurve2D.new([Vector2(-3, 2), Vector2(4, 7), Vector2(9, -1)])
	source.weights[1] = 2.5
	var restored := NurbsCurve2D.from_dictionary(source.to_dictionary())
	_expect(restored.is_valid(), "Deserialized curve must be valid")
	_expect(restored.control_points == source.control_points, "Control points must round-trip")
	_expect(is_equal_approx(restored.weights[1], 2.5), "Weights must round-trip")


func _test_custom_knot_validation() -> void:
	var curve := NurbsCurve2D.new([Vector2.ZERO, Vector2.ONE, Vector2(2, 0)])
	curve.set_degree(2)
	_expect(curve.set_custom_knots([0.0, 0.0, 0.0, 2.0, 2.0, 2.0]), "Valid custom domain must be accepted")
	_expect(not curve.set_custom_knots([0.0, 0.0, 1.0]), "Wrong knot count must be rejected")
	_expect(is_equal_approx(curve.get_domain().y, 2.0), "Rejected knots must not replace prior vector")
