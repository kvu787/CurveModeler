class_name NurbsCurve2D
extends RefCounted

## A non-uniform rational B-spline curve with an open knot vector.
##
## Control points and their weights are kept in parallel arrays. Knot values are
## normalized only when generating a new uniform vector; imported custom vectors
## retain their original parameter domain.

const EPSILON := 0.000001
const TESSELLATION_SEARCH_STEPS := 24
const TESSELLATION_REFINEMENT_STEPS := 3

var control_points: Array[Vector2] = []
var weights: Array[float] = []
var degree: int = 3
var knots: Array[float] = []


func _init(initial_points: Array[Vector2] = []) -> void:
	control_points.assign(initial_points)
	for _point in control_points:
		weights.append(1.0)
	degree = mini(3, maxi(1, control_points.size() - 1))
	regenerate_knots()


func duplicate_curve() -> NurbsCurve2D:
	var copy := NurbsCurve2D.new()
	copy.control_points.assign(control_points)
	copy.weights.assign(weights)
	copy.degree = degree
	copy.knots.assign(knots)
	return copy


func is_valid() -> bool:
	if control_points.size() < 2:
		return false
	if degree < 1 or degree >= control_points.size():
		return false
	if weights.size() != control_points.size():
		return false
	if knots.size() != control_points.size() + degree + 1:
		return false
	for weight in weights:
		if weight <= EPSILON or not is_finite(weight):
			return false
	for index in range(1, knots.size()):
		if knots[index] + EPSILON < knots[index - 1]:
			return false
	return get_domain().y - get_domain().x > EPSILON


func get_domain() -> Vector2:
	if knots.size() <= degree or control_points.is_empty():
		return Vector2.ZERO
	return Vector2(knots[degree], knots[control_points.size()])


func set_degree(value: int) -> void:
	if control_points.size() < 2:
		degree = 1
	else:
		degree = clampi(value, 1, control_points.size() - 1)
	regenerate_knots()


func regenerate_knots() -> void:
	knots.clear()
	if control_points.size() < 2:
		return
	degree = clampi(degree, 1, control_points.size() - 1)
	var knot_count := control_points.size() + degree + 1
	var interior_count := control_points.size() - degree - 1
	for index in range(knot_count):
		if index <= degree:
			knots.append(0.0)
		elif index >= control_points.size():
			knots.append(1.0)
		else:
			knots.append(float(index - degree) / float(interior_count + 1))


func set_custom_knots(values: Array[float]) -> bool:
	if values.size() != control_points.size() + degree + 1:
		return false
	for index in range(1, values.size()):
		if values[index] + EPSILON < values[index - 1]:
			return false
	var old_knots: Array[float] = knots.duplicate()
	knots.assign(values)
	if not is_valid():
		knots = old_knots
		return false
	return true


func add_point(point: Vector2, at_index: int = -1) -> int:
	var index := at_index
	if index < 0 or index > control_points.size():
		index = control_points.size()
	control_points.insert(index, point)
	weights.insert(index, 1.0)
	degree = mini(degree, control_points.size() - 1)
	regenerate_knots()
	return index


func remove_point(index: int) -> bool:
	if index < 0 or index >= control_points.size() or control_points.size() <= 2:
		return false
	control_points.remove_at(index)
	weights.remove_at(index)
	degree = mini(degree, control_points.size() - 1)
	regenerate_knots()
	return true


func evaluate(parameter: float) -> Vector2:
	if not is_valid():
		return Vector2.ZERO
	var domain := get_domain()
	var u := clampf(parameter, domain.x, domain.y)
	var span := _find_span(u)
	var basis := _basis_functions(span, u)
	var numerator := Vector2.ZERO
	var denominator := 0.0
	for local_index in range(degree + 1):
		var point_index := span - degree + local_index
		var rational_basis := basis[local_index] * weights[point_index]
		numerator += control_points[point_index] * rational_basis
		denominator += rational_basis
	if absf(denominator) <= EPSILON:
		return Vector2.ZERO
	return numerator / denominator


