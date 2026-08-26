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

	_expect(app.curve.is_valid(), "Default document must contain a valid curve")
	_expect(app.canvas.curve == app.curve, "Canvas must display the active document")
	_expect(app.canvas.show_curvature, "Curvature visualization must be visible by default")
	app._toggle_curvature(false)
	_expect(not app.canvas.show_curvature, "Curvature visualization must be toggleable")
	app._toggle_curvature(true)

	app.canvas.select_point(2)
	_expect(app.canvas.selected_index == 2, "Control-point selection must update")
	var original_point: Vector2 = app.curve.control_points[2]
	app._on_edit_started()
	app.curve.control_points[2] += Vector2(25, -10)
	app._on_curve_changed()
	app._on_edit_finished()
	app._undo()
	_expect(app.curve.control_points[2].is_equal_approx(original_point), "Undo must restore a point drag")
	app._redo()
	_expect(app.curve.control_points[2].is_equal_approx(original_point + Vector2(25, -10)), "Redo must restore the edit")

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
