extends SceneTree

var failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene: PackedScene = load("res://main.tscn")
	var app = scene.instantiate()
	root.add_child(app)
	await process_frame
	await process_frame

	_expect(ProjectSettings.get_setting("application/config/name") == "Curve Explorer", "Godot project metadata must use the Curve Explorer name")
	_expect(app.APP_TITLE == "Curve Explorer", "Application UI metadata must use the Curve Explorer name")
	_expect(app.name == "CurveExplorer", "The main scene root must use the Curve Explorer identifier")
	var brand_label := app.find_child("Brand", true, false) as Label
	_expect(brand_label != null and brand_label.text == "Curve Explorer", "Visible title-bar branding must read Curve Explorer exactly")
	_expect(app.curve.is_valid(), "Default document must contain a valid curve")
	_expect(app.canvas.curve == app.curve, "Canvas must display the active document")
	_expect(app.canvas.show_curvature, "Curvature visualization must be visible by default")
	_expect(app.canvas.tessellation_vertex_count == 32, "Adaptive tessellation must have a useful default vertex count")
	_expect(app.canvas.focus_mode == Control.FOCUS_NONE, "The canvas must not accept keyboard focus")
	_expect(app.canvas._weight_color(1.0).is_equal_approx(app.canvas.POINT_COLOR), "Unit-weight control points must use the gradient midpoint")
	_expect(app.canvas._weight_color(0.25).b > app.canvas._weight_color(0.25).r, "Lower weights must use the cool side of the gradient")
	_expect(app.canvas._weight_color(4.0).r > app.canvas._weight_color(4.0).b, "Higher weights must use the warm side of the gradient")
	for button in app.tool_buttons:
		_expect(button.focus_mode == Control.FOCUS_NONE, "Tool buttons must be mouse-only")
	var key_event := InputEventKey.new()
	key_event.keycode = KEY_N
	key_event.ctrl_pressed = true
	_expect(not app._is_value_entry_key(key_event), "Application shortcuts must be blocked")
	_expect(not app.knot_display.editable, "The knot vector must be displayed read-only")
	_expect(not app.knot_display.text.is_empty(), "The current knot vector must be visible")
	app.point_fields[0].get_line_edit().grab_focus()
	await process_frame
	key_event.ctrl_pressed = false
	key_event.unicode = 110
	_expect(app._is_value_entry_key(key_event), "Typing must remain available in value fields")
	key_event.keycode = KEY_ENTER
	key_event.unicode = 0
	_expect(not app._is_value_entry_key(key_event), "Value fields must not turn Enter into an application action")
	app.tessellation_spin.value = 11
	_expect(app.canvas.tessellation_vertex_count == 11, "The inspector must update the tessellation vertex count")
	_expect(app.canvas.get_tessellation_points().size() == 11, "The canvas must display exactly the requested tessellation vertices")
	app._toggle_curvature(false)
	_expect(not app.canvas.show_curvature, "Curvature visualization must be toggleable")
	app._toggle_curvature(true)

	app.canvas.select_point(2)
	_expect(app.canvas.selected_index == 2, "Control-point selection must update")
	var original_point: Vector2 = app.curve.control_points[2]
	app.curve.control_points[2] += Vector2(25, -10)
	app._on_curve_changed()
	_expect(app.curve.control_points[2].is_equal_approx(original_point + Vector2(25, -10)), "Point edits must update the active curve")
	_expect(app.dirty, "Point edits must mark the document as modified")

	var output_directory := ProjectSettings.globalize_path("res://.godot/test-output")
	DirAccess.make_dir_recursive_absolute(output_directory)
	var document_path := output_directory.path_join("smoke.nurbs.json")
	var svg_path := output_directory.path_join("smoke.svg")
	app._write_document(document_path)
	app._export_svg(svg_path)
	_expect(FileAccess.file_exists(document_path), "Save must create a document")
	_expect(FileAccess.file_exists(svg_path), "Export must create an SVG")
	var svg := FileAccess.get_file_as_string(svg_path)
	_expect(svg.contains("<svg") and svg.contains("<path"), "SVG export must contain path geometry")

	app.queue_free()
	await process_frame
	if failures == 0:
		print("Application smoke tests passed")
	quit(failures)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
