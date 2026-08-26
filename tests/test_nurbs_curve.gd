extends SceneTree

var failures := 0


func _init() -> void:
	_test_linear_curve()
	_test_quadratic_rational_arc()
	_test_curvature()
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


func _test_curvature() -> void:
	var line := NurbsCurve2D.new([Vector2(0, 0), Vector2(10, 20)])
	line.weights[1] = 3.0
	for parameter in [0.1, 0.5, 0.9]:
		_expect(absf(line.curvature(parameter)) < 0.000001, "A rationally parameterized line must have zero curvature")

	var circle := NurbsCurve2D.new([Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)])
	circle.set_degree(2)
	circle.weights[1] = sqrt(0.5)
	for parameter in [0.0, 0.2, 0.5, 0.8, 1.0]:
		_expect(absf(circle.curvature(parameter) - 1.0) < 0.00001, "A unit circular arc must have unit curvature")
	_expect(circle.signed_curvature(0.5) > 0.0, "Counterclockwise bending must have positive signed curvature")
	_expect(circle.evaluate_derivatives(0.5)[0].is_equal_approx(circle.evaluate(0.5)), "Derivative evaluation must preserve the curve position")

	var non_uniform := NurbsCurve2D.new([Vector2(0, 0), Vector2(1, 2), Vector2(3, -1), Vector2(4, 3), Vector2(6, 0)])
	non_uniform.set_degree(3)
	non_uniform.weights.assign([1.0, 1.7, 0.8, 2.1, 1.0])
	_expect(non_uniform.set_custom_knots([0.0, 0.0, 0.0, 0.0, 0.3, 1.0, 1.0, 1.0, 1.0]), "Curvature fixture knots must be valid")
	var parameter := 0.6
	var step := 0.001
	var analytic := non_uniform.evaluate_derivatives(parameter)
	var evaluated := non_uniform.evaluate(parameter)
	var finite_first := (non_uniform.evaluate(parameter + step) - non_uniform.evaluate(parameter - step)) / (2.0 * step)
	_expect(analytic[0].distance_to(evaluated) < 0.000001, "Derivative basis must preserve non-uniform position: %s versus %s" % [analytic[0], evaluated])
	_expect(non_uniform.evaluate_derivatives(parameter - step)[0].distance_to(non_uniform.evaluate(parameter - step)) < 0.000001, "Derivative basis must preserve nearby non-uniform positions")
	_expect(non_uniform.evaluate_derivatives(parameter + step)[0].distance_to(non_uniform.evaluate(parameter + step)) < 0.000001, "Derivative basis must preserve nearby non-uniform positions")
	_expect(
		analytic[1].distance_to(finite_first) < 0.0002,
		"Analytic derivatives must agree with a non-uniform finite difference: %s versus %s" % [analytic[1], finite_first]
	)


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
