class_name NurbsCurve2D
extends RefCounted

## A non-uniform rational B-spline curve with an open knot vector.
##
## Control points and their weights are kept in parallel arrays. Knot values are
## normalized only when generating a new uniform vector; imported custom vectors
## retain their original parameter domain.

const EPSILON := 0.000001

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


func tangent(parameter: float) -> Vector2:
	if not is_valid():
		return Vector2.RIGHT
	var domain := get_domain()
	var step := maxf((domain.y - domain.x) * 0.0001, EPSILON)
	var before := evaluate(maxf(domain.x, parameter - step))
	var after := evaluate(minf(domain.y, parameter + step))
	return before.direction_to(after)


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