func evaluate_derivatives(parameter: float) -> Array[Vector2]:
	## Returns the position, first derivative, and second derivative at `parameter`.
	## Basis derivatives are evaluated analytically, including the rational weight
	## correction, so the result remains accurate for non-uniform knot vectors.
	var result: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]
	if not is_valid():
		return result
	var domain := get_domain()
	var u := clampf(parameter, domain.x, domain.y)
	var basis_derivatives := _basis_derivatives(u)
	var numerator_derivatives: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]
	var weight_derivatives: Array[float] = [0.0, 0.0, 0.0]
	for derivative_order in range(3):
		for point_index in range(control_points.size()):
			var weighted_basis: float = basis_derivatives[derivative_order][point_index] * weights[point_index]
			numerator_derivatives[derivative_order] += control_points[point_index] * weighted_basis
			weight_derivatives[derivative_order] += weighted_basis
	if absf(weight_derivatives[0]) <= EPSILON:
		return result
	result[0] = numerator_derivatives[0] / weight_derivatives[0]
	result[1] = (numerator_derivatives[1] - result[0] * weight_derivatives[1]) / weight_derivatives[0]
	result[2] = (
		numerator_derivatives[2]
		- result[0] * weight_derivatives[2]
		- result[1] * (2.0 * weight_derivatives[1])
	) / weight_derivatives[0]
	return result


func curvature(parameter: float) -> float:
	return absf(signed_curvature(parameter))


func signed_curvature(parameter: float) -> float:
	var derivatives := evaluate_derivatives(parameter)
	var speed_squared := derivatives[1].length_squared()
	if speed_squared <= EPSILON * EPSILON:
		return 0.0
	return derivatives[1].cross(derivatives[2]) / (speed_squared * sqrt(speed_squared))


func tangent(parameter: float) -> Vector2:
	if not is_valid():
		return Vector2.RIGHT
	var first_derivative := evaluate_derivatives(parameter)[1]
	return first_derivative.normalized() if first_derivative.length_squared() > EPSILON * EPSILON else Vector2.RIGHT


func tessellate(segment_count: int = 160) -> PackedVector2Array:
	var result := PackedVector2Array()
	if not is_valid():
		return result
	var domain := get_domain()
	var count := maxi(segment_count, 2)
	for index in range(count + 1):
		var ratio := float(index) / float(count)
		result.append(evaluate(lerpf(domain.x, domain.y, ratio)))
	return result


func tessellate_adaptive(vertex_count: int) -> PackedVector2Array:
	## Returns an exact-size polyline by repeatedly splitting the curve interval
	## whose chord has the greatest deviation from the curve.
	var result := PackedVector2Array()
	if not is_valid():
		return result
	var count := maxi(vertex_count, 3)
	var domain := get_domain()
	var intervals: Array[Dictionary] = [_make_tessellation_interval(domain.x, domain.y)]
	while intervals.size() < count - 1:
		var split_index := 0
		var greatest_error := -1.0
		var longest_chord := -1.0
		for index in range(intervals.size()):
			var interval := intervals[index]
			var error: float = interval.error_squared
			var chord_length: float = interval.chord_length_squared
			if error > greatest_error or (error == greatest_error and chord_length > longest_chord):
				split_index = index
				greatest_error = error
				longest_chord = chord_length

		var selected := intervals[split_index]
		var start_parameter: float = selected.start_parameter
		var end_parameter: float = selected.end_parameter
		var split_parameter: float = selected.split_parameter
		if split_parameter <= start_parameter or split_parameter >= end_parameter:
			split_parameter = (start_parameter + end_parameter) * 0.5
		intervals[split_index] = _make_tessellation_interval(start_parameter, split_parameter)
		intervals.insert(split_index + 1, _make_tessellation_interval(split_parameter, end_parameter))

	result.append(evaluate(float(intervals[0].start_parameter)))
	for interval in intervals:
		result.append(evaluate(float(interval.end_parameter)))
	return result


