class_name NurbsCanvas
extends Control

signal selection_changed(index: int)
signal curve_changed
signal pointer_status(text: String)

enum ToolMode { SELECT, ADD, DELETE }

const BACKGROUND := Color("111722")
const GRID_MINOR := Color("1c2634")
const GRID_MAJOR := Color("29384a")
const AXIS_X := Color("70414a")
const AXIS_Y := Color("37645f")
const CONTROL_LINE := Color("64748b")
const CURVE_GLOW := Color("163d52")
const CURVE_COLOR := Color("38bdf8")
const TESSELLATION_VERTEX_COLOR := Color("c084fc")
const CURVATURE_LOW := Color("38bdf8")
const CURVATURE_HIGH := Color("fb7185")
const POINT_COLOR := Color("e2e8f0")
const WEIGHT_LOW := Color("38bdf8")
const WEIGHT_HIGH := Color("fb7185")
const SELECTED_COLOR := Color("fbbf24")
const HOVER_COLOR := Color("7dd3fc")
const CONTROL_POINT_RADIUS := 8.0

var curve := NurbsCurve2D.new()
var tool_mode := ToolMode.SELECT
var selected_index := -1
var hover_index := -1
var zoom := 1.0
var view_offset := Vector2.ZERO
var grid_size := 50.0
var show_grid := true
var show_curvature := true
var tessellation_vertex_count := 32

var _dragging_point := false
var _panning := false
var _last_mouse_position := Vector2.ZERO
var _display_tessellation := PackedVector2Array()
var _tessellation_dirty := true


func _ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_CROSS
	clip_contents = true
	focus_mode = Control.FOCUS_NONE
	resized.connect(queue_redraw)


func set_curve(value: NurbsCurve2D) -> void:
	curve = value
	selected_index = -1
	hover_index = -1
	invalidate_tessellation()
	selection_changed.emit(-1)


func set_tessellation_vertex_count(value: int) -> void:
	tessellation_vertex_count = maxi(value, 3)
	invalidate_tessellation()


func get_tessellation_points() -> PackedVector2Array:
	_update_tessellation()
	return _display_tessellation


func invalidate_tessellation() -> void:
	_tessellation_dirty = true
	queue_redraw()


func _update_tessellation() -> void:
	if not _tessellation_dirty:
		return
	_display_tessellation = curve.tessellate_adaptive(tessellation_vertex_count)
	_tessellation_dirty = false


func set_tool(value: ToolMode) -> void:
	tool_mode = value
	_dragging_point = false
	match tool_mode:
		ToolMode.SELECT:
			mouse_default_cursor_shape = Control.CURSOR_ARROW
		ToolMode.ADD:
			mouse_default_cursor_shape = Control.CURSOR_CROSS
		ToolMode.DELETE:
			mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	queue_redraw()


func select_point(index: int) -> void:
	selected_index = index if index >= 0 and index < curve.control_points.size() else -1
	selection_changed.emit(selected_index)
	queue_redraw()


func delete_selected() -> void:
	if selected_index < 0:
		return
	if curve.remove_point(selected_index):
		selected_index = mini(selected_index, curve.control_points.size() - 1)
		curve_changed.emit()
		selection_changed.emit(selected_index)
	queue_redraw()


func fit_curve() -> void:
	if curve.control_points.is_empty() or size.x <= 1.0 or size.y <= 1.0:
		return
	var bounds := curve.get_bounds()
	var padded_size := bounds.size + Vector2(180, 180)
	zoom = clampf(minf(size.x / maxf(padded_size.x, 1.0), size.y / maxf(padded_size.y, 1.0)), 0.1, 8.0)
	view_offset = -_world_vector_to_screen(bounds.get_center())
	queue_redraw()


func reset_view() -> void:
	zoom = 1.0
	view_offset = Vector2.ZERO
	queue_redraw()


func world_to_screen(point: Vector2) -> Vector2:
	return size * 0.5 + view_offset + _world_vector_to_screen(point)


func screen_to_world(point: Vector2) -> Vector2:
	var relative := (point - size * 0.5 - view_offset) / zoom
	return Vector2(relative.x, -relative.y)


func _world_vector_to_screen(value: Vector2) -> Vector2:
	return Vector2(value.x, -value.y) * zoom


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BACKGROUND)
	if show_grid:
		_draw_grid()
	_draw_origin_axes()
	if curve.control_points.is_empty():
		_draw_empty_hint()
		return
	_draw_control_polygon()
	_draw_curve()
	if show_curvature:
		_draw_curvature_comb()
	_draw_control_points()
	_draw_tessellation_vertices()