func _make_tessellation_interval(start_parameter: float, end_parameter: float) -> Dictionary:
	var start_point := evaluate(start_parameter)
	var end_point := evaluate(end_parameter)
	var interval_length := end_parameter - start_parameter
	var split_parameter := (start_parameter + end_parameter) * 0.5
	var split_point := evaluate(split_parameter)
	var greatest_error := _distance_squared_to_segment(split_point, start_point, end_point)

	for step in range(1, TESSELLATION_SEARCH_STEPS):
		var parameter := start_parameter + interval_length * float(step) / float(TESSELLATION_SEARCH_STEPS)
		var point := evaluate(parameter)
		var error := _distance_squared_to_segment(point, start_point, end_point)
		if error > greatest_error:
			greatest_error = error
			split_parameter = parameter

	# Repeated knots can contain corners, so consider them explicitly even when
	# they do not happen to coincide with the regular search samples.
	for knot in knots:
		if knot > start_parameter + EPSILON and knot < end_parameter - EPSILON:
			var knot_point := evaluate(knot)
			var knot_error := _distance_squared_to_segment(knot_point, start_point, end_point)
			if knot_error > greatest_error:
				greatest_error = knot_error
				split_parameter = knot

	var search_radius := interval_length / float(TESSELLATION_SEARCH_STEPS)
	for _iteration in range(TESSELLATION_REFINEMENT_STEPS):
		var search_start := maxf(start_parameter, split_parameter - search_radius)
		var search_end := minf(end_parameter, split_parameter + search_radius)
		for step in range(1, 8):
			var parameter := lerpf(search_start, search_end, float(step) / 8.0)
			var point := evaluate(parameter)
			var error := _distance_squared_to_segment(point, start_point, end_point)
			if error > greatest_error:
				greatest_error = error
				split_parameter = parameter
		search_radius = (search_end - search_start) / 8.0

	return {
		"start_parameter": start_parameter,
		"end_parameter": end_parameter,
		"split_parameter": split_parameter,
		"error_squared": greatest_error,
		"chord_length_squared": start_point.distance_squared_to(end_point),
	}


static func _distance_squared_to_segment(point: Vector2, start: Vector2, end: Vector2) -> float:
	var segment := end - start
	var length_squared := segment.length_squared()
	if length_squared <= EPSILON * EPSILON:
		return point.distance_squared_to(start)
	var ratio := clampf((point - start).dot(segment) / length_squared, 0.0, 1.0)
	return point.distance_squared_to(start + segment * ratio)


func nearest_parameter(point: Vector2, coarse_steps: int = 120) -> float:
	var domain := get_domain()
	if not is_valid():
		return domain.x
	var best_parameter := domain.x
	var best_distance := INF
	for index in range(coarse_steps + 1):
		var parameter := lerpf(domain.x, domain.y, float(index) / coarse_steps)
		var distance := evaluate(parameter).distance_squared_to(point)
		if distance < best_distance:
			best_distance = distance
			best_parameter = parameter
	var radius := (domain.y - domain.x) / coarse_steps
	for _iteration in range(8):
		var left := maxf(domain.x, best_parameter - radius)
		var right := minf(domain.y, best_parameter + radius)
		var p1 := lerpf(left, right, 1.0 / 3.0)
		var p2 := lerpf(left, right, 2.0 / 3.0)
		if evaluate(p1).distance_squared_to(point) < evaluate(p2).distance_squared_to(point):
			best_parameter = p1
		else:
			best_parameter = p2
		radius *= 0.5
	return best_parameter


func get_bounds() -> Rect2:
	if control_points.is_empty():
		return Rect2()
	var minimum := control_points[0]
	var maximum := control_points[0]
	for point in control_points:
		minimum = minimum.min(point)
		maximum = maximum.max(point)
	return Rect2(minimum, maximum - minimum)


func to_dictionary() -> Dictionary:
	var point_data: Array[Dictionary] = []
	for index in range(control_points.size()):
		point_data.append({
			"x": control_points[index].x,
			"y": control_points[index].y,
			"weight": weights[index],
		})
	return {
		"version": 1,
		"degree": degree,
		"points": point_data,
		"knots": knots.duplicate(),
	}


static func from_dictionary(data: Dictionary) -> NurbsCurve2D:
	var curve := NurbsCurve2D.new()
	var point_values: Array[Vector2] = []
	var weight_values: Array[float] = []
	for entry in data.get("points", []):
		if entry is Dictionary:
			point_values.append(Vector2(float(entry.get("x", 0.0)), float(entry.get("y", 0.0))))
			weight_values.append(float(entry.get("weight", 1.0)))
	curve.control_points.assign(point_values)
	curve.weights.assign(weight_values)
	curve.degree = int(data.get("degree", 3))
	curve.degree = clampi(curve.degree, 1, maxi(1, curve.control_points.size() - 1))
	var knot_values: Array[float] = []
	for knot in data.get("knots", []):
		knot_values.append(float(knot))
	curve.knots.assign(knot_values)
	if not curve.is_valid():
		curve.regenerate_knots()
	return curve


func _find_span(parameter: float) -> int:
	var point_count := control_points.size()
	if parameter >= knots[point_count] - EPSILON:
		return point_count - 1
	if parameter <= knots[degree] + EPSILON:
		return degree
	var low := degree
	var high := point_count
	var middle := (low + high) / 2
	while parameter < knots[middle] or parameter >= knots[middle + 1]:
		if parameter < knots[middle]:
			high = middle
		else:
			low = middle
		middle = (low + high) / 2
	return middle


func _basis_functions(span: int, parameter: float) -> Array[float]:
	var basis: Array[float] = []
	var left: Array[float] = []
	var right: Array[float] = []
	basis.resize(degree + 1)
	left.resize(degree + 1)
	right.resize(degree + 1)
	basis[0] = 1.0
	for order in range(1, degree + 1):
		left[order] = parameter - knots[span + 1 - order]
		right[order] = knots[span + order] - parameter
		var saved := 0.0
		for index in range(order):
			var divisor := right[index + 1] + left[order - index]
			var temporary := 0.0 if absf(divisor) <= EPSILON else basis[index] / divisor
			basis[index] = saved + right[index + 1] * temporary
			saved = left[order - index] * temporary
		basis[order] = saved
	return basis


func _basis_derivatives(parameter: float) -> Array:
	# Build every basis degree from the piecewise-constant functions upward.
	# Differentiating the Cox-de Boor recurrence then gives exact first and
	# second derivatives without finite-difference step-size sensitivity.
	var interval_count := knots.size() - 1
	var basis_by_degree: Array = []
	var first_by_degree: Array = []
	var second_by_degree: Array = []
	var degree_zero: Array[float] = []
	var first_zero: Array[float] = []
	var second_zero: Array[float] = []
	degree_zero.resize(interval_count)
	first_zero.resize(interval_count)
	second_zero.resize(interval_count)
	degree_zero.fill(0.0)
	first_zero.fill(0.0)
	second_zero.fill(0.0)

	var domain := get_domain()
	if is_equal_approx(parameter, domain.y):
		degree_zero[control_points.size() - 1] = 1.0
	else:
		for index in range(interval_count):
			if parameter >= knots[index] and parameter < knots[index + 1]:
				degree_zero[index] = 1.0
				break
	basis_by_degree.append(degree_zero)
	first_by_degree.append(first_zero)
	second_by_degree.append(second_zero)

	for current_degree in range(1, degree + 1):
		var previous_basis: Array = basis_by_degree[current_degree - 1]
		var previous_first: Array = first_by_degree[current_degree - 1]
		var current_size := previous_basis.size() - 1
		var current_basis: Array[float] = []
		var current_first: Array[float] = []
		var current_second: Array[float] = []
		current_basis.resize(current_size)
		current_first.resize(current_size)
		current_second.resize(current_size)
		current_basis.fill(0.0)
		current_first.fill(0.0)
		current_second.fill(0.0)
		for index in range(current_size):
			var left_denominator := knots[index + current_degree] - knots[index]
			var right_denominator := knots[index + current_degree + 1] - knots[index + 1]
			if absf(left_denominator) > EPSILON:
				var left_factor := (parameter - knots[index]) / left_denominator
				current_basis[index] += left_factor * previous_basis[index]
				current_first[index] += float(current_degree) * previous_basis[index] / left_denominator
				current_second[index] += float(current_degree) * previous_first[index] / left_denominator
			if absf(right_denominator) > EPSILON:
				var right_factor := (knots[index + current_degree + 1] - parameter) / right_denominator
				current_basis[index] += right_factor * previous_basis[index + 1]
				current_first[index] -= float(current_degree) * previous_basis[index + 1] / right_denominator
				current_second[index] -= float(current_degree) * previous_first[index + 1] / right_denominator
		basis_by_degree.append(current_basis)
		first_by_degree.append(current_first)
		second_by_degree.append(current_second)

	return [basis_by_degree[degree], first_by_degree[degree], second_by_degree[degree]]