func _draw_grid() -> void:
	var scaled_step := grid_size * zoom
	var multiplier := 1.0
	while scaled_step * multiplier < 28.0:
		multiplier *= 2.0
	while scaled_step * multiplier > 110.0:
		multiplier *= 0.5
	var step := scaled_step * multiplier
	if step <= 0.0:
		return
	var origin := world_to_screen(Vector2.ZERO)
	var start_x := fposmod(origin.x, step)
	var start_y := fposmod(origin.y, step)
	var line_index := int(floor(-origin.x / step))
	var x := start_x
	while x < size.x:
		var major := posmod(line_index, 5) == 0
		draw_line(Vector2(x, 0), Vector2(x, size.y), GRID_MAJOR if major else GRID_MINOR, 1.0)
		x += step
		line_index += 1
	line_index = int(floor(-origin.y / step))
	var y := start_y
	while y < size.y:
		var major := posmod(line_index, 5) == 0
		draw_line(Vector2(0, y), Vector2(size.x, y), GRID_MAJOR if major else GRID_MINOR, 1.0)
		y += step
		line_index += 1


func _draw_origin_axes() -> void:
	var origin := world_to_screen(Vector2.ZERO)
	if origin.y >= 0.0 and origin.y <= size.y:
		draw_line(Vector2(0, origin.y), Vector2(size.x, origin.y), AXIS_X, 1.5)
	if origin.x >= 0.0 and origin.x <= size.x:
		draw_line(Vector2(origin.x, 0), Vector2(origin.x, size.y), AXIS_Y, 1.5)


func _draw_empty_hint() -> void:
	var font := get_theme_default_font()
	var text := "Choose Add Point and click to begin"
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
	draw_string(font, Vector2((size.x - width) * 0.5, size.y * 0.5), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("94a3b8"))


func _draw_control_polygon() -> void:
	if curve.control_points.size() < 2:
		return
	var screen_points := PackedVector2Array()
	for point in curve.control_points:
		screen_points.append(world_to_screen(point))
	draw_polyline(screen_points, CONTROL_LINE, 1.25, true)


func _draw_curve() -> void:
	if not curve.is_valid():
		_display_tessellation.clear()
		return
	_update_tessellation()
	var screen_points := PackedVector2Array()
	for point in _display_tessellation:
		screen_points.append(world_to_screen(point))
	draw_polyline(screen_points, CURVE_GLOW, 7.0, true)
	draw_polyline(screen_points, CURVE_COLOR, 2.5, true)


func _draw_tessellation_vertices() -> void:
	if not curve.is_valid():
		return
	for point in _display_tessellation:
		var position := world_to_screen(point)
		draw_circle(position, 5.5, Color(BACKGROUND, 0.96))
		var diamond := PackedVector2Array([
			position + Vector2(0, -4),
			position + Vector2(4, 0),
			position + Vector2(0, 4),
			position + Vector2(-4, 0),
		])
		draw_colored_polygon(diamond, TESSELLATION_VERTEX_COLOR)


func _draw_curvature_comb() -> void:
	if not curve.is_valid():
		return
	var domain := curve.get_domain()
	var sample_count := clampi(int(size.x / 42.0), 16, 44)
	var reference_length := maxf(curve.get_bounds().size.length(), 1.0)
	for index in range(sample_count + 1):
		var parameter := lerpf(domain.x, domain.y, float(index) / float(sample_count))
		var derivatives := curve.evaluate_derivatives(parameter)
		var tangent := derivatives[1]
		var speed_squared := tangent.length_squared()
		if speed_squared <= NurbsCurve2D.EPSILON * NurbsCurve2D.EPSILON:
			continue
		var signed_value := tangent.cross(derivatives[2]) / (speed_squared * sqrt(speed_squared))
		var relative_curvature := absf(signed_value) * reference_length
		var strength := relative_curvature / (1.0 + relative_curvature)
		var indicator_length := 52.0 * strength
		if indicator_length < 0.75:
			continue
		var world_normal := Vector2(-tangent.y, tangent.x).normalized()
		if signed_value < 0.0:
			world_normal = -world_normal
		var screen_normal := _world_vector_to_screen(world_normal).normalized()
		var base := world_to_screen(derivatives[0])
		var start := base + screen_normal * 3.5
		var tip := base + screen_normal * indicator_length
		var color := CURVATURE_LOW.lerp(CURVATURE_HIGH, strength)
		draw_line(start, tip, Color(color, 0.82), 1.5, true)
		draw_circle(tip, 2.4, color)
	_draw_curvature_legend()


func _draw_curvature_legend() -> void:
	var panel := Rect2(12, 12, 226, 45)
	draw_rect(panel, Color("0b111b", 0.9), true)
	draw_rect(panel, Color("334155", 0.9), false, 1.0)
	var font := get_theme_default_font()
	draw_string(font, Vector2(22, 31), "CURVATURE COMB", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("bae6fd"))
	draw_string(font, Vector2(22, 48), "longer + warmer = sharper", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("94a3b8"))


func _draw_control_points() -> void:
	for index in range(curve.control_points.size()):
		var position := world_to_screen(curve.control_points[index])
		var weight_color := _weight_color(curve.weights[index])
		draw_circle(position, CONTROL_POINT_RADIUS + 3.0, Color(BACKGROUND, 0.95))
		draw_circle(position, CONTROL_POINT_RADIUS, weight_color)
		draw_circle(position, CONTROL_POINT_RADIUS - 3.0, BACKGROUND)
		if index == selected_index:
			draw_arc(position, CONTROL_POINT_RADIUS + 6.0, 0, TAU, 28, Color(SELECTED_COLOR, 0.75), 1.5, true)
		elif index == hover_index:
			draw_arc(position, CONTROL_POINT_RADIUS + 5.0, 0, TAU, 28, Color(HOVER_COLOR, 0.7), 1.0, true)


func _weight_color(weight: float) -> Color:
	var logarithmic_weight := log(maxf(weight, NurbsCurve2D.EPSILON))
	var gradient_position := 0.5 + 0.5 * logarithmic_weight / (1.0 + absf(logarithmic_weight))
	if gradient_position < 0.5:
		return WEIGHT_LOW.lerp(POINT_COLOR, gradient_position * 2.0)
	return POINT_COLOR.lerp(WEIGHT_HIGH, (gradient_position - 0.5) * 2.0)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_handle_mouse_button(event)
	elif event is InputEventMouseMotion:
		_handle_mouse_motion(event)


func _handle_mouse_button(event: InputEventMouseButton) -> void:
	_last_mouse_position = event.position
	if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
		_zoom_at(event.position, 1.12)
		accept_event()
		return
	if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
		_zoom_at(event.position, 1.0 / 1.12)
		accept_event()
		return
	if event.button_index in [MOUSE_BUTTON_MIDDLE, MOUSE_BUTTON_RIGHT]:
		_panning = event.pressed
		mouse_default_cursor_shape = Control.CURSOR_DRAG if _panning else Control.CURSOR_ARROW
		accept_event()
		return
	if event.button_index != MOUSE_BUTTON_LEFT:
		return
	if event.pressed:
		var point_index := _point_at(event.position)
		match tool_mode:
			ToolMode.SELECT:
				select_point(point_index)
				if point_index >= 0:
					_dragging_point = true
			ToolMode.ADD:
				var new_point := screen_to_world(event.position)
				var insert_index := _nearest_control_segment(event.position) + 1 if curve.control_points.size() >= 2 else -1
				select_point(curve.add_point(new_point, insert_index))
				curve_changed.emit()
			ToolMode.DELETE:
				if point_index >= 0:
					select_point(point_index)
					delete_selected()
	else:
		if _dragging_point:
			_dragging_point = false
	accept_event()


func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	if _panning:
		view_offset += event.relative
		queue_redraw()
	elif _dragging_point and selected_index >= 0:
		curve.control_points[selected_index] = screen_to_world(event.position)
		curve_changed.emit()
		queue_redraw()
	else:
		var new_hover := _point_at(event.position)
		if new_hover != hover_index:
			hover_index = new_hover
			queue_redraw()
	var world := screen_to_world(event.position)
	pointer_status.emit("x  %.2f    y  %.2f    zoom  %.0f%%" % [world.x, world.y, zoom * 100.0])
	_last_mouse_position = event.position


func _zoom_at(screen_position: Vector2, factor: float) -> void:
	var world_before := screen_to_world(screen_position)
	zoom = clampf(zoom * factor, 0.05, 20.0)
	var screen_after := world_to_screen(world_before)
	view_offset += screen_position - screen_after
	queue_redraw()


func _point_at(screen_position: Vector2) -> int:
	var best_index := -1
	var best_distance := 14.0
	for index in range(curve.control_points.size()):
		var distance := screen_position.distance_to(world_to_screen(curve.control_points[index]))
		if distance < best_distance:
			best_distance = distance
			best_index = index
	return best_index


func _nearest_control_segment(screen_position: Vector2) -> int:
	if curve.control_points.size() < 2:
		return curve.control_points.size() - 1
	var best_index := curve.control_points.size() - 2
	var best_distance := INF
	for index in range(curve.control_points.size() - 1):
		var start := world_to_screen(curve.control_points[index])
		var end := world_to_screen(curve.control_points[index + 1])
		var closest := Geometry2D.get_closest_point_to_segment(screen_position, start, end)
		var distance := screen_position.distance_squared_to(closest)
		if distance < best_distance:
			best_distance = distance
			best_index = index
	return best_index
